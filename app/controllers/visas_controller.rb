class VisasController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index, :show]

  def index
    # 获取所有国家，按区域分组
    @countries = Country.includes(:visa_products).order(:region, :name)
    @regions = @countries.group_by(&:region)
    
    # 精选国家（热门国家）
    @featured_countries = @countries.where(code: ['JP', 'KR', 'US', 'VN', 'AU', 'GB', 'NZ', 'FR']).to_a
    
    # 统计数据
    @total_countries = @countries.count
    @total_users_served = 30000000 # 3000万+
  end

  def show
    @country = Country.friendly.find(params[:id])
    @visa_products = @country.visa_products.order(sales_count: :desc, price: :asc)
    
    # 获取用户常住地（从session或默认）
    @residence_area = params[:residence_area] || session[:residence_area] || '广东'
    
    # 按类型分组
    @products_by_type = @visa_products.group_by(&:product_type)
  end

  private
  # Write your private methods here
end
