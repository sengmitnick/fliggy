class Admin::HotelPackagesController < Admin::BaseController
  before_action :set_hotel_package, only: [:show, :edit, :update, :destroy]

  def index
    @hotel_packages = HotelPackage.page(params[:page]).per(10).ordered
  end

  def show
  end

  def new
    @hotel_package = HotelPackage.new
  end

  def create
    @hotel_package = HotelPackage.new(hotel_package_params)

    if @hotel_package.save
      redirect_to admin_hotel_package_path(@hotel_package), notice: 'Hotel package was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @hotel_package.update(hotel_package_params)
      redirect_to admin_hotel_package_path(@hotel_package), notice: 'Hotel package was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @hotel_package.destroy
    redirect_to admin_hotel_packages_path, notice: 'Hotel package was successfully deleted.'
  end

  # 批量生成页面
  def generator
    @regions = ["全国通用", "华东地区", "华南地区", "华北地区", "西南地区", "华中地区", "西北地区", "东北地区"]
    @cities = City.pluck(:name).sort
  end

  # 批量生成酒店套餐
  def batch_generate
    region = params[:region]
    city = params[:city]
    count = params[:count].to_i

    if region.blank? || city.blank?
      redirect_to generator_admin_hotel_packages_path, alert: '请选择地区和城市'
      return
    end

    if count < 1 || count > 50
      redirect_to generator_admin_hotel_packages_path, alert: '生成数量必须在1-50之间'
      return
    end

    packages = HotelPackage.generate_for_region(region, city, count: count)

    redirect_to admin_hotel_packages_path, 
                notice: "成功生成 #{packages.count} 个酒店套餐 (#{region} - #{city})"
  rescue StandardError => e
    redirect_to generator_admin_hotel_packages_path, alert: "生成失败: #{e.message}"
  end

  private

  def set_hotel_package
    @hotel_package = HotelPackage.find(params[:id])
  end

  def hotel_package_params
    params.require(:hotel_package).permit(
      :brand_name, :title, :description, :price, :original_price, 
      :sales_count, :is_featured, :valid_days, :terms, :region, :city,
      :package_type, :display_order, :night_count, :refundable, 
      :instant_booking, :luxury, :brand_logo_url, :hotel_id
    )
  end
end
