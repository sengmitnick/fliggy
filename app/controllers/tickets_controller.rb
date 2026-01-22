class TicketsController < ApplicationController
  include CitySelectorDataConcern
  
  def index
    # 默认城市为深圳（根据设计稿）
    @city = params[:city].presence || '深圳'
    @selected_tag = params[:tag].presence
    @sort_by = params[:sort_by].presence || 'smart' # 智能排序/sales/rating
    
    # 获取所有可用的城市列表
    @cities = TourGroupProduct.where(tour_category: 'ticket')
                              .distinct
                              .pluck(:destination)
                              .compact
                              .sort
    
    # 如果没有城市数据，使用默认列表
    @cities = ['深圳', '上海', '北京', '广州', '杭州', '成都'] if @cities.empty?
    
    # 从数据库查询门票产品
    products = TourGroupProduct.includes(:travel_agency)
                               .where(tour_category: 'ticket')
                               .where("destination LIKE ?", "%#{@city}%")
    
    # 根据标签筛选
    if @selected_tag.present?
      products = products.where("tags LIKE ?", "%#{@selected_tag}%")
    end
    
    # 排序逻辑
    products = case @sort_by
    when 'sales'
      products.order(sales_count: :desc)
    when 'rating'
      products.order(rating: :desc)
    else # 'smart' or default
      products.by_display_order
    end
    
    # 限制结果
    products = products.limit(50)
    
    # 转换为视图需要的格式
    @tickets = products.map do |product|
      {
        id: product.id,
        image: product.image_url,
        badge: product.badge,
        title: product.title,
        rating: product.rating > 0 ? product.rating : nil,
        rating_desc: product.rating_desc,
        tags: product.tags || [],
        provider: product.travel_agency&.name || '官方',
        sales: product.format_sales,
        price: product.price.to_i.to_s,
        price_suffix: '起'
      }
    end
    
    # 如果没有数据，显示空结果
    @tickets = [] if @tickets.empty?
  end
  
  def show
    @product = TourGroupProduct.includes(:travel_agency).find(params[:id])
    
    # 重定向到 tour_groups 的 show 页面
    redirect_to tour_group_path(@product)
  end
end
