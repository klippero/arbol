RelacionFamiliar = Data.define(:kind, :genero) do
  def to_s
    case kind
    when :ninguna
      ""
    when :hermano
      por_genero("hermano", "hermana", "herman@")
    when :medio_hermano
      por_genero("½ hermano", "½ hermana", "½ herman@")
    when :padre
      por_genero("padre", "madre", "progenitor")
    when :hijo
      por_genero("hijo", "hija", "hij@")
    when :hijastro
      por_genero("hijastro", "hijastra", "hijastr@")
    when :padrastro
      por_genero("padrastro", "madrastra", "padrastro/madrastra")
    when :consorte
      "consorte"
    when :nieto
      por_genero("nieto", "nieta", "niet@")
    when :abuelo
      por_genero("abuelo", "abuela", "abuel@")
    when :bisnieto
      por_genero("bisnieto", "bisnieta", "bisniet@")
    when :bisabuelo
      por_genero("bisabuelo", "bisabuela", "bisabuel@")
    when :tataranieto
      por_genero("tataranieto", "tataranieta", "tataraniet@")
    when :tatarabuelo
      por_genero("tatarabuelo", "tatarabuela", "tatarabuel@")
    when :cunado
      por_genero("cuñado", "cuñada", "cuñad@")
    when :concunado
      por_genero("concuñado", "concuñada", "concuñad@")
    when :tio
      por_genero("tío", "tía", "tí@")
    when :sobrino
      por_genero("sobrino", "sobrina", "sobrin@")
    when :tio_politico
      por_genero("tío político", "tía política", "tí@ polític@")
    when :sobrino_politico
      por_genero("sobrino político", "sobrina política", "sobrin@ polític@")
    when :primo
      por_genero("primo", "prima", "prim@")
    when :primo2
      por_genero("primo segundo", "prima segunda", "prim@ segundo")
    when :yerno
      por_genero("yerno", "nuera", "nuer@")
    when :suegro
      por_genero("suegro", "suegra", "suegr@")
    when :consuegro
      por_genero("consuegro", "consuegra", "consuegr@")
    else
      ""
    end
  end

  private

  def por_genero(masculino, femenino, neutro)
    case genero
    when :masculino then masculino
    when :femenino then femenino
    else neutro
    end
  end
end
