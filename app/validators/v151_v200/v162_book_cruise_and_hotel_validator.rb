# frozen_string_literal: true

require_relative '../base_validator'

# V162BookCruiseAndHotelValidator
# 验证用例162: 给张三和李四2成人预订当月最近日期上海出发日本邮轮6天5晚，并预订邮轮出发前1天入住上海酒店（住1晚，第2天退房）
#
# 任务描述:
#   张三和李四计划预订上海出发日本邮轮6天5晚，并提前入住上海酒店：邮轮出发前1天入住上海酒店，住1晚后第2天退房（即邮轮出发当天退房）。
#   1. 上海出发日本邮轮6天5晚（当月最近日期班次，2成人：张三和李四）
#   2. 酒店住宿（邮轮出发前1天入住上海酒店，住1晚第2天退房）
#
# 任务分解步骤:
#   1. 查询上海出发日本邮轮班次（departure_port=上海，duration_days=6，duration_nights=5，当月）
#   2. 选择当月最近日期的班次（按departure_date升序排序后取第一个）
#   3. 创建邮轮订单（2成人：张三和李四，联系人=张三）
#   4. 查询上海酒店（从Hotel获取上海酒店）
#   5. 计算酒店入住日期（邮轮出发前1天）和退房日期（邮轮出发当天）
#   6. 创建酒店订单（邮轮出发前1天入住，住1晚第2天退房，入住人=张三）
#
# 评分标准（总分100分）:
#   1. 创建了邮轮订单 (20分)
#   2. 出发港正确（上海） (10分)
#   3. 创建了酒店订单 (25分)
#   4. 酒店城市正确（上海） (15分)
#   5. 入住日期正确（邮轮出发前1天） (10分)
#   6. 退房日期正确（住1晚，第2天退房） (5分)
#   7. 邮轮联系人信息正确（张三） (8分)
#   8. 酒店入住人信息正确（张三） (7分)

