class TreeController < ApplicationController

  before_action :authenticate_user!

  def new
    @root_family_id = params[:f] || Family.first.id
  end

  def familia_json
    f = Family.find(params[:f].to_i)
    render json: {
      id:       f.id,
      marriage_date: f.marriagedate ? IncompleteDate.new(date: f.marriagedate, accurate: f.marriagedateAcc).to_s : nil,
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
      @impersonate_candidate = @p
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

  def parentesco
    @p = Person.find(params[:p].to_i)
    @camino = effective_person ? Person.path_between(effective_person, @p) : nil
    @filas = Person.parentesco_filas(@camino)
  end

  def arbol
    @p = Person.find(params[:p].to_i)
    @root_family_id = @p.childrenof_id || @p.consortof.first&.id
  end

  def mis_fotos
    @p = effective_person
    @photos = @p.owned_photos.includes(:people, people_photos: :person).sort_by { |p| p.date || Date.new(0) }
  end

  def foto
    @photo = Photo.find(params[:id])
    @back_person = Person.find_by(id: params[:p]) if params[:p].present?
    @back_family = Family.find_by(id: params[:f]) if params[:f].present?
  end

  def fechas
    eventos = []
    kind_order = { nacimiento: 0, defuncion: 1 }
    related_ids = effective_person ? Person.related_to_ids(effective_person) : nil

    nacimientos = Person.where.not(birthdate: nil)
    nacimientos = nacimientos.where(id: related_ids) if related_ids
    nacimientos.find_each do |p|
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

    defunciones = Person.where.not(death: nil)
    defunciones = defunciones.where(id: related_ids) if related_ids
    defunciones.find_each do |p|
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

    related_ids = effective_person ? Person.related_to_ids(effective_person) : nil
    people = scope
    people = people.where(id: related_ids) if related_ids
    people = people.order(Arel.sql("COALESCE(people.surname,''), COALESCE(people.name,'')"))
                    .limit(25)
    render json: people.map { |p|
      {
        id: p.id,
        label: p.fullname.strip,
        dates: p.dates,
        url: tree_persona_path(p: p.id)
      }
    }
  end

  def cumples
    puts 1
  end

  def versiones
    @versiones = [
      {
        version: "v4.0",
        fecha: "1/11/2026",
        actual: true,
        cambios: [
          "Identificación de usuarios con personas",
          "Navegar la aplicación como si fuese otro usuario (solo para el administrador)",
          "Relación de propiedad de foto con personas en lugar de texto",
          "Diagrama de parentesco",
          "Identificación del género sin necesidad de un diccionario completo",
          "Nuevas relaciones: tío/tía política, bisabuelo, tatarabuelo",
          "Fixes: detección de parientes políticos, si la persona buscada ya no existe se redirige a la home en vez de dar error"
        ]
      },
      {
        version: "v3.0",
        fecha: "4/10/2026",
        actual: false,
        cambios: [
          "Contornos de personas en las fotos: mostrar/ocultar por protagonista o para todos",
          "El buscador y la home solo muestran personas con relación familiar (sanguínea o política)",
          "Fixes: fechas y edades en el listado de próximas fechas, numeración y maquetación del listado de personas al pie de fotos"
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
