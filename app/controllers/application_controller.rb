class ApplicationController < ActionController::Base
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :require_person!
  rescue_from ActiveRecord::RecordNotFound, with: :ir_a_home

  SUPLANTADOR_PERSON_ID = 7

  helper_method :effective_person, :impersonando?, :puede_suplantar?

  # mientras se navega con ?s=<id>, todos los enlaces generados con los path
  # helpers conservan ese parámetro para poder seguir navegando "como" esa persona
  def default_url_options
    puede_suplantar? && params[:s].present? ? { s: params[:s] } : {}
  end

  # la persona desde cuyo punto de vista se muestra la app: normalmente la propia,
  # salvo que el usuario 7 esté navegando con ?s=<person_id> para ver la app como otra persona
  def effective_person
    return @effective_person if defined?(@effective_person)
    @effective_person =
      if puede_suplantar? && params[:s].present?
        Person.find_by(id: params[:s].to_i) || current_user.person
      else
        current_user&.person
      end
  end

  def impersonando?
    effective_person && current_user.person_id != effective_person.id
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:person_id])
  end

  # obliga a completar "¿quién eres?" antes de poder usar el resto de la aplicación
  def require_person!
    return unless user_signed_in?
    return if current_user.person_id.present?
    return if devise_controller?

    redirect_to complete_profile_path
  end

  private

  def puede_suplantar?
    current_user&.person_id == SUPLANTADOR_PERSON_ID
  end

  # si se pide una persona/familia/foto que no existe, en vez de un error llevamos a la home
  def ir_a_home
    redirect_to tree_fechas_path
  end
end