module V151V200
  class V162BookCruiseAndHotelValidator < BaseValidator
    self.validator_id = 'v162_book_cruise_and_hotel_validator'
    self.task_id = 'f2a3b4c5-6d7e-8f9a-0b1c-2d3e4f5a6b7c'
    self.title = '给张三和李四2成人预订当月最近日期上海出发日本邮轮6天5晚，并预订邮轮出发前1天入住上海酒店（住1晚，第2天退房）'
    self.description = '给张三和李四预订上海出发日本邮轮6天5晚（当月最近日期班次），并预订邮轮出发前1天入住上海酒店，住1晚后第2天退房（即邮轮出发当天退房）'
    self.timeout_seconds = 300

    def prepare
      # 邮轮出发月份：当前月份
      @expected_month = Date.current.month

      @departure_port = '上海'
      @duration_days = 6
      @duration_nights = 5
      @adult_count = 2
      
      # 预查询demo_user的乘客信息（张三作为联系人和第一位出行人员）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_contact_name = @passenger.name
      @expected_contact_phone = @passenger.phone
      
      # 查找可用的上海邮轮班次（按月份查询，且出发日期>=今天）
      @available_sailings = CruiseSailing
        .where("departure_port LIKE ?", "%#{@departure_port}%")
        .where(duration_days: @duration_days, duration_nights: @duration_nights, data_version: 0)
        .where('EXTRACT(MONTH FROM departure_date) = ?', @expected_month)
        .where('departure_date >= ?', Date.current)  # 只查询今天及以后的班次
        .order(departure_date: :asc)
        .to_a
      
      expect(@available_sailings).not_to be_empty, "数据包缺少上海出发日本6天5晚邮轮班次（#{@expected_month}月份）"
      
      # 查找可用的上海酒店
      @available_hotels = Hotel
        .where("city LIKE ?", "%#{@departure_port}%")
        .where(data_version: 0)
        .to_a
      
      expect(@available_hotels).not_to be_empty, "数据包缺少上海酒店"
    end

    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 选择最近日期的班次
      sailing = @available_sailings.first
      ship = sailing.cruise_ship
      
      # 计算酒店入住日期（邮轮出发前1天）
      @hotel_checkin_date = sailing.departure_date - 1.day
      @hotel_checkout_date = sailing.departure_date
      
      cabin_type = CabinType.where(data_version: 0, cruise_ship_id: ship.id, category: 'interior').first
      raise "未找到舱房类型" unless cabin_type
      
      # 查找邮轮产品（必须存在于数据包中）
      cruise_product = CruiseProduct.find_by!(
        cruise_sailing_id: sailing.id,
        cabin_type_id: cabin_type.id,
        data_version: 0
      )
      
      total_price = cruise_product.price_per_person * @adult_count
      
      # 准备出行人员信息（2成人：张三和李四）
      passenger_info = [
        {
          name: @passenger.name,
          id_number: @passenger.id_number,
          phone: @passenger.phone,
          passenger_type: 'adult'
        },
        {
          name: '李四',
          id_number: '110101199001012346',
          phone: '13900000002',
          passenger_type: 'adult'
        }
      ]
      
      # 创建邮轮订单（明确出行人员：张三和李四）
      CruiseOrder.create!(
        user_id: user.id,
        cruise_product_id: cruise_product.id,
        quantity: @adult_count,
        passenger_info: passenger_info,
        contact_name: @passenger.name,
        contact_phone: @passenger.phone,
        total_price: total_price,
        accept_terms: true,
        status: 'pending',
        data_version: @data_version
      )
      
      # 创建酒店订单（邮轮出发前1天入住，住1晚第2天退房）
      hotel = @available_hotels.first
      room = hotel.hotel_rooms.where(data_version: 0).order(:price).first
      raise "未找到酒店房型" unless room
      
      HotelBooking.create!(
        user: user,
        hotel_id: hotel.id,
        hotel_room_id: room.id,
        check_in_date: @hotel_checkin_date,  # 邮轮出发前1天
        check_out_date: @hotel_checkout_date,  # 邮轮出发当天（第2天）
        guest_name: @passenger.name,
        guest_phone: @passenger.phone,
        payment_method: '花呗',
        total_price: room.price,
        data_version: @data_version
      )
    end

    def execution_state_data
      {
        data_version: @data_version,
        expected_month: @expected_month,
        hotel_checkin_date: @hotel_checkin_date&.to_s,
        hotel_checkout_date: @hotel_checkout_date&.to_s,
        departure_port: @departure_port,
        duration_days: @duration_days,
        duration_nights: @duration_nights,
        adult_count: @adult_count,
        expected_contact_name: @expected_contact_name,
        expected_contact_phone: @expected_contact_phone
      }
    end

    def restore_from_state(data)
      @data_version = data['data_version']
      @expected_month = data['expected_month']
      @hotel_checkin_date = Date.parse(data['hotel_checkin_date']) if data['hotel_checkin_date']
      @hotel_checkout_date = Date.parse(data['hotel_checkout_date']) if data['hotel_checkout_date']
      @departure_port = data['departure_port']
      @duration_days = data['duration_days']
      @duration_nights = data['duration_nights']
      @adult_count = data['adult_count']
      @expected_contact_name = data['expected_contact_name']
      @expected_contact_phone = data['expected_contact_phone']
      
      # 重新查询乘客信息（张三作为联系人和第一位出行人员）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_contact_name = @passenger.name
      @expected_contact_phone = @passenger.phone
      
      # 重新查询邮轮班次（只查询今天及以后的）
      @available_sailings = CruiseSailing
        .where("departure_port LIKE ?", "%#{@departure_port}%")
        .where(duration_days: @duration_days, duration_nights: @duration_nights, data_version: 0)
        .where('EXTRACT(MONTH FROM departure_date) = ?', @expected_month)
        .where('departure_date >= ?', Date.current)
        .order(departure_date: :asc)
        .to_a
      
      # 重新查询酒店
      @available_hotels = Hotel
        .where("city LIKE ?", "%#{@departure_port}%")
        .where(data_version: 0)
        .to_a
    end

    def verify
      # 断言1: 创建了邮轮订单
      add_assertion "创建了邮轮订单", weight: 20 do
        @cruise_order = CruiseOrder
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@cruise_order).not_to be_nil, "未找到任何邮轮订单"
      end
      
      return if @cruise_order.nil?
      
      # 断言2: 出发港正确
      add_assertion "出发港正确（#{@departure_port}）", weight: 10 do
        sailing = @cruise_order.cruise_product.cruise_sailing
        expect(sailing.departure_port).to include(@departure_port),
          "出发港错误。期望包含: #{@departure_port}, 实际: #{sailing.departure_port}"
      end
      
      # 断言3: 创建了酒店订单
      add_assertion "创建了酒店订单", weight: 25 do
        @hotel_booking = HotelBooking
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@hotel_booking).not_to be_nil, "未找到任何酒店订单"
      end
      
      return if @hotel_booking.nil?
      
      # 断言4: 酒店城市正确
      add_assertion "酒店城市正确（#{@departure_port}）", weight: 15 do
        expect(@hotel_booking.hotel.city).to include(@departure_port),
          "酒店城市错误。期望: #{@departure_port}, 实际: #{@hotel_booking.hotel.city}"
      end
      
      # 断言5: 入住日期正确（邮轮出发前1天）
      add_assertion "入住日期正确（邮轮出发前1天）", weight: 10 do
        sailing = @cruise_order.cruise_product.cruise_sailing
        expected_checkin = sailing.departure_date - 1.day
        expect(@hotel_booking.check_in_date).to eq(expected_checkin),
          "入住日期错误。期望: #{expected_checkin}（邮轮#{sailing.departure_date.strftime('%m月%d日')}出发前1天）, 实际: #{@hotel_booking.check_in_date}"
      end
      
      # 断言6: 退房日期正确（住1晚，第2天退房）
      add_assertion "退房日期正确（住1晚，第2天退房）", weight: 5 do
        sailing = @cruise_order.cruise_product.cruise_sailing
        expected_checkout = sailing.departure_date  # 邮轮出发当天退房
        expect(@hotel_booking.check_out_date).to eq(expected_checkout),
          "退房日期错误。期望: #{expected_checkout}（邮轮#{sailing.departure_date.strftime('%m月%d日')}出发当天/第2天退房）, 实际: #{@hotel_booking.check_out_date}"
      end
      
      # 断言7: 邮轮联系人信息正确（#{@expected_contact_name}）
      add_assertion "邮轮联系人信息正确（#{@expected_contact_name}）", weight: 8 do
        expect(@cruise_order.contact_name).to eq(@expected_contact_name),
          "邮轮联系人姓名错误。期望: #{@expected_contact_name}, 实际: #{@cruise_order.contact_name}"
        expect(@cruise_order.contact_phone).to eq(@expected_contact_phone),
          "邮轮联系人电话错误。期望: #{@expected_contact_phone}, 实际: #{@cruise_order.contact_phone}"
      end
      
      # 断言8: 酒店入住人信息正确（#{@expected_contact_name}）
      add_assertion "酒店入住人信息正确（#{@expected_contact_name}）", weight: 7 do
        expect(@hotel_booking.guest_name).to eq(@expected_contact_name),
          "酒店入住人姓名错误。期望: #{@expected_contact_name}, 实际: #{@hotel_booking.guest_name}"
        expect(@hotel_booking.guest_phone).to eq(@expected_contact_phone),
          "酒店入住人电话错误。期望: #{@expected_contact_phone}, 实际: #{@hotel_booking.guest_phone}"
      end
    end
  end
end
