class AddBoundingBoxToPeoplePhotos < ActiveRecord::Migration[8.1]
  def change
    add_column :people_photos, :x, :float
    add_column :people_photos, :y, :float
    add_column :people_photos, :width, :float
    add_column :people_photos, :height, :float
  end
end
