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
    @selected_tag = params[:tag].presence
    @tour_category = params[:tour_category].presence
    @sort_by = params[:sort_by].presence || 'smart' # 智能排序/sales/rating
    @departure_city = params[:departure_city].presence # 出发地
    @duration = params[:duration].to_i if params[:duration].present?
    @travel_type = params[:travel_type].presence # 旅游类型：跟团游/独立成团/自由出行
    
    # 处理顶部tab参数，将tab ID映射到travel_type
    @active_tab = params[:tab].presence || 'comprehensive'
    tab_to_travel_type = {
      'group_tour' => '跟团游',
      'private_group' => '独立成团',
      'free_travel' => '自由出行'
    }
    # 如果有tab参数且不是comprehensive，则设置对应的travel_type
    if @active_tab != 'comprehensive' && tab_to_travel_type[@active_tab]
      @travel_type = tab_to_travel_type[@active_tab]
    end
    
    # 获取所有可用的目的地列表
    @destinations = TourGroupProduct.distinct.pluck(:destination).sort
    
    # 根据目的地智能分组出发城市
    @departure_city_groups = get_departure_city_groups(@destination)
    
    # 从数据库查询产品
    products = TourGroupProduct.includes(:travel_agency)
                               .where("destination LIKE ?", "%#{@destination}%")
    
    # 根据tour_category筛选（如果提供）
    if @tour_category.present?
      products = products.where(tour_category: @tour_category)
    end
    
    # 根据旅游类型筛选
    if @travel_type.present?
      products = products.where(travel_type: @travel_type)
    end
    
    # 根据天数筛选
    if @duration.present? && @duration > 0
      products = products.where(duration: @duration)
    end
    
    # 根据标签筛选（在SQL层面过滤，更高效）
    if @selected_tag.present?
      products = products.where("tags LIKE ?", "%#{@selected_tag}%")
    end
    
    # 排序逻辑（出发地优先）
    products = case @sort_by
    when 'sales'
      if @departure_city.present?
        # 选择了出发地：优先展示该出发地的商品
        products.order(
          Arel.sql("CASE WHEN departure_city = #{ActiveRecord::Base.connection.quote(@departure_city)} THEN 0 ELSE 1 END"),
          sales_count: :desc
        )
      else
        products.order(sales_count: :desc)
      end
    when 'rating'
      if @departure_city.present?
        # 选择了出发地：优先展示该出发地的商品
        products.order(
          Arel.sql("CASE WHEN departure_city = #{ActiveRecord::Base.connection.quote(@departure_city)} THEN 0 ELSE 1 END"),
          rating: :desc
        )
      else
        products.order(rating: :desc)
      end
    else # 'smart' or default
      if @departure_city.present?
        # 选择了出发地：优先展示该出发地的商品
        products.order(
          Arel.sql("CASE WHEN departure_city = #{ActiveRecord::Base.connection.quote(@departure_city)} THEN 0 ELSE 1 END")
        ).by_display_order
      else
        products.by_display_order
      end
    end
    
    # 限制结果
    products = products.limit(50)
    
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
    
    # 处理出发城市参数（用于城市选择器显示）
    @selected_departure_city = params[:departure_city].presence || @product.departure_city
    
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

  private

  # 根据目的地返回分组的出发城市
  def get_departure_city_groups(destination)
    # 城市地理关系映射表
    city_regions = {
      # 华东地区
      '上海' => { nearby: ['上海', '杭州', '南京', '苏州', '无锡', '常州', '黄山', '芜湖'], others: ['北京', '合肥', '宁波', '金华', '福州', '郑州', '武汉', '厦门'] },
      '杭州' => { nearby: ['杭州', '上海', '南京', '苏州', '无锡', '常州', '黄山', '芜湖'], others: ['北京', '合肥', '宁波', '金华', '福州', '郑州', '武汉', '厦门'] },
      '南京' => { nearby: ['南京', '上海', '杭州', '苏州', '无锡', '常州', '黄山', '芜湖'], others: ['北京', '合肥', '宁波', '金华', '福州', '郑州', '武汉', '厦门'] },
      '苏州' => { nearby: ['苏州', '上海', '杭州', '南京', '无锡', '常州', '黄山', '芜湖'], others: ['北京', '合肥', '宁波', '金华', '福州', '郑州', '武汉', '厦门'] },
      '浙江' => { nearby: ['杭州', '上海', '南京', '苏州', '无锡', '常州', '黄山', '芜湖'], others: ['北京', '合肥', '宁波', '金华', '福州', '郑州', '武汉', '厦门'] },
      
      # 华北地区
      '北京' => { nearby: ['北京', '天津', '石家庄', '太原', '呼和浩特'], others: ['上海', '杭州', '南京', '西安', '郑州', '济南', '青岛', '沈阳'] },
      '天津' => { nearby: ['天津', '北京', '石家庄', '太原', '呼和浩特'], others: ['上海', '杭州', '南京', '西安', '郑州', '济南', '青岛', '沈阳'] },
      
      # 华南地区
      '广州' => { nearby: ['广州', '深圳', '珠海', '佛山', '东莞', '中山', '惠州', '江门'], others: ['北京', '上海', '杭州', '南京', '厦门', '福州', '南宁', '海口'] },
      '深圳' => { nearby: ['深圳', '广州', '珠海', '佛山', '东莞', '中山', '惠州', '江门'], others: ['北京', '上海', '杭州', '南京', '厦门', '福州', '南宁', '海口'] },
      
      # 西南地区
      '成都' => { nearby: ['成都', '重庆', '绵阳', '德阳', '乐山', '峨眉山'], others: ['北京', '上海', '杭州', '广州', '深圳', '西安', '昆明', '贵阳'] },
      '重庆' => { nearby: ['重庆', '成都', '绵阳', '德阳', '乐山', '峨眉山'], others: ['北京', '上海', '杭州', '广州', '深圳', '西安', '昆明', '贵阳'] },
      
      # 西北地区
      '西安' => { nearby: ['西安', '咸阳', '宝鸡', '渭南', '汉中'], others: ['北京', '上海', '杭州', '成都', '重庆', '郑州', '兰州', '银川'] },
      
      # 华中地区
      '武汉' => { nearby: ['武汉', '长沙', '南昌', '合肥', '郑州'], others: ['北京', '上海', '杭州', '广州', '深圳', '成都', '重庆', '西安'] }
    }
    
    # 默认分组（如果目的地不在映射表中）
    default_groups = {
      nearby: ['上海', '杭州', '南京', '苏州', '无锡', '常州', '黄山', '芜湖'],
      others: ['北京', '合肥', '宁波', '金华', '福州', '郑州', '武汉', '厦门']
    }
    
    # 查找匹配的城市分组
    groups = city_regions.find { |key, _| destination.to_s.include?(key) }&.last || default_groups
    
    # 返回分组结果，标题根据目的地动态生成
    nearby_title = if destination.to_s.include?('杭州')
      '杭州及周边参团'
    elsif destination.to_s.include?('上海')
      '上海及周边参团'
    elsif destination.to_s.include?('南京')
      '南京及周边参团'
    elsif destination.to_s.include?('北京')
      '北京及周边参团'
    elsif destination.to_s.include?('广州')
      '广州及周边参团'
    elsif destination.to_s.include?('成都')
      '成都及周边参团'
    elsif destination.to_s.include?('西安')
      '西安及周边参团'
    elsif destination.to_s.include?('浙江')
      '杭州及周边参团'
    else
      "#{groups[:nearby].first}及周边参团"
    end
    
    [
      { title: nearby_title, cities: groups[:nearby] },
      { title: '其他城市参团', cities: groups[:others] }
    ]
  end
end
