class Photo < ApplicationRecord
    has_many :people_photos, dependent: :destroy
    has_many :people, through: :people_photos
    accepts_nested_attributes_for :people_photos, allow_destroy: true
    has_one_attached :image

    def info_to_dropdown
        d = IncompleteDate.new(date:date,accurate:dateAcc)
        "#{title} #{d.to_s}"
    end

    def familyMatch(family)
        persons = []
        family.consorts.each do |consort|
            persons << consort
        end
        family.children.each do |son|
            persons << son
        end
        return peopleMatch(persons)
    end

    def peopleMatch(group)
        inPhoto = 0
        group.each do |person|
            if people.include?(person)
                inPhoto += 1
            end
        end
        return inPhoto.to_f / group.size
    end
end