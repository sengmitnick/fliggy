class CruisesController < ApplicationController
  before_action :authenticate_user!

  def index
    # 获取所有航线分类
    @cruise_routes = CruiseRoute.order(:id)
    
    # 获取热门游轮班次（推荐列表，不做筛选）
    @popular_sailings = CruiseSailing.where(status: 'on_sale')
                                      .includes(:cruise_ship, :cruise_route, :cruise_products)
                                      .order('cruise_sailings.created_at DESC')
                                      .limit(20)
  end

  def search
    # 获取所有航线分类
    @cruise_routes = CruiseRoute.order(:id)
    
    # 获取选中的航线
    @selected_route = CruiseRoute.find_by(id: params[:route])
    
    # 按航线筛选游轮班次
    @sailings = CruiseSailing.where(status: 'on_sale')
    
    if @selected_route.present?
      @sailings = @sailings.where(cruise_route_id: @selected_route.id)
    end
    
    # 按城市筛选
    if params[:city].present?
      @sailings = @sailings.where(departure_port: params[:city])
    end
    
    # 按月份筛选
    if params[:month].present?
      # params[:month] 格式为 "YYYY-MM"
      begin
        start_date = Date.parse("#{params[:month]}-01")
        end_date = start_date.end_of_month
        @sailings = @sailings.where(departure_date: start_date..end_date)
      rescue ArgumentError
        # 如果日期解析失败，忽略月份筛选
      end
    end
    
    @sailings = @sailings
                 .includes(:cruise_ship, :cruise_route, :cruise_products)
                 .order('cruise_sailings.created_at DESC')
  end

  def show
    # 通过 slug 查找船只
    @cruise_ship = CruiseShip.friendly.find(params[:id])
    
    # 获取该船只的所有在售班次
    @sailings = @cruise_ship.cruise_sailings
                            .where(status: 'on_sale')
                            .includes(:cruise_route, :cruise_products)
                            .order(:departure_date)
    
    # 获取船只的所有舱房类型
    @cabin_types = @cruise_ship.cabin_types.order(:category)
    
    # 如果 URL 中有指定 sailing_id，则选中该班次
    @selected_sailing = @sailings.find_by(id: params[:sailing_id]) || @sailings.first
    
    # 如果有选中的班次，获取其行程信息
    @itinerary = @selected_sailing&.itinerary_list || []
  end

  private
  # Write your private methods here
end
