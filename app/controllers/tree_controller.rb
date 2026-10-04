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
      @photos = @p.photos.includes(:people, people_photos: :person).sort_by { |p| p.date || Date.new(0) }
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
    related_ids = Person.related_to_root_ids

    Person.where.not(birthdate: nil).where(id: related_ids).find_each do |p|
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

    Person.where.not(death: nil).where(id: related_ids).find_each do |p|
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

    related_ids = Person.related_to_root_ids
    people = scope.where(id: related_ids)
                  .order(Arel.sql("COALESCE(people.surname,''), COALESCE(people.name,'')"))
                  .limit(25)
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

  def versiones
    @versiones = [
      {
        version: "v3.0",
        fecha: "hoy",
        actual: true,
        cambios: [
          "Contornos de personas en las fotos (persona, familia y foto): mostrar/ocultar por protagonista o para todos, etiquetas con el nombre que nunca se salen de la foto",
          "El buscador y la home solo muestran personas con relación familiar (sanguínea o política) conmigo, de cualquier grado",
          "Correcciones en fechas y edades: no mostrar edades imposibles cuando no se conoce el año, \"hoy\"/\"mañana\" en el listado de próximas fechas, sin paréntesis vacíos",
          "Numeración y maquetación del listado de personas al pie de cada foto"
        ]
      },
      {
        version: "v2.0",
        fecha: "6/6/2026",
        actual: false,
        cambios: [
          "Buscador de personas y listado de próximas fechas (nacimientos y defunciones)",
          "Relación de primo segundo",
          "Página individual de foto",
          "Listado fluido de personas al pie de las fotos",
          "Poder editar una foto sin tener que volver a subirla",
          "Varios bugs corregidos (fechas, fotos sin imagen, nombres y apellidos)"
        ]
      },
      {
        version: "v1.0",
        fecha: "11/7/2023",
        actual: false,
        cambios: [
          "Versión original de la aplicación, hecha antes de usar IA: árbol genealógico, páginas de persona y familia, gestión de fotos y autenticación"
        ]
      }
    ]
  end
end
