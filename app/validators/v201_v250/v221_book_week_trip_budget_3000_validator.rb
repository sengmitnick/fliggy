# frozen_string_literal: true

require_relative '../base_validator'

# V221: 预订7天自由行（往返交通+酒店，总预算≤3000元）
#
# 任务描述:
#   用户需要预订7天自由行（往返交通+酒店），总预算≤3000元
#
# 评分标准:
#   - 创建了往返交通订单 (20%)
#   - 创建了酒店订单 (15%)
#   - 酒店住7晚 (10%)
#   - 总价格≤3000元 (35%)
#   - 订单状态有效 (20%)
module V201V250
  class V221BookWeekTripBudget3000Validator < BaseValidator
    self.validator_id = 'v221_book_week_trip_budget_3000_validator'
    self.task_id = '8fd809fc-9f9f-9f1f-1f2f-0f3a4b5c6d7f'
    self.title = '预订7天自由行（≤3000元）'
    self.description = '用户需要预订7天自由行（往返交通+酒店），总预算≤3000元'
    self.timeout_seconds = 300
    
    def prepare
      @origin_city = '广州'
      @destination_city = '成都'
      @outbound_date = Date.current + 2.days
      @return_date = @outbound_date + 7.days
      @check_in_date = @outbound_date
      @check_out_date = @return_date
      @nights = 7
      @max_budget = 3000
      
      # 查找往返交通（火车为主，价格便宜）
      @outbound_trains = Train.by_route(@origin_city, @destination_city)
        .by_date(@outbound_date)
        .where(data_version: 0)
        .order(price_second_class: :asc)
      
      @return_trains = Train.by_route(@destination_city, @origin_city)
        .by_date(@return_date)
        .where(data_version: 0)
        .order(price_second_class: :asc)
      
      @available_hotels = Hotel.where(
        city: @destination_city,
        data_version: 0
      ).order(price: :asc)
      
      raise "未找到往返火车或酒店" if @outbound_trains.empty? || @return_trains.empty? || @available_hotels.empty?
      
      {
        task: "请预订#{@outbound_date.strftime('%Y年%m月%d日')}从#{@origin_city}到#{@destination_city}的7天自由行（#{@return_date.strftime('%m月%d日')}返回），包含往返交通和#{@destination_city}酒店#{@nights}晚。总预算不超过#{@max_budget}元。",
        requirements: {
          origin_city: @origin_city,
          destination_city: @destination_city,
          outbound_date: @outbound_date,
          return_date: @return_date,
          nights: @nights,
          max_budget: @max_budget
        },
        hint: "需要综合考虑往返交通和酒店7晚的价格，确保总价不超过#{@max_budget}元。优先选择火车出行更经济。"
      }
    end
    
    def verify
      add_assertion "创建了往返交通订单", weight: 20 do
        @outbound_booking = TrainBooking
          .joins(:train)
          .where(trains: { departure_city: @origin_city, arrival_city: @destination_city })
          .where(data_version: @data_version)
          .first
        
        @return_booking = TrainBooking
          .joins(:train)
          .where(trains: { departure_city: @destination_city, arrival_city: @origin_city })
          .where(data_version: @data_version)
          .first
        
        expect(@outbound_booking).not_to be_nil, "未找到去程交通订单"
        expect(@return_booking).not_to be_nil, "未找到返程交通订单"
      end
      
      return if @outbound_booking.nil? || @return_booking.nil?
      
      add_assertion "创建了酒店订单", weight: 15 do
        @hotel_booking = HotelBooking
          .joins(:hotel)
          .where(hotels: { city: @destination_city })
          .where(data_version: @data_version)
          .first
        
        expect(@hotel_booking).not_to be_nil, "未找到酒店订单"
      end
      
      return if @hotel_booking.nil?
      
      add_assertion "酒店住#{@nights}晚", weight: 10 do
        actual_nights = (@hotel_booking.check_out_date - @hotel_booking.check_in_date).to_i
        expect(actual_nights).to eq(@nights),
          "住宿天数错误。期望: #{@nights}晚, 实际: #{actual_nights}晚"
      end
      
      add_assertion "总价格≤#{@max_budget}元", weight: 35 do
        outbound_price = @outbound_booking.total_price
        return_price = @return_booking.total_price
        hotel_price = @hotel_booking.total_price
        total_price = outbound_price + return_price + hotel_price
        
        expect(total_price).to be <= @max_budget,
          "总价格超出预算。去程: #{outbound_price}元, 返程: #{return_price}元, 酒店: #{hotel_price}元, 总计: #{total_price}元, 预算上限: #{@max_budget}元"
      end
      
      add_assertion "订单状态有效", weight: 20 do
        expect(@outbound_booking.status).to be_in(['pending', 'paid', 'completed'])
        expect(@return_booking.status).to be_in(['pending', 'paid', 'completed'])
        expect(@hotel_booking.status).to be_in(['pending', 'paid', 'completed'])
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 找到预算内的最佳组合
      best_combo = nil
      best_value = 0
      
      @outbound_trains.first(3).each do |outbound|
        @return_trains.first(3).each do |return_train|
          @available_hotels.first(5).each do |hotel|
            room = hotel.hotel_rooms.where(data_version: 0).first
            next unless room
            
            total = outbound.price_second_class + return_train.price_second_class + (room.price * @nights)
            next if total > @max_budget
            
            value_score = @max_budget - total
            if best_combo.nil? || value_score > best_value
              best_combo = { outbound: outbound, return: return_train, hotel: hotel, room: room }
              best_value = value_score
            end
          end
        end
      end
      
      raise "未找到符合预算的组合" if best_combo.nil?
      
      # 创建去程火车订单
      TrainBooking.create!(
        user: user,
        train: best_combo[:outbound],
        passenger_name: user.name,
        passenger_id_number: '110101199001011234',
        contact_phone: '13800138000',
        seat_type: 'second_class',
        ticket_count: 1,
        total_price: best_combo[:outbound].price_second_class,
        status: 'paid',
        accept_terms: true,
        data_version: @data_version
      )
      
      # 创建返程火车订单
      TrainBooking.create!(
        user: user,
        train: best_combo[:return],
        passenger_name: user.name,
        passenger_id_number: '110101199001011234',
        contact_phone: '13800138000',
        seat_type: 'second_class',
        ticket_count: 1,
        total_price: best_combo[:return].price_second_class,
        status: 'paid',
        accept_terms: true,
        data_version: @data_version
      )
      
      # 创建酒店订单
      HotelBooking.create!(
        user: user,
        hotel: best_combo[:hotel],
        hotel_room_id: best_combo[:room].id,
        check_in_date: @check_in_date,
        check_out_date: @check_out_date,
        guest_name: user.name,
        guest_phone: '13800138000',
        room_count: 1,
        total_price: best_combo[:room].price * @nights,
        status: 'paid',
        payment_method: '花呗',
        data_version: @data_version
      )
    end
    
    private
    
    def execution_state_data
      {
        origin_city: @origin_city,
        destination_city: @destination_city,
        outbound_date: @outbound_date.to_s,
        return_date: @return_date.to_s,
        check_in_date: @check_in_date.to_s,
        check_out_date: @check_out_date.to_s,
        nights: @nights,
        max_budget: @max_budget
      }
    end
    
    def restore_from_state(data)
      @origin_city = data['origin_city']
      @destination_city = data['destination_city']
      @outbound_date = Date.parse(data['outbound_date'])
      @return_date = Date.parse(data['return_date'])
      @check_in_date = Date.parse(data['check_in_date'])
      @check_out_date = Date.parse(data['check_out_date'])
      @nights = data['nights']
      @max_budget = data['max_budget']
      
      @outbound_trains = Train.by_route(@origin_city, @destination_city)
        .by_date(@outbound_date)
        .where(data_version: 0)
        .order(price_second_class: :asc)
      
      @return_trains = Train.by_route(@destination_city, @origin_city)
        .by_date(@return_date)
        .where(data_version: 0)
        .order(price_second_class: :asc)
      
      @available_hotels = Hotel.where(
        city: @destination_city,
        data_version: 0
      ).order(price: :asc)
    end
  end
end
