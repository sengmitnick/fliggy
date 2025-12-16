class Admin::FlightOffersController < Admin::BaseController
  before_action :set_flight_offer, only: [:show, :edit, :update, :destroy]

  def index
    @flight_offers = FlightOffer.page(params[:page]).per(10)
  end

  def show
  end

  def new
    @flight_offer = FlightOffer.new
  end

  def create
    @flight_offer = FlightOffer.new(flight_offer_params)

    if @flight_offer.save
      redirect_to admin_flight_offer_path(@flight_offer), notice: 'Flight offer was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @flight_offer.update(flight_offer_params)
      redirect_to admin_flight_offer_path(@flight_offer), notice: 'Flight offer was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @flight_offer.destroy
    redirect_to admin_flight_offers_path, notice: 'Flight offer was successfully deleted.'
  end

  private

  def set_flight_offer
    @flight_offer = FlightOffer.find(params[:id])
  end

  def flight_offer_params
    params.require(:flight_offer).permit(:provider_name, :offer_type, :price, :original_price, :cashback_amount, :discount_items, :seat_class, :services, :tags, :baggage_info, :meal_included, :refund_policy, :is_featured, :display_order, :flight_id)
  end
end
