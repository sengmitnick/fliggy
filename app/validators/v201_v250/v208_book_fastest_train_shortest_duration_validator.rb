# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例208: 张三需要预订明天从上海到杭州的高铁，要求行程时间最短
#
# 任务描述:
#   张三明天需要从上海到杭州，要求选择行程时间最短的高铁以快速到达。
#   Agent需要理解"行程时间最短"的要求，筛选所有车次并选择时长最短的。
#
# 业务流程:
#   1. 搜索上海→杭州高铁（明天）
#   2. 获取所有车次的行程时间
#   3. 筛选出行程时间最短的车次
#   4. 填写乘客信息（张三）
#   5. 确认订单
#
# 复杂度分析:
#   1. 需要理解"行程时间最短"等同于"最快车次"
#   2. 需要比较所有车次的duration字段
#   3. 需要正确选择最小duration的车次
#   4. 需要理解"明天"的时间概念
#
# 评分标准:
#   - 创建了火车票订单 (20分)
#   - 火车路线正确（上海→杭州） (15分)
#   - 出发日期正确（明天） (15分)
#   - 选择了行程时间最短的车次 (20分)
#   - 乘客信息正确 (10分)
#   - 订单状态有效 (20分)
module V201V250
  class V208BookFastestTrainShortestDurationValidator < BaseValidator
    self.validator_id = 'v208_book_fastest_train_shortest_duration_validator'
    self.task_id = '7f8809f2-8f8f-4f1e-ef1f-2f4a5b6c7d8f'
    self.title = '张三需要预订明天从上海到杭州的高铁，要求行程时间最短'
    self.description = '张三需要预订明天从上海到杭州的高铁，要求行程时间最短'
    self.timeout_seconds = 300
    
    def prepare
      @departure_city = '上海'
      @arrival_city = '杭州'
      @travel_date = Date.current + 1.day
      
      # 预查询乘客数据（避免 simulate 中使用 data_version: 0）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_passenger_name = @passenger.name
      @expected_passenger_id = @passenger.id_number
      @expected_contact_phone = @passenger.phone
      
      # 查找所有可用火车
      @available_trains = Train.by_route(@departure_city, @arrival_city)
        .by_date(@travel_date)
        .where(data_version: 0)
        .to_a
      
      raise "未找到可用的火车" if @available_trains.empty?
      
      # 计算最短行程时间
      @min_duration = @available_trains.map(&:duration).min
      @acceptable_max_duration = @min_duration + 10  # 允许10分钟误差
      
      # 找到最快的车次作为示例
      @sample_train = @available_trains.min_by(&:duration)
      
      {
        task: "请预订#{@travel_date.strftime('%Y年%m月%d日')}（明天）从#{@departure_city}到#{@arrival_city}的高铁，要求行程时间最短，追求速度优先。",
        scenario: "#{@expected_passenger_name}明天需要从#{@departure_city}到#{@arrival_city}，要求选择行程时间最短的高铁以便快速到达",
        requirements: {
          departure_city: @departure_city,
          arrival_city: @arrival_city,
          travel_date: @travel_date,
          priority: '行程时间最短',
          passenger: @expected_passenger_name,
          purpose: '快速到达'
        },
        available_trains_sample: {
          count: @available_trains.count,
          shortest_duration: "#{@min_duration}分钟",
          example: "#{@sample_train.train_number}（#{@sample_train.duration}分钟，二等座#{@sample_train.price_second_class}元）"
        },
        hint: "选择行程时间最短的车次。"
      }
    end
    
    def verify
      # 断言1: 创建了火车票订单 (20%)
      add_assertion "创建了火车票订单", weight: 20 do
        all_bookings = TrainBooking
          .joins(:train)
          .includes(:train)
          .where(trains: { departure_city: @departure_city, arrival_city: @arrival_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        expect(all_bookings).not_to be_empty, "未找到从#{@departure_city}到#{@arrival_city}的火车票订单"
        @booking = all_bookings.first
      end
      
      return if @booking.nil?
      
      # 断言2: 火车路线正确（上海→杭州） (15%)
      add_assertion "火车路线正确（#{@departure_city}→#{@arrival_city}）", weight: 15 do
        expect(@booking.train.departure_city).to eq(@departure_city),
          "出发城市错误。期望: #{@departure_city}, 实际: #{@booking.train.departure_city}"
        expect(@booking.train.arrival_city).to eq(@arrival_city),
          "到达城市错误。期望: #{@arrival_city}, 实际: #{@booking.train.arrival_city}"
      end
      
      # 断言3: 出发日期正确（明天） (15%)
      add_assertion "出发日期正确（明天#{@travel_date}）", weight: 15 do
        actual_date = @booking.train.departure_time.to_date
        expect(actual_date).to eq(@travel_date),
          "出发日期错误。期望: #{@travel_date}（明天）, 实际: #{actual_date}"
      end
      
      # 断言4: 选择了行程时间最短的车次 (20%)
      add_assertion "选择了行程时间最短的车次（≤#{@min_duration}分钟+10分钟误差）", weight: 20 do
        duration = @booking.train.duration
        expect(duration).to be <= @acceptable_max_duration,
          "未选择最快车次。最短行程: #{@min_duration}分钟, 实际: #{duration}分钟（允许误差10分钟）"
      end
      
      # 断言5: 乘客信息正确（张三） (10%)
      add_assertion "乘客信息正确（#{@expected_passenger_name}）", weight: 10 do
        expect(@booking.passenger_name).to eq(@expected_passenger_name),
          "乘客姓名错误。期望: #{@expected_passenger_name}, 实际: #{@booking.passenger_name}"
        expect(@booking.passenger_id_number).to eq(@expected_passenger_id),
          "乘客身份证错误。期望: #{@expected_passenger_id}, 实际: #{@booking.passenger_id_number}"
        expect(@booking.contact_phone).to eq(@expected_contact_phone),
          "联系电话错误。期望: #{@expected_contact_phone}, 实际: #{@booking.contact_phone}"
      end
      
      # 断言6: 订单状态有效 (20%)
      add_assertion "订单状态有效", weight: 20 do
        expect(@booking.status).to be_in(['pending', 'paid', 'completed']),
          "订单状态异常。实际状态: #{@booking.status}"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 选择行程时间最短的火车
      train = @available_trains.min_by(&:duration)
      
      # 使用 prepare 中预查询的乘客数据
      TrainBooking.create!(
        user: user,
        train: train,
        passenger_name: @passenger.name,
        passenger_id_number: @passenger.id_number,
        contact_phone: @passenger.phone,
        seat_type: 'second_class',
        ticket_count: 1,
        total_price: train.price_second_class,
        status: 'paid',
        accept_terms: true,
        data_version: @data_version
      )
    end
    
    private
    
    def execution_state_data
      {
        departure_city: @departure_city,
        arrival_city: @arrival_city,
        travel_date: @travel_date.to_s,
        min_duration: @min_duration,
        acceptable_max_duration: @acceptable_max_duration,
        expected_passenger_name: @expected_passenger_name,
        expected_passenger_id: @expected_passenger_id,
        expected_contact_phone: @expected_contact_phone
      }
    end
    
    def restore_from_state(data)
      @departure_city = data['departure_city']
      @arrival_city = data['arrival_city']
      @travel_date = Date.parse(data['travel_date'])
      @min_duration = data['min_duration']
      @acceptable_max_duration = data['acceptable_max_duration']
      @expected_passenger_name = data['expected_passenger_name']
      @expected_passenger_id = data['expected_passenger_id']
      @expected_contact_phone = data['expected_contact_phone']
      
      # 恢复乘客对象
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: @expected_passenger_name, data_version: 0)
      
      @available_trains = Train.by_route(@departure_city, @arrival_city)
        .by_date(@travel_date)
        .where(data_version: 0)
        .to_a
      
      @sample_train = @available_trains.min_by(&:duration) if @available_trains.any?
    end
  end
end
