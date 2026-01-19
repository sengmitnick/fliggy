class TourGroupsController < ApplicationController
  def index
    # Default destination
    @destination = params[:destination].presence || '上海'
    @duration = params[:duration].presence
    @group_size = params[:group_size].presence
    
    # Hot destinations - 从数据库获取
    @hot_destinations = TourGroupProduct.select(:destination)
                                        .distinct
                                        .pluck(:destination)
                                        .compact
                                        .uniq
                                        .take(5)
    
    @hot_destinations = ['上海', '北京', '杭州', '广州', '成都'] if @hot_destinations.empty?
    
    # Duration options for main page (only show 3 options)
    @duration_quick_options = [
      { label: '一日游', value: '1' },
      { label: '2天', value: '2' },
      { label: '3天', value: '3' }
    ]
    
    # All duration options for modal (show all 14 options)
    @duration_options = [
      { label: '一日游', value: '1' },
      { label: '2天', value: '2' },
      { label: '3天', value: '3' },
      { label: '4天', value: '4' },
      { label: '5天', value: '5' },
      { label: '6天', value: '6' },
      { label: '7天', value: '7' },
      { label: '8天', value: '8' },
      { label: '9天', value: '9' },
      { label: '10天', value: '10' },
      { label: '11天', value: '11' },
      { label: '12天', value: '12' },
      { label: '13天', value: '13' },
      { label: '14天', value: '14' }
    ]
    
    # Group size options
    @group_size_options = [
      { label: '大团', description: '15人以上', value: 'large' },
      { label: '小团', description: '最多15人', value: 'small' }
    ]
    
    # Tour recommendations - 从数据库获取
    products = TourGroupProduct.includes(:travel_agency)
                               .where("destination LIKE ?", "%#{@destination}%")
                               .featured
                               .by_display_order
                               .limit(3)
    
    @tour_recommendations = products.map do |product|
      {
        id: product.id,
        image: product.image_url,
        badge: product.badge,
        title: product.title,
        price: product.format_price,
        sales: product.format_sales
      }
    end
  end
  
  def search
    @destination = params[:destination].presence || '上海'
    @duration = params[:duration].presence
    @group_size = params[:group_size].presence
    @tour_category = params[:tour_category].presence
    
    # 获取所有可用的目的地列表
    @destinations = TourGroupProduct.distinct.pluck(:destination).sort
    
    # 从数据库查询产品
    products = TourGroupProduct.includes(:travel_agency)
                               .where("destination LIKE ?", "%#{@destination}%")
    
    # 根据tour_category筛选（如果提供）
    if @tour_category.present?
      products = products.where(tour_category: @tour_category)
    end
    
    # 根据天数筛选（如果提供）
    if @duration.present?
      products = products.where(duration: @duration)
    end
    
    # 根据团队大小筛选（如果提供）
    if @group_size.present?
      # 这里假设数据库有 group_size 字段，如果没有可以忽略或根据其他逻辑筛选
      # products = products.where(group_size: @group_size)
    end
    
    # 排序和限制
    products = products.by_display_order.limit(50)
    
    # 转换为视图需要的格式
    @search_results = products.map do |product|
      {
        id: product.id,
        image: product.image_url,
        badge: product.badge,
        departure: product.departure_label,
        title: product.title,
        rating: product.rating > 0 ? product.rating : nil,
        rating_desc: product.rating_desc,
        highlights: product.highlights || [],
        tags: product.tags || [],
        provider: product.travel_agency.name,
        sales: product.format_sales,
        price: product.price.to_i.to_s,
        price_suffix: '起'
      }
    end
    
    # 如果没有数据，不显示任何结果（避免无效链接）
    @search_results = [] if @search_results.empty?
  end

  def show
    @product = TourGroupProduct.includes(
      :travel_agency,
      :tour_packages,
      :tour_itinerary_days,
      tour_reviews: :user
    ).find(params[:id])
    
    # 准备套餐数据
    @packages = @product.tour_packages.by_display_order
    @selected_package = @packages.first
    
    # 准备行程数据
    @itinerary_days = @product.tour_itinerary_days.by_day_order
    
    # 准备评价数据
    @reviews = @product.tour_reviews.recent.limit(10)
    @featured_reviews = @product.featured_reviews
    @review_stats = {
      total_count: @product.review_count,
      average_rating: @product.average_rating,
      guide_attitude: @product.tour_reviews.average(:guide_attitude)&.round(1) || 0,
      meal_quality: @product.tour_reviews.average(:meal_quality)&.round(1) || 0,
      itinerary_arrangement: @product.tour_reviews.average(:itinerary_arrangement)&.round(1) || 0,
      travel_transportation: @product.tour_reviews.average(:travel_transportation)&.round(1) || 0
    }
    
    # 推荐相关产品
    @related_products = TourGroupProduct.includes(:travel_agency)
                                       .where(destination: @product.destination)
                                       .where.not(id: @product.id)
                                       .popular
                                       .limit(4)
  end
end
