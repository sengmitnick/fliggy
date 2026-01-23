class Admin::CruiseSailingsController < Admin::BaseController
  before_action :set_cruise_sailing, only: [:show, :edit, :update, :destroy]

  def index
    @cruise_sailings = CruiseSailing.page(params[:page]).per(10)
  end

  def show
  end

  def new
    @cruise_sailing = CruiseSailing.new
  end

  def create
    @cruise_sailing = CruiseSailing.new(cruise_sailing_params)

    if @cruise_sailing.save
      redirect_to admin_cruise_sailing_path(@cruise_sailing), notice: 'Cruise sailing was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @cruise_sailing.update(cruise_sailing_params)
      redirect_to admin_cruise_sailing_path(@cruise_sailing), notice: 'Cruise sailing was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @cruise_sailing.destroy
    redirect_to admin_cruise_sailings_path, notice: 'Cruise sailing was successfully deleted.'
  end

  private

  def set_cruise_sailing
    @cruise_sailing = CruiseSailing.find(params[:id])
  end

  def cruise_sailing_params
    params.require(:cruise_sailing).permit(:departure_date, :return_date, :duration_days, :duration_nights, :departure_port, :arrival_port, :itinerary, :data_version, :status, :cruise_ship_id, :cruise_route_id)
  end
end
