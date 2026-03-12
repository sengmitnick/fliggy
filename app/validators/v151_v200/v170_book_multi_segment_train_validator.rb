# frozen_string_literal: true

require_relative '../base_validator'

# V170: 预订多段联程火车
# 验证用例170: 给张三预订多城市联程火车（明天北京→天津，后天天津→上海）
#
# 任务描述:
#   张三计划预订多城市联程火车：明天从北京坐火车到天津，后天从天津坐火车到上海。
#   1. 第一段火车（明天北京→天津）
#   2. 第二段火车（后天天津→上海）
#
# 任务分解步骤:
#   1. 查询第一段火车（明天北京→天津）
#   2. 创建第一段火车订单（乘客=张三，联系人电话=张三手机号）
#   3. 查询第二段火车（后天天津→上海）
#   4. 创建第二段火车订单（乘客=张三，联系人电话=张三手机号）
#
# 评分标准（总分100分）:
#   1. 创建了第一段火车订单（北京→天津） (25分)
#   2. 创建了第二段火车订单（天津→上海） (25分)
#   3. 第一段火车日期正确（明天） (15分)
#   4. 第二段火车日期正确（后天） (15分)
#   5. 形成联程路线（北京→天津→上海） (15分)
#   6. 两段火车乘客信息一致（张三） (5分)

module V151V200
  class V170BookMultiSegmentTrainValidator < BaseValidator
    self.validator_id = 'v170_book_multi_segment_train_validator'
    self.task_id = 'b0c1d2e3-4f5a-6b7c-8d9e-0f1a2b3c4d5e'
    self.title = '给张三预订多城市联程火车（明天北京→天津，后天天津→上海）'
    self.description = '张三计划预订多城市联程火车：明天从北京坐火车到天津，后天从天津坐火车到上海'
    self.timeout_seconds = 300

    def prepare
      @city1 = '北京'
      @city2 = '天津'
      @city3 = '上海'
      @train1_date = Date.current + 1.day  # 明天
      @train2_date = Date.current + 2.days  # 后天（今天+2天）
      
      # 预查询demo_user的乘客信息
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_name = @passenger.name
      @expected_phone = @passenger.phone
      @expected_id_number = @passenger.id_number
      
      # 查找第一段火车
      @available_train1 = Train
        .where(departure_city: @city1, arrival_city: @city2, data_version: 0)
        .by_date(@train1_date)
        .order(price_second_class: :asc)
        .to_a
      
      expect(@available_train1).not_to be_empty, "数据包缺少#{@city1}→#{@city2}的火车"
      return if @available_train1.empty?  # Guard clause
      
      # 查找第二段火车
      @available_train2 = Train
        .where(departure_city: @city2, arrival_city: @city3, data_version: 0)
        .by_date(@train2_date)
        .order(price_second_class: :asc)
        .to_a
      
      expect(@available_train2).not_to be_empty, "数据包缺少#{@city2}→#{@city3}的火车"
      return if @available_train2.empty?  # Guard clause
    end

    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      passenger = Passenger.find_by!(phone: @passenger.phone, data_version: 0)
      
      # 创建第一段火车订单（明天北京→天津）
      train1 = @available_train1.first
      TrainBooking.create!(
        user_id: user.id,
        train_id: train1.id,
        passenger_name: @passenger.name,
        passenger_id_number: @passenger.id_number,
        contact_phone: @passenger.phone,
        seat_type: 'second_class',
        total_price: train1.price_second_class,
        accept_terms: true,
        status: 'paid',
        data_version: @data_version
      )
      
      # 创建第二段火车订单（后天天津→上海）
      train2 = @available_train2.first
      TrainBooking.create!(
        user_id: user.id,
        train_id: train2.id,
        passenger_name: @passenger.name,
        passenger_id_number: @passenger.id_number,
        contact_phone: @passenger.phone,
        seat_type: 'second_class',
        total_price: train2.price_second_class,
        accept_terms: true,
        status: 'paid',
        data_version: @data_version
      )
    end

    def execution_state_data
      {
        data_version: @data_version,
        city1: @city1,
        city2: @city2,
        city3: @city3,
        train1_date: @train1_date.to_s,
        train2_date: @train2_date.to_s,
        expected_name: @expected_name,
        expected_phone: @expected_phone,
        expected_id_number: @expected_id_number
      }
    end

    def restore_from_state(data)
      @data_version = data['data_version']
      @city1 = data['city1']
      @city2 = data['city2']
      @city3 = data['city3']
      @train1_date = Date.parse(data['train1_date']) if data['train1_date']
      @train2_date = Date.parse(data['train2_date']) if data['train2_date']
      @expected_name = data['expected_name']
      @expected_phone = data['expected_phone']
      @expected_id_number = data['expected_id_number']
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
      
      return if @ticket1.nil?  # Guard clause after assertion 1
      
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
      
      return if @ticket2.nil?  # Guard clause after assertion 2
      
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
      add_assertion "形成联程路线（#{@city1}→#{@city2}→#{@city3}）", weight: 15 do
        # 第一段终点是第二段起点
        expect(@ticket1.train.arrival_city).to eq(@ticket2.train.departure_city),
          "联程路线错误。第一段终点: #{@ticket1.train.arrival_city}, 第二段起点: #{@ticket2.train.departure_city}"
        
        # 第二段应该在第一段之后
        train1_date = @ticket1.train.departure_time.to_date
        train2_date = @ticket2.train.departure_time.to_date
        expect(train2_date).to be > train1_date,
          "第二段火车应该在第一段火车之后"
      end
      
      # 断言6: 乘客信息正确（张三）
      add_assertion "两段火车乘客信息一致（#{@expected_name}）", weight: 5 do
        # 验证第一段
        expect(@ticket1.passenger_name).to eq(@expected_name),
          "第一段火车乘客姓名错误。期望: #{@expected_name}, 实际: #{@ticket1.passenger_name}"
        expect(@ticket1.passenger_id_number).to eq(@expected_id_number),
          "第一段火车乘客身份证号错误。期望: #{@expected_id_number}, 实际: #{@ticket1.passenger_id_number}"
        
        # 验证第二段
        expect(@ticket2.passenger_name).to eq(@expected_name),
          "第二段火车乘客姓名错误。期望: #{@expected_name}, 实际: #{@ticket2.passenger_name}"
        expect(@ticket2.passenger_id_number).to eq(@expected_id_number),
          "第二段火车乘客身份证号错误。期望: #{@expected_id_number}, 实际: #{@ticket2.passenger_id_number}"
      end
    end
  end
end
