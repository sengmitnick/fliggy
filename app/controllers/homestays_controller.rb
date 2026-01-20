class HomestaysController < ApplicationController
  include CitySelectorDataConcern
  def index
    # 重用酒店的逻辑，但固定类型为民宿
    @city = params[:city] || '深圳'
    @check_in = params[:check_in] || Time.zone.today
    @check_out = params[:check_out] || (Time.zone.today + 1.day)
    @rooms = params[:rooms]&.to_i || 1
    @adults = params[:adults]&.to_i || 1
    @children = params[:children]&.to_i || 0
    @location_type = 'domestic' # 民宿首页默认国内
    @query = params[:q]

    # 获取民宿数据（type = 'homestay'）
    @hotels = Hotel.by_type('homestay').domestic
    
    # 城市筛选
    @hotels = @hotels.by_city(@city)
    
    # 应用搜索筛选
    if @query.present?
      @hotels = @hotels.where("name ILIKE ? OR address ILIKE ?", "%#{@query}%", "%#{@query}%")
    end
    
    @hotels = @hotels.ordered.page(params[:page]).per(10)
    @featured_hotels = Hotel.by_type('homestay').featured.limit(2)
  end

  def search
    # 搜索逻辑：跳转到酒店搜索页面，但加上 type=homestay 参数
    search_params = params.permit(:city, :check_in, :check_out, :rooms, :adults, :children, :q)
    search_params[:type] = 'homestay'
    search_params[:location_type] = 'domestic'
    
    redirect_to search_hotels_path(search_params)
  end
end
