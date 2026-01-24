class Admin::CharterRoutesController < Admin::BaseController
  before_action :set_charter_route, only: [:show, :edit, :update, :destroy]

  def index
    @charter_routes = CharterRoute.page(params[:page]).per(10)
  end

  def show
  end

  def new
    @charter_route = CharterRoute.new
  end

  def create
    @charter_route = CharterRoute.new(charter_route_params)

    if @charter_route.save
      redirect_to admin_charter_route_path(@charter_route), notice: 'Charter route was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @charter_route.update(charter_route_params)
      redirect_to admin_charter_route_path(@charter_route), notice: 'Charter route was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @charter_route.destroy
    redirect_to admin_charter_routes_path, notice: 'Charter route was successfully deleted.'
  end

  private

  def set_charter_route
    @charter_route = CharterRoute.find(params[:id])
  end

  def charter_route_params
    params.require(:charter_route).permit(:name, :slug, :duration_days, :distance_km, :category, :description, :price_from, :highlights, :cover_image_url, :city_id)
  end
end
