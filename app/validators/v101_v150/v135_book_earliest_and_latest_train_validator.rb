# frozen_string_literal: true

require_relative '../base_validator'

module V101V150
  class V135BookEarliestAndLatestTrainValidator < BaseValidator
    self.validator_id = 'v135_book_earliest_and_latest_train_validator'
    self.task_id = 'b5c6d7e8-9f0a-1b2c-3d4e-5f6a7b8c9d1f'
    self.title = '帮张三订明天上海到杭州的最早高铁/动车（去程），以及后天杭州回上海的最晚高铁/动车（返程）。都为二等座'
    self.description = '帮张三订明天上海到杭州的最早高铁/动车（去程），以及后天杭州回上海的最晚高铁/动车（返程）。都为二等座'
    self.timeout_seconds = 300

    def task_description
      "帮张三订明天上海到杭州的最早高铁/动车（去程），以及后天杭州回上海的最晚高铁/动车（返程）。都为二等座"
    end

    def prepare
      @outbound_departure_city = "上海"
      @outbound_arrival_city = "杭州"
      @outbound_date = Date.current + 1.day
      
      @return_departure_city = "杭州"
      @return_arrival_city = "上海"
      @return_date = Date.current + 2.days

      # 预查询乘客信息（张三）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_passenger_name = @passenger.name
      @expected_passenger_id = @passenger.id_number
      @expected_phone = @passenger.phone

      # 查询去程所有高铁/动车（上海→杭州）
      outbound_trains = Train.where(
        departure_city: @outbound_departure_city,
        arrival_city: @outbound_arrival_city,
        data_version: 0
      ).by_date(@outbound_date).where("train_number LIKE 'G%' OR train_number LIKE 'D%'").order('departure_time ASC')

      raise "未找到去程（上海→杭州）高铁/动车" if outbound_trains.empty?

      # 找到去程最早车次
      @earliest_outbound_train = outbound_trains.first

      # 查询返程所有高铁/动车（杭州→上海）
      return_trains = Train.where(
        departure_city: @return_departure_city,
        arrival_city: @return_arrival_city,
        data_version: 0
      ).by_date(@return_date).where("train_number LIKE 'G%' OR train_number LIKE 'D%'").order('departure_time ASC')

      raise "未找到返程（杭州→上海）高铁/动车" if return_trains.empty?

      # 找到返程最晚车次
      @latest_return_train = return_trains.last
    end

    def verify
      # 断言1: 创建了2个火车票订单（去程+返程） (20分) - 核心评分项
      add_assertion "创建了2个火车票订单（去程+返程）", weight: 20 do
        all_train_bookings = TrainBooking
          .joins(:train)
          .includes(:train)
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a

        expect(all_train_bookings.size).to be >= 2, "订单数量不足。期望至少2个订单（去程+返程），实际找到#{all_train_bookings.size}个订单"
        
        @outbound_bookings = all_train_bookings.select do |b|
          b.train.departure_city == @outbound_departure_city && b.train.arrival_city == @outbound_arrival_city
        end
        
        @return_bookings = all_train_bookings.select do |b|
          b.train.departure_city == @return_departure_city && b.train.arrival_city == @return_arrival_city
        end
        
        expect(@outbound_bookings).not_to be_empty, "未找到去程订单（上海→杭州）"
        expect(@return_bookings).not_to be_empty, "未找到返程订单（杭州→上海）"
      end

      return if @outbound_bookings.nil? || @outbound_bookings.empty? || @return_bookings.nil? || @return_bookings.empty?

      # 断言2: 去程订单正确（上海→杭州，明天） (20分) - 核心评分项
      add_assertion "去程订单正确（上海→杭州，明天）", weight: 20 do
        outbound_booking = @outbound_bookings.first
        expect(outbound_booking.train.departure_city).to eq(@outbound_departure_city)
        expect(outbound_booking.train.arrival_city).to eq(@outbound_arrival_city)
        expect(outbound_booking.train.departure_time.to_date).to eq(@outbound_date),
          "去程日期错误。期望: #{@outbound_date}（明天），实际: #{outbound_booking.train.departure_time.to_date}"
      end

      # 断言3: 返程订单正确（杭州→上海，后天） (20分) - 核心评分项
      add_assertion "返程订单正确（杭州→上海，后天）", weight: 20 do
        return_booking = @return_bookings.first
        expect(return_booking.train.departure_city).to eq(@return_departure_city)
        expect(return_booking.train.arrival_city).to eq(@return_arrival_city)
        expect(return_booking.train.departure_time.to_date).to eq(@return_date),
          "返程日期错误。期望: #{@return_date}（后天），实际: #{return_booking.train.departure_time.to_date}"
      end

      # 断言4: 座位类型都为二等座 (10分)
      add_assertion "座位类型都为二等座", weight: 10 do
        [@outbound_bookings.first, @return_bookings.first].each do |booking|
          expect(booking.seat_type).to eq('second_class'), "订单#{booking.id}的座位类型错误"
        end
      end

      # 断言5: 去程乘客信息正确（张三） (5分)
      add_assertion "去程乘客信息正确（张三）", weight: 5 do
        outbound_booking = @outbound_bookings.first
        expect(outbound_booking.passenger_name).to eq(@expected_passenger_name),
          "去程乘客姓名错误。期望: #{@expected_passenger_name}, 实际: #{outbound_booking.passenger_name}"
        expect(outbound_booking.passenger_id_number).to eq(@expected_passenger_id),
          "去程乘客身份证号错误。期望: #{@expected_passenger_id}, 实际: #{outbound_booking.passenger_id_number}"
      end

      # 断言6: 返程乘客信息正确（张三） (5分)
      add_assertion "返程乘客信息正确（张三）", weight: 5 do
        return_booking = @return_bookings.first
        expect(return_booking.passenger_name).to eq(@expected_passenger_name),
          "返程乘客姓名错误。期望: #{@expected_passenger_name}, 实际: #{return_booking.passenger_name}"
        expect(return_booking.passenger_id_number).to eq(@expected_passenger_id),
          "返程乘客身份证号错误。期望: #{@expected_passenger_id}, 实际: #{return_booking.passenger_id_number}"
      end

      # 断言7: 去程为最早车次 (10分)
      add_assertion "去程为最早车次", weight: 10 do
        outbound_booking = @outbound_bookings.first
        expect(outbound_booking.train.id).to eq(@earliest_outbound_train.id),
          "去程车次错误。期望最早车次: #{@earliest_outbound_train.train_number}（#{@earliest_outbound_train.departure_time.strftime('%H:%M')}），实际: #{outbound_booking.train.train_number}（#{outbound_booking.train.departure_time.strftime('%H:%M')}）"
      end

      # 断言8: 返程为最晚车次 (10分)
      add_assertion "返程为最晚车次", weight: 10 do
        return_booking = @return_bookings.first
        expect(return_booking.train.id).to eq(@latest_return_train.id),
          "返程车次错误。期望最晚车次: #{@latest_return_train.train_number}（#{@latest_return_train.departure_time.strftime('%H:%M')}），实际: #{return_booking.train.train_number}（#{return_booking.train.departure_time.strftime('%H:%M')}）"
      end
    end

    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      passenger = user.passengers.find_by!(name: '张三', data_version: 0)

      # 创建去程订单（上海→杭州，最早车次）
      TrainBooking.create!(
        user_id: user.id,
        train_id: @earliest_outbound_train.id,
        passenger_name: passenger.name,
        passenger_id_number: passenger.id_number,
        contact_phone: passenger.phone,
        seat_type: 'second_class',
        total_price: @earliest_outbound_train.price_second_class,
        accept_terms: true,
        status: 'paid',
        data_version: @data_version
      )

      # 创建返程订单（杭州→上海，最晚车次）
      TrainBooking.create!(
        user_id: user.id,
        train_id: @latest_return_train.id,
        passenger_name: passenger.name,
        passenger_id_number: passenger.id_number,
        contact_phone: passenger.phone,
        seat_type: 'second_class',
        total_price: @latest_return_train.price_second_class,
        accept_terms: true,
        status: 'paid',
        data_version: @data_version
      )
    end

    private

    def execution_state_data
      {
        outbound_departure_city: @outbound_departure_city,
        outbound_arrival_city: @outbound_arrival_city,
        outbound_date: @outbound_date.to_s,
        return_departure_city: @return_departure_city,
        return_arrival_city: @return_arrival_city,
        return_date: @return_date.to_s,
        expected_passenger_name: @expected_passenger_name,
        expected_passenger_id: @expected_passenger_id,
        expected_phone: @expected_phone
      }
    end

    def restore_from_state(data)
      @outbound_departure_city = data['outbound_departure_city']
      @outbound_arrival_city = data['outbound_arrival_city']
      @outbound_date = Date.parse(data['outbound_date'])
      @return_departure_city = data['return_departure_city']
      @return_arrival_city = data['return_arrival_city']
      @return_date = Date.parse(data['return_date'])
      @expected_passenger_name = data['expected_passenger_name']
      @expected_passenger_id = data['expected_passenger_id']
      @expected_phone = data['expected_phone']

      # 重新查询去程最早车次
      outbound_trains = Train.where(
        departure_city: @outbound_departure_city,
        arrival_city: @outbound_arrival_city,
        data_version: 0
      ).by_date(@outbound_date).where("train_number LIKE 'G%' OR train_number LIKE 'D%'").order('departure_time ASC')

      @earliest_outbound_train = outbound_trains.first

      # 重新查询返程最晚车次
      return_trains = Train.where(
        departure_city: @return_departure_city,
        arrival_city: @return_arrival_city,
        data_version: 0
      ).by_date(@return_date).where("train_number LIKE 'G%' OR train_number LIKE 'D%'").order('departure_time ASC')

      @latest_return_train = return_trains.last
    end
  end
end
