# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例231: 帮张三预订后天成都→重庆火车+酒店，在最便宜基础方案上加100元升级到更好服务（如更高星级酒店或一等座）
#
# 任务描述:
#   张三需要从成都到重庆出差，先查询最便宜的基础方案（火车二等座+经济型酒店），
#   然后在基础方案上加100元预算，升级到更好的服务（如一等座或更高星级酒店）。
#   要求Agent先计算基础方案价格，然后在基础价格+100元（允许±50元）的预算内选择档次明显提升的服务。
#
# 业务流程（8个关键步骤）：
#   1. 明确受益人信息（张三，使用其姓名、身份证号、电话作为乘客和入住人信息）
#   2. 搜索成都→重庆火车（后天出发，获取二等座价格）
#   3. 搜索重庆市区酒店（后天入住1晚，获取房间价格）
#   4. 计算基础方案价格（最便宜的火车+最便宜的酒店）
#   5. 设定升级预算（基础价格+100元，允许±50元范围）
#   6. 在升级预算范围内，搜索所有可能的火车+酒店组合
#   7. 筛选档次有明显提升的组合（火车座位升级或酒店评分至少提升0.1星，至少满足一项）
#   8. 选择档次提升最大的组合（优先酒店评分提升，其次座位升级），创建火车订单和酒店订单
#
# 复杂度分析（7个关键点）：
#   1. 需要理解"增量升级"概念：先确定基础方案，然后在此基础上加预算升级
#   2. 需要计算基础方案价格作为参照基准（最便宜的二等座火车+最便宜的酒店房间）
#   3. 需要理解预算约束：总价必须在基础价格+100元±50元范围内（即+50元至+150元）
#   4. 需要验证档次提升：升级后的服务档次必须比基础方案明显提升（火车座位升级或酒店评分提升≥0.1星，至少满足一项）
#   5. 需要优化选择逻辑：在满足预算和档次要求的组合中，优先选择酒店评分提升最大的，其次选择座位升级
#   6. 需要协调火车和酒店日期：入住日期与火车到达日期一致
#   7. 需要使用受益人信息作为火车乘客和酒店入住人
#   ❌ 不能简单选最贵的：必须确保价格增加接近100元，且档次有明显提升
#
# 评分标准（9项，总计100分）：
#   1. 创建了火车订单（15分）
#   2. 创建了酒店订单（15分）
#   3. 出行日期正确（后天）（5分）
#   4. 酒店入住日期正确（后天，火车当天）（5分）
#   5. 乘车人信息正确（张三的姓名、身份证号、电话）（5分）
#   6. 入住人信息正确（张三的姓名、电话）（5分）
#   7. 总价比基础方案多约100元（允许±50元）（25分）
#   8. 至少一项服务有明显提升（火车座位升级或酒店评分提高≥0.1星）（20分）
#   9. 订单状态有效（5分）
#
# 使用方法:
#   rake validator:simulate_single[v231_book_incremental_upgrade_100_more_validator]
#   或访问 http://localhost:<PORT>/api/tasks 获取任务列表
#
module V201V250
  class V231BookIncrementalUpgrade100MoreValidator < BaseValidator
    self.validator_id = 'v231_book_incremental_upgrade_100_more_validator'
    self.task_id = '7ff798ff-8f8f-8f0f-0f1f-9f2a3b4c5d6f'
    self.title = '帮张三预订后天成都→重庆火车+酒店，在最便宜基础方案上加100元升级到更好服务（如更高星级酒店或一等座）'
    self.description = '张三后天从成都到重庆出差，先查最便宜的火车+酒店组合作为基础方案，然后加100元升级到更好服务（如一等座或更高星级酒店），要求档次有明显提升'
    self.timeout_seconds = 300
    
    def prepare
      @departure_city = '成都'
      @destination_city = '重庆'
      @upgrade_budget = 100
      
      # 查询demo_user乘客信息
      demo_user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      demo_passenger = Passenger.find_by!(user_id: demo_user.id, is_self: true, data_version: 0)
      @passenger = OpenStruct.new(
        name: demo_passenger.name,
        id_number: demo_passenger.id_number,
        phone: demo_passenger.phone
      )
      
      # 设置出行日期为后天
      @travel_date = Date.current + 2.days
      @check_in_date = @travel_date
      @check_out_date = @check_in_date + 1.day
      
      # 筛选指定日期的火车
      @available_trains = Train.by_route(@departure_city, @destination_city)
        .by_date(@travel_date)
        .where(data_version: 0)
        .order(price_second_class: :asc)
        .to_a
      
      @available_hotels = Hotel.where(city: @destination_city, data_version: 0)
        .order(price: :asc)
        .to_a
      
      raise "未找到交通或酒店" if @available_trains.empty? || @available_hotels.empty?
      
      # 计算基础方案价格（最便宜的组合：火车+酒店）
      min_transport_price = @available_trains.first.price_second_class
      
      min_hotel_room = @available_hotels.first.hotel_rooms.where(data_version: 0).order(price: :asc).first
      min_hotel_price = min_hotel_room ? min_hotel_room.price : Float::INFINITY
      
      @base_price = min_transport_price + min_hotel_price
      @target_price = @base_price + @upgrade_budget
      
      {  
        task: "帮张三订后天（#{@travel_date.strftime('%Y年%m月%d日')}）从#{@departure_city}到#{@destination_city}的火车票（二等座）和酒店（当晚入住1晚）。基础方案约#{@base_price.round}元（最便宜的火车+酒店），现在加#{@upgrade_budget}元（目标预算#{@target_price.round}元）升级到更好的服务（如更高星级酒店或一等座）。",
        requirements: {
          beneficiary: '张三',
          train_route: "#{@departure_city}→#{@destination_city}",
          travel_date: @travel_date.to_s,
          seat_type: '二等座（可升级一等座）',
          hotel_city: @destination_city,
          check_in_date: @check_in_date.to_s,
          check_out_date: @check_out_date.to_s,
          nights: 1,
          base_price: "约#{@base_price.round}元",
          target_price: "约#{@target_price.round}元",
          upgrade_budget: "+#{@upgrade_budget}元（±50元）",
          purpose: '增量升级服务（火车+酒店）'
        },
        hint: "基础方案是最便宜的二等座火车+最便宜的酒店房间，加#{@upgrade_budget}元可以升级到更好的服务（如一等座或更高星级酒店）。至少需要一项服务有明显提升（火车座位升级或酒店评分提升≥0.1星）。",
        statistics: {
          available_trains: @available_trains.count,
          available_hotels: @available_hotels.count,
          train_price_range: {
            min: @available_trains.minimum(:price_second_class),
            max: @available_trains.maximum(:price_second_class)
          },
          hotel_price_range: {
            min: @available_hotels.map { |h| h.hotel_rooms.where(data_version: 0).minimum(:price) }.compact.min,
            max: @available_hotels.map { |h| h.hotel_rooms.where(data_version: 0).maximum(:price) }.compact.max
          },
          base_price: @base_price.round,
          upgrade_range: {
            min: (@base_price + @upgrade_budget - 50).round,
            max: (@base_price + @upgrade_budget + 50).round
          }
        }
      }
    end
    
    def verify
      add_assertion "创建了火车订单", weight: 15 do
        @train_booking = TrainBooking
          .joins(:train)
          .where(trains: { departure_city: @departure_city, arrival_city: @destination_city })
          .where(data_version: @data_version)
          .first
        
        expect(@train_booking).not_to be_nil, "未找到火车订单"
      end
      
      return if @train_booking.nil?
      
      add_assertion "创建了酒店订单", weight: 15 do
        @hotel_booking = HotelBooking
          .joins(:hotel)
          .where(hotels: { city: @destination_city })
          .where(data_version: @data_version)
          .first
        
        expect(@hotel_booking).not_to be_nil, "未找到酒店订单"
      end
      
      return if @hotel_booking.nil?
      
      add_assertion "出行日期正确（#{@travel_date.strftime('%m月%d日')}）", weight: 5 do
        train_date = @train_booking.train.departure_time.to_date
        expect(train_date).to eq(@travel_date),
          "出行日期错误。期望: #{@travel_date}, 实际: #{train_date}"
      end
      
      add_assertion "酒店入住日期正确（入住#{@check_in_date.strftime('%m月%d日')}，退房#{@check_out_date.strftime('%m月%d日')}）", weight: 5 do
        expect(@hotel_booking.check_in_date).to eq(@check_in_date),
          "入住日期错误。期望: #{@check_in_date}, 实际: #{@hotel_booking.check_in_date}"
        expect(@hotel_booking.check_out_date).to eq(@check_out_date),
          "退房日期错误。期望: #{@check_out_date}, 实际: #{@hotel_booking.check_out_date}"
      end
      
      add_assertion "乘车人信息正确（张三的姓名、身份证号、电话）", weight: 5 do
        expect(@train_booking.passenger_name).to eq(@passenger.name),
          "乘客姓名错误。期望: #{@passenger.name}, 实际: #{@train_booking.passenger_name}"
        expect(@train_booking.passenger_id_number).to eq(@passenger.id_number),
          "身份证号错误。期望: #{@passenger.id_number}, 实际: #{@train_booking.passenger_id_number}"
        expect(@train_booking.contact_phone).to eq(@passenger.phone),
          "联系电话错误。期望: #{@passenger.phone}, 实际: #{@train_booking.contact_phone}"
      end
      
      add_assertion "入住人信息正确（张三的姓名、电话）", weight: 5 do
        expect(@hotel_booking.guest_name).to eq(@passenger.name),
          "入住人姓名错误。期望: #{@passenger.name}, 实际: #{@hotel_booking.guest_name}"
        expect(@hotel_booking.guest_phone).to eq(@passenger.phone),
          "入住人电话错误。期望: #{@passenger.phone}, 实际: #{@hotel_booking.guest_phone}"
      end
      
      add_assertion "总价比基础方案多约#{@upgrade_budget}元（允许±50元）", weight: 25 do
        train_price = @train_booking.total_price
        hotel_price = @hotel_booking.total_price
        actual_total = train_price + hotel_price
        
        price_increase = actual_total - @base_price
        
        expect(price_increase).to be >= @upgrade_budget - 50,
          "升级金额不足。基础方案: #{@base_price.round}元, 实际总价: #{actual_total.round}元, 增加: #{price_increase.round}元, 期望增加: #{@upgrade_budget}元（±50元）"
        expect(price_increase).to be <= @upgrade_budget + 50,
          "升级金额过多。基础方案: #{@base_price.round}元, 实际总价: #{actual_total.round}元, 增加: #{price_increase.round}元, 期望增加: #{@upgrade_budget}元（±50元）"
      end
      
      add_assertion "至少一项服务有明显提升（火车座位升级或酒店评分提高≥0.1星）", weight: 20 do
        hotel = @hotel_booking.hotel
        min_hotel = @available_hotels.first
        min_train = @available_trains.first
        
        # 检查酒店评分提升
        rating_upgrade = hotel.rating - min_hotel.rating
        hotel_upgraded = rating_upgrade >= 0.1
        
        # 检查火车座位升级（基础方案是最便宜的二等座火车）
        seat_upgraded = @train_booking.seat_type != 'second_class'
        
        # 至少一项服务有明显提升
        expect(hotel_upgraded || seat_upgraded).to be_truthy,
          "服务档次没有明显提升。基础方案: #{min_train.train_number}二等座+#{min_hotel.name}（#{min_hotel.rating}星），" +
          "实际选择: #{@train_booking.train.train_number}#{@train_booking.seat_type == 'first_class' ? '一等座' : '二等座'}+#{hotel.name}（#{hotel.rating}星），" +
          "酒店评分提升: #{rating_upgrade.round(1)}星，座位升级: #{seat_upgraded ? '是' : '否'}"
      end
      
      add_assertion "订单状态有效", weight: 5 do
        expect(@train_booking.status).to be_in(['pending', 'paid', 'completed'])
        expect(@hotel_booking.status).to be_in(['pending', 'paid', 'completed'])
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 找到价格在目标范围内且至少一项服务有明显提升的组合
      best_combo = nil
      best_score = -1  # 评分：酒店评分提升*10 + 座位升级*5
      min_hotel_rating = @available_hotels.first.rating
      min_train = @available_trains.first
      
      # 遍历所有火车+酒店组合，尝试二等座和一等座
      @available_trains.each do |train|
        @available_hotels.each do |hotel|
          room = hotel.hotel_rooms.where(data_version: 0).order(price: :asc).first
          next unless room
          
          # 尝试二等座
          ['second_class', 'first_class'].each do |seat_type|
            seat_price = (seat_type == 'first_class' && train.price_first_class) ? train.price_first_class : train.price_second_class
            next if seat_price.nil? || seat_price == 0  # 跳过没有一等座价格的火车
            
            total = seat_price + room.price
            price_increase = total - @base_price
            
            # 必须在预算范围内
            next unless price_increase >= (@upgrade_budget - 50) && price_increase <= (@upgrade_budget + 50)
            
            # 计算服务提升得分
            rating_upgrade = hotel.rating - min_hotel_rating
            hotel_upgraded = rating_upgrade >= 0.1
            seat_upgraded = seat_type == 'first_class'
            
            # 至少一项服务有明显提升
            next unless hotel_upgraded || seat_upgraded
            
            # 计算综合得分：优先酒店评分提升，其次座位升级
            score = rating_upgrade * 10 + (seat_upgraded ? 5 : 0)
            
            if score > best_score
              best_score = score
              best_combo = { train: train, hotel: hotel, room: room, seat_type: seat_type, seat_price: seat_price }
            end
          end
        end
      end
      
      raise "未找到符合升级要求的组合（至少一项服务需要明显提升：火车座位升级或酒店评分提升≥0.1星）" if best_combo.nil?
      
      # 创建火车订单
      TrainBooking.create!(
        user: user,
        train: best_combo[:train],
        passenger_name: @passenger.name,
        passenger_id_number: @passenger.id_number,
        contact_phone: @passenger.phone,
        seat_type: best_combo[:seat_type],
        ticket_count: 1,
        total_price: best_combo[:seat_price],
        status: 'paid',
        accept_terms: true,
        data_version: @data_version
      )
      
      # 创建酒店订单
      HotelBooking.create!(
        user: user,
        hotel: best_combo[:hotel],
        hotel_room: best_combo[:room],
        check_in_date: @check_in_date,
        check_out_date: @check_out_date,
        guest_name: @passenger.name,
        guest_phone: @passenger.phone,
        room_count: 1,
        total_price: best_combo[:room].price,
        status: 'paid',
        payment_method: '花呗',
        data_version: @data_version
      )
    end
    
    private
    
    def execution_state_data
      {
        departure_city: @departure_city,
        destination_city: @destination_city,
        travel_date: @travel_date.to_s,
        check_in_date: @check_in_date.to_s,
        check_out_date: @check_out_date.to_s,
        base_price: @base_price,
        target_price: @target_price,
        upgrade_budget: @upgrade_budget,
        passenger_name: @passenger.name,
        passenger_id_number: @passenger.id_number,
        passenger_phone: @passenger.phone
      }
    end
    
    def restore_from_state(data)
      @departure_city = data['departure_city']
      @destination_city = data['destination_city']
      @travel_date = Date.parse(data['travel_date'])
      @check_in_date = Date.parse(data['check_in_date'])
      @check_out_date = Date.parse(data['check_out_date'])
      @base_price = data['base_price'].to_f
      @target_price = data['target_price'].to_f
      @upgrade_budget = data['upgrade_budget'].to_i
      
      @passenger = OpenStruct.new(
        name: data['passenger_name'],
        id_number: data['passenger_id_number'],
        phone: data['passenger_phone']
      )
      
      @available_trains = Train.by_route(@departure_city, @destination_city)
        .by_date(@travel_date)
        .where(data_version: 0)
        .order(price_second_class: :asc)
        .to_a
      
      @available_hotels = Hotel.where(city: @destination_city, data_version: 0)
        .order(price: :asc)
        .to_a
    end
  end
end
