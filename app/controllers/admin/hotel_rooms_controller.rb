class Admin::HotelRoomsController < Admin::BaseController
  before_action :set_hotel_room, only: [:show, :edit, :update, :destroy]

  def index
    @hotel_rooms = HotelRoom.page(params[:page]).per(10)
  end

  def show
  end

  def new
    @hotel_room = HotelRoom.new
  end

  def create
    @hotel_room = HotelRoom.new(hotel_room_params)

    if @hotel_room.save
      redirect_to admin_hotel_room_path(@hotel_room), notice: 'Hotel room was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @hotel_room.update(hotel_room_params)
      redirect_to admin_hotel_room_path(@hotel_room), notice: 'Hotel room was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @hotel_room.destroy
    redirect_to admin_hotel_rooms_path, notice: 'Hotel room was successfully deleted.'
  end

  private

  def set_hotel_room
    @hotel_room = HotelRoom.find(params[:id])
  end

  def hotel_room_params
    params.require(:hotel_room).permit(:room_type, :bed_type, :price, :original_price, :area, :max_guests, :has_window, :available_rooms, :room_category, :data_version, :hotel_id)
  end
end
