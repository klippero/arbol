class CreateFamiliesPeople < ActiveRecord::Migration[6.1]
  def change
    create_table :families_people do |t|
      t.integer :person_id
      t.integer :family_id

      t.timestamps
    end
  end
end
