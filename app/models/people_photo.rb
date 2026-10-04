class PeoplePhoto < ApplicationRecord
  belongs_to :person
  belongs_to :photo

  # Returns [[x%,y%], ...] or nil. Falls back to rect if only x/y/w/h stored.
  def display_points
    pts = read_attribute(:points)
    if pts.present?
      JSON.parse(pts) rescue nil
    elsif read_attribute(:x).present?
      x, y, w, h = read_attribute(:x), read_attribute(:y), read_attribute(:width), read_attribute(:height)
      [[x, y], [x + w, y], [x + w, y + h], [x, y + h]]
    end
  end
end
