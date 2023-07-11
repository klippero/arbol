class PeoplePhotosController < ApplicationController
  before_action :set_people_photo, only: %i[ show edit update destroy ]
  before_action :authenticate_user!

  # GET /people_photos or /people_photos.json
  def index
    @people_photos = PeoplePhoto.all
  end

  # GET /people_photos/1 or /people_photos/1.json
  def show
  end

  # GET /people_photos/new
  def new
    @people_photo = PeoplePhoto.new
  end

  # GET /people_photos/1/edit
  def edit
  end

  # POST /people_photos or /people_photos.json
  def create
    @people_photo = PeoplePhoto.new(people_photo_params)

    respond_to do |format|
      if @people_photo.save
        format.html { redirect_to @people_photo, notice: "People photo was successfully created." }
        format.json { render :show, status: :created, location: @people_photo }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @people_photo.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /people_photos/1 or /people_photos/1.json
  def update
    respond_to do |format|
      if @people_photo.update(people_photo_params)
        format.html { redirect_to @people_photo, notice: "People photo was successfully updated." }
        format.json { render :show, status: :ok, location: @people_photo }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @people_photo.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /people_photos/1 or /people_photos/1.json
  def destroy
    @people_photo.destroy
    respond_to do |format|
      format.html { redirect_to people_photos_url, notice: "People photo was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_people_photo
      @people_photo = PeoplePhoto.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def people_photo_params
      params.require(:people_photo).permit(:person_id, :photo_id)
    end
end
