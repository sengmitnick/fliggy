# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例232: 张三后天要去北京开会，需要在CBD核心区附近预订酒店住2晚，方便参会
#
# 任务描述:
#   张三后天要去北京开会，需要在CBD核心区附近预订酒店住2晚。
#   要求Agent搜索酒店时，优先选择名称或地址包含"CBD核心区"关键词的酒店，确保位置便利。
#   Agent需要使用张三的信息作为入住人信息，创建1个酒店订单，确保入住日期为后天，住宿2晚。
#
# 业务流程（6个关键步骤）：
#   1. 明确受益人信息（张三，使用其姓名、身份证号、电话作为入住人信息）
#   2. 搜索北京市区酒店
#   3. 筛选位置符合要求的酒店（名称或地址包含"CBD核心区"关键词）
#   4. 选择符合位置要求的酒店和房间
#   5. 创建酒店订单（入住日期=后天，退房日期=大后天+1天，住2晚）
#   6. 使用受益人信息作为入住人信息
#
# 复杂度分析（5个关键点）：
#   1. 需要理解位置要求：酒店名称或地址必须包含"CBD核心区"关键词
#   2. 需要正确计算入住和退房日期：入住日期=后天，退房日期=后天+2天
#   3. 需要正确计算总价：房间价格×2晚
#   4. 需要使用受益人信息作为入住人
#   5. 需要验证酒店位置是否真正符合要求（名称或地址包含关键词）
#   ❌ 不能随意选择任何北京酒店：必须确保位置在CBD核心区附近
#
# 评分标准（5项，总计100分）：
#   1. 创建了酒店订单（25分）
#   2. 酒店位置符合要求（名称或地址包含"CBD核心区"）（35分）
#   3. 入住日期和时长正确（后天入住，住2晚）（20分）
#   4. 入住人信息正确（张三的姓名、电话）（15分）
#   5. 订单状态有效（5分）
#
# 使用方法:
#   rake validator:simulate_single[v232_book_hotel_near_specific_location_validator]
#   或访问 http://localhost:<PORT>/api/tasks 获取任务列表
#
module V201V250
  class V232BookHotelNearSpecificLocationValidator < BaseValidator
    self.validator_id = 'v232_book_hotel_near_specific_location_validator'
    self.task_id = '8ff8a9ff-9f9f-9f1f-1f2f-0f3a4b5c6d7f'
    self.title = '张三后天要去北京开会，需要在CBD核心区附近预订酒店住2晚，方便参会'
    self.description = '张三后天要去北京开会，需要在CBD核心区附近预订酒店住2晚，方便参会'
    self.timeout_seconds = 300
    
    def prepare
      @city = '北京'
      @location_keyword = 'CBD核心区'  # 市中心/商圈
      @check_in_date = Date.current + 2.days
      @check_out_date = @check_in_date + 2.days
      @nights = 2
      
      # 查询demo_user乘客信息
      demo_user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      demo_passenger = demo_user.passengers.find_by!(is_self: true)  # RLS 自动注入 data_version
      @passenger = OpenStruct.new(
        name: demo_passenger.name,
        id_number: demo_passenger.id_number,
        phone: demo_passenger.phone
      )
      
      # 查找包含位置关键词的酒店
      @available_hotels = Hotel.where(city: @city, data_version: 0)
        .where("name LIKE ? OR address LIKE ?", "%#{@location_keyword}%", "%#{@location_keyword}%")
        .order(price: :asc)
        .to_a
      
      raise "未找到#{@location_keyword}附近的酒店" if @available_hotels.empty?
      
      {
        task: "请为张三预订#{@check_in_date.strftime('%Y年%m月%d日')}（后天）在#{@city}#{@location_keyword}附近的酒店，住#{@nights}晚。",
        requirements: {
          beneficiary: '张三',
          city: @city,
          location: "#{@location_keyword}附近",
          check_in_date: @check_in_date.to_s,
          check_out_date: @check_out_date.to_s,
          nights: @nights,
          purpose: '位置便利，方便参会'
        },
        hint: "选择名称或地址包含'#{@location_keyword}'的酒店。使用张三的信息作为入住人。",
        statistics: {
          available_hotels: @available_hotels.count,
          location_keyword: @location_keyword,
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
      
      add_assertion "酒店位置符合要求（名称或地址包含\"#{@location_keyword}\"）", weight: 35 do
        hotel = @hotel_booking.hotel
        name_match = hotel.name.include?(@location_keyword)
        address_match = hotel.address&.include?(@location_keyword)
        
        expect(name_match || address_match).to eq(true),
          "酒店位置不符合要求。期望: #{@location_keyword}附近, 实际酒店: #{hotel.name}（地址: #{hotel.address}）"
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
      
      # 选择第一家符合位置要求的酒店
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
        location_keyword: @location_keyword,
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
      @location_keyword = data['location_keyword']
      @check_in_date = Date.parse(data['check_in_date'])
      @check_out_date = Date.parse(data['check_out_date'])
      @nights = data['nights'] || 2
      
      @passenger = OpenStruct.new(
        name: data['passenger_name'],
        id_number: data['passenger_id_number'],
        phone: data['passenger_phone']
      )
      
      @available_hotels = Hotel.where(city: @city, data_version: 0)
        .where("name LIKE ? OR address LIKE ?", "%#{@location_keyword}%", "%#{@location_keyword}%")
        .order(price: :asc)
        .to_a
    end
  end
end
