class Admin::MembershipProductsController < Admin::BaseController
  before_action :set_membership_product, only: [:show, :edit, :update, :destroy]

  def index
    @membership_products = MembershipProduct.page(params[:page]).per(10)
  end

  def show
  end

  def new
    @membership_product = MembershipProduct.new
  end

  def create
    @membership_product = MembershipProduct.new(membership_product_params)

    if @membership_product.save
      redirect_to admin_membership_product_path(@membership_product), notice: 'Membership product was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @membership_product.update(membership_product_params)
      redirect_to admin_membership_product_path(@membership_product), notice: 'Membership product was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @membership_product.destroy
    redirect_to admin_membership_products_path, notice: 'Membership product was successfully deleted.'
  end

  private

  def set_membership_product
    @membership_product = MembershipProduct.find(params[:id])
  end

  def membership_product_params
    params.require(:membership_product).permit(:name, :slug, :category, :price_cash, :price_mileage, :original_price, :sales_count, :stock, :rating, :description, :image_url, :region, :featured, :image)
  end
end
