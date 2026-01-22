class Admin::CruiseShipsController < Admin::BaseController
  before_action :set_cruise_ship, only: [:show, :edit, :update, :destroy]

  def index
    @cruise_ships = CruiseShip.page(params[:page]).per(10)
  end

  def show
  end

  def new
    @cruise_ship = CruiseShip.new
  end

  def create
    @cruise_ship = CruiseShip.new(cruise_ship_params)

    if @cruise_ship.save
      redirect_to admin_cruise_ship_path(@cruise_ship), notice: 'Cruise ship was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @cruise_ship.update(cruise_ship_params)
      redirect_to admin_cruise_ship_path(@cruise_ship), notice: 'Cruise ship was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @cruise_ship.destroy
    redirect_to admin_cruise_ships_path, notice: 'Cruise ship was successfully deleted.'
  end

  private

  def set_cruise_ship
    @cruise_ship = CruiseShip.find(params[:id])
  end

  def cruise_ship_params
    params.require(:cruise_ship).permit(:name, :name_en, :image_url, :features, :slug, :data_version, :cruise_line_id)
  end
end
