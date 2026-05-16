class Person < ApplicationRecord
    belongs_to :childrenof, optional: true, inverse_of: :children, class_name: "Family"
    has_and_belongs_to_many :photos
    has_and_belongs_to_many :consortof, class_name: "Family", inverse_of: :consorts

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
            if !deathAcc.nil? && deathAcc != 0 && birthdateIncomplete.accurate != 0
                res += ' (+' + birthdateIncomplete.to(deathIncomplete)[:str] + ')'
            elsif res.empty?
                res = '+'
            elsif not ' +'.include?( res[0] )  # casos 257 554
                res += ' +'
            end
        else
            if !birthdate.nil?
                res += ' (' + birthdateIncomplete.toStr + ')'
            end
        end

        return res
    end

    def info_to_dropdown
        "#{fullname} #{dates}"
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

    def genero
        if ['Ramón','Joaquín','Álvaro','Yago','Moisés','Ángel','Antonio Abilio','Toribio','Casimiro','Tomás','Félix','José Antonio','Mariano','Santiago','Miguel','Roberto','Amadeo','Miguel Constancio','Daniel','Frasio','Julián','Gabriel','Diego','Ramón','Joaquín','Álvaro'].include?(name)
            return :masculino
        elsif ['Laura','Marina','Berta','Esmeralda','Delfina','Ángeles','Adelina','María','Florinda','Rosalina','María del Rosario','Marina Victoria','Elena','Virgilia','Lourdes','Cristina','Inés','María Elena','Marta','María Victoria','Ana Rosa','Beatriz','Isabel','Maribel','Teresa','Elvira','Mercedes','Laia','Maite','Marisa','Anabel','Simona','Julita','Margarita','Florencia','Ángela','Antonia','Alba','Lucía','Laura','Marina'].include?(name)
            return :femenino
        else
            return nil
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
            elsif otro.consorteDe(self)
                :consorte
            elsif otro.nietoDe(self)
                :nieto
            elsif otro.abueloDe(self)
                :abuelo
            elsif otro.cunadoDe(self)
                :cunado
            elsif otro.concunadoDe(self)
                :concunado
            elsif otro.tioDe(self)
                :tio
            elsif otro.sobrinoDe(self)
                :sobrino
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
        # hermano o consorte de uno de mis padres
        tio = false
        i=0
        while !otro.childrenof.nil? && !tio && i<otro.childrenof.consorts.size
            tio = hermanoDe(otro.childrenof.consorts[i])
            #también de consortes (hasta aquí tío carnal)
            j=0
            cons = consortes
            while !tio && j<cons.size
                tio = cons[j].hermanoDe(otro.childrenof.consorts[i])
                j+=1
            end
            i+=1
        end
        return tio
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
        !death.nil? || ( !deathAcc.nil? && deathAcc == 0 ) || ( [1,3,7].include?(birthdateAcc) && IncompleteDate.new(date:birthdate,accurate:birthdateAcc).edad() > 120 )
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
