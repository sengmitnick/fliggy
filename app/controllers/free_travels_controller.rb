class FreeTravelsController < ApplicationController
  def index
    # Default destination
    @destination = params[:destination].presence || '上海'
    @duration = params[:duration].presence
    @group_size = params[:group_size].presence
    
    # Hot destinations - 从数据库获取（筛选自由出行类型）
    @hot_destinations = TourGroupProduct.where(travel_type: '自由出行')
                                        .select(:destination)
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
    
    # Tour recommendations - 从数据库获取（只显示自由出行类型）
    products = TourGroupProduct.includes(:travel_agency)
                               .where(travel_type: '自由出行')
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

  private
  # Write your private methods here
end
