class Admin::TourGroupProductsController < Admin::BaseController
  before_action :set_tour_group_product, only: [:show, :edit, :update, :destroy]

  def index
    @tour_group_products = TourGroupProduct.page(params[:page]).per(10)
  end

  def show
  end

  def new
    @tour_group_product = TourGroupProduct.new
  end

  def create
    @tour_group_product = TourGroupProduct.new(tour_group_product_params)

    if @tour_group_product.save
      redirect_to admin_tour_group_product_path(@tour_group_product), notice: 'Tour group product was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @tour_group_product.update(tour_group_product_params)
      redirect_to admin_tour_group_product_path(@tour_group_product), notice: 'Tour group product was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @tour_group_product.destroy
    redirect_to admin_tour_group_products_path, notice: 'Tour group product was successfully deleted.'
  end

  private

  def set_tour_group_product
    @tour_group_product = TourGroupProduct.find(params[:id])
  end

  def tour_group_product_params
    params.require(:tour_group_product).permit(:title, :subtitle, :tour_category, :destination, :duration, :departure_city, :price, :original_price, :rating, :rating_desc, :highlights, :tags, :provider, :sales_count, :badge, :departure_label, :image_url, :is_featured, :display_order, :travel_agency_id)
  end
end
