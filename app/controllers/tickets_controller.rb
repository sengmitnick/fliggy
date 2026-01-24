class TicketsController < ApplicationController
  include CitySelectorDataConcern
  
  def index
    # 默认城市为深圳（根据设计稿）
    @city = params[:city].presence || '深圳市'
    @selected_tag = params[:tag].presence
    @sort_by = params[:sort_by].presence || 'smart' # 智能排序/sales/rating
    
    # 获取所有可用的城市列表（从景点数据中提取）
    @cities = Attraction.distinct.pluck(:city).compact.sort
    
    # 如果没有城市数据，使用默认列表
    @cities = ['深圳市', '上海市', '北京市', '广州市', '杭州市', '成都市'] if @cities.empty?
    
    # 从数据库查询景点
    attractions = Attraction.includes(:tickets)
                            .where("city LIKE ?", "%#{@city.gsub('市', '')}%")
    
    # 排序逻辑
    attractions = case @sort_by
    when 'sales'
      attractions.order(review_count: :desc)
    when 'rating'
      attractions.order(rating: :desc)
    else # 'smart' or default
      attractions.order(rating: :desc, review_count: :desc)
    end
    
    # 限制结果
    attractions = attractions.limit(50)
    
    # 转换为视图需要的格式
    @tickets = attractions.map do |attraction|
      # 获取最低价格的门票
      min_ticket = attraction.tickets.available.order(:current_price).first
      
      {
        id: attraction.id,
        image: "https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800", # 默认图片，后续可以添加 cover_image
        badge: attraction.review_count > 1000 ? '热门' : nil,
        title: attraction.name,
        rating: attraction.rating > 0 ? attraction.rating : nil,
        rating_desc: "#{attraction.review_count}条评价",
        tags: [], # 可以后续添加景点标签字段
        provider: '官方',
        sales: "已售#{attraction.review_count}",
        price: min_ticket&.current_price&.to_i&.to_s || '0',
        price_suffix: '起'
      }
    end
    
    # 如果没有数据，显示空结果
    @tickets = [] if @tickets.empty?
  end
  
  def show
    @attraction = Attraction.includes(:tickets, :attraction_activities).find(params[:id])
    
    # 重定向到 attractions 的 show 页面
    redirect_to attraction_path(@attraction)
  end

  # 门票选择页面：选择门票类型（成人/儿童）和日期
  def select
    @ticket = Ticket.includes(:attraction, :ticket_suppliers).find(params[:id])
    @attraction = @ticket.attraction
    
    # 获取同一景点下的所有成人票和儿童票
    @adult_tickets = @attraction.tickets.available.where(ticket_type: 'adult')
    @child_tickets = @attraction.tickets.available.where(ticket_type: 'child')
  end

  # 供应商列表页面：显示不同供应商的价格和优惠
  def suppliers
    # 使用用户选择的 ticket_id（如果存在），否则使用 URL 中的 id
    ticket_id = params[:ticket_id].presence || params[:id]
    @ticket = Ticket.includes(:attraction, ticket_suppliers: :supplier).find(ticket_id)
    @attraction = @ticket.attraction
    @visit_date = params[:visit_date]&.to_date || Date.tomorrow
    @ticket_type = params[:ticket_type] || @ticket.ticket_type
    
    # 获取该门票的所有供应商（按评分排序）
    @ticket_suppliers = @ticket.ticket_suppliers
                              .includes(:supplier)
                              .joins(:supplier)
                              .order('suppliers.rating DESC, ticket_suppliers.sales_count DESC')
  end
end
