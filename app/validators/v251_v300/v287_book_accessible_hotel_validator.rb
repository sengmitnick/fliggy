# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例287: 给张三预订健身养生酒店
#
# 任务描述:
#   给张三预订上海配备健身养生设施的酒店
#
# 评分标准:
#   - 创建酒店预订 (30%)
#   - 酒店配备健身养生设施 (25%)
#   - 入住人信息正确（张三） (20%)
#   - 入住日期正确 (15%)
#   - 订单状态正确 (10%)
module V251V300
  class V287BookAccessibleHotelValidator < BaseValidator
    self.validator_id = 'v287_book_accessible_hotel_validator'
    self.task_id = 'd72a4ed6-b4c8-40f7-b9cc-c0424c05be6a'
    self.title = '给张三预订健身养生酒店'
    self.description = '给张三预订上海配备健身养生设施的酒店'
    self.timeout_seconds = 300
    
    def prepare
      @city = '上海'
      @check_in_date = Date.current + 3.days
      @check_out_date = @check_in_date + 2.days
      
      # 预查询乘客信息
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @zhangsan = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_guest_name = @zhangsan.name
      @expected_guest_phone = @zhangsan.phone
      
      if user.balance < 2000
        user.update!(balance: 3000)
      end
      
      {
        task: "请给张三预订#{@city}的健身养生酒店，需要配备健身房、游泳池等养生设施，#{@check_in_date.strftime('%Y年%-m月%-d日')}入住，住#{(@check_out_date - @check_in_date).to_i}晚",
        city: @city,
        check_in_date: @check_in_date.to_s,
        check_out_date: @check_out_date.to_s,
        hint: "选择配备健身养生设施的酒店"
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
      
      add_assertion "酒店配备健身养生设施", weight: 25 do
        hotel = @hotel_booking.hotel
        expect(hotel.facilities).to be_present, "酒店未配置设施信息"
        # 检查是否有健身养生相关设施（健身房、游泳池、水疗等）
        has_fitness_features = hotel.facilities.to_s.match?(/健身|游泳|水疗|桑拿|按摩|养生|美容/i)
        expect(has_fitness_features).to be(true), 
          "酒店未配备健身养生设施。当前设施: #{hotel.facilities}"
      end
      
      add_assertion "入住人信息正确（张三）", weight: 20 do
        expect(@hotel_booking.guest_name).to eq(@expected_guest_name),
          "入住人姓名错误。期望: #{@expected_guest_name}（张三），实际: #{@hotel_booking.guest_name}"
        expect(@hotel_booking.guest_phone).to eq(@expected_guest_phone),
          "入住人联系电话错误。期望: #{@expected_guest_phone}，实际: #{@hotel_booking.guest_phone}"
      end
      
      add_assertion "入住日期正确", weight: 15 do
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
      zhangsan = user.passengers.find_by!(name: '张三', data_version: 0)
      
      # 1. 预订配备健身养生设施的酒店
      # 筛选出带有健身养生相关设施的酒店
      hotels_with_fitness = Hotel
        .where(city: @city, data_version: 0)
        .select { |h| h.facilities.to_s.match?(/健身|游泳|水疗|桑拿|按摩|养生|美容/i) }
      
      hotel = hotels_with_fitness.max_by(&:price)
      raise "未找到配备健身养生设施的酒店" if hotel.nil?
      
      HotelBooking.create!(
        hotel_room_id: hotel.hotel_rooms.first!.id,
        user_id: user.id,
        rooms_count: 1,
        adults_count: 1,
        children_count: 0,
        hotel_id: hotel.id,
        check_in_date: @check_in_date,
        check_out_date: @check_out_date,
        guest_name: zhangsan.name,
        guest_phone: zhangsan.phone,
        payment_method: '花呗',
        total_price: hotel.price * (@check_out_date - @check_in_date).to_i,
        status: 'pending',
        data_version: @data_version
      )
    end
    
    private
    
    def execution_state_data
      {
        city: @city,
        check_in_date: @check_in_date&.to_s,
        check_out_date: @check_out_date&.to_s,
        expected_guest_name: @expected_guest_name,
        expected_guest_phone: @expected_guest_phone
      }
    end
    
    def restore_from_state(data)
      @city = data['city']
      @check_in_date = Date.parse(data['check_in_date']) if data['check_in_date']
      @check_out_date = Date.parse(data['check_out_date']) if data['check_out_date']
      @expected_guest_name = data['expected_guest_name']
      @expected_guest_phone = data['expected_guest_phone']
    end
  end
end
