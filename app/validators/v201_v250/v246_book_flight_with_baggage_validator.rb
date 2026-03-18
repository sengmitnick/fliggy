# frozen_string_literal: true

require_relative '../base_validator'

# V246: 张三3天后要从上海去成都出差，有大件行李需要托运，必须预订包含托运行李额度的机票
#
# 任务描述:
#   张三计划3天后从上海飞往成都出差，携带大件行李需要托运。
#   需要预订明确包含托运行李额度的机票，避免现场支付高额行李费。
#
# 业务流程:
#   1. 用户输入：出发城市（上海）、目的地（成都）、出发日期（3天后）
#   2. 系统筛选：仅显示包含托运行李额度的航班选项
#   3. 用户选择：对比行李额度和价格，选择合适航班
#   4. 填写信息：乘客姓名（张三）、身份证号、联系电话
#   5. 确认支付：核对航班信息、行李额度、总价格
#   6. 完成订单：生成订单，获取行李凭证
#
# 复杂度分析:
#   1. **行李政策识别**（中）：需理解baggage_allowance字段含义，区分有无行李额度
#   2. **航班筛选逻辑**（低）：过滤baggage_allowance非空且非零的航班
#   3. **价格对比决策**（低）：在含行李额度的航班中选择性价比高的
#   4. **订单信息填写**（低）：标准的乘客信息录入流程
#   5. **行李额度验证**（中）：确认订单中航班确实包含行李额度
#
# 评分标准（总分100%）:
#   - 创建了航班订单 (20%) - 基础操作
#   - 航线正确（上海→成都） (15%) - 城市匹配
#   - 机票包含托运行李额度 (30%) - 核心要求（最高权重）
#   - 出发日期正确（3天后） (15%) - 日期准确性
#   - 乘客信息正确（张三） (10%) - 信息完整性
#   - 订单状态有效 (10%) - 订单可用性
module V201V250
  class V246BookFlightWithBaggageValidator < BaseValidator
    self.validator_id = 'v246_book_flight_with_baggage_validator'
    self.task_id = '1ff17cff-2f2f-2f4f-4f5f-3f6a7b8c9d0f'
    self.title = '张三3天后要从上海去成都出差，有大件行李需要托运，必须预订包含托运行李额度的机票'
    self.description = '张三3天后要从上海去成都出差，有大件行李需要托运，必须预订包含托运行李额度的机票'
    self.timeout_seconds = 300
    
    def prepare
      @departure_city = '上海'
      @destination_city = '成都'
      @flight_date = Date.current + 3.days
      
      # 查询demo_user乘客信息（张三）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_passenger_name = @passenger.name
      @expected_passenger_id = @passenger.id_number
      @expected_contact_phone = @passenger.phone
      
      # 查找包含行李额度的航班套餐（通过FlightOffer的baggage_info判断）
      @available_offers = FlightOffer
        .joins(:flight)
        .where(flights: {
          departure_city: @departure_city,
          destination_city: @destination_city,
          flight_date: @flight_date,
          data_version: 0
        })
        .where(data_version: 0)
        .where("baggage_info NOT LIKE '%仅手提%' AND baggage_info NOT LIKE '%无免费%'")
        .to_a
      
      raise "未找到包含行李额度的航班套餐" if @available_offers.empty?
      
      # === 统计信息 ===
      puts "\n=== 上海→成都航班统计（含行李额度套餐） ==="
      puts "可用套餐总数: #{@available_offers.size}个"
      puts "航班套餐列表:"
      @available_offers.group_by(&:flight).each do |flight, offers|
        puts "  - #{flight.flight_number}: #{flight.price}元起, 日期: #{flight.flight_date}"
        offers.each do |offer|
          puts "    * #{offer.provider_name}: #{offer.price}元, 行李: #{offer.baggage_info}"
        end
      end
      
      prices = @available_offers.map(&:price)
      puts "套餐价格区间: #{prices.min}-#{prices.max}元"
      puts ""
      puts "乘客信息: #{@expected_passenger_name}（#{@expected_passenger_id}）"
      puts "出发日期: #{@flight_date}（3天后）"
      puts "="*50
      puts ""
      
      {
        title: "今天是#{Date.current.strftime('%Y年%m月%d日')}。#{self.class.title}",
        description: self.class.description,
        requirements: {
          departure_city: @departure_city,
          destination_city: @destination_city,
          flight_date: @flight_date.to_s,
          baggage_requirement: '必须包含托运行李额度',
          passenger_name: @expected_passenger_name,
          purpose: '携带大件行李出差'
        }
      }
    end
    
    def verify
      # 断言1: 创建了航班订单 (20%)
      add_assertion "创建了航班订单", weight: 20 do
        all_bookings = Booking
          .joins(:flight)
          .includes(:flight)
          .where(flights: { departure_city: @departure_city, destination_city: @destination_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        expect(all_bookings).not_to be_empty, 
          "未找到任何#{@departure_city}→#{@destination_city}的航班订单"
        
        @flight_booking = all_bookings.first
        expect(@flight_booking).not_to be_nil, "订单对象为空"
      end
      
      return if @flight_booking.nil?
      
      # 断言2: 航线正确（上海→成都） (15%)
      add_assertion "航线正确（#{@departure_city}→#{@destination_city}）", weight: 15 do
        flight = @flight_booking.flight
        expect(flight.departure_city).to eq(@departure_city),
          "出发城市错误。期望: #{@departure_city}, 实际: #{flight.departure_city}（航班号: #{flight.flight_number}）"
        expect(flight.destination_city).to eq(@destination_city),
          "目的地城市错误。期望: #{@destination_city}, 实际: #{flight.destination_city}（航班号: #{flight.flight_number}）"
      end
      
      # 断言3: 机票包含托运行李额度（核心要求，最高权重） (30%)
      add_assertion "机票包含托运行李额度（核心要求）", weight: 30 do
        flight = @flight_booking.flight
        offer = @flight_booking.flight_offer
        
        # 检查是否关联了FlightOffer
        expect(offer).not_to be_nil,
          "订单未关联航班套餐。航班号: #{flight.flight_number}（提示: 订单应选择包含托运行李的套餐）"
        
        # 检查FlightOffer的baggage_info是否包含托运行李
        has_baggage = offer.baggage_info.present? && 
                      !offer.baggage_info.include?('仅手提') && 
                      !offer.baggage_info.include?('无免费')
        
        expect(has_baggage).to eq(true),
          "机票不包含托运行李额度，无法托运大件行李。航班号: #{flight.flight_number}, 行李额度: #{offer.baggage_info.inspect}（期望: 包含托运行李额度，如'托运行李1件(23kg)'）"
      end
      
      # 断言4: 出发日期正确（3天后） (15%)
      add_assertion "出发日期正确（#{@flight_date}，3天后）", weight: 15 do
        flight = @flight_booking.flight
        expect(flight.flight_date).to eq(@flight_date),
          "出发日期错误。期望: #{@flight_date}（3天后）, 实际: #{flight.flight_date}（航班号: #{flight.flight_number}）"
      end
      
      # 断言5: 乘客信息正确（张三） (10%)
      add_assertion "乘客信息正确（#{@expected_passenger_name}）", weight: 10 do
        expect(@flight_booking.passenger_name).to eq(@expected_passenger_name),
          "乘客姓名错误。期望: #{@expected_passenger_name}, 实际: #{@flight_booking.passenger_name}"
        expect(@flight_booking.passenger_id_number).to eq(@expected_passenger_id),
          "乘客身份证号错误。期望: #{@expected_passenger_id}, 实际: #{@flight_booking.passenger_id_number}"
      end
      
      # 断言6: 订单状态有效 (10%)
      add_assertion "订单状态有效", weight: 10 do
        valid_statuses = ['pending', 'paid', 'completed']
        expect(@flight_booking.status).to be_in(valid_statuses),
          "订单状态异常。期望状态: #{valid_statuses.join('/')}, 实际状态: #{@flight_booking.status}"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      passenger = user.passengers.find_by!(name: '张三', data_version: 0)
      
      # 选择第一个包含行李额度的航班套餐
      offer = @available_offers.first
      flight = offer.flight
      
      Booking.create!(
        user: user,
        flight: flight,
        flight_offer: offer,
        passenger_name: passenger.name,
        passenger_id_number: passenger.id_number,
        contact_phone: passenger.phone,
        total_price: offer.price,
        accept_terms: true,
        status: 'paid',
        data_version: @data_version
      )
    end
    
    private
    
    def execution_state_data
      {
        departure_city: @departure_city,
        destination_city: @destination_city,
        flight_date: @flight_date.to_s,
        expected_passenger_name: @expected_passenger_name,
        expected_passenger_id: @expected_passenger_id,
        expected_contact_phone: @expected_contact_phone
      }
    end
    
    def restore_from_state(data)
      @departure_city = data['departure_city']
      @destination_city = data['destination_city']
      @flight_date = Date.parse(data['flight_date'])
      @expected_passenger_name = data['expected_passenger_name']
      @expected_passenger_id = data['expected_passenger_id']
      @expected_contact_phone = data['expected_contact_phone']
      
      @available_offers = FlightOffer
        .joins(:flight)
        .where(flights: {
          departure_city: @departure_city,
          destination_city: @destination_city,
          flight_date: @flight_date,
          data_version: 0
        })
        .where(data_version: 0)
        .where("baggage_info NOT LIKE '%仅手提%' AND baggage_info NOT LIKE '%无免费%'")
        .to_a
    end
  end
end
