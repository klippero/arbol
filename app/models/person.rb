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
            elsif res.length > 0 and not ' +'.include?( res[0] )  # casos 257 554
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
        if ['Yago','Moisés','Ángel','Antonio Abilio','Toribio','Casimiro','Tomás','Félix','José Antonio','Mariano','Santiago','Miguel','Roberto','Amadeo','Miguel Constancio','Daniel','Frasio','Julián','Gabriel','Diego','Ramón','Joaquín','Álvaro'].include?(name)
            return :masculino
        elsif ['Berta','Esmeralda','Delfina','Ángeles','Adelina','María','Florinda','Rosalina','María del Rosario','Marina Victoria','Elena','Virgilia','Lourdes','Cristina','Inés','María Elena','Marta','María Victoria','Ana Rosa','Beatriz','Isabel','Maribel','Teresa','Elvira','Mercedes','Laia','Maite','Marisa','Anabel','Simona','Julita','Margarita','Florencia','Ángela','Antonia','Alba','Lucía','Laura','Marina'].include?(name)
            return :femenino
        else
            return nil
        end
    end

    def relacionCon( otro )
        res = ''
        if otro != self
            if otro.hermanoDe(self)
                res = otro.genero == :masculino ? 'hermano' : ( otro.genero == :femenino ? 'hermana' : 'herman@' )
            elsif otro.mediohermanoDe(self)
                res = otro.genero == :masculino ? '½ hermano' : ( otro.genero == :femenino ? '½ hermana' : '½ herman@' )
            elsif otro.padreDe(self)
                res = otro.genero == :masculino ? 'padre' : ( otro.genero == :femenino ? 'madre' : 'progenitor' )
            elsif otro.hijoDe(self)
                res = otro.genero == :masculino ? 'hijo' : ( otro.genero == :femenino ? 'hija' : 'hij@' )
            elsif otro.consorteDe(self)
                res = 'consorte'
            elsif otro.nietoDe(self)
                res = otro.genero == :masculino ? 'nieto' : ( otro.genero == :femenino ? 'nieta' : 'niet@' )
            elsif otro.abueloDe(self)
                res = otro.genero == :masculino ? 'abuelo' : ( otro.genero == :femenino ? 'abuela' : 'abuel@' )
            elsif otro.cunadoDe(self)
                res = otro.genero == :masculino ? 'cuñado' : ( otro.genero == :femenino ? 'cuñada' : 'cuñad@' )
            elsif otro.concunadoDe(self)
                res = otro.genero == :masculino ? 'concuñado' : ( otro.genero == :femenino ? 'concuñada' : 'concuñad@' )
            elsif otro.tioDe(self)
                res = otro.genero == :masculino ? 'tío' : ( otro.genero == :femenino ? 'tía' : 'tí@' )
            elsif otro.sobrinoDe(self)
                res = otro.genero == :masculino ? 'sobrino' : ( otro.genero == :femenino ? 'sobrina' : 'sobrin@' )
            elsif otro.primoDe(self)
                res = otro.genero == :masculino ? 'primo' : ( otro.genero == :femenino ? 'prima' : 'prim@' )
            elsif otro.yernoDe(self)
                res = otro.genero == :masculino ? 'yerno' : ( otro.genero == :femenino ? 'nuera' : 'nuer@' )
            elsif otro.suegroDe(self)
                res = otro.genero == :masculino ? 'suegro' : ( otro.genero == :femenino ? 'suegra' : 'suegr@' )
            elsif otro.consuegroDe(self)
                res = otro.genero == :masculino ? 'consuegro' : ( otro.genero == :femenino ? 'consuegra' : 'consuegr@' )
            end
        end
        return res
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

    def difDates
        d1 = IncompleteDate.new(date:birthdate,accurate:birthdateAcc)
        d2 = IncompleteDate.new(date:Date.new(2010,12,6),accurate:7)
        return d1.difDates(d2).to_s
    end
end
