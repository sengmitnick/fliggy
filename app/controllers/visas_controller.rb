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
    
    # 地区名称转拼音slug（用于锚点ID）
    @region_slugs = {
      '东亚' => 'east-asia',
      '东南亚' => 'southeast-asia',
      '南亚' => 'south-asia',
      '中东' => 'middle-east',
      '中亚' => 'central-asia',
      '西亚' => 'west-asia',
      '欧洲' => 'europe',
      '西欧' => 'west-europe',
      '东欧' => 'east-europe',
      '南欧' => 'south-europe',
      '北欧' => 'north-europe',
      '大洋洲' => 'oceania',
      '北美洲' => 'north-america',
      '北美' => 'north-america-2',
      '南美洲' => 'south-america',
      '南美' => 'south-america-2',
      '非洲' => 'africa',
      '东非' => 'east-africa',
      '西非' => 'west-africa',
      '南非' => 'south-africa',
      '北非' => 'north-africa'
    }
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
