# frozen_string_literal: true

require_relative '../base_validator'

# V208: 预订最快高铁（行程时间最短）
#
# 任务描述:
#   用户需要预订明天上海→杭州，行程时间最短的高铁
#
# 评分标准:
#   - 创建了火车票订单 (20%)
#   - 火车路线正确（上海→杭州） (15%)
#   - 出发日期正确（明天） (15%)
#   - 选择了行程时间最短的车次（≤理论最短时间+10分钟） (30%)
#   - 订单状态有效 (20%)
module V201V250
  class V208BookFastestTrainShortestDurationValidator < BaseValidator
    self.validator_id = 'v208_book_fastest_train_shortest_duration_validator'
    self.task_id = '7f8809f2-8f8f-4f1e-ef1f-2f4a5b6c7d8f'
    self.title = '预订明天最快高铁（行程时间最短，1人）'
    self.description = '用户需要预订明天上海→杭州，行程时间最短的高铁'
    self.timeout_seconds = 300
    
    def prepare
      @departure_city = '上海'
      @arrival_city = '杭州'
      @travel_date = Date.current + 1.day
      
      # 查找所有可用火车
      @available_trains = Train.by_route(@departure_city, @arrival_city)
        .by_date(@travel_date)
        .where(data_version: 0)
        .to_a
      
      raise "未找到可用的火车" if @available_trains.empty?
      
      # 计算最短行程时间
      @min_duration = @available_trains.map(&:duration).min
      @acceptable_max_duration = @min_duration + 10  # 允许10分钟误差
      
      {
        task: "请预订#{@travel_date.strftime('%Y年%m月%d日')}（明天）从#{@departure_city}到#{@arrival_city}的高铁，要求行程时间最短，追求速度优先。",
        requirements: {
          departure_city: @departure_city,
          arrival_city: @arrival_city,
          travel_date: @travel_date,
          priority: '行程时间最短',
          purpose: '快速到达'
        },
        hint: "选择行程时间最短的车次。"
      }
    end
    
    def verify
      add_assertion "创建了火车票订单", weight: 20 do
        all_bookings = TrainBooking
          .joins(:train)
          .includes(:train)
          .where(trains: { departure_city: @departure_city, arrival_city: @arrival_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        @booking = all_bookings.first
        expect(@booking).not_to be_nil, "未找到从#{@departure_city}到#{@arrival_city}的火车票订单"
      end
      
      return if @booking.nil?
      
      add_assertion "火车路线正确（#{@departure_city}→#{@arrival_city}）", weight: 15 do
        expect(@booking.train.departure_city).to eq(@departure_city),
          "出发城市错误。期望: #{@departure_city}, 实际: #{@booking.train.departure_city}"
        expect(@booking.train.arrival_city).to eq(@arrival_city),
          "到达城市错误。期望: #{@arrival_city}, 实际: #{@booking.train.arrival_city}"
      end
      
      add_assertion "出发日期正确（明天#{@travel_date}）", weight: 15 do
        actual_date = @booking.train.departure_time.to_date
        expect(actual_date).to eq(@travel_date),
          "出发日期错误。期望: #{@travel_date}（明天）, 实际: #{actual_date}"
      end
      
      add_assertion "选择了行程时间最短的车次", weight: 30 do
        duration = @booking.train.duration
        expect(duration).to be <= @acceptable_max_duration,
          "未选择最快车次。最短行程: #{@min_duration}分钟, 实际: #{duration}分钟（允许误差10分钟）"
      end
      
      add_assertion "订单状态有效", weight: 20 do
        expect(@booking.status).to be_in(['pending', 'paid', 'completed']),
          "订单状态异常。实际状态: #{@booking.status}"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 选择行程时间最短的火车
      train = @available_trains.min_by(&:duration)
      
      TrainBooking.create!(
        user: user,
        train: train,
        passenger_name: user.name,
        passenger_id_number: '110101199001011234',
        contact_phone: '13800138000',
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
        acceptable_max_duration: @acceptable_max_duration
      }
    end
    
    def restore_from_state(data)
      @departure_city = data['departure_city']
      @arrival_city = data['arrival_city']
      @travel_date = Date.parse(data['travel_date'])
      @min_duration = data['min_duration']
      @acceptable_max_duration = data['acceptable_max_duration']
      
      @available_trains = Train.by_route(@departure_city, @arrival_city)
        .by_date(@travel_date)
        .where(data_version: 0)
        .to_a
    end
  end
end
