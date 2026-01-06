class Admin::TravelAgenciesController < Admin::BaseController
  before_action :set_travel_agency, only: [:show, :edit, :update, :destroy]

  def index
    @travel_agencies = TravelAgency.page(params[:page]).per(10)
  end

  def show
  end

  def new
    @travel_agency = TravelAgency.new
  end

  def create
    @travel_agency = TravelAgency.new(travel_agency_params)

    if @travel_agency.save
      redirect_to admin_travel_agency_path(@travel_agency), notice: 'Travel agency was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @travel_agency.update(travel_agency_params)
      redirect_to admin_travel_agency_path(@travel_agency), notice: 'Travel agency was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @travel_agency.destroy
    redirect_to admin_travel_agencies_path, notice: 'Travel agency was successfully deleted.'
  end

  private

  def set_travel_agency
    @travel_agency = TravelAgency.find(params[:id])
  end

  def travel_agency_params
    params.require(:travel_agency).permit(:name, :description, :logo_url, :rating, :sales_count, :is_verified)
  end
end
