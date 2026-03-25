# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例317: 预订北京到成都Z50次列车火车票（张三，5天后，1人，软卧）
#
# 任务描述:
#   张三预订5天后从北京到成都的Z50次列车火车票。
#   要求：北京→成都，5天后出发，1人，座位类型为软卧（soft_sleeper）。
#   Agent 需要创建一个订单：
#   1) 火车票订单（TrainBooking）- Z50次列车，北京→成都，5天后，软卧
#   联系人使用张三的信息。
#
# 业务流程（6个关键步骤）：
#   1. 确定出发地（北京）和目的地（成都）
#   2. 确定出发日期（5天后）
#   3. 搜索Z50次列车（北京→成都，特快直达）
#   4. 验证列车出发时间与目标日期匹配
#   5. 选择座位类型（软卧/soft_sleeper）
#   6. 创建火车票订单，填写乘客信息（张三）和联系方式
#
# 复杂度分析（6个关键点）：
#   1. 需要准确匹配车次号（Z50）、出发地（北京）、目的地（成都）
#   2. 需要正确计算出发日期（Date.today + 5.days）
#   3. 需要匹配列车的departure_time.to_date与目标日期
#   4. 需要正确选择座位类型（软卧对应soft_sleeper枚举值）
#   5. 需要填写完整的乘客信息（passenger_name + passenger_id_number + contact_phone）
#
# 评分标准（8项，总计100%）：
#   - 创建了北京到成都的火车票订单 (20%)
#   - 出发地和目的地正确（北京→成都） (15%)
#   - 车次号正确（Z50） (10%)
#   - 出发日期正确（5天后） (15%)
#   - 座位类型正确（软卧/soft_sleeper） (15%)
#   - 乘客信息正确（张三，含身份证号） (10%)
#   - 联系人信息正确（张三联系电话） (10%)
#   - 订单状态有效（pending/confirmed/paid） (5%)
module V301V350
  class V317BookSpringFestivalTrainTicketValidator < BaseValidator
    self.validator_id = 'v317_book_spring_festival_train_ticket_validator'
    self.task_id = "fa4b7ee9-b151-4421-bdf0-30338b7de3f6"
    self.title = '预订北京到成都Z50次列车火车票（张三，5天后，1人，软卧）'
    self.description = "预订5天后从北京到成都的Z50次列车火车票，张三，1人，座位类型为软卧（soft_sleeper）"
    self.timeout_seconds = 180

    def prepare
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # Pre-query existing passenger from demo_user
      @zhangsan = user.passengers.find_by!(name: '张三', data_version: 0)
      
      # Expected contact info (single person: 张三)
      @expected_contact_name = @zhangsan.name
      @expected_contact_phone = @zhangsan.phone
      
      # 出发日期：5天后
      @departure_date = Date.today + 5.days
      @departure_city = "北京"
      @arrival_city = "成都"
      @seat_class = "软卧"
      @train_number = "Z50"
      
      # 查找指定车次（北京到成都的列车，5天后出发）
      @train = Train.where(
        train_number: @train_number,
        departure_city: @departure_city,
        arrival_city: @arrival_city,
        data_version: 0
      ).find { |t| t.departure_time.to_date == @departure_date }
      
      raise "数据包缺少#{@departure_date}从#{@departure_city}到#{@arrival_city}的#{@train_number}列车" if @train.nil?

      {
        task: "请为张三预订#{@departure_date.strftime('%Y年%m月%d日')}（5天后）从#{@departure_city}到#{@arrival_city}的#{@train_number}次列车火车票，座位类型为软卧。",
        requirements: {
          departure_city: @departure_city,
          arrival_city: @arrival_city,
          departure_date: @departure_date,
          train_number: @train_number,
          seat_class: @seat_class,
          seat_type_code: 'soft_sleeper',
          passenger_name: @zhangsan.name,
          passenger_id_number: @zhangsan.id_number
        },
        hint: "#{@train_number}次列车为#{@departure_city}到#{@arrival_city}的直达特快列车，软卧舒适度高，适合长途旅行，需要填写乘客姓名和身份证号。"
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
          ['soft_sleeper'].include?(b.seat_type)
        }
        
        expect(@train_bookings.size).to be >= 1, "未找到符合条件的订单（须为5天后且座位为soft_sleeper）"
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

      # 断言4: 出发日期正确（5天后）(15%)
      add_assertion "出发日期正确（5天后）", weight: 15 do
        @train_bookings.each do |booking|
          actual_date = booking.train.departure_time.to_date
          expect(actual_date).to eq(@departure_date),
            "出发日期错误。期望: #{@departure_date}（5天后），实际: #{actual_date}"
        end
      end

      # 断言5: 座位类型正确（软卧/soft_sleeper）(15%)
      add_assertion "座位类型正确（软卧/soft_sleeper）", weight: 15 do
        @train_bookings.each do |booking|
          expect(booking.seat_type).to eq('soft_sleeper'),
            "座位类型错误。期望: soft_sleeper（软卧），实际: #{booking.seat_type}"
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
    
      # 创建订单（软卧）
      booking = TrainBooking.create!(
        train_id: @train.id,  # ✅ Use @train from prepare
        user_id: user.id,
        passenger_name: @zhangsan.name,
        passenger_id_number: @zhangsan.id_number,
        contact_phone: @zhangsan.phone,
        seat_type: 'soft_sleeper',
        accept_terms: true,
        total_price: @train.price_business_class || 690,
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
        expected_contact_phone: @expected_contact_phone,
        zhangsan_id: @zhangsan&.id
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
      @zhangsan = Passenger.find(state['zhangsan_id']) if state['zhangsan_id']
    end
  end
end
