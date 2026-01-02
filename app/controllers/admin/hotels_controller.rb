class Admin::HotelsController < Admin::BaseController
  before_action :set_hotel, only: [:show, :edit, :update, :destroy]

  def generate_batch
    count = params[:count].to_i
    count = 10 if count <= 0 || count > 100
    
    generated = HotelGeneratorService.generate_batch(count)
    
    redirect_to admin_hotels_path, notice: "Successfully generated #{generated} hotels."
  rescue => e
    redirect_to admin_hotels_path, alert: "Failed to generate hotels: #{e.message}"
  end

  def index
    @hotels = Hotel.page(params[:page]).per(10)
  end

  def show
  end

  def new
    @hotel = Hotel.new
  end

  def create
    @hotel = Hotel.new(hotel_params)

    if @hotel.save
      redirect_to admin_hotel_path(@hotel), notice: 'Hotel was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @hotel.update(hotel_params)
      redirect_to admin_hotel_path(@hotel), notice: 'Hotel was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @hotel.destroy
    redirect_to admin_hotels_path, notice: 'Hotel was successfully deleted.'
  end

  private

  def set_hotel
    @hotel = Hotel.find(params[:id])
  end

  def hotel_params
    params.require(:hotel).permit(:name, :city, :address, :rating, :price, :original_price, :distance, :features, :star_level, :image_url, :is_featured, :display_order, :image)
  end

  def batch_generate_params
    params.permit(:count)
  end
end
