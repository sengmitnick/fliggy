# frozen_string_literal: true

require_relative '../base_validator'

module V101V150
  class V135BookEarliestAndLatestTrainValidator < BaseValidator
    self.validator_id = 'v135_book_earliest_and_latest_train_validator'
    self.task_id = 'b5c6d7e8-9f0a-1b2c-3d4e-5f6a7b8c9d1f'
    self.title = '预订最早和最晚高铁（往返）'
    self.description = '预订明天上海到杭州的最早高铁和最晚高铁（都为二等座）'
    self.timeout_seconds = 300

    def task_description
      "预订明天上海到杭州的最早高铁和最晚高铁（都为二等座）"
    end

    def prepare
      @departure_city = "上海"
      @arrival_city = "杭州"
      @train_date = Date.current + 1.day

      # 查询所有高铁
      all_trains = Train.where(
        departure_city: @departure_city,
        arrival_city: @arrival_city,
        data_version: 0
      ).by_date(@train_date).where("train_number LIKE 'G%'").order('departure_time ASC')

      raise "未找到符合条件的高铁" if all_trains.empty?

      # 找到最早和最晚车次
      @earliest_train = all_trains.first
      @latest_train = all_trains.last

      raise "最早和最晚车次相同，需要至少2个车次" if @earliest_train.id == @latest_train.id
    end

    def verify
      add_assertion "创建了2个火车票订单", weight: 20 do
        all_train_bookings = TrainBooking
          .joins(:train)
          .includes(:train)
          .where(trains: { departure_city: @departure_city, arrival_city: @arrival_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a

        expect(all_train_bookings.size).to be >= 2, "订单数量不足。期望至少2个订单，实际找到#{all_train_bookings.size}个订单"
        
        @train_bookings = all_train_bookings.first(2)
      end

      return if @train_bookings.nil? || @train_bookings.size < 2

      add_assertion "火车票路线正确（#{@departure_city}→#{@arrival_city}）", weight: 15 do
        @train_bookings.each do |booking|
          expect(booking.train.departure_city).to eq(@departure_city)
          expect(booking.train.arrival_city).to eq(@arrival_city)
        end
      end

      add_assertion "座位类型都为二等座", weight: 10 do
        @train_bookings.each do |booking|
          expect(booking.seat_type).to eq('second_class'), "订单#{booking.id}的座位类型错误"
        end
      end

      add_assertion "火车日期正确（#{@train_date}）", weight: 10 do
        @train_bookings.each do |booking|
          expect(booking.train.departure_time.to_date).to eq(@train_date)
        end
      end

      add_assertion "包含最早车次订单", weight: 22 do
        earliest_booking = @train_bookings.min_by { |b| b.train.departure_time }
        expect(earliest_booking.train.id).to eq(@earliest_train.id),
          "未找到最早车次订单。期望车次: #{@earliest_train.train_number}（#{@earliest_train.departure_time.strftime('%H:%M')}），实际最早车次: #{earliest_booking.train.train_number}（#{earliest_booking.train.departure_time.strftime('%H:%M')}）"
      end

      add_assertion "包含最晚车次订单", weight: 23 do
        latest_booking = @train_bookings.max_by { |b| b.train.departure_time }
        expect(latest_booking.train.id).to eq(@latest_train.id),
          "未找到最晚车次订单。期望车次: #{@latest_train.train_number}（#{@latest_train.departure_time.strftime('%H:%M')}），实际最晚车次: #{latest_booking.train.train_number}（#{latest_booking.train.departure_time.strftime('%H:%M')}）"
      end
    end

    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)

      # 创建最早车次订单
      TrainBooking.create!(
        user_id: user.id,
        train_id: @earliest_train.id,
        passenger_name: user.name,
        passenger_id_number: '110101199001011234',
        contact_phone: '13800138000',
        seat_type: 'second_class',
        total_price: @earliest_train.price_second_class,
        accept_terms: true,
        status: 'paid',
        data_version: @data_version
      )

      # 创建最晚车次订单
      TrainBooking.create!(
        user_id: user.id,
        train_id: @latest_train.id,
        passenger_name: user.name,
        passenger_id_number: '110101199001011234',
        contact_phone: '13800138000',
        seat_type: 'second_class',
        total_price: @latest_train.price_second_class,
        accept_terms: true,
        status: 'paid',
        data_version: @data_version
      )
    end

    private

    def execution_state_data
      {
        departure_city: @departure_city,
        arrival_city: @arrival_city,
        train_date: @train_date.to_s
      }
    end

    def restore_from_state(data)
      @departure_city = data['departure_city']
      @arrival_city = data['arrival_city']
      @train_date = Date.parse(data['train_date'])

      all_trains = Train.where(
        departure_city: @departure_city,
        arrival_city: @arrival_city,
        data_version: 0
      ).by_date(@train_date).where("train_number LIKE 'G%'").order('departure_time ASC')

      @earliest_train = all_trains.first
      @latest_train = all_trains.last
    end
  end
end
