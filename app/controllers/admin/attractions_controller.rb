class Admin::AttractionsController < Admin::BaseController
  before_action :set_attraction, only: [:show, :edit, :update, :destroy]

  def index
    @attractions = Attraction.page(params[:page]).per(10)
  end

  def show
  end

  def new
    @attraction = Attraction.new
  end

  def create
    @attraction = Attraction.new(attraction_params)

    if @attraction.save
      redirect_to admin_attraction_path(@attraction), notice: 'Attraction was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @attraction.update(attraction_params)
      redirect_to admin_attraction_path(@attraction), notice: 'Attraction was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @attraction.destroy
    redirect_to admin_attractions_path, notice: 'Attraction was successfully deleted.'
  end

  private

  def set_attraction
    @attraction = Attraction.find(params[:id])
  end

  def attraction_params
    params.require(:attraction).permit(:name, :province, :city, :district, :address, :latitude, :longitude, :rating, :review_count, :opening_hours, :phone, :description, :slug, :cover_image, gallery_images: [])
  end
end
