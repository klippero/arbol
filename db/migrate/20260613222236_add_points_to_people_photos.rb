class AddPointsToPeoplePhotos < ActiveRecord::Migration[8.1]
  def change
    add_column :people_photos, :points, :text
  end
end
