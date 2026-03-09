# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例137: 帮张三预订后天上海→杭州火车票（二等座）+杭州酒店（后天入住1晚）+返程送站服务（大后天10:00从西湖风景区到杭州东站）
#
# 任务描述:
#   张三后天需要从上海到杭州出差，需要预订火车票（二等座）、杭州酒店住1晚，以及返程时大后天上午10:00从西湖风景区（酒店所在区域）到杭州东站的送站服务。
#   Agent 需要创建3个订单（火车票+酒店+送站服务），确保酒店入住日期与火车日期一致，送站服务在退房日上午10:00从西湖风景区出发到杭州东站。
#
# 业务流程（11个关键步骤）：
#   1. 明确受益人信息（张三，使用其姓名、身份证号、电话作为乘客、入住人和送站乘客信息）
#   2. 搜索上海→杭州火车票（后天出发）
#   3. 按二等座价格升序排序，选择火车票
#   4. 创建火车票订单（座位类型=二等座）
#   5. 搜索杭州酒店
#   6. 筛选酒店房间（room_category='overnight'，排除钟点房）
#   7. 按房间价格升序排序，选择酒店房间
#   8. 创建酒店订单（入住日期=火车日期，入住1晚，退房日期=大后天）
#   9. 从TransferLocation查询杭州的接送点（西湖风景区或武林广场等酒店区域）
#   10. 创建送站服务订单（transfer_type='train_dropoff', service_type='to_station'，从酒店区域到杭州东站）
#   11. 设置送站时间为退房日期当天上午10:00（pickup_datetime = 大后天 10:00）
#
# 复杂度分析（10个关键点）：
#   1. 需要理解火车+酒店+送站服务的三模块组合预订场景
#   2. 需要明确火车路线（上海→杭州，后天出发）
#   3. 需要选择二等座座位类型（seat_type = 'second_class'）
#   4. 需要协调酒店入住日期与火车到达日期一致（check_in_date = train_date）
#   5. 需要计算退房日期（check_out_date = check_in_date + 1.day = 大后天）
#   6. 需要理解送站服务类型（transfer_type='train_dropoff' 送到火车站，service_type='to_station' 到站服务）
#   7. 需要从TransferLocation查询杭州的酒店区域接送点（使用city='杭州'和location_type='other'过滤，如西湖风景区、武林广场、钱江新城CBD）
#   8. 需要使用TransferLocation查询结果的name字段作为location_from（不能硬编码，应选择合理的酒店区域而非火车站广场）
#   9. 需要明确送站时间（pickup_datetime = 大后天 10:00）
#   10. 需要使用受益人信息作为乘客、入住人和送站乘客信息
#   ❌ 不能一次性提供所有信息：需要分别查询火车、酒店、TransferLocation数据，协调时间和地点逻辑，分步骤创建3个订单。
#
# 评分标准（10项，总计100分）：
#   1. 创建了火车票+酒店+送站3个订单（25分）
#   2. 火车票路线正确（上海→杭州）（10分）
#   3. 座位类型=二等座（10分）
#   4. 乘客信息正确（张三的姓名和身份证号）（10分）
#   5. 酒店城市正确（杭州）（10分）
#   6. 入住日期=火车日期（10分）
#   7. 送站终点=火车站（10分）
#   8. 送站起点为TransferLocation中的杭州酒店区域接送点（验证location_from是否在TransferLocation.where(city: '杭州', location_type: 'other')中，如西湖风景区、武林广场、钱江新城CBD）（5分）
#   9. 送站时间为10:00（5分）
#   10. 入住人信息正确（张三的姓名和联系电话）（5分）
#
# 使用方法:
#   rake validator:simulate_single[v137_book_train_hotel_and_return_dropoff_validator]
#   或访问 http://localhost:<PORT>/api/tasks 获取任务列表
#
module V101V150
  class V137BookTrainHotelAndReturnDropoffValidator < BaseValidator
    self.validator_id = 'v137_book_train_hotel_and_return_dropoff_validator'
    self.task_id = 'd7e8f9a0-1b2c-3d4e-5f6a-7b8c9d0e1f3a'
    self.title = '帮张三预订后天上海→杭州火车票（二等座）+杭州酒店（后天入住1晚）+返程送站服务（大后天10:00从西湖风景区到杭州东站）'
    self.description = '帮张三预订后天上海→杭州火车票（二等座）+杭州酒店（后天入住1晚）+返程送站服务（大后天10:00从西湖风景区到杭州东站）'
    self.timeout_seconds = 300

    def task_description
      "帮张三订后天上海到杭州的火车票（二等座），预订杭州酒店1晚，并预订返程送站服务"
    end

    def prepare
      @departure_city = "上海"
      @arrival_city = "杭州"
      @train_date = Date.current + 2.days
      @hotel_city = "杭州"
      @check_in_date = @train_date
      @check_out_date = @train_date + 1.day
      @dropoff_date = @check_out_date

      # 预查询乘客信息（张三）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_passenger_name = @passenger.name
      @expected_passenger_id = @passenger.id_number
      @expected_phone = @passenger.phone

      @available_trains = Train.where(
        departure_city: @departure_city,
        arrival_city: @arrival_city,
        data_version: 0
      ).by_date(@train_date).order(price_second_class: :asc)

      raise "未找到符合条件的火车" if @available_trains.empty?

      @available_hotels = Hotel.where(
        city: @hotel_city,
        data_version: 0
      ).order(price: :asc)

      raise "未找到符合条件的酒店" if @available_hotels.empty?

      # 预查询杭州酒店区域接送点（TransferLocation - 西湖风景区）
      @departure_loc = TransferLocation.find_by(
        city: @hotel_city,
        name: '西湖风景区',
        location_type: 'other',
        data_version: 0
      )

      raise "未找到杭州接送点: 西湖风景区" unless @departure_loc

      @station_name = "杭州东站"

      {
        task: "帮张三订后天上海到杭州的火车票（二等座），预订杭州酒店1晚，并预订返程送站服务（大后天10:00从#{@departure_loc.name}到#{@station_name}）",
        requirements: {
          beneficiary: '张三',
          train_route: "#{@departure_city}→#{@arrival_city}",
          train_date: @train_date.to_s,
          seat_type: '二等座',
          hotel_city: @hotel_city,
          check_in_date: @check_in_date.to_s,
          check_out_date: @check_out_date.to_s,
          dropoff_location_from: @departure_loc.name,
          dropoff_location_to: @station_name,
          dropoff_time: '10:00'
        },
        hint: "需要协调火车、酒店和送站服务的时间和地点",
        statistics: {
          available_trains: @available_trains.count,
          available_hotels: @available_hotels.count,
          train_price_range: {
            min: @available_trains.minimum(:price_second_class),
            max: @available_trains.maximum(:price_second_class)
          },
          hotel_price_range: {
            min: @available_hotels.minimum(:price),
            max: @available_hotels.maximum(:price)
          }
        }
      }
    end

    def verify
      # 断言1: 创建了火车票+酒店+送站3个订单 (25分) - 核心评分项
      add_assertion "创建了火车票+酒店+送站3个订单", weight: 25 do
        train_bookings = TrainBooking
          .joins(:train)
          .where(trains: { departure_city: @departure_city, arrival_city: @arrival_city })
          .where(data_version: @data_version)

        hotel_bookings = HotelBooking
          .joins(:hotel)
          .where(hotels: { city: @hotel_city })
          .where(data_version: @data_version)

        transfers = Transfer.where(
          transfer_type: 'train_dropoff',
          data_version: @data_version
        )

        @train_booking = train_bookings.first
        @hotel_booking = hotel_bookings.first
        @transfer = transfers.first

        expect(@train_booking).not_to be_nil, "未找到火车票订单"
        expect(@hotel_booking).not_to be_nil, "未找到酒店订单"
        expect(@transfer).not_to be_nil, "未找到送站订单"
      end

      return if @train_booking.nil? || @hotel_booking.nil? || @transfer.nil?

      # 断言2: 火车票路线正确（#{@departure_city}→#{@arrival_city}） (10分)
      add_assertion "火车票路线正确（#{@departure_city}→#{@arrival_city}）", weight: 10 do
        expect(@train_booking.train.departure_city).to eq(@departure_city)
        expect(@train_booking.train.arrival_city).to eq(@arrival_city)
      end

      # 断言3: 座位类型=二等座 (10分)
      add_assertion "座位类型=二等座", weight: 10 do
        expect(@train_booking.seat_type).to eq('second_class')
      end

      # 断言4: 乘客信息正确（张三） (10分)
      add_assertion "乘客信息正确（张三）", weight: 10 do
        expect(@train_booking.passenger_name).to eq(@expected_passenger_name),
          "乘客姓名错误。期望: #{@expected_passenger_name}, 实际: #{@train_booking.passenger_name}"
        expect(@train_booking.passenger_id_number).to eq(@expected_passenger_id),
          "乘客身份证号错误。期望: #{@expected_passenger_id}, 实际: #{@train_booking.passenger_id_number}"
      end

      # 断言5: 酒店城市正确（#{@hotel_city}） (10分)
      add_assertion "酒店城市正确（#{@hotel_city}）", weight: 10 do
        expect(@hotel_booking.hotel.city).to eq(@hotel_city)
      end

      # 断言6: 入住日期=火车日期（#{@check_in_date}） (10分)
      add_assertion "入住日期=火车日期（#{@check_in_date}）", weight: 10 do
        expect(@hotel_booking.check_in_date).to eq(@check_in_date)
      end

      # 断言7: 送站终点=火车站 (10分)
      add_assertion "送站终点=火车站", weight: 10 do
        destination = @transfer.location_to.to_s
        has_station = destination.include?("站") || destination.include?("火车站") || destination.include?("Railway")
        expect(has_station).to be(true),
          "送站终点不是火车站。实际: #{destination}"
      end

      # 断言8: 送站起点为杭州的酒店区域接送点（TransferLocation中location_type='other'的地点） (5分)
      add_assertion "送站起点为杭州的酒店区域接送点", weight: 5 do
        valid_locations = TransferLocation
          .where(city: '杭州', location_type: 'other', data_version: 0)
          .pluck(:name)
        
        expect(valid_locations).to include(@transfer.location_from),
          "送站起点不在TransferLocation酒店区域中。实际: #{@transfer.location_from}, 可选: #{valid_locations.join(', ')}"
      end

      # 断言9: 送站时间为10:00 (5分)
      add_assertion "送站时间为10:00", weight: 5 do
        transfer_time = @transfer.pickup_datetime
        pickup_hour = transfer_time.hour
        pickup_minute = transfer_time.min
        # 验证时间为10:00
        expect(pickup_hour).to eq(10), "送站时间错误。期望: 10:00, 实际: #{transfer_time.strftime('%H:%M')}"
        expect(pickup_minute).to eq(0), "送站时间错误。期望: 10:00, 实际: #{transfer_time.strftime('%H:%M')}"
      end

      # 断言10: 入住人信息正确（张三） (5分)
      add_assertion "入住人信息正确（张三）", weight: 5 do
        expect(@hotel_booking.guest_name).to eq(@expected_passenger_name),
          "入住人姓名错误。期望: #{@expected_passenger_name}, 实际: #{@hotel_booking.guest_name}"
        expect(@hotel_booking.guest_phone).to eq(@expected_phone),
          "入住人联系电话错误。期望: #{@expected_phone}, 实际: #{@hotel_booking.guest_phone}"
      end
    end

    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      passenger = user.passengers.find_by!(name: '张三', data_version: 0)

      train = @available_trains.first
      TrainBooking.create!(
        user_id: user.id,
        train_id: train.id,
        passenger_name: passenger.name,
        passenger_id_number: passenger.id_number,
        contact_phone: passenger.phone,
        seat_type: 'second_class',
        total_price: train.price_second_class,
        accept_terms: true,
        status: 'paid',
        data_version: @data_version
      )

      hotel = @available_hotels.first
      # CRITICAL: 必须过滤掉钟点房，只考虑整晚房价
      room = hotel.hotel_rooms.where(data_version: 0, room_category: 'overnight').order(price: :asc).first
      HotelBooking.create!(
        user: user,
        hotel: hotel,
        hotel_room_id: room.id,
        check_in_date: @check_in_date,
        check_out_date: @check_out_date,
        guest_name: passenger.name,
        guest_phone: passenger.phone,
        payment_method: '花呗',
        total_price: room.price,
        data_version: @data_version
      )

      # 送站服务：使用TransferLocation查询的酒店区域接送点（西湖风景区）到杭州东站
      Transfer.create!(
        user: user,
        transfer_type: 'train_dropoff',  # 送到火车站
        service_type: 'to_station',      # 到站服务
        location_from: @departure_loc.name,  # 使用TransferLocation查询结果（西湖风景区）
        location_to: @station_name,
        pickup_datetime: @dropoff_date.in_time_zone + 10.hours,  # 10:00送站，使用in_time_zone确保时区正确
        vehicle_type: 'economy_5',
        passenger_name: passenger.name,
        passenger_phone: passenger.phone,
        total_price: 50.0,
        status: 'pending',
        data_version: @data_version
      )
    end

    private

    def execution_state_data
      {
        departure_city: @departure_city,
        arrival_city: @arrival_city,
        train_date: @train_date.to_s,
        hotel_city: @hotel_city,
        check_in_date: @check_in_date.to_s,
        check_out_date: @check_out_date.to_s,
        dropoff_date: @dropoff_date.to_s,
        expected_passenger_name: @expected_passenger_name,
        expected_passenger_id: @expected_passenger_id,
        expected_phone: @expected_phone,
        departure_location_name: @departure_loc&.name,
        station_name: @station_name
      }
    end

    def restore_from_state(data)
      @departure_city = data['departure_city']
      @arrival_city = data['arrival_city']
      @train_date = Date.parse(data['train_date'])
      @hotel_city = data['hotel_city']
      @check_in_date = Date.parse(data['check_in_date'])
      @check_out_date = Date.parse(data['check_out_date'])
      @dropoff_date = Date.parse(data['dropoff_date'])
      @expected_passenger_name = data['expected_passenger_name']
      @expected_passenger_id = data['expected_passenger_id']
      @expected_phone = data['expected_phone']
      @station_name = data['station_name']

      @available_trains = Train.where(
        departure_city: @departure_city,
        arrival_city: @arrival_city,
        data_version: 0
      ).by_date(@train_date).order(price_second_class: :asc)

      @available_hotels = Hotel.where(
        city: @hotel_city,
        data_version: 0
      ).order(price: :asc)

      # 重新查询TransferLocation
      @departure_loc = TransferLocation.find_by(
        city: @hotel_city,
        name: data['departure_location_name'],
        data_version: 0
      ) if data['departure_location_name']
    end
  end
end
