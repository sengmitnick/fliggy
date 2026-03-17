# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例233: 张三明天要去上海出差，喜欢运动健身，需要预订带游泳池的酒店住1晚
#
# 任务描述:
#   张三明天要去上海出差，喜欢运动健身，需要预订带游泳池的酒店住1晚。
#   要求Agent搜索酒店时，必须筛选出设施中包含"游泳池"的酒店，确保满足张三的健身需求。
#   Agent需要使用张三的信息作为入住人信息，创建1个酒店订单，确保入住日期为明天，住宿1晚。
#
# 业务流程（6个关键步骤）：
#   1. 明确受益人信息（张三，使用其姓名、身份证号、电话作为入住人信息）
#   2. 搜索上海市区酒店
#   3. 筛选设施符合要求的酒店（设施字段包含"游泳池"关键词）
#   4. 选择符合设施要求的酒店和房间
#   5. 创建酒店订单（入住日期=明天，退房日期=后天，住1晚）
#   6. 使用受益人信息作为入住人信息
#
# 复杂度分析（5个关键点）：
#   1. 需要理解设施要求：酒店设施字段必须包含"游泳池"关键词
#   2. 需要正确计算入住和退房日期：入住日期=明天，退房日期=明天+1天
#   3. 需要正确计算总价：房间价格×1晚
#   4. 需要使用受益人信息作为入住人
#   5. 需要验证酒店设施是否真正符合要求（设施字段包含关键词）
#   ❌ 不能随意选择任何上海酒店：必须确保酒店设施包含游泳池
#
# 评分标准（5项，总计100分）：
#   1. 创建了酒店订单（25分）
#   2. 酒店包含所需设施（游泳池）（35分）
#   3. 入住日期和时长正确（明天入住，住1晚）（20分）
#   4. 入住人信息正确（张三的姓名、电话）（15分）
#   5. 订单状态有效（5分）
#
# 使用方法:
#   rake validator:simulate_single[v233_book_hotel_with_specific_facilities_validator]
#   或访问 http://localhost:<PORT>/api/tasks 获取任务列表
#
module V201V250
  class V233BookHotelWithSpecificFacilitiesValidator < BaseValidator
    self.validator_id = 'v233_book_hotel_with_specific_facilities_validator'
    self.task_id = '9ff9b0ff-0f0f-0f2f-2f3f-1f4a5b6c7d8f'
    self.title = '张三明天要去上海出差，喜欢运动健身，需要预订带游泳池的酒店住1晚'
    self.description = '张三明天要去上海出差，喜欢运动健身，需要预订带游泳池的酒店住1晚'
    self.timeout_seconds = 300
    
    def prepare
      @city = '上海'
      @required_facility = '游泳池'
      @check_in_date = Date.current + 1.day
      @check_out_date = @check_in_date + 1.day
      @nights = 1
      
      # 查询demo_user乘客信息
      demo_user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      demo_passenger = Passenger.find_by!(user_id: demo_user.id, is_self: true, data_version: 0)
      @passenger = OpenStruct.new(
        name: demo_passenger.name,
        id_number: demo_passenger.id_number,
        phone: demo_passenger.phone
      )
      
      # 查找包含指定设施的酒店
      @available_hotels = Hotel.where(city: @city, data_version: 0)
        .where("facilities LIKE ?", "%#{@required_facility}%")
        .order(price: :asc)
        .to_a
      
      raise "未找到带#{@required_facility}的酒店" if @available_hotels.empty?
      
      {
        task: "请为张三预订#{@check_in_date.strftime('%Y年%m月%d日')}（明天）在#{@city}带#{@required_facility}的酒店，住#{@nights}晚。",
        requirements: {
          beneficiary: '张三',
          city: @city,
          facilities: "必须有#{@required_facility}",
          check_in_date: @check_in_date.to_s,
          check_out_date: @check_out_date.to_s,
          nights: @nights,
          purpose: '运动健身'
        },
        hint: "选择设施中包含'#{@required_facility}'的酒店。使用张三的信息作为入住人。",
        statistics: {
          available_hotels: @available_hotels.count,
          required_facility: @required_facility,
          hotel_price_range: {
            min: @available_hotels.map { |h| h.hotel_rooms.where(data_version: 0).minimum(:price) }.compact.min,
            max: @available_hotels.map { |h| h.hotel_rooms.where(data_version: 0).maximum(:price) }.compact.max
          },
          nights: @nights,
          check_in_date: @check_in_date.to_s,
          check_out_date: @check_out_date.to_s
        }
      }
    end
    
    def verify
      add_assertion "创建了酒店订单", weight: 25 do
        all_bookings = HotelBooking
          .joins(:hotel)
          .includes(:hotel)
          .where(hotels: { city: @city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        @hotel_booking = all_bookings.first
        expect(@hotel_booking).not_to be_nil, "未找到#{@city}的酒店订单"
      end
      
      return if @hotel_booking.nil?
      
      add_assertion "酒店包含所需设施（#{@required_facility}）", weight: 35 do
        hotel = @hotel_booking.hotel
        has_facility = hotel.facilities&.include?(@required_facility)
        
        expect(has_facility).to eq(true),
          "酒店不包含所需设施。要求: #{@required_facility}, 实际酒店设施: #{hotel.facilities}"
      end
      
      add_assertion "入住日期和时长正确（入住#{@check_in_date.strftime('%m月%d日')}，退房#{@check_out_date.strftime('%m月%d日')}）", weight: 20 do
        expect(@hotel_booking.check_in_date).to eq(@check_in_date),
          "入住日期错误。期望: #{@check_in_date}, 实际: #{@hotel_booking.check_in_date}"
        expect(@hotel_booking.check_out_date).to eq(@check_out_date),
          "退房日期错误。期望: #{@check_out_date}, 实际: #{@hotel_booking.check_out_date}"
      end
      
      add_assertion "入住人信息正确（张三的姓名、电话）", weight: 15 do
        expect(@hotel_booking.guest_name).to eq(@passenger.name),
          "入住人姓名错误。期望: #{@passenger.name}, 实际: #{@hotel_booking.guest_name}"
        expect(@hotel_booking.guest_phone).to eq(@passenger.phone),
          "入住人电话错误。期望: #{@passenger.phone}, 实际: #{@hotel_booking.guest_phone}"
      end
      
      add_assertion "订单状态有效", weight: 5 do
        expect(@hotel_booking.status).to be_in(['pending', 'paid', 'completed'])
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 选择第一家符合设施要求的酒店
      hotel = @available_hotels.first
      room = hotel.hotel_rooms.where(data_version: 0).order(price: :asc).first
      
      raise "未找到可用房间" unless room
      
      HotelBooking.create!(
        user: user,
        hotel: hotel,
        hotel_room: room,
        check_in_date: @check_in_date,
        check_out_date: @check_out_date,
        guest_name: @passenger.name,
        guest_phone: @passenger.phone,
        room_count: 1,
        total_price: room.price * @nights,
        status: 'paid',
        payment_method: '花呗',
        data_version: @data_version
      )
    end
    
    private
    
    def execution_state_data
      {
        city: @city,
        required_facility: @required_facility,
        check_in_date: @check_in_date.to_s,
        check_out_date: @check_out_date.to_s,
        nights: @nights,
        passenger_name: @passenger.name,
        passenger_id_number: @passenger.id_number,
        passenger_phone: @passenger.phone
      }
    end
    
    def restore_from_state(data)
      @city = data['city']
      @required_facility = data['required_facility']
      @check_in_date = Date.parse(data['check_in_date'])
      @check_out_date = Date.parse(data['check_out_date'])
      @nights = data['nights'] || 1
      
      @passenger = OpenStruct.new(
        name: data['passenger_name'],
        id_number: data['passenger_id_number'],
        phone: data['passenger_phone']
      )
      
      @available_hotels = Hotel.where(city: @city, data_version: 0)
        .where("facilities LIKE ?", "%#{@required_facility}%")
        .order(price: :asc)
        .to_a
    end
  end
end
