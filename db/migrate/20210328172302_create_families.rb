class CreateFamilies < ActiveRecord::Migration[6.1]
  def change
    create_table :families do |t|
      t.string :familyname
      t.string :liveplace
      t.date :marriagedate
      t.integer :marriagedateAcc

      t.timestamps
    end
  end
end
