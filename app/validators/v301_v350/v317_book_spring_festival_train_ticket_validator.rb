# frozen_string_literal: true

require_relative '../base_validator'

# V317: 张三想60天后从Z50次列车从北京到成都，要订一等座火车票
#
# 任务描述:
#   张三想60天后从Z50次列车从北京到成都，要订一等座火车票
#
# 评分标准:
#   - 创建了火车票订单 (20%)
#   - 出发地和目的地正确（北京→成都）(15%)
#   - 车次号正确（Z50）(10%)
#   - 出发日期正确（60天后）(15%)
#   - 座位类型正确（一等座/first_class）(15%)
#   - 乘客信息正确（张三） (10%)
#   - 联系人信息正确（张三） (10%)
#   - 订单状态有效 (5%)
module V301V350
  class V317BookSpringFestivalTrainTicketValidator < BaseValidator
    self.validator_id = 'v317_book_spring_festival_train_ticket_validator'
    self.task_id = "fa4b7ee9-b151-4421-bdf0-30338b7de3f6"
    self.title = '张三想60天后从Z50次列车从北京到成都，要订一等座火车票'
    self.description = "张三想60天后从Z50次列车从北京到成都，要订一等座火车票"
    self.timeout_seconds = 180

    def prepare
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # Pre-query existing passenger from demo_user
      @zhangsan = user.passengers.find_by!(name: '张三', data_version: 0)
      
      # Expected contact info (single person: 张三)
      @expected_contact_name = @zhangsan.name
      @expected_contact_phone = @zhangsan.phone
      
      # 出发日期：60天后
      @departure_date = Date.today + 60.days
      @departure_city = "北京"
      @arrival_city = "成都"
      @seat_class = "一等座"
      @train_number = "Z50"
      
      # 查找指定车次（北京到成都的列车，60天后出发）
      @train = Train.where(
        train_number: @train_number,
        departure_city: @departure_city,
        arrival_city: @arrival_city,
        data_version: 0
      ).find { |t| t.departure_time.to_date == @departure_date }
      
      raise "数据包缺少#{@departure_date}从#{@departure_city}到#{@arrival_city}的#{@train_number}列车" if @train.nil?

      {
        task: "请为张三预订#{@departure_date.strftime('%Y年%m月%d日')}（60天后）从北京到成都的火车票，车次#{@train_number}，座位类型为一等座。",
        requirements: {
          departure_city: @departure_city,
          arrival_city: @arrival_city,
          departure_date: @departure_date,
          train_number: @train_number,
          seat_class: @seat_class,
          seat_type_code: 'first_class',
          passenger_name: @zhangsan.name
        },
        hint: "春运期间一等座票需求量大，建议尽早预订。Z50次列车为北京到成都的直达特快列车。"
      }
    end

    def verify
      # 断言1: 创建了火车票订单 (20%)
      add_assertion "创建了北京到成都的火车票订单", weight: 20 do
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

      # 断言2: 出发地和目的地正确（北京→成都）(15%)
      add_assertion "出发地和目的地正确（#{@departure_city}→#{@arrival_city}）", weight: 15 do
        @train_bookings.each do |booking|
          expect(booking.train.departure_city).to eq(@departure_city),
            "出发地错误。期望: #{@departure_city}, 实际: #{booking.train.departure_city}"
          expect(booking.train.arrival_city).to eq(@arrival_city),
            "目的地错误。期望: #{@arrival_city}, 实际: #{booking.train.arrival_city}"
        end
      end

      # 断言3: 车次号正确（Z50）(10%)
      add_assertion "车次号正确（#{@train_number}）", weight: 10 do
        @train_bookings.each do |booking|
          expect(booking.train.train_number).to eq(@train_number),
            "车次号错误。期望: #{@train_number}, 实际: #{booking.train.train_number}"
        end
      end

      # 断言4: 出发日期正确（60天后）(15%)
      add_assertion "出发日期正确（60天后）", weight: 15 do
        @train_bookings.each do |booking|
          actual_date = booking.train.departure_time.to_date
          expect(actual_date).to eq(@departure_date),
            "出发日期错误。期望: #{@departure_date}（60天后），实际: #{actual_date}"
        end
      end

      # 断言5: 座位类型正确（一等座/first_class）(15%)
      add_assertion "座位类型正确（一等座/first_class）", weight: 15 do
        @train_bookings.each do |booking|
          expect(booking.seat_type).to eq('first_class'),
            "座位类型错误。期望: first_class（一等座），实际: #{booking.seat_type}"
        end
      end

      # 断言6: 乘客信息正确（张三）(10%)
      add_assertion "乘客信息正确（张三）", weight: 10 do
        @train_bookings.each do |booking|
          expect(booking.passenger_name).to eq(@expected_contact_name),
            "乘客姓名错误。期望: #{@expected_contact_name}, 实际: #{booking.passenger_name}"
          expect(booking.passenger_id_number).to eq(@zhangsan.id_number),
            "乘客身份证号错误。期望: #{@zhangsan.id_number}, 实际: #{booking.passenger_id_number}"
        end
      end

      # 断言7: 联系人信息正确（张三）(10%)
      add_assertion "联系人信息正确（张三）", weight: 10 do
        @train_bookings.each do |booking|
          expect(booking.contact_phone).to eq(@expected_contact_phone),
            "联系电话错误。期望: #{@expected_contact_phone}, 实际: #{booking.contact_phone}"
        end
      end

      # 断言8: 订单状态有效 (5%)
      add_assertion "订单状态有效", weight: 5 do
        @train_bookings.each do |booking|
          expect(['pending', 'confirmed', 'paid']).to include(booking.status),
            "订单状态异常: #{booking.status}"
        end
      end
    end

    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
    
      # 创建订单（一等座）
      booking = TrainBooking.create!(
        train_id: @train.id,  # ✅ Use @train from prepare
        user_id: user.id,
        passenger_name: @zhangsan.name,
        passenger_id_number: @zhangsan.id_number,
        contact_phone: @zhangsan.phone,
        seat_type: 'first_class',
        accept_terms: true,
        total_price: @train.price_first_class || 450,
        status: 'pending',
        data_version: @data_version  # ✅ Session-scoped
      )
    
      {
        action: 'create_train_booking',
        booking_id: booking.id,
        train_number: @train.train_number,
        seat_type: booking.seat_type
      }
    end

    private

    def execution_state_data
      {
        departure_date: @departure_date&.to_s,
        departure_city: @departure_city,
        arrival_city: @arrival_city,
        seat_class: @seat_class,
        train_number: @train_number,
        train_id: @train&.id,
        expected_contact_name: @expected_contact_name,
        expected_contact_phone: @expected_contact_phone
      }
    end

    def restore_from_state(state)
      @departure_date = Date.parse(state['departure_date']) if state['departure_date']
      @departure_city = state['departure_city']
      @arrival_city = state['arrival_city']
      @seat_class = state['seat_class']
      @train_number = state['train_number']
      @expected_contact_name = state['expected_contact_name']
      @expected_contact_phone = state['expected_contact_phone']
      @train = Train.find_by(id: state['train_id']) if state['train_id']
    end
  end
end
