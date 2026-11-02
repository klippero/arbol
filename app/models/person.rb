class Person < ApplicationRecord
    belongs_to :childrenof, optional: true, inverse_of: :children, class_name: "Family"
    has_many :people_photos
    has_many :photos, through: :people_photos
    has_many :owned_photos, class_name: "Photo", foreign_key: :owner_person_id, inverse_of: :owner_person
    has_and_belongs_to_many :consortof, class_name: "Family", inverse_of: :consorts

    # grados de parentesco colateral que se consideran "familia": hasta el antepasado común
    # tatarabuelo (cubre también hermanos de bisabuelos, como un tío bisabuelo, y primos de
    # tercer grado), el mismo tope que relacionCon ya nombra con :tatarabuelo.
    MAX_COLLATERAL_GENERATIONS = 4

    # etiquetas en plural para la línea de parentesco colateral (ver parentesco_filas)
    RELACION_LATERAL_PLURAL = {
        hermano: { masculino: "hermanos", femenino: "hermanas" },
        medio_hermano: { masculino: "½ hermanos", femenino: "½ hermanas" },
        primo: { masculino: "primos", femenino: "primas" },
        primo2: { masculino: "primos segundos", femenino: "primas segundas" }
    }.freeze

    # ids de los ascendientes directos de una persona (padres, abuelos, bisabuelos...),
    # sin límite de generaciones: su propia línea de sangre siempre cuenta como familia.
    def self.direct_ancestors_ids(root)
        visited = { root.id => true }
        queue = [root]
        until queue.empty?
            (queue.shift.childrenof&.consorts.to_a || []).each do |padre|
                next if visited[padre.id]
                visited[padre.id] = true
                queue << padre
            end
        end
        visited.keys
    end

    # ids de una persona y todos sus descendientes, sin límite de generaciones.
    # Admite un hash "visited" compartido para acumular varias llamadas sin repetir trabajo.
    def self.descendants_ids(root, visited = {})
        queue = [root]
        visited[root.id] = true
        until queue.empty?
            queue.shift.consortof.flat_map(&:children).each do |hijo|
                next if visited[hijo.id]
                visited[hijo.id] = true
                queue << hijo
            end
        end
        visited
    end

    # ids de parientes sanguíneos de root (o ella misma): su línea de ascendientes directos
    # (sin límite, siempre familia) más todos los descendientes de cada antepasado hasta
    # MAX_COLLATERAL_GENERATIONS generaciones hacia arriba (cubre hermanos, tíos, primos,
    # primos segundos... con sus respectivos descendientes). Así un antepasado muy lejano no
    # "contagia" parentesco con todo lo que ese antepasado conecta en un árbol muy tupido.
    def self.blood_closure_ids(root)
        result = {}
        direct_ancestors_ids(root).each { |id| result[id] = true }

        generacion = [root]
        gen = 0
        while gen <= MAX_COLLATERAL_GENERATIONS && generacion.any?
            generacion.each { |ascendiente| descendants_ids(ascendiente, result) }
            gen += 1
            generacion = generacion.flat_map { |p| p.childrenof&.consorts.to_a }.uniq
        end

        result.keys
    end

    # ids de las personas con parentesco sanguíneo o político con root, o root misma:
    # - :blood ids de parientes de sangre (de cualquier grado, con el tope de colateralidad de arriba)
    # - :all además añade:
    #   · por la propia pareja de root, todos SUS parientes de sangre (hermanos, sobrinos, primos...
    #     con el mismo tope de colateralidad: mi cuñado y sus hijos sí cuentan como familia política
    #     mía)
    #   · por un padrastro/madrastra de root (la pareja de un progenitor en OTRA familia distinta a
    #     la propia), también todos SUS parientes de sangre: su familia es tan política para mí como
    #     la de mi propia pareja
    #   · para el resto de parientes de sangre, en cambio, solo se añade su cónyuge y los
    #     descendientes de ambos (NO se sube por la línea de ascendientes/colaterales del cónyuge: la
    #     abuela o el hermano del marido de mi prima no se consideran familia política mía, solo lo
    #     sería la familia de MI PROPIA pareja o la de un padrastro/madrastra míos)
    # Se cachea porque recorrer todo el árbol es costoso y el parentesco apenas cambia.
    def self.relatedness_to(root)
        return { blood: [], all: [] } unless root

        Rails.cache.fetch("person_relatedness_v4_#{root.id}", expires_in: 1.hour) do
            blood_ids = blood_closure_ids(root)
            result = {}
            blood_ids.each { |id| result[id] = true }

            root.consortof.flat_map(&:consorts).each do |conyuge|
                next if result[conyuge.id]
                blood_closure_ids(conyuge).each { |id| result[id] = true }
            end

            root.childrenof&.consorts.to_a.each do |progenitor|
                progenitor.consortof.each do |otra_familia|
                    next if otra_familia == root.childrenof
                    otra_familia.consorts.each do |padrastro|
                        next if padrastro == progenitor || result[padrastro.id]
                        blood_closure_ids(padrastro).each { |id| result[id] = true }
                    end
                end
            end

            where(id: blood_ids - [root.id]).find_each do |persona|
                persona.consortof.flat_map(&:consorts).each do |conyuge|
                    next if result[conyuge.id]
                    descendants_ids(conyuge, result)
                end
            end

            { blood: blood_ids, all: result.keys }
        end
    end

    def self.related_to_ids(root)
        relatedness_to(root)[:all]
    end

    def self.blood_related_to_ids(root)
        relatedness_to(root)[:blood]
    end

    # camino más corto de "from" a "to" recorriendo solo enlaces padre/hijo/cónyuge, restringido a
    # personas que ya cuentan como parientes de "from" (evita atajos por desconocidos de paso).
    # Devuelve un array de pasos: [{ person:, tipo:, nivel: }, ...], donde el primer paso es "from"
    # (tipo nil, nivel 0) y cada paso siguiente indica cómo se llega a esa persona desde la anterior:
    # tipo es :sanguinea o :politica, y nivel es la generación relativa a "from" (negativo = hacia
    # arriba/ascendientes, positivo = hacia abajo/descendientes, igual nivel = misma generación).
    # Devuelve nil si no hay camino.
    def self.path_between(from, to)
        return nil unless from && to
        return [{ person: from, tipo: nil, nivel: 0 }] if from == to

        allowed = relatedness_to(from)[:all].to_set
        allowed << from.id << to.id

        visited = { from.id => true }
        predecessor = {}
        queue = [from]

        until queue.empty?
            current = queue.shift
            vecinos = []
            (current.childrenof&.consorts.to_a || []).each { |p| vecinos << [p, :sanguinea, -1] }
            current.consortof.flat_map(&:children).each { |c| vecinos << [c, :sanguinea, 1] }
            current.consortof.flat_map(&:consorts).each { |s| vecinos << [s, :politica, 0] unless s == current }

            vecinos.each do |(vecino, tipo, delta)|
                next unless allowed.include?(vecino.id)
                next if visited[vecino.id]
                visited[vecino.id] = true
                predecessor[vecino.id] = [current, tipo, delta]

                if vecino == to
                    path = []
                    node = vecino
                    while node != from
                        prev, paso_tipo, paso_delta = predecessor[node.id]
                        path.unshift({ person: node, tipo: paso_tipo, delta: paso_delta })
                        node = prev
                    end
                    path.unshift({ person: from, tipo: nil, delta: 0 })

                    nivel = 0
                    path.each { |paso| nivel += paso[:delta]; paso[:nivel] = nivel }
                    return path
                end

                queue << vecino
            end
        end

        nil
    end

    # agrupa un camino (ver path_between) en filas por nivel generacional, añadiendo a cada
    # ascendiente el cónyuge que falte cuando dos de sus hijos ya aparecen en el camino (p.ej. dos
    # hermanos ambos en la ruta): así se ve a la pareja completa, aunque el camino más corto no
    # pasara por ese cónyuge. Devuelve [[nivel, [paso, ...]], ...] ordenado de ascendientes a
    # descendientes; cada paso añadido lleva tipo: :politica y extra: true (sin "idx").
    def self.parentesco_filas(camino)
        return [] unless camino

        camino_indexado = camino.each_with_index.map { |paso, idx| paso.merge(idx: idx) }
        personas_en_camino = camino_indexado.map { |paso| paso[:person] }.to_set
        familias_vistas = Set.new
        extra_por_persona = Hash.new { |h, k| h[k] = [] }

        camino_indexado.each do |paso|
            familia = paso[:person].childrenof
            next unless familia && !familias_vistas.include?(familia.id)

            hijos_en_camino = familia.children.count { |hijo| personas_en_camino.include?(hijo) }
            next unless hijos_en_camino >= 2

            familias_vistas << familia.id

            # el cónyuge que falta se añade junto al progenitor que SÍ está en el camino (no junto
            # al hijo que disparó la comprobación, que está una generación más abajo)
            padre_en_camino = camino_indexado.find { |p| familia.consorts.include?(p[:person]) }
            next unless padre_en_camino

            familia.consorts.each do |consorte|
                next if personas_en_camino.include?(consorte)
                extra_por_persona[padre_en_camino[:person].id] << { person: consorte, nivel: padre_en_camino[:nivel], tipo: :politica, extra: true }
            end
        end

        grupos = camino_indexado.group_by { |paso| paso[:nivel] }.sort_by { |nivel, _| nivel }

        # cada "unidad" es una caja a dibujar: una persona sola, o una pareja junta en la misma caja
        dom_id_de = {}
        grupos_unidades = grupos.map do |nivel, pasos|
            fila = pasos.flat_map { |paso| [paso] + extra_por_persona[paso[:person].id] }

            unidades = []
            i = 0
            while i < fila.length
                actual = fila[i]
                siguiente = fila[i + 1]
                # si el camino entra o sale de esta pareja por un hijo compartido, solo son pareja de
                # verdad si ese hijo lo es de AMBOS: si no, el camino solo pasa por el OTRO matrimonio
                # de uno de los dos y no deben aparecer juntos en la misma caja (p.ej. "actual" es
                # madre/padre de quien viene justo antes en el camino, pero de otro matrimonio suyo)
                predecesor_de_actual = actual[:idx] && actual[:idx] > 0 ? camino_indexado[actual[:idx] - 1] : nil
                seguro_hacia_atras =
                    predecesor_de_actual.nil? || actual[:tipo] != :sanguinea || actual[:delta] != -1 ||
                    predecesor_de_actual[:person].childrenof&.consorts&.include?(siguiente && siguiente[:person])

                es_pareja = siguiente && seguro_hacia_atras && (
                    siguiente[:extra] ||
                    (
                        siguiente[:tipo] == :politica && actual[:idx] && siguiente[:idx] == actual[:idx] + 1 &&
                        (
                            (siguiente_hijo = camino_indexado[siguiente[:idx] + 1]).nil? ||
                            siguiente_hijo[:tipo] != :sanguinea || siguiente_hijo[:delta] != 1 ||
                            siguiente_hijo[:person].childrenof&.consorts&.include?(actual[:person])
                        )
                    )
                )

                personas = es_pareja ? [actual, siguiente] : [actual]
                dom_id = "u-#{personas.map { |p| p[:person].id }.join('-')}"
                personas.each { |p| dom_id_de[p[:person].id] = dom_id }
                unidades << { dom_id: dom_id, personas: personas }
                i += es_pareja ? 2 : 1
            end

            [nivel, unidades]
        end

        # resuelve, para cada unidad, a qué otra unidad (ya fusionada o no) apunta su arista
        # entrante (sanguínea o política); si la unidad es una pareja ya fusionada, "actual" va
        # primero en personas y su arista sanguínea gana, así que esto solo añade una línea nueva
        # cuando el cónyuge queda en su propia caja (p.ej. un matrimonio que no comparte al hijo
        # por el que continúa el camino, como el "otro" matrimonio de alguien)
        grupos_unidades.each do |_nivel, unidades|
            unidades.each do |unidad|
                paso_con_arista = unidad[:personas].find { |p| p[:idx] && p[:idx] > 0 && [:sanguinea, :politica].include?(p[:tipo]) }
                next unless paso_con_arista

                predecesor = camino_indexado[paso_con_arista[:idx] - 1]
                predecesor_dom_id = dom_id_de[predecesor[:person].id]
                next if predecesor_dom_id == unidad[:dom_id]

                unidad[:prev_dom_id] = predecesor_dom_id
                unidad[:prev_tipo] = paso_con_arista[:tipo]
                unidad[:prev_persona_id] = predecesor[:person].id
                unidad[:destino_persona_id] = paso_con_arista[:person].id
            end
        end

        # cuando dos unidades consecutivas de un mismo nivel son parientes colaterales directos
        # (hermanos, primos, primos segundos), se marca esa relación en plural junto a la primera: no
        # basta con comparar solo las dos primeras del nivel, porque puede haber de por medio una
        # unidad "ajena" a la línea colateral (p.ej. el cónyuge de alguien, sin parentesco de sangre
        # con nadie más del nivel), así que se prueban todos los pares consecutivos hasta encontrar
        # uno con una relación reconocida; y dentro de cada unidad se prueban TODAS sus personas (no
        # solo la primera), porque en una pareja fusionada quien de verdad sigue la línea de sangre
        # colateral puede ser el cónyuge "extra", no quien iba primero en el camino
        grupos_unidades.each do |_nivel, unidades|
            (0...(unidades.size - 1)).each do |i|
                match = nil

                unidades[i][:personas].each do |pi|
                    unidades[i + 1][:personas].each do |pj|
                        kind = pi[:person].relacionCon(pj[:person]).kind
                        etiqueta = RELACION_LATERAL_PLURAL[kind]
                        next unless etiqueta

                        match = [pi[:person], pj[:person], etiqueta]
                        break
                    end
                    break if match
                end

                next unless match

                persona_i, persona_j, etiqueta = match
                ambas_femeninas = [persona_i, persona_j].all? { |p| p.genero == :femenino }
                unidades[i][:relacion_lateral] = etiqueta[ambas_femeninas ? :femenino : :masculino]
                break
            end
        end

        grupos_unidades
    end

    def fullname
        ( self.name ? self.name : "" ) + ( self.surname ? " " + self.surname : "" ) + ( self.surname2 ?  " " + self.surname2 : "" )
    end

    def addDates
        @birthdateIncomplete = IncompleteDate.new(date:birthdate,accurate:birthdateAcc)
        @deathIncomplete = IncompleteDate.new(date:death,accurate:deathAcc)
    end

    def dates
        birthdateIncomplete = IncompleteDate.new(date:birthdate,accurate:birthdateAcc)
        deathIncomplete = IncompleteDate.new(date:death,accurate:deathAcc)
        res = birthdateIncomplete.to_s
        if !birthplace.blank?
            res += " " + birthplace
        end
        if deathIncomplete.to_s != '' or not deathplace.blank?
            res += ( res == '' ? '+' : " - " ) + deathIncomplete.to_s
            if !deathplace.blank?
                res += " " + deathplace
            end
        end

        if fallecio?
            edad_al_morir = birthdateIncomplete.to(deathIncomplete)[:str]
            if !deathAcc.nil? && deathAcc != 0 && birthdateIncomplete.accurate != 0 && edad_al_morir.present?
                res += ' (+' + edad_al_morir + ')'
            elsif res.empty?
                res = '+'
            elsif not ' +'.include?( res[0] )  # casos 257 554
                res += ' +'
            end
        else
            if !birthdate.nil? && birthdateIncomplete.toStr.present?
                res += ' (' + birthdateIncomplete.toStr + ')'
            end
        end

        return res
    end

    def info_to_dropdown
        "#{fullname} #{dates}"
    end

    # "Nombre (edad)" con la edad que tenía en la fecha dada (p.ej. la fecha de una foto),
    # no la edad actual. Sin paréntesis si no se puede calcular (sin fecha de nacimiento,
    # sin fecha de referencia, o sin precisión de año en alguna de las dos).
    def info_con_edad_en(ref_date, ref_dateAcc)
        return fullname if birthdate.nil?
        edad = IncompleteDate.new(date: birthdate, accurate: birthdateAcc)
                             .toStr(IncompleteDate.new(date: ref_date, accurate: ref_dateAcc))
        edad.present? ? "#{fullname} (#{edad})" : fullname
    end

    def fullNameDatesNoPhotos
        fullname + ( dates != '' ? ' (' + dates + ')' : '' ) + ( photos.count > 1 ? ' ' + photos.count.to_s : '' )
    end

    def noName
        ( birthorder.nil? ? '-' : birthorder.to_s + '.' ) + ' ' + name
    end

    def medioHermanos
        res = []
        familia = childrenof
        if !familia.nil?
            familia.consorts.each do |consort|
                consort.consortof.each do |familia2|
                    if familia2 != familia
                        res += familia2.children
                    end
             end
            end
        end
        return res
    end

    # nombres femeninos terminados en "o" (advocaciones marianas, la excepción
    # más conocida a la regla "-o = masculino" en español)
    FEMENINOS_TERMINADOS_EN_O = %w[amparo consuelo rosario socorro rocío loreto].freeze

    # nombres femeninos que no terminan en "a": ni la terminación en "o" ni en
    # "a" los delata, así que son la única excepción real que hace falta mantener
    FEMENINOS_EXCEPCION = %w[
        ángeles lourdes inés beatriz isabel maribel mercedes maite anabel
        dolores soledad pilar carmen cruz paz luz esther raquel noemí
        nieves belén milagros marisol araceli angelines ariane caroline
        eduvigis encarnación concepción purificación felicitas montse
        mari tere rosi july leire miren maitane valerie natividad matilde
    ].freeze

    # determina el género a partir de la terminación del primer nombre (en
    # compuestos, el primero manda: "María José" es femenino, "José María" es
    # masculino), sin necesidad de un diccionario por persona:
    # - termina en "a" -> femenino
    # - termina en "o" -> masculino, salvo las advocaciones marianas conocidas
    # - cualquier otra terminación -> masculino, salvo la lista corta de
    #   excepciones femeninas conocidas
    def genero
        primer_nombre = name.to_s.split.first.to_s.downcase
        return nil if primer_nombre.blank?

        if primer_nombre.end_with?('a')
            :femenino
        elsif primer_nombre.end_with?('o')
            FEMENINOS_TERMINADOS_EN_O.include?(primer_nombre) ? :femenino : :masculino
        elsif FEMENINOS_EXCEPCION.include?(primer_nombre)
            :femenino
        else
            :masculino
        end
    end

    def relacionCon( otro )
        return RelacionFamiliar.new(:ninguna, nil) if otro == self

        kind =
            if otro.hermanoDe(self)
                :hermano
            elsif otro.mediohermanoDe(self)
                :medio_hermano
            elsif otro.padreDe(self)
                :padre
            elsif otro.hijoDe(self)
                :hijo
            elsif otro.hijastroDe(self)
                :hijastro
            elsif otro.padrastroDe(self)
                :padrastro
            elsif otro.consorteDe(self)
                :consorte
            elsif otro.nietoDe(self)
                :nieto
            elsif otro.abueloDe(self)
                :abuelo
            elsif otro.bisnietoDe(self)
                :bisnieto
            elsif otro.bisabueloDe(self)
                :bisabuelo
            elsif otro.tataranietoDe(self)
                :tataranieto
            elsif otro.tatarabueloDe(self)
                :tatarabuelo
            elsif otro.cunadoDe(self)
                :cunado
            elsif otro.concunadoDe(self)
                :concunado
            elsif otro.tioDe(self)
                :tio
            elsif otro.sobrinoDe(self)
                :sobrino
            elsif otro.tioPoliticoDe(self)
                :tio_politico
            elsif otro.sobrinoPoliticoDe(self)
                :sobrino_politico
            elsif otro.primoDe(self)
                :primo
            elsif otro.primo2de(self)
                :primo2
            elsif otro.yernoDe(self)
                :yerno
            elsif otro.suegroDe(self)
                :suegro
            elsif otro.consuegroDe(self)
                :consuegro
            end

        kind ? RelacionFamiliar.new(kind, otro.genero) : RelacionFamiliar.new(:ninguna, nil)
    end

    def hermanoDe(otro)
        !otro.nil? && otro != self && !childrenof.nil? && !otro.childrenof.nil? &&
            childrenof == otro.childrenof
    end

    def mediohermanoDe(otro)
        !otro.nil? && !otro.childrenof.nil? && !otro.childrenof.consorts.nil? && !childrenof.nil? && !childrenof.consorts.nil? && !( otro.childrenof.consorts & childrenof.consorts ).blank?
    end

    def padreDe(otro)
        !otro.childrenof.nil? &&
            consortof.include?(otro.childrenof)
    end

    def hijoDe(otro)
        otro.padreDe(self)
    end

    # hijo de uno de los consortes de otro, pero no de otro mismo
    def hijastroDe(otro)
        return false if childrenof.nil? || otro.padreDe(self)
        childrenof.consorts.any? { |padre| padre != otro && padre.consorteDe(otro) }
    end

    def padrastroDe(otro)
        otro.hijastroDe(self)
    end

    def consorteDe(otro)
        ( consortof & otro.consortof ).length > 0
    end

    def nietoDe(otro)
        # alguno de sus padres es hijo de otro
        nieto = false
        i=0
        while !childrenof.nil? && !nieto && i<childrenof.consorts.size
            nieto = childrenof.consorts[i].hijoDe(otro)
            i+=1
        end
        return nieto
    end

    def abueloDe(otro)
        otro.nietoDe(self)
    end

    def bisnietoDe(otro)
        # alguno de sus padres es nieto de otro
        bisnieto = false
        i=0
        while !childrenof.nil? && !bisnieto && i<childrenof.consorts.size
            bisnieto = childrenof.consorts[i].nietoDe(otro)
            i+=1
        end
        return bisnieto
    end

    def bisabueloDe(otro)
        otro.bisnietoDe(self)
    end

    def tataranietoDe(otro)
        # alguno de sus padres es bisnieto de otro
        tataranieto = false
        i=0
        while !childrenof.nil? && !tataranieto && i<childrenof.consorts.size
            tataranieto = childrenof.consorts[i].bisnietoDe(otro)
            i+=1
        end
        return tataranieto
    end

    def tatarabueloDe(otro)
        otro.tataranietoDe(self)
    end

    def cunadoDe(otro)
        cunado = false

        # alguno de sus consortes es hermano de otro
        i=0
        while !cunado && i<consortes.size
            cunado = consortes[i].hermanoDe(otro)
            i+=1
        end

        # alguno de sus hermanos es consorte de otro
        i=0
        while !childrenof.nil? && !cunado && i<childrenof.children.size
            cunado = childrenof.children[i].consorteDe(otro)
            i+=1
        end

        return cunado
    end

    def concunadoDe(otro)
        concunado = false
        i=0
        while !concunado && i<consortes.size
            concunado = consortes[i].cunadoDe(otro)
            i+=1
        end
        return concunado
    end

    def sobrinoDe(otro)
        otro.tioDe(self)
    end

    # Santiago.tioDe(Lourdes)
    def tioDe(otro)
        # hermano de sangre de uno de los padres de otro (tío carnal, no político)
        tio = false
        i=0
        while !otro.childrenof.nil? && !tio && i<otro.childrenof.consorts.size
            tio = hermanoDe(otro.childrenof.consorts[i])
            i+=1
        end
        return tio
    end

    # cónyuge de un tío carnal (no de sangre): Tere.tioPoliticoDe(Miguel) si Tere está
    # casada con Félix y Félix es hermano de uno de los padres de Miguel
    def tioPoliticoDe(otro)
        return false if tioDe(otro)
        consortes.any? { |conyuge| conyuge.tioDe(otro) }
    end

    def sobrinoPoliticoDe(otro)
        otro.tioPoliticoDe(self)
    end

    # Maribel.primoDe(Lourdes)
    def primoDe(otro)
        primo = false
        i=0
        while !otro.childrenof.nil? && !primo && i<otro.childrenof.consorts.size
            primo = otro.childrenof.consorts[i].tioDe(self)
            i+=1
        end
        return primo
    end

    # Primos segundos: algún padre/madre de uno es primo de un padre/madre del otro.
    def primo2de(otro)
        return false if otro.nil? || otro == self
        return false if childrenof.nil? || otro.childrenof.nil?

        childrenof.consorts.each do |p_self|
            otro.childrenof.consorts.each do |p_otro|
                return true if p_self.primoDe(p_otro) || p_otro.primoDe(p_self)
            end
        end
        false
    end

    # Felix.yernoDe(Toribio)
    def yernoDe(otro)
        yerno = false
        i=0
        while !yerno && i<consortes.size
            yerno = consortes[i].hijoDe(otro)
            i+=1
        end
        return yerno
    end

    def suegroDe(otro)
        otro.yernoDe(self)
    end

    def consuegroDe(otro)
        consuegro = false
        i = 0
        while !consuegro && i<children.size
            consuegro = children[i].yernoDe(otro)
            i+=1
        end
        return consuegro
    end

    def consortes
        res = []
        consortof.each do |familia|
            res += familia.consorts
            res.delete(self)
        end
        return res
    end

    def children
        res = []
        consortof.each do |familia|
            res += familia.children
        end
        return res
    end

    def fallecio?
        #si tiene fecha de fallecicimiento o acc=0
        return true if !death.nil?
        return true if !deathAcc.nil? && deathAcc == 0
        return true if [1,3,7].include?(birthdateAcc) && IncompleteDate.new(date:birthdate,accurate:birthdateAcc).edad() > 120

        # sin fecha de nacimiento propia: si la boda de sus padres fue hace más de 120 años,
        # esta persona no puede seguir viva (nació como pronto en esa fecha)
        if birthdate.nil? && childrenof && [1,3,7].include?(childrenof.marriagedateAcc)
            return true if IncompleteDate.new(date: childrenof.marriagedate, accurate: childrenof.marriagedateAcc).edad() > 120
        end

        false
    end

    def nextBirthday
        result = IncompleteDate.new(date:birthdate,accurate:birthdateAcc).to[:nextSameDay]
        return result
    end

    def days2birthday
        result = IncompleteDate.new(date:birthdate,accurate:birthdateAcc).to[:days2sameDay]
        return result
    end

    # "16/4" cuando hay mes y día de nacimiento (d/m sin ceros a la izquierda)
    def nacimiento_dia_mes_corto
        inc = IncompleteDate.new(date: birthdate, accurate: birthdateAcc)
        return nil unless birthdate && inc.month? && inc.day?
        "#{inc.day}/#{inc.month}"
    end

    def edad_en_fecha(d)
        return nil unless birthdate && d
        return nil unless IncompleteDate.new(date: birthdate, accurate: birthdateAcc).year?
        d.year - birthdate.year - ((d.month > birthdate.month || (d.month == birthdate.month && d.day >= birthdate.day)) ? 0 : 1)
    end

    # "27/4" día/mes de defunción cuando hay mes y día conocidos
    def defuncion_dia_mes_corto
        return nil unless death
        di = IncompleteDate.new(date: death, accurate: deathAcc)
        return nil unless di.month? && di.day?
        "#{di.day}/#{di.month}"
    end

    # Años completos transcurridos desde la defunción hasta hoy
    def annos_desde_fallecimiento(ref = Date.current)
        return nil unless death
        return nil unless IncompleteDate.new(date: death, accurate: deathAcc).year?
        ref.year - death.year - ((ref.month > death.month || (ref.month == death.month && ref.day >= death.day)) ? 0 : 1)
    end

    def difDates
        d1 = IncompleteDate.new(date:birthdate,accurate:birthdateAcc)
        d2 = IncompleteDate.new(date:Date.new(2010,12,6),accurate:7)
        return d1.difDates(d2).to_s
    end

    def apellidos_genealogicos
        apellidos_rec(Set.new).reverse.drop_while { |ap, _| ap == '---' }.reverse
    end

    protected

    # Si no tiene apellido 1, toma el apellido 2 y lo separa en dos por el primer espacio.
    def effective_surnames
        s1 = surname.presence
        s2 = surname2.presence
        if s1.nil? && s2&.include?(' ')
            parts = s2.split(' ', 2)
            [parts[0], parts[1]]
        else
            [s1, s2]
        end
    end

    def apellidos_rec(visited)
        return [] if visited.include?(id)
        visited << id

        parents = childrenof&.consorts.to_a
        if parents.empty?
            s1, s2 = effective_surnames
            list = []
            list << [s1, self] if s1.present?
            list << [s2, self] if s2.present?
            return list
        end

        eff_s1, eff_s2 = effective_surnames
        father = parents.find { |p| p.surname == eff_s1 } || parents.first
        mother = (parents - [father]).first

        f_list = father.apellidos_rec(visited)
        m_list = mother ? mother.apellidos_rec(visited) : []
        merged = zip_merge(f_list, m_list)

        if merged.empty?
            list = []
            list << [eff_s1, father] if eff_s1.present?
            list << [eff_s2, mother || father] if eff_s2.present?
            return list
        end

        if merged[0]
            ap = (eff_s1.present? && merged[0][0] != eff_s1) ? eff_s1 : merged[0][0]
            merged[0] = [ap, father]
        end
        if merged[1]
            ap = (eff_s2.present? && merged[1][0] != eff_s2) ? eff_s2 : merged[1][0]
            merged[1] = [ap, mother]
        end
        merged
    end

    private

    def zip_merge(a, b)
        n = [a.size, b.size].max
        out = []
        n.times do |i|
            out << (i < a.size ? a[i] : ['---', nil])
            out << (i < b.size ? b[i] : ['---', nil])
        end
        out
    end
end
