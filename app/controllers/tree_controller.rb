class TreeController < ApplicationController

  before_action :authenticate_user!

  def new
    @root_family_id = params[:f] || Family.first.id
  end

  def familia_json
    f = Family.find(params[:f].to_i)
    render json: {
      id:       f.id,
      consorts: f.consorts.map { |p|
        { id: p.id, name: p.name, fullname: p.fullname, dates: p.dates,
          childrenof_id: p.childrenof_id }
      },
      children: f.children.sort_by { |c| c.birthorder || 99 }.map { |p|
        { id: p.id, name: p.name, fullname: p.fullname, dates: p.dates,
          consortof: p.consortof.map(&:id) }
      }
    }
  end

  def familia
    @f = Family.find(params[:f].to_i)

    family_size = (@f.consorts + @f.children).size
    scored = Photo.all.map { |photo| [photo, photo.familyMatch(@f)] }

    perfect = scored.select { |_, fm| fm == 1 }.map(&:first)
    @photos = if perfect.any?
      perfect
    else
      scored.select { |_, fm| (fm * family_size) >= 2 }.map(&:first)
    end
  end

  def persona
    if params[:p]
      @p = Person.find(params[:p].to_i)
      @photos = @p.photos.sort_by { |p| p.date || Date.new(0) }
      @f = @p.childrenof
    else
      @p = nil
      @photos = Photo.all.sort_by { |p| p.date || Date.new(0) }
    end
  end

  def apellidos
    @p = Person.find(params[:p].to_i)
  end

  def foto
    @photo = Photo.find(params[:id])
    @back_person = Person.find_by(id: params[:p]) if params[:p].present?
    @back_family = Family.find_by(id: params[:f]) if params[:f].present?
  end

  def fechas
    eventos = []
    kind_order = { nacimiento: 0, defuncion: 1 }

    Person.where.not(birthdate: nil).find_each do |p|
      inc = IncompleteDate.new(date: p.birthdate, accurate: p.birthdateAcc)
      next unless inc.month? && inc.day?
      t = inc.to
      days = t[:days2sameDay]
      next if days.nil?
      eventos << {
        person: p,
        kind: :nacimiento,
        next_date: t[:nextSameDay],
        days: days
      }
    end

    Person.where.not(death: nil).find_each do |p|
      next unless p.fallecio?
      di = IncompleteDate.new(date: p.death, accurate: p.deathAcc)
      next unless di.month? && di.day?
      t = di.to
      days = t[:days2sameDay]
      next if days.nil?
      eventos << {
        person: p,
        kind: :defuncion,
        next_date: t[:nextSameDay],
        days: days
      }
    end

    @eventos = eventos.sort_by do |e|
      [
        e[:days],
        e[:person].fullname.to_s,
        kind_order[e[:kind]]
      ]
    end
  end

  def personas_buscar
    q = params[:q].to_s.strip.downcase
    if q.length < 2
      render json: []
      return
    end

    tokens = q.split(/\s+/).reject(&:blank?)
    scope = Person.all
    haystack = "LOWER(TRIM(IFNULL(people.name,'') || ' ' || IFNULL(people.surname,'') || ' ' || IFNULL(people.surname2,'')))"

    tokens.each do |raw|
      token = "%#{ActiveRecord::Base.sanitize_sql_like(raw)}%"
      date_match = <<~SQL.squish
        LOWER(IFNULL(people.birthplace, '')) LIKE :t
        OR LOWER(IFNULL(people.deathplace, '')) LIKE :t
        OR IFNULL(CAST(strftime('%Y', people.birthdate) AS TEXT), '') LIKE :t
        OR IFNULL(CAST(strftime('%Y', people.death) AS TEXT), '') LIKE :t
      SQL
      scope = scope.where("(#{haystack} LIKE :t OR #{date_match})", t: token)
    end

    people = scope.order(Arel.sql("COALESCE(people.surname,''), COALESCE(people.name,'')")).limit(25)
    render json: people.map { |p|
      {
        id: p.id,
        label: p.fullname.strip,
        dates: p.dates,
        url: "/tree/persona?p=#{p.id}"
      }
    }
  end

  def cumples
    puts 1
  end
end
