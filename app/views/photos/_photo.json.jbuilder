json.extract! photo, :id, :title, :date, :dateAcc, :place, :owner, :owner_person_id, :content, :created_at, :updated_at
json.url photo_url(photo, format: :json)
