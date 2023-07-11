class CreatePhotos < ActiveRecord::Migration[6.1]
  def change
    create_table :photos do |t|
      t.string :title
      t.date :date
      t.integer :dateAcc
      t.string :place
      t.string :owner
      t.text :content

      t.timestamps
    end
  end
end
