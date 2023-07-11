json.extract! people_photo, :id, :person_id, :photo_id, :created_at, :updated_at
json.url people_photo_url(people_photo, format: :json)
