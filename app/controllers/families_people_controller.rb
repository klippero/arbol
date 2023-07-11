class FamiliesPeopleController < ApplicationController
  before_action :set_families_person, only: %i[ show edit update destroy ]
  before_action :authenticate_user!

  # GET /families_people or /families_people.json
  def index
    @families_people = FamiliesPerson.all
  end

  # GET /families_people/1 or /families_people/1.json
  def show
  end

  # GET /families_people/new
  def new
    @families_person = FamiliesPerson.new
  end

  # GET /families_people/1/edit
  def edit
  end

  # POST /families_people or /families_people.json
  def create
    @families_person = FamiliesPerson.new(families_person_params)

    respond_to do |format|
      if @families_person.save
        format.html { redirect_to @families_person, notice: "Families person was successfully created." }
        format.json { render :show, status: :created, location: @families_person }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @families_person.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /families_people/1 or /families_people/1.json
  def update
    respond_to do |format|
      if @families_person.update(families_person_params)
        format.html { redirect_to @families_person, notice: "Families person was successfully updated." }
        format.json { render :show, status: :ok, location: @families_person }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @families_person.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /families_people/1 or /families_people/1.json
  def destroy
    @families_person.destroy
    respond_to do |format|
      format.html { redirect_to families_people_url, notice: "Families person was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_families_person
      @families_person = FamiliesPerson.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def families_person_params
      params.require(:families_person).permit(:person_id, :family_id)
    end
end
