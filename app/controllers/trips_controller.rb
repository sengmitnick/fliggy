class TripsController < ApplicationController

  def index
    @full_render = true
    if current_user
      # 已登录用户：加载真实订单数据（首次5个）
      @bookings = current_user.bookings.includes(:flight).where('flights.flight_date >= ?', Date.today).references(:flights).order('flights.flight_date ASC, flights.departure_time ASC').limit(5)
      @has_upcoming_trips = @bookings.any?
      
      # 获取总数，用于判断是否还有更多
      @total_bookings_count = current_user.bookings.joins(:flight).where('flights.flight_date >= ?', Date.today).count
      @has_more = @total_bookings_count > 5
    else
      # 未登录用户：显示演示数据
      @has_upcoming_trips = true
      @bookings = [OpenStruct.new(
        id: 999999,
        flight: OpenStruct.new(
          departure_city: '深圳',
          destination_city: '武汉',
          departure_time: (Date.today + 10.days).to_time.change(hour: 10, min: 55),
          arrival_time: (Date.today + 10.days).to_time.change(hour: 12, min: 55),
          departure_airport: '宝安T3',
          arrival_airport: '天河T3',
          airline: '东方航空',
          flight_number: 'MU2478',
          aircraft_type: '中型机737',
          flight_date: Date.today + 10.days
        ),
        passenger_name: '张润胜',
        status: 'paid'
      )]
      @has_more = false
    end
  end

  def load_more
    page = params[:page].to_i
    offset = page * 5
    
    @bookings = current_user.bookings.includes(:flight).where('flights.flight_date >= ?', Date.today).references(:flights).order('flights.flight_date ASC, flights.departure_time ASC').offset(offset).limit(5)
    
    # 判断是否还有更多
    @total_bookings_count = current_user.bookings.joins(:flight).where('flights.flight_date >= ?', Date.today).count
    @has_more = @total_bookings_count > (offset + 5)
  end

  private
  # Write your private methods here
end
