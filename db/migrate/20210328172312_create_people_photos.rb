class CreatePeoplePhotos < ActiveRecord::Migration[6.1]
  def change
    create_table :people_photos do |t|
      t.integer :person_id
      t.integer :photo_id

      t.timestamps
    end
  end
end
