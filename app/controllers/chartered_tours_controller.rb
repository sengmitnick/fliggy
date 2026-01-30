class CharteredToursController < ApplicationController
  before_action :authenticate_user!

  def index
    # 定制旅游首页 - 展示个人定制和公司团建两个tab
    # 目前默认显示个人定制tab
    @active_tab = params[:tab] || 'personal'
  end

  def vehicles
    # 车型选择页面 - 显示不同时长和车型的价格
    @route = CharterRoute.friendly.find(params[:route_id])
    @departure_date = params[:departure_date].present? ? Date.parse(params[:departure_date]) : Date.tomorrow
    @duration_hours = params[:duration_hours]&.to_i || 6
    @passenger_count = params[:passenger_count]&.to_i || 1
    
    # 获取所有车型
    @vehicle_types = VehicleType.order(:category, :level)
    
    # 为每个车型计算价格（使用CharterPriceCalculatorService）
    @vehicle_prices = @vehicle_types.each_with_object({}) do |vehicle, hash|
      price = CharterPriceCalculatorService.call(
        route: @route,
        vehicle_type: vehicle,
        duration_hours: @duration_hours,
        departure_date: @departure_date
      )
      hash[vehicle.id] = price
    end
  end

  private
  # Write your private methods here
end
