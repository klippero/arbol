json.extract! person, :id, :name, :surname, :surname2, :birthdate, :birthdateAcc, :birthorder, :birthplace, :death, :deathAcc, :deathplace, :comment, :childrenof_id, :created_at, :updated_at
json.url person_url(person, format: :json)
