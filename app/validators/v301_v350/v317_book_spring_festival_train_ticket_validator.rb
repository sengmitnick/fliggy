# V317: 预订60天后从北京到成都的一等座火车票
#
# 任务描述:
#   用户需要预订60天后从北京到成都的一等座火车票
#
# 评分标准:
#   - 创建了北京到成都的火车票订单 (30%)
#   - 出发地和目的地正确（北京→成都）(15%)
#   - 出发日期正确（60天后）(20%)
#   - 座位类型正确（一等座/first_class）(20%)
#   - 订单状态有效 (15%)

module V301V350
  class V317BookSpringFestivalTrainTicketValidator < BaseValidator
    self.validator_id = 'v317_book_spring_festival_train_ticket_validator'
    self.task_id = "fa4b7ee9-b151-4421-bdf0-30338b7de3f6"
    self.title = "预订60天后从北京到成都的一等座火车票"
    self.description = "用户需要预订60天后从北京到成都的一等座火车票"
    self.timeout_seconds = 180

    def prepare
      # 出发日期：60天后
      @departure_date = Date.today + 60.days
      @departure_city = "北京"
      @arrival_city = "成都"
      @seat_class = "一等座"
      
      # 查找指定车次（北京到成都的列车）
      @train = Train.find_by!(
        train_number: "Z50",
        departure_city: @departure_city,
        arrival_city: @arrival_city,
        data_version: 0
      )

      {
        task: "请预订#{@departure_date.strftime('%Y年%m月%d日')}（60天后）从北京到成都的火车票，座位类型为一等座。",
        requirements: {
          departure_city: '北京',
          arrival_city: '成都',
          departure_date: @departure_date,
          seat_class: '一等座',
          seat_type_code: 'first_class',
          train_number: @train.train_number
        },
        hint: "一等座票需求量大，建议尽早预订。"
      }
    end

    def simulate
      # 1. 查找测试用户
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
    
      # 2. 查找乘客
      passenger = Passenger.find_by!(user: user, name: '张三', data_version: 0)
    
      # 3. 查找目标车次（北京到成都的列车）
      target_train = Train.where(
        departure_city: @departure_city,
        arrival_city: @arrival_city,
        data_version: 0
      ).where("DATE(departure_time AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Shanghai') = ?", @departure_date)
       .first
    
      raise "未找到符合条件的车次" unless target_train
    
      # 4. 创建订单（一等座）
      booking = TrainBooking.create!(
        train_id: target_train.id,
        user_id: user.id,
        passenger_name: passenger.name,
        passenger_id_number: passenger.id_number,
        contact_phone: passenger.phone,
        seat_type: 'first_class',
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
      add_assertion "创建了北京到成都的火车票订单", weight: 30 do
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
        
        expect(all_bookings).not_to be_empty, "未找到北京到成都的火车票订单"
        
        @train_bookings = all_bookings.select { |b| 
          b.train.departure_time.to_date == @departure_date &&
          ['first_class'].include?(b.seat_type)
        }
        
        expect(@train_bookings.size).to be >= 1, "未找到符合条件的订单（须为60天后且座位为first_class）"
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

      add_assertion "出发日期正确（60天后）", weight: 20 do
        @train_bookings.each do |booking|
          actual_date = booking.train.departure_time.to_date
          expect(actual_date).to eq(@departure_date),
            "出发日期错误。期望: #{@departure_date}（60天后），实际: #{actual_date}"
        end
      end

      add_assertion "座位类型正确（一等座）", weight: 20 do
        @train_bookings.each do |booking|
          expect(booking.seat_type).to eq('first_class'),
            "座位类型错误。期望: first_class（一等座），实际: #{booking.seat_type}"
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
