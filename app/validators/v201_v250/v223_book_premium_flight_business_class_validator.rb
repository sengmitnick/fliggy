# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例223: 张三需要7天后从上海飞往纽约进行商务洽谈，希望预订商务舱航班，预算至少2000元起
#
# 任务描述：
#   张三需要7天后去纽约进行商务洽谈，需要预订商务舱航班，预算至少2000元起。
#   Agent 需要在价格≥2000元的航班中选择最优航班，创建1个航班订单。
#
#   ⚠️ 商务舱航班预订详细说明：
#   - 出发城市 = 上海
#   - 到达城市 = 纽约
#   - 出发日期 = 7天后(Date.current + 7.days)
#   - 乘客数量 = 1人(张三)
#   - 舱位等级 = 商务舱(business_class)
#   - 价格要求 = ≥2000元（高端商务出行）
#   - 选择策略 = 在价格≥2000元的航班中选择价格最低的（性价比最优）
#   - 价格计算 = 航班单价×1人
#
# 核心要求：
#   - 受益人：张三(使用其姓名、身份证、手机号作为乘客信息)
#   - 出发城市：上海
#   - 到达城市：纽约
#   - 出发日期：7天后(Date.current + 7.days)
#   - 乘客数量：1人
#   - 舱位等级：商务舱(business_class)
#   - 价格要求：≥2000元
#   - 选择策略：在价格≥2000元的航班中选择价格最低的
#
# 业务流程(5个关键步骤)：
#   1. 明确受益人信息(张三，使用其姓名、身份证、手机号作为乘客信息)
#   2. 搜索上海→纽约航班，筛选7天后出发的航班
#   3. 筛选价格≥2000元的商务舱航班
#   4. 在符合价格要求的航班中，选择价格最低的（性价比最优）
#   5. 创建航班订单，1人乘坐
#
# 复杂度分析(5个关键点)：
#   1. 需要理解价格下限约束(≥2000元，无上限)
#   2. 需要筛选商务舱航班(seat_class = 'business_class')
#   3. 需要在价格≥2000元的航班中选择价格最低的（不是最贵，而是性价比最优）
#   4. 需要正确计算出发日期(7天后)
#   5. 需要正确计算总价(航班单价×1人)
#   ❌ 不能一次性提供所有信息：需要查询航班数据，筛选价格区间，按价格排序选择最优选项。
#
# 评分标准(8项，总计100分)：
#   1. 创建了航班订单(20分)
#   2. 航班价格≥2000元(25分)- 核心业务逻辑
#   3. 航班路线正确(上海→纽约)(15分)
#   4. 航班日期正确(7天后)(10分)
#   5. 预订1人(5分)
#   6. 舱位等级为商务舱(10分)
#   7. 乘客信息正确(张三的姓名、身份证、手机号)(10分)
#   8. 订单状态有效(5分)
#
# 验证要点(8个断言)：
#   - 断言1: 航班订单已创建(Booking)(20分)
#   - 断言2: 航班价格≥2000元(25分)
#   - 断言3: 航班路线正确(上海→纽约)(15分)
#   - 断言4: 航班日期为7天后(10分)
#   - 断言5: 预订1人(5分)
#   - 断言6: 舱位等级为商务舱(business_class)(10分)
#   - 断言7: 乘客信息正确(张三的姓名、身份证、手机号)(10分)
#   - 断言8: 订单状态有效(5分)
#
# 使用方法:
#   rake validator:simulate_single[v223_book_premium_flight_business_class_validator]
#   或访问 http://localhost:<PORT>/api/tasks 获取任务列表
module V201V250
  class V223BookPremiumFlightBusinessClassValidator < BaseValidator
    self.validator_id = 'v223_book_premium_flight_business_class_validator'
    self.task_id = '0ff021fe-1f1f-1f3f-3f4f-2f5a6b7c8d9f'
    self.title = '张三需要7天后从上海飞往纽约进行商务洽谈，希望预订商务舱航班，预算至少2000元起'
    self.description = '张三需要7天后从上海飞往纽约进行商务洽谈，希望预订商务舱航班，预算至少2000元起'
    self.timeout_seconds = 300
    
    def prepare
      @departure_city = '上海'
      @arrival_city = '纽约'
      @flight_date = Date.current + 7.days
      @min_price = 2000
      @seat_class = 'business_class'  # 商务舱
      
      # 查询demo_user和乘客信息
      demo_user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      demo_passenger = demo_user.passengers.find_by!(is_self: true)  # RLS 自动注入 data_version
      @passenger = OpenStruct.new(
        name: demo_passenger.name,
        id_number: demo_passenger.id_number,
        phone: demo_passenger.phone
      )
      
      # 查找商务舱/高价航班（按日期过滤）
      @available_flights = Flight.where(
        departure_city: @departure_city,
        destination_city: @arrival_city,
        flight_date: @flight_date,
        data_version: 0
      ).to_a.select { |f| f.price >= @min_price && (f.seat_class.nil? || f.seat_class == @seat_class) }
      
      raise "未找到价格≥#{@min_price}元的高端航班" if @available_flights.empty?
      
      {
        task: "请预订#{@flight_date.strftime('%Y年%m月%d日')}从#{@departure_city}到#{@arrival_city}的高端商务舱航班，价格要求≥#{@min_price}元。",
        requirements: {
          departure_city: @departure_city,
          arrival_city: @arrival_city,
          flight_date: @flight_date,
          min_price: "≥#{@min_price}元",
          purpose: '高端商务出行'
        },
        hint: "选择价格≥#{@min_price}元的高端航班，服务品质优先。"
      }
    end
    
    # 验证方法：检查订单是否符合任务要求
    # 共8个断言：
    # 1. 创建了航班订单（20分）
    # 2. 航班价格≥2000元（25分）- 核心业务逻辑
    # 3. 航班路线正确（上海→纽约）（15分）
    # 4. 航班日期正确（7天后）（10分）
    # 5. 预订1人（5分）
    # 6. 舱位等级为商务舱（10分）
    # 7. 乘客信息正确（10分）
    # 8. 订单状态有效（5分）
    def verify
      # 断言1: 创建了航班订单 (20分)
      add_assertion "创建了航班订单", weight: 20 do
        @booking = Booking
          .joins(:flight)
          .where(flights: { departure_city: @departure_city, destination_city: @arrival_city })
          .where(data_version: @data_version)
          .first
        
        expect(@booking).not_to be_nil, "未找到从#{@departure_city}到#{@arrival_city}的航班订单"
      end
      
      return if @booking.nil?
      
      # 断言2: 航班价格≥2000元 (25分) - 核心业务逻辑
      add_assertion "航班价格≥#{@min_price}元", weight: 25 do
        price = @booking.flight.price
        expect(price).to be >= @min_price,
          "航班价格过低。期望: ≥#{@min_price}元, 实际: #{price}元"
      end
      
      # 断言3: 航班路线正确（上海→纽约） (15分)
      add_assertion "航班路线正确（#{@departure_city}→#{@arrival_city}）", weight: 15 do
        expect(@booking.flight.departure_city).to eq(@departure_city),
          "出发城市错误。期望: #{@departure_city}, 实际: #{@booking.flight.departure_city}"
        expect(@booking.flight.destination_city).to eq(@arrival_city),
          "到达城市错误。期望: #{@arrival_city}, 实际: #{@booking.flight.destination_city}"
      end
      
      # 断言4: 航班日期正确（7天后） (10分)
      add_assertion "航班日期正确（#{@flight_date.strftime('%m月%d日')}，7天后）", weight: 10 do
        expect(@booking.flight.flight_date).to eq(@flight_date),
          "航班日期错误。期望: #{@flight_date}（7天后）, 实际: #{@booking.flight.flight_date}"
      end
      
      # 断言5: 预订1人 (5分)
      add_assertion "预订1人", weight: 5 do
        # Booking模型中乘客信息存储为单个字段，验证只有一个乘客信息
        expect(@booking.passenger_name).not_to be_nil,
          "乘客信息缺失"
        expect(@booking.passenger_name).to eq(@passenger.name),
          "预订应为1人（#{@passenger.name}）"
      end
      
      # 断言6: 舱位等级为商务舱 (10分)
      add_assertion "舱位等级为商务舱", weight: 10 do
        seat_class = @booking.flight.seat_class || @booking.seat_class
        expect(seat_class).to eq('business_class'),
          "舱位等级错误。期望: business_class（商务舱）, 实际: #{seat_class}"
      end
      
      # 断言7: 乘客信息正确（张三的姓名、身份证、手机号） (10分)
      add_assertion "乘客信息正确（#{@passenger.name}的姓名、身份证、手机号）", weight: 10 do
        expect(@booking.passenger_name).to eq(@passenger.name),
          "乘客姓名错误。期望: #{@passenger.name}, 实际: #{@booking.passenger_name}"
        expect(@booking.passenger_id_number).to eq(@passenger.id_number),
          "乘客身份证错误。期望: #{@passenger.id_number}, 实际: #{@booking.passenger_id_number}"
        expect(@booking.contact_phone).to eq(@passenger.phone),
          "联系电话错误。期望: #{@passenger.phone}, 实际: #{@booking.contact_phone}"
      end
      
      # 断言8: 订单状态有效 (5分)
      add_assertion "订单状态有效", weight: 5 do
        expect(@booking.status).to be_in(['pending', 'paid', 'completed']),
          "订单状态异常。实际状态: #{@booking.status}"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 选择价格适中且服务好的高端航班
      flight = @available_flights.min_by(&:price)
      
      Booking.create!(
        user: user,
        flight: flight,
        passenger_name: @passenger.name,
        passenger_id_number: @passenger.id_number,
        contact_phone: @passenger.phone,
        total_price: flight.price,
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
        flight_date: @flight_date.to_s,
        min_price: @min_price,
        passenger_name: @passenger.name,
        passenger_id_number: @passenger.id_number,
        passenger_phone: @passenger.phone
      }
    end
    
    def restore_from_state(data)
      @departure_city = data['departure_city']
      @arrival_city = data['arrival_city']
      @flight_date = Date.parse(data['flight_date'])
      @min_price = data['min_price']
      @seat_class = 'business_class'  # 商务舱
      
      # Restore passenger data from flattened fields
      @passenger = OpenStruct.new(
        name: data['passenger_name'],
        id_number: data['passenger_id_number'],
        phone: data['passenger_phone']
      )
      
      @available_flights = Flight.where(
        departure_city: @departure_city,
        destination_city: @arrival_city,
        flight_date: @flight_date,
        data_version: 0
      ).to_a.select { |f| f.price >= @min_price && (f.seat_class.nil? || f.seat_class == @seat_class) }
    end
  end
end
