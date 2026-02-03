# frozen_string_literal: true

require_relative '../base_validator'

# V170: 预订多段联程火车
# 验证用户能够完成多城市联程火车预订（北京→天津→上海）

module V151V200
  class V170BookMultiSegmentTrainValidator < BaseValidator
    self.validator_id = 'v170_book_multi_segment_train_validator'
    self.task_id = 'b0c1d2e3-4f5a-6b7c-8d9e-0f1a2b3c4d5e'
    self.title = '预订多段联程火车（北京→天津→上海）'
    self.description = '预订明天北京到天津的火车，以及后天天津到上海的火车，完成多城市联程'
    self.timeout_seconds = 300

    def prepare
      @city1 = '北京'
      @city2 = '天津'
      @city3 = '上海'
      @train1_date = Date.tomorrow
      @train2_date = @train1_date + 1.day
      
      # 查找第一段火车
      @available_train1 = Train
        .where(departure_city: @city1, arrival_city: @city2, data_version: 0)
        .by_date(@train1_date)
        .order(price_second_class: :asc)
        .to_a
      
      expect(@available_train1).not_to be_empty, "数据包缺少#{@city1}→#{@city2}的火车"
      
      # 查找第二段火车
      @available_train2 = Train
        .where(departure_city: @city2, arrival_city: @city3, data_version: 0)
        .by_date(@train2_date)
        .order(price_second_class: :asc)
        .to_a
      
      expect(@available_train2).not_to be_empty, "数据包缺少#{@city2}→#{@city3}的火车"
    end

    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      passenger = Passenger.find_by!(phone: '13800138000', data_version: 0)
      
      # 创建第一段火车订单
      train1 = @available_train1.first
      TrainBooking.create!(
        user_id: user.id,
        train_id: train1.id,
        passenger_name: user.name,
        passenger_id_number: '110101199001011234',
        contact_phone: '13800138000',
        seat_type: 'second_class',
        total_price: train1.price_second_class,
        accept_terms: true,
        status: 'paid',
        data_version: @data_version
      )
      
      # 创建第二段火车订单
      train2 = @available_train2.first
      TrainBooking.create!(
        user_id: user.id,
        train_id: train2.id,
        passenger_name: user.name,
        passenger_id_number: '110101199001011234',
        contact_phone: '13800138000',
        seat_type: 'second_class',
        total_price: train2.price_second_class,
        accept_terms: true,
        status: 'paid',
        data_version: @data_version
      )
    end

    def verify
      # 断言1: 创建了第一段火车订单
      add_assertion "创建了第一段火车订单（#{@city1}→#{@city2}）", weight: 25 do
        @ticket1 = TrainBooking
          .joins(:train)
          .includes(:train)
          .where(trains: { departure_city: @city1, arrival_city: @city2 })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@ticket1).not_to be_nil, "未找到#{@city1}→#{@city2}的火车订单"
      end
      
      return if @ticket1.nil?
      
      # 断言2: 创建了第二段火车订单
      add_assertion "创建了第二段火车订单（#{@city2}→#{@city3}）", weight: 25 do
        @ticket2 = TrainBooking
          .joins(:train)
          .includes(:train)
          .where(trains: { departure_city: @city2, arrival_city: @city3 })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@ticket2).not_to be_nil, "未找到#{@city2}→#{@city3}的火车订单"
      end
      
      return if @ticket2.nil?
      
      # 断言3: 第一段火车日期正确
      add_assertion "第一段火车日期正确（#{@train1_date}）", weight: 15 do
        train1_date = @ticket1.train.departure_time.to_date
        expect(train1_date).to eq(@train1_date),
          "第一段火车日期错误。期望: #{@train1_date}（明天）, 实际: #{train1_date}"
      end
      
      # 断言4: 第二段火车日期正确
      add_assertion "第二段火车日期正确（#{@train2_date}）", weight: 15 do
        train2_date = @ticket2.train.departure_time.to_date
        expect(train2_date).to eq(@train2_date),
          "第二段火车日期错误。期望: #{@train2_date}（后天）, 实际: #{train2_date}"
      end
      
      # 断言5: 形成联程路线（北京→天津→上海）
      add_assertion "形成联程路线（#{@city1}→#{@city2}→#{@city3}）", weight: 20 do
        # 第一段终点是第二段起点
        expect(@ticket1.train.arrival_city).to eq(@ticket2.train.departure_city),
          "联程路线错误。第一段终点: #{@ticket1.train.arrival_city}, 第二段起点: #{@ticket2.train.departure_city}"
        
        # 第二段应该在第一段之后
        train1_date = @ticket1.train.departure_time.to_date
        train2_date = @ticket2.train.departure_time.to_date
        expect(train2_date).to be > train1_date,
          "第二段火车应该在第一段火车之后"
      end
    end
  end
end
