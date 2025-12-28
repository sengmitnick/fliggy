class Admin::DeepTravelProductsController < Admin::BaseController
  before_action :set_deep_travel_product, only: [:show, :edit, :update, :destroy]

  def index
    @deep_travel_products = DeepTravelProduct.page(params[:page]).per(10)
  end

  def show
  end

  def new
    @deep_travel_product = DeepTravelProduct.new
  end

  def create
    @deep_travel_product = DeepTravelProduct.new(deep_travel_product_params)

    if @deep_travel_product.save
      redirect_to admin_deep_travel_product_path(@deep_travel_product), notice: 'Deep travel product was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @deep_travel_product.update(deep_travel_product_params)
      redirect_to admin_deep_travel_product_path(@deep_travel_product), notice: 'Deep travel product was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @deep_travel_product.destroy
    redirect_to admin_deep_travel_products_path, notice: 'Deep travel product was successfully deleted.'
  end

  private

  def set_deep_travel_product
    @deep_travel_product = DeepTravelProduct.find(params[:id])
  end

  def deep_travel_product_params
    params.require(:deep_travel_product).permit(:title, :subtitle, :location, :price, :sales_count, :description, :itinerary, :featured, :deep_travel_guide_id, images: [])
  end
end
