class UsersController < ApplicationController
  before_action :authenticate_user!
  skip_before_action :require_person!, only: [:complete_profile, :update_profile]

  def complete_profile
    redirect_to tree_fechas_path if current_user.person_id.present?
  end

  def update_profile
    if person_params[:person_id].present? && current_user.update(person_params)
      redirect_to tree_fechas_path, notice: "¡Gracias! Ya puedes usar la aplicación."
    else
      @error = "Tienes que indicar quién eres para continuar."
      render :complete_profile, status: :unprocessable_entity
    end
  end

  private

  def person_params
    params.require(:user).permit(:person_id)
  end
end
