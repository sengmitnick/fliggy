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

    @hotels = Hotel.all
    @hotels = @hotels.by_city(@city)
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
  end

  def policy
    @hotel = Hotel.find(params[:id])
    @hotel_policy = @hotel.hotel_policy || @hotel.build_hotel_policy(default_policy_data)
  end

  def search
    @query = params[:q]
    @city = params[:city] || '深圳市'
    
    @hotels = Hotel.all
    @hotels = @hotels.by_city(@city)
    
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
