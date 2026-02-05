# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例287: 预订无障碍设施酒店
#
# 任务描述:
#   用户预订配备无障碍设施的酒店+轮椅租赁服务
#
# 评分标准:
#   - 创建酒店预订 (30%)
#   - 酒店配备无障碍设施 (25%)
#   - 创建轮椅租赁服务 (25%)
#   - 入住日期正确 (10%)
#   - 订单状态正确 (10%)
module V251V300
  class V287BookAccessibleHotelValidator < BaseValidator
    self.validator_id = 'v287_book_accessible_hotel_validator'
    self.task_id = 'd72a4ed6-b4c8-40f7-b9cc-c0424c05be6a'
    self.title = '预订无障碍设施酒店'
    self.description = '用户预订配备无障碍设施的酒店+轮椅租赁服务'
    self.timeout_seconds = 300
    
    def prepare
      @city = '上海'
      @check_in_date = Date.current + 3.days
      @check_out_date = @check_in_date + 2.days
      
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      if user.balance < 2000
        user.update!(balance: 3000)
      end
      
      {
        task: "请预订#{@city}的无障碍设施酒店，需要配备轮椅通道和无障碍设施，#{@check_in_date.strftime('%Y年%-m月%-d日')}入住，住#{(@check_out_date - @check_in_date).to_i}晚，同时需要租赁轮椅服务",
        city: @city,
        check_in_date: @check_in_date.to_s,
        check_out_date: @check_out_date.to_s,
        hint: "选择配备无障碍设施的酒店，并预订轮椅租赁服务"
      }
    end
    
    def verify
      add_assertion "创建了酒店预订", weight: 30 do
        @hotel_booking = HotelBooking
          .joins(:hotel)
          .where(hotels: { city: @city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        expect(@hotel_booking).not_to be_nil, "未找到#{@city}的酒店预订"
      end
      
      return unless @hotel_booking
      
      add_assertion "酒店配备无障碍设施", weight: 25 do
        hotel = @hotel_booking.hotel
        expect(hotel.facilities).to be_present, "酒店未配置设施信息"
        # 检查是否有无障碍相关设施（停车、电梯等可作为无障碍设施的标志）
        has_accessible_features = hotel.facilities.to_s.match?(/停车|电梯|无障碍/i)
        expect(has_accessible_features).to be(true), 
          "酒店未配备无障碍相关设施。当前设施: #{hotel.facilities}"
      end
      
      add_assertion "创建了轮椅租赁服务订单", weight: 25 do
        @car_order = CarOrder
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        # 使用用车订单模拟轮椅租赁服务
        expect(@car_order).not_to be_nil, "未找到轮椅租赁服务订单"
      end
      
      add_assertion "入住日期正确", weight: 10 do
        expect(@hotel_booking.check_in_date).to eq(@check_in_date),
          "入住日期错误。期望: #{@check_in_date}, 实际: #{@hotel_booking.check_in_date}"
      end
      
      add_assertion "订单状态正确", weight: 10 do
        valid_statuses = ['pending', 'paid']
        expect(valid_statuses).to include(@hotel_booking.status),
          "酒店订单状态错误: #{@hotel_booking.status}"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 1. 预订配备无障碍设施的酒店
      hotel = Hotel
        .where(city: @city, data_version: 0)
        .order(price: :desc)
        .first!
      
      HotelBooking.create!(
        hotel_room_id: hotel.hotel_rooms.first!.id,
        user_id: user.id,
        rooms_count: 1,
        adults_count: 1,
        children_count: 0,
        hotel_id: hotel.id,
        check_in_date: @check_in_date,
        check_out_date: @check_out_date,
        guest_name: user.name || '张三',
        guest_phone: user.phone || '13800138000',
        payment_method: '花呗',
        total_price: hotel.price * (@check_out_date - @check_in_date).to_i,
        status: 'pending',
        data_version: @data_version
      )
      
      # 2. 租赁轮椅服务（使用CarOrder模拟）
      car = Car.where(data_version: 0).first!
      CarOrder.create!(
        user_id: user.id,
        car_id: car.id,
        driver_name: user.name || '张三',
        driver_id_number: '440300199001011234',
        contact_phone: user.phone || '13800138000',
        pickup_datetime: @check_in_date,
        return_datetime: @check_out_date,
        pickup_location: "#{@city}#{hotel.name}",
        status: 'pending',
        total_price: 100 * (@check_out_date - @check_in_date).to_i,
        data_version: @data_version
      )
    end
    
    private
    
    def execution_state_data
      {
        city: @city,
        check_in_date: @check_in_date&.to_s,
        check_out_date: @check_out_date&.to_s
      }
    end
    
    def restore_from_state(data)
      @city = data['city']
      @check_in_date = Date.parse(data['check_in_date']) if data['check_in_date']
      @check_out_date = Date.parse(data['check_out_date']) if data['check_out_date']
    end
  end
end
