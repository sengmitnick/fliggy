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

  # 批量生成页面
  def generator
    @destinations = City.pluck(:name).sort
    @departure_cities = City.pluck(:name).sort
  end

  # 批量生成旅游产品
  def batch_generate
    destination = params[:destination]
    departure_city = params[:departure_city]
    start_date = Date.parse(params[:start_date])
    end_date = Date.parse(params[:end_date])
    count_per_day = params[:count_per_day].to_i

    if destination.blank? || departure_city.blank?
      redirect_to generator_admin_tour_group_products_path, alert: '请选择目的地和出发城市'
      return
    end

    if start_date > end_date
      redirect_to generator_admin_tour_group_products_path, alert: '开始日期不能晚于结束日期'
      return
    end

    if count_per_day < 1 || count_per_day > 10
      redirect_to generator_admin_tour_group_products_path, alert: '每天生成数量必须在1-10之间'
      return
    end

    products = TourGroupProduct.generate_for_destination(
      destination, 
      departure_city, 
      start_date, 
      end_date, 
      count_per_day: count_per_day
    )

    redirect_to admin_tour_group_products_path, 
                notice: "成功生成 #{products.count} 个旅游产品 (#{destination}, #{start_date} 至 #{end_date})"
  rescue ArgumentError => e
    redirect_to generator_admin_tour_group_products_path, alert: "日期格式错误: #{e.message}"
  end

  private

  def set_tour_group_product
    @tour_group_product = TourGroupProduct.find(params[:id])
  end

  def tour_group_product_params
    params.require(:tour_group_product).permit(:title, :subtitle, :tour_category, :destination, :duration, :departure_city, :price, :original_price, :rating, :rating_desc, :highlights, :tags, :provider, :sales_count, :badge, :departure_label, :image_url, :is_featured, :display_order, :travel_agency_id)
  end
end
