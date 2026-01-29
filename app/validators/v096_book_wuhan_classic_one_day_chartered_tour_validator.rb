# frozen_string_literal: true

require_relative 'base_validator'

# 验证用例96: 预订武汉经典一日包车游（经济7座，家庭出行）
class V096BookWuhanClassicOneDayCharteredTourValidator < BaseValidator
  self.validator_id = 'v096_book_wuhan_classic_one_day_chartered_tour_validator'
  self.task_id = 'eba7a78e-2541-4232-b0cf-427687f70264'
  self.title = '预订武汉经典一日包车游（经济7座，家庭5人）'
  self.description = '预订武汉经典一日游包车路线，家庭5人出行，选择经济7座车型，8小时服务'
  self.timeout_seconds = 240
  
  def prepare
    @city = '武汉'
    @route_keyword = '经典一日游'
    @vehicle_type = '经济7座'
    @duration_type = '8小时'
    @passenger_count = 5
    @travel_date = Date.current + 3.days
    
    @available_routes = CharterRoute.where(data_version: 0)
                                    .joins(:city)
                                    .where('cities.name = ?', @city)
                                    .where('charter_routes.name LIKE ?', "%#{@route_keyword}%")
    
    {
      task: "请预订#{@travel_date.strftime('%Y年%m月%d日')}的#{@city}#{@route_keyword}包车路线，家庭#{@passenger_count}人出行，选择#{@vehicle_type}车型，#{@duration_type}服务",
      city: @city,
      route_keyword: @route_keyword,
      vehicle_type: @vehicle_type,
      duration_type: @duration_type,
      passenger_count: @passenger_count,
      travel_date: @travel_date.strftime('%Y-%m-%d'),
      hint: "筛选武汉城市、路线名包含'经典一日游'的路线，选择车型为'经济7座'，服务时长8小时",
      available_routes_count: @available_routes.count
    }
  end
  
  def verify
    add_assertion "订单已创建", weight: 20 do
      @booking = CharterBooking.order(created_at: :desc).first
      expect(@booking).not_to be_nil, "未找到任何包车游订单"
    end
    
    return unless @booking
    
    add_assertion "城市正确（武汉）", weight: 20 do
      city = @booking.charter_route.city
      expect(city.name).to eq(@city),
        "城市不符合要求。期望: #{@city}, 实际: #{city.name}"
    end
    
    add_assertion "路线正确（经典一日游）", weight: 20 do
      route = @booking.charter_route
      expect(route.name).to include(@route_keyword),
        "路线不符合要求。期望包含: #{@route_keyword}, 实际: #{route.name}"
    end
    
    add_assertion "车型正确（经济7座）", weight: 20 do
      vehicle = @booking.vehicle_type
      expect(vehicle.name).to eq(@vehicle_type),
        "车型不符合要求。期望: #{@vehicle_type}, 实际: #{vehicle.name}"
    end
    
    add_assertion "服务时长正确（8小时）", weight: 20 do
      expect(@booking.duration_hours).to eq(8),
        "服务时长不符合要求。期望: 8小时, 实际: #{@booking.duration_hours}小时"
    end
  end
  
  def execution_state_data
    { city: @city, route_keyword: @route_keyword, vehicle_type: @vehicle_type, duration_type: @duration_type,
      passenger_count: @passenger_count, travel_date: @travel_date.to_s }
  end
  
  def restore_from_state(data)
    @city = data['city']
    @route_keyword = data['route_keyword']
    @vehicle_type = data['vehicle_type']
    @duration_type = data['duration_type']
    @passenger_count = data['passenger_count']
    @travel_date = Date.parse(data['travel_date'])
    @available_routes = CharterRoute.where(data_version: 0)
                                    .joins(:city)
                                    .where('cities.name = ?', @city)
                                    .where('charter_routes.name LIKE ?', "%#{@route_keyword}%")
  end
  
  def simulate
    user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
    
    route = CharterRoute.where(data_version: 0)
                        .joins(:city)
                        .where('cities.name = ?', @city)
                        .where('charter_routes.name LIKE ?', "%#{@route_keyword}%")
                        .first
    raise "未找到符合条件的路线" unless route
    
    vehicle_type = VehicleType.where(data_version: 0, name: @vehicle_type).first
    raise "未找到符合条件的车型" unless vehicle_type
    
    price = vehicle_type.hourly_price_8h
    
    CharterBooking.create!(
      user_id: user.id,
      charter_route_id: route.id,
      vehicle_type_id: vehicle_type.id,
      departure_date: @travel_date,
      departure_time: '09:00',
      duration_hours: 8,
      booking_mode: 'by_route',
      passengers_count: @passenger_count,
      contact_name: '吴九',
      contact_phone: '13800138007',
      total_price: price,
      status: 'pending'
    )
  end
end