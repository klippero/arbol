class Family < ApplicationRecord
    has_many :children, class_name: "Person", foreign_key: :childrenof_id, inverse_of: :childrenof
    has_and_belongs_to_many :consorts, class_name: "Person", inverse_of: :consortof    

    def otherconsort( a )
        resp = ""
        self.consorts.each { |consort|
            resp += consort.name unless consort == a
        }
        return resp
    end

    def firstOtherconsort( a )
        # devuelve el primer consorte que no sea el recibido
        i=0
        while i<consorts.size and a==consorts[i]
            i = i+1
        end
        return ( a!=consorts[i] ? consorts[i] : nil )
    end

    def name
        result = ( self.familyname.nil? ? '' : self.familyname )
        if result.blank?
            self.consorts.each { |consort|
                if consort.surname
                    result += consort.surname + ' '
                end
            }
        end
        return result
    end
end
