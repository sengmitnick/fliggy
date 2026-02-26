# frozen_string_literal: true

require_relative '../base_validator'

# V159: 预订上海邮轮 + 火车站接站服务
# 验证用户能够完成邮轮预订+火车站接站服务的组合下单

module V151V200
  class V159BookCruiseAndStationTransferValidator < BaseValidator
    self.validator_id = 'v159_book_cruise_and_station_transfer_validator'
    self.task_id = 'c9d0e1f2-3a4b-5c6d-7e8f-9a0b1c2d3e4f'
    self.title = '给张三预订明天上海出发的日本邮轮航线，并预订火车站接站服务（接今天从北京到上海虹桥站的火车）'
    self.description = '预订明天上海出发的日本邮轮航线，并预订火车站接站服务（接今天从北京到上海虹桥站的火车）'
    self.timeout_seconds = 300

    def prepare
      @departure_date = Date.current + 1.day  # 明天邮轮出发
      @train_date = Date.current  # 今天火车到达
      @departure_port = '上海'
      @station_location = '上海虹桥站'
      @train_origin = '北京'
      @duration_days = 6
      @duration_nights = 5
      @adult_count = 1
      
      # 预查询demo_user的乘客信息
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_contact_name = @passenger.name
      @expected_contact_phone = @passenger.phone
      
      # 查找可用的上海邮轮班次
      @available_sailings = CruiseSailing
        .where("departure_port LIKE ?", "%#{@departure_port}%")
        .where(duration_days: @duration_days, duration_nights: @duration_nights, data_version: 0)
        .where("departure_date >= ?", @departure_date)
        .to_a
      
      expect(@available_sailings).not_to be_empty, "数据包缺少上海出发的邮轮班次"
      
      # 查找今天从北京到上海虹桥站的火车（接站）
      @pickup_trains = Train
        .where(departure_city: @train_origin, arrival_city: @departure_port, data_version: 0)
        .by_date(@train_date)
        .where("arrival_station LIKE ?", "%虹桥%")
        .to_a
      
      expect(@pickup_trains).not_to be_empty, "数据包缺少#{@train_origin}到#{@departure_port}虹桥站的火车"
    end

    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      sailing = @available_sailings.first
      ship = sailing.cruise_ship
      
      # 查找舱房类型（选择经济舱）
      cabin_type = CabinType.where(data_version: 0, cruise_ship_id: ship.id, category: 'interior').first
      raise "未找到舱房类型" unless cabin_type
      
      # 查找或创建邮轮产品
      cruise_product = CruiseProduct.find_or_create_by!(
        cruise_sailing_id: sailing.id,
        cabin_type_id: cabin_type.id,
        data_version: 0
      ) do |product|
        product.merchant_name = '邮轮旅游网'
        product.price_per_person = 3500.0
        product.occupancy_requirement = 2
        product.stock = 10
        product.sales_count = 0
        product.is_refundable = true
        product.requires_confirmation = false
        product.status = 'on_sale'
      end
      
      total_price = cruise_product.price_per_person * @adult_count
      
      # 创建邮轮订单
      CruiseOrder.create!(
        user_id: user.id,
        cruise_product_id: cruise_product.id,
        quantity: @adult_count,
        contact_name: @passenger.name,
        contact_phone: @passenger.phone,
        total_price: total_price,
        accept_terms: true,
        status: 'pending',
        data_version: @data_version
      )
      
      # 创建火车站接站服务（今天火车到达）
      # 选择今天最早到达虹桥站的火车
      pickup_train = @pickup_trains.min_by { |t| t.arrival_time }
      pickup_datetime = pickup_train.arrival_time + 30.minutes
      
      Transfer.create!(
        user: user,
        transfer_type: 'train_pickup',
        service_type: 'from_station',
        location_from: @station_location,
        location_to: "#{@departure_port}邮轮码头",
        pickup_datetime: pickup_datetime,
        train_number: pickup_train.train_number,
        vehicle_type: 'business_5',
        passenger_name: @passenger.name,
        passenger_phone: @passenger.phone,
        total_price: 100.0,
        status: 'pending',
        data_version: @data_version
      )
    end

    def execution_state_data
      {
        data_version: @data_version,
        departure_date: @departure_date.to_s,
        train_date: @train_date.to_s,
        departure_port: @departure_port,
        station_location: @station_location,
        train_origin: @train_origin,
        duration_days: @duration_days,
        duration_nights: @duration_nights,
        adult_count: @adult_count
      }
    end

    def restore_from_state(data)
      @data_version = data['data_version']
      @departure_date = Date.parse(data['departure_date']) if data['departure_date']
      @train_date = Date.parse(data['train_date']) if data['train_date']
      @departure_port = data['departure_port']
      @station_location = data['station_location']
      @train_origin = data['train_origin']
      @duration_days = data['duration_days']
      @duration_nights = data['duration_nights']
      @adult_count = data['adult_count']
    end

    def verify
      # 断言1: 创建了邮轮订单
      add_assertion "创建了邮轮订单", weight: 25 do
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
      
      # 断言3: 行程天数正确
      add_assertion "行程天数正确（#{@duration_days}天#{@duration_nights}晚）", weight: 15 do
        sailing = @cruise_order.cruise_product.cruise_sailing
        expect(sailing.duration_days).to eq(@duration_days),
          "行程天数错误。期望: #{@duration_days}天, 实际: #{sailing.duration_days}天"
      end
      
      # 断言4: 创建了火车站接站服务
      add_assertion "创建了火车站接站服务", weight: 10 do
        @transfer = Transfer
          .where(transfer_type: 'train_pickup', data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@transfer).not_to be_nil, "未找到火车站接站服务订单"
      end
      
      return if @transfer.nil?
      
      # 断言5: 接站服务关联了具体火车班次号
      add_assertion "接站服务关联了具体火车班次号（#{@train_origin}→#{@departure_port}）", weight: 20 do
        expect(@transfer.train_number).not_to be_nil,
          "接站服务未关联火车班次号"
        
        train = Train.find_by(
          train_number: @transfer.train_number,
          departure_city: @train_origin,
          arrival_city: @departure_port,
          data_version: 0
        )
        
        expect(train).not_to be_nil,
          "未找到关联的火车: #{@transfer.train_number}"
        expect(train.arrival_station).to include('虹桥'),
          "火车到达车站错误。期望: 虹桥, 实际: #{train.arrival_station}"
      end
      
      # 断言6: 接站时间合理（火车到达后20-40分钟）
      add_assertion "接站时间合理（火车到达后20-40分钟）", weight: 10 do
        train = Train
          .where(train_number: @transfer.train_number, data_version: 0)
          .where(departure_city: @train_origin, arrival_city: @departure_port)
          .by_date(@train_date)
          .first
        
        expect(train).not_to be_nil, "未找到关联的火车"
        
        time_after_arrival = ((@transfer.pickup_datetime - train.arrival_time) / 60.0).round
        expect(time_after_arrival >= 20 && time_after_arrival <= 40).to be(true),
          "接站时间不合理。火车到达: #{train.arrival_time.strftime('%H:%M')}, 接站时间: #{@transfer.pickup_datetime.strftime('%H:%M')}, 间隔: #{time_after_arrival}分钟（期望20-40分钟）"
      end
      
      # 断言7: 接站地点在上海
      add_assertion "接站地点在上海", weight: 5 do
        in_city = @transfer.location_from.include?(@departure_port) || @transfer.location_to.include?(@departure_port)
        expect(in_city).to be(true),
          "接站地点错误。期望包含: #{@departure_port}, 实际: #{@transfer.location_from} -> #{@transfer.location_to}"
      end
      
      # 断言8: 联系人信息正确（张三）
      add_assertion "联系人信息正确（#{@expected_contact_name}）", weight: 5 do
        expect(@cruise_order.contact_name).to eq(@expected_contact_name),
          "联系人姓名错误。期望: #{@expected_contact_name}, 实际: #{@cruise_order.contact_name}"
        expect(@cruise_order.contact_phone).to eq(@expected_contact_phone),
          "联系人电话错误。期望: #{@expected_contact_phone}, 实际: #{@cruise_order.contact_phone}"
      end
    end
  end
end