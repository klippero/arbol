require 'csv'

namespace :import do

    desc "import from csv"
    task people: :environment do
        filename = File.join Rails.root, "data-personas.csv"

        CSV.foreach(filename, headers: true, liberal_parsing: true, col_sep: ";", quote_char: '"', force_quotes: true) do |row|
            person = {}
            person[:id] = row["id"].to_i
            person[:name] = row["nombre"]
        
            if ( row["apellido_1"] != "" || row["apellido_2"] != "" ) && row["apellidos"] != ""
                p "ERROR #{row["id"]} #{row["apellidos"]}"
            end
        
            if row["apellido_1"] != ""
                person[:surname] = row["apellido_1"]
            end
            if row["apellido_2"] != ""
                person[:surname2] = row["apellido_2"]
            end
            if row["apellidos"] != ""
                words = row["apellidos"].split(" ")
                if words.length > 2
                    p "ERROR"
                end
                person[:surname] = words[0]
                person[:surname2] = words[1]
            end
        
            begin
                id = IncompleteDate.new(str:row["nacimiento"])
                if id.accurate != 0
                    person[:birthdate] = id.date
                    person[:birthdateAcc] = id.accurate
                end
            rescue ArgumentError => e
            end

            person[:birthorder] = row["orden_nacimiento"].to_i if row["orden_nacimiento"].to_i != 0
            person[:birthplace] = row["nacimiento_lugar"]

            begin
                id = IncompleteDate.new(str:row["defuncion"])
                if id.accurate != 0
                    person[:death] = id.date
                    person[:deathAcc] = id.accurate
                end
            rescue ArgumentError => e
            end

            person[:deathplace] = row["defuncion_lugar"]
            person[:comment] = row["comentario"]
            person[:childrenof_id] = row["padres"].to_i if row["padres"].to_i != 0

#            puts row["nacimiento"]
            Person.create( person )
        end
    end

    task family: :environment do
        filename = File.join Rails.root, "data-matrimonios.csv"

        CSV.foreach(filename, headers: true, liberal_parsing: true, col_sep: ";", quote_char: '"', force_quotes: true) do |row|
            family = {}
            family[:id] = row["id"].to_i
            begin
                id = IncompleteDate.new(str:row["boda"])
                if id.accurate != 0
                    family[:marriagedate] = id.date
                    family[:marriagedateAcc] = id.accurate
                end
            rescue ArgumentError => e
            end
            family[:liveplace] = row["vecinos_de"]
            Family.create( family )

            family_person = {}
            family_person[:person_id] = row["hombre"].to_i
            family_person[:family_id] = row["id"].to_i
            FamiliesPerson.create( family_person )

            family_person[:person_id] = row["mujer"].to_i
            FamiliesPerson.create( family_person )
        end
    end

end