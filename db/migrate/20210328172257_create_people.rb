class CreatePeople < ActiveRecord::Migration[6.1]
  def change
    create_table :people do |t|
      t.string :name
      t.string :surname
      t.string :surname2
      t.date :birthdate
      t.integer :birthdateAcc
      t.integer :birthorder
      t.string :birthplace
      t.date :death
      t.integer :deathAcc
      t.string :deathplace
      t.text :comment
      t.integer :childrenof_id

      t.timestamps
    end
  end
end
