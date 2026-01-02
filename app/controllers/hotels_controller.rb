class HotelsController < ApplicationController

  def index
    @city = params[:city] || '深圳市'
    @check_in = params[:check_in] || Time.zone.today
    @check_out = params[:check_out] || (Time.zone.today + 1.day)
    @rooms = params[:rooms]&.to_i || 1
    @adults = params[:adults]&.to_i || 1
    @children = params[:children]&.to_i || 0
    @star_level = params[:star_level]
    @price_min = params[:price_min]
    @price_max = params[:price_max]
    @quick_filter = params[:quick_filter]
    @hotel_type = params[:type] # hotel, homestay
    @region = params[:region]
    @location_type = params[:location_type] || 'domestic' # domestic, international
    @room_category = params[:room_category] # hourly - 用于显示钟点房

    @hotels = Hotel.all
    
    # 位置筛选：国内/国际
    if @location_type == 'international'
      @hotels = @hotels.international
    else
      @hotels = @hotels.domestic
    end
    
    # 城市筛选
    @hotels = @hotels.by_city(@city)
    
    # 地区筛选
    @hotels = @hotels.by_region(@region) if @region.present?
    
    # 类型筛选：酒店/民宿/钟点房
    if @room_category == 'hourly'
      # 钟点房：查询所有有钟点房的住宿场所
      @hotels = @hotels.with_hourly_rooms
    elsif @hotel_type.present?
      # 酒店或民宿：按 hotel_type 筛选
      @hotels = @hotels.by_type(@hotel_type)
    end
    
    @hotels = @hotels.by_star_level(@star_level) if @star_level.present?
    @hotels = @hotels.by_price_range(@price_min, @price_max) if @price_min.present? || @price_max.present?
    @hotels = @hotels.ordered.page(params[:page]).per(10)

    @featured_hotels = Hotel.featured.limit(3)
  end

  def show
    @hotel = Hotel.find(params[:id])
    @check_in = params[:check_in] || Time.zone.today
    @check_out = params[:check_out] || (Time.zone.today + 1.day)
    @rooms = params[:rooms]&.to_i || 1
    @adults = params[:adults]&.to_i || 1
    @children = params[:children]&.to_i || 0
    @room_category = params[:room_category] # 房型分类：overnight 或 hourly
  end

  def policy
    @hotel = Hotel.find(params[:id])
    @hotel_policy = @hotel.hotel_policy || @hotel.build_hotel_policy(default_policy_data)
  end

  def search
    @query = params[:q]
    @city = params[:city] || '深圳市'
    @check_in = params[:check_in] || Time.zone.today
    @check_out = params[:check_out] || (Time.zone.today + 1.day)
    @rooms = params[:rooms]&.to_i || 1
    @adults = params[:adults]&.to_i || 1
    @children = params[:children]&.to_i || 0
    @hotel_type = params[:type]
    @region = params[:region]
    @location_type = params[:location_type] || 'domestic'
    @room_category = params[:room_category]
    
    @hotels = Hotel.all
    
    # 位置筛选
    if @location_type == 'international'
      @hotels = @hotels.international
    else
      @hotels = @hotels.domestic
    end
    
    @hotels = @hotels.by_city(@city)
    @hotels = @hotels.by_region(@region) if @region.present?
    
    # 类型筛选
    if @room_category == 'hourly'
      @hotels = @hotels.with_hourly_rooms
    elsif @hotel_type.present?
      @hotels = @hotels.by_type(@hotel_type)
    end
    
    if @query.present?
      @hotels = @hotels.where("name ILIKE ? OR address ILIKE ?", "%#{@query}%", "%#{@query}%")
    end
    
    @hotels = @hotels.ordered.page(params[:page]).per(10)
    
    render :index
  end

  private
  
  def default_policy_data
    {
      check_in_time: "15:00后",
      check_out_time: "12:00前",
      pet_policy: "暂不支持携带宠物和服务型宠物，感谢理解",
      breakfast_type: "其他",
      breakfast_hours: "每天07:00-10:00",
      breakfast_price: 44,
      payment_methods: ["银联", "支付宝"]
    }
  end
end
