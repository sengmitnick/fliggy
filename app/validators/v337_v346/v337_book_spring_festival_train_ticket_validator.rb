# frozen_string_literal: true

module V337V346
  class V337BookSpringFestivalTrainTicketValidator < BaseValidator
    self.validator_id = 337
    self.task_id = "a1b2c3d4-5e6f-7g8h-9i0j-1k2l3m4n5o6p"
    self.title = "春节返乡抢票+预订热门时段火车票"
    self.description = "用户需要预订春节期间（1月底）从北京返回成都的火车票，要求卧铺"
    self.timeout_seconds = 180

    def prepare
      # 春节时间：明年1月28日（假设为春节）
      @departure_date = Date.today + 60.days
      @departure_city = "北京"
      @arrival_city = "成都"
      @seat_class = "卧铺"
      
      # 创建热门春运列车
      @train = Train.find_by!(
        train_number: "Z50",
        departure_city: @departure_city,
        arrival_city: @arrival_city,
        data_version: 0
      )

      {
        departure_date: @departure_date.to_s,
        departure_city: @departure_city,
        arrival_city: @arrival_city,
        seat_class: @seat_class,
        train_number: @train.train_number,
        task_info: "用户在春节返乡高峰期预订火车票"
      }
    end

    def simulate
      # 1. 查找测试用户
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
    
      # 2. 查找乘客
      passenger = Passenger.find_by!(user: user, name: '张三', data_version: 0)
    
      # 3. 查找目标车次（春节返乡卧铺列车）
      target_train = Train.where(
        departure_city: @departure_city,
        arrival_city: @arrival_city,
        data_version: 0
      ).where("DATE(departure_time AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Shanghai') = ?", @departure_date)
       .first
    
      raise "未找到符合条件的车次" unless target_train
    
      # 4. 创建订单（使用一等座代表卧铺）
      booking = TrainBooking.create!(
        train_id: target_train.id,
        user_id: user.id,
        passenger_name: passenger.name,
        passenger_id_number: passenger.id_number,
        contact_phone: passenger.phone,
        seat_type: 'first_class',  # 使用一等座代表卧铺
        accept_terms: true,
        total_price: target_train.price_first_class || 450,
        status: 'pending',
        data_version: @data_version
      )
    
      {
        action: 'create_train_booking',
        booking_id: booking.id,
        train_number: target_train.train_number,
        seat_type: booking.seat_type
      }
    end

    def verify
      add_assertion "创建了火车票订单", weight: 30 do
        all_bookings = TrainBooking
          .joins(:train)
          .includes(:train)
          .where(trains: { 
            departure_city: @departure_city,
            arrival_city: @arrival_city
          })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        expect(all_bookings).not_to be_empty, "未找到任何火车票订单"
        
        @train_bookings = all_bookings.select { |b| 
          b.train.departure_time.to_date == @departure_date &&
          ['卧铺', '硬卧', '软卧'].include?(b.seat_class)
        }
        
        expect(@train_bookings.size).to be >= 1, "未找到符合条件的订单"
      end

      return if @train_bookings.nil? || @train_bookings.empty?

      add_assertion "出发地和目的地正确（#{@departure_city}→#{@arrival_city}）", weight: 15 do
        @train_bookings.each do |booking|
          expect(booking.train.departure_city).to eq(@departure_city),
            "出发地错误。期望: #{@departure_city}, 实际: #{booking.train.departure_city}"
          expect(booking.train.arrival_city).to eq(@arrival_city),
            "目的地错误。期望: #{@arrival_city}, 实际: #{booking.train.arrival_city}"
        end
      end

      add_assertion "出发日期正确（春节返乡时段：#{@departure_date}）", weight: 20 do
        @train_bookings.each do |booking|
          actual_date = booking.train.departure_time.to_date
          expect(actual_date).to eq(@departure_date),
            "出发日期错误。期望: #{@departure_date}（春节返乡高峰），实际: #{actual_date}"
        end
      end

      add_assertion "座位类型正确（卧铺）", weight: 20 do
        @train_bookings.each do |booking|
          expect(['卧铺', '硬卧', '软卧']).to include(booking.seat_class),
            "座位类型错误。期望: 卧铺类型（卧铺/硬卧/软卧），实际: #{booking.seat_class}"
        end
      end

      add_assertion "订单状态有效", weight: 15 do
        @train_bookings.each do |booking|
          expect(['pending', 'confirmed', 'paid']).to include(booking.status),
            "订单状态异常: #{booking.status}"
        end
      end
    end

    def execution_state_data
      {
        departure_date: @departure_date&.to_s,
        departure_city: @departure_city,
        arrival_city: @arrival_city,
        seat_class: @seat_class,
        train_id: @train&.id
      }
    end

    def restore_from_state(state)
      @departure_date = Date.parse(state['departure_date']) if state['departure_date']
      @departure_city = state['departure_city']
      @arrival_city = state['arrival_city']
      @seat_class = state['seat_class']
      @train = Train.find_by(id: state['train_id']) if state['train_id']
    end
  end
end
