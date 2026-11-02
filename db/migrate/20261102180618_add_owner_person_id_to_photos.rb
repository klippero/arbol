class AddOwnerPersonIdToPhotos < ActiveRecord::Migration[8.1]
  def change
    add_column :photos, :owner_person_id, :integer
  end
end
