# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例23: 给张三预订后天上海到深圳的一等座
# 
# 任务描述:
#   Agent 需要在系统中搜索后天上海到深圳的高铁，
#   选择一等座并成功创建订单
#
# 复杂度分析:
#   1. 需要搜索上海到深圳的路线
#   2. 需要选择"后天"日期
#   3. 需要选择一等座座位类型
#   ❌ 无时间要求，关注座位类型即可
# 
# 评分标准:
#   - 订单已创建 (20分)
#   - 路线正确（上海→深圳） (30分)
#   - 出发日期正确（后天） (20分)
#   - 座位类型正确（一等座） (30分)
#
module V001V050
  class V023BookFirstClassTrainShanghaiShenzhenValidator < BaseValidator
    self.validator_id = 'v023_book_first_class_train_shanghai_shenzhen_validator'
    self.task_id = 'a09b2f8a-8e9f-44bc-b9e4-ddf833016e09'
    self.title = '给张三预订后天上海到深圳的一等座'
    self.description = '预订后天上海到深圳的一等座'
    self.timeout_seconds = 240
  
    def prepare
      @origin = '上海'
      @destination = '深圳'
      @target_date = Date.current + 2.days
      @seat_type = 'first_class'
    
      available_trains = Train.where(
        departure_city: @origin,
        arrival_city: @destination,
        data_version: 0
      ).where("DATE(departure_time AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Shanghai') = ?", @target_date)
    
      {
        task: "请给张三预订一张后天从#{@origin}到#{@destination}的高铁票（一等座）",
        departure_city: @origin,
        destination_city: @destination,
        date: @target_date.to_s,
        date_description: "后天（#{@target_date.strftime('%Y年%m月%d日')}）",
        seat_requirement: "一等座",
        hint: "系统中有多个车次可选，请选择一等座",
        available_trains_count: available_trains.count
      }
    end
  
    def verify
      add_assertion "订单已创建", weight: 20 do
        all_train_bookings = TrainBooking
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        expect(all_train_bookings).not_to be_empty, "未找到任何TrainBooking记录"
        @booking = all_train_bookings.first
        # Replaced by expect(all_train_bookings).not_to be_empty above, "未找到任何火车票订单记录"
      end
    
      return unless @booking
    
      add_assertion "出发城市正确", weight: 15 do
        expect(@booking.train.departure_city).to eq(@origin)
      end
    
      add_assertion "到达城市正确", weight: 15 do
        expect(@booking.train.arrival_city).to eq(@destination)
      end
    
      add_assertion "出发日期正确", weight: 20 do
        booking_date = @booking.train.departure_time.to_date
        expect(booking_date).to eq(@target_date),
          "出发日期不正确。预期: #{@target_date}, 实际: #{booking_date}"
      end
    
      add_assertion "座位类型正确（一等座）", weight: 20 do
        expect(@booking.seat_type).to eq(@seat_type),
          "应选择一等座，实际选择: #{@booking.seat_type_label}"
      end
    
      # 断言5: 乘客信息正确（来自demo_user）
      add_assertion "乘客信息正确（张三 110101199001011234）", weight: 10 do
        expect(@booking.passenger_name).to eq('张三'),
          "乘客姓名错误。期望: 张三（demo_user数据）, 实际: #{@booking.passenger_name}"
        expect(@booking.passenger_id_number).to eq('110101199001011234'),
          "乘客身份证错误。期望: 110101199001011234（demo_user数据）, 实际: #{@booking.passenger_id_number}"
      end
    end
  
    private
  
    def execution_state_data
      { origin: @origin, destination: @destination, target_date: @target_date.to_s, seat_type: @seat_type }
    end
  
    def restore_from_state(data)
      @origin = data['origin']
      @destination = data['destination']
      @target_date = Date.parse(data['target_date'])
      @seat_type = data['seat_type']
    end
  
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      passenger = Passenger.find_by!(user: user, name: '张三', data_version: 0)
    
      target_train = Train.where(
        departure_city: @origin,
        arrival_city: @destination,
        data_version: 0
      ).where("DATE(departure_time AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Shanghai') = ?", @target_date).sample
    
      seat = target_train.train_seats.find_by(seat_type: @seat_type)
    
      TrainBooking.create!(
        train_id: target_train.id,
        user_id: user.id,
        passenger_name: passenger.name,
        passenger_id_number: passenger.id_number,
        contact_phone: passenger.phone,
        seat_type: @seat_type,
        accept_terms: true,
        total_price: seat.price,
        status: 'pending'
      )
    
      { action: 'create_train_booking', train_number: target_train.train_number }
    end
    end
end