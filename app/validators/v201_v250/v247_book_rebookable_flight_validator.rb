# frozen_string_literal: true

require_relative '../base_validator'

# V247: 张三明天要从上海去广州，但行程还没最终确定，需要预订改签免费的航班
#
# 任务描述:
#   张三计划从上海飞往广州，但具体行程还没最终确定。
#   需要预订支持改签免手续费的航班套餐，避免后续调整时间需支付额外费用。
#
# 业务流程:
#   1. 用户输入：出发城市（上海）、目的地（广州）、出发日期（明天）
#   2. 系统筛选：仅显示明天出发且改签免费的航班套餐选项
#   3. 用户选择：对比退改政策和价格，选择合适套餐
#   4. 填写信息：乘客姓名（张三）、身份证号、联系电话
#   5. 确认支付：核对航班信息、退改政策、总价格
#   6. 完成订单：生成订单，获取改签免费凭证
#
# 复杂度分析:
#   1. **退改政策识别**（中）：需理解FlightOffer.refund_policy字段含义，区分免费和收费改签
#   2. **套餐筛选逻辑**（低）：过滤refund_policy包含"免手续费"或"免费"的套餐
#   3. **价格对比决策**（低）：在改签免费的套餐中选择性价比高的
#   4. **订单信息填写**（低）：标准的乘客信息录入流程
#   5. **改签政策验证**（中）：确认订单中套餐确实支持改签免费
#
# 评分标准（总分100%）:
#   - 创建了航班订单 (20%) - 基础操作
#   - 航线正确（上海→广州） (10%) - 城市匹配
#   - 出发日期正确 (10%) - 日期匹配
#   - 选择了改签免费套餐 (10%) - 套餐关联
#   - 改签政策为免费 (30%) - 核心要求（最高权重）
#   - 乘客信息正确（张三） (15%) - 信息完整性
#   - 订单状态有效 (5%) - 订单可用性
module V201V250
  class V247BookRebookableFlightValidator < BaseValidator
    self.validator_id = 'v247_book_rebookable_flight_validator'
    self.task_id = '1ff17cff-2f2f-2f4f-4f5f-3f6a7b8c9d10'
    self.title = '张三明天要从上海去广州，但行程还没最终确定，需要预订改签免费的航班'
    self.description = '张三明天要从上海去广州，但行程还没最终确定，需要预订改签免费的航班'
    self.timeout_seconds = 300
    
    def prepare
      @departure_city = '上海'
      @destination_city = '广州'
      @flight_date = Date.today + 1.day  # 明天出发
      
      # 查询demo_user乘客信息（张三）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_passenger_name = @passenger.name
      @expected_passenger_id = @passenger.id_number
      @expected_contact_phone = @passenger.phone
      
      # 查找改签免费的航班套餐（检查FlightOffer的refund_policy）
      @available_offers = FlightOffer
        .joins(:flight)
        .where(flights: {
          departure_city: @departure_city,
          destination_city: @destination_city,
          flight_date: @flight_date,
          data_version: 0
        })
        .where(data_version: 0)
        .where("flight_offers.refund_policy LIKE '%免手续费%' OR flight_offers.refund_policy LIKE '%免费改签%'")
        .to_a
      
      raise "未找到#{@flight_date.strftime('%Y年%m月%d日')}从#{@departure_city}到#{@destination_city}的改签免费航班套餐" if @available_offers.empty?
      
      {
        title: "今天是#{Date.current.strftime('%Y年%m月%d日')}。#{self.class.title}",
        description: self.class.description,
        requirements: {
          departure_city: @departure_city,
          destination_city: @destination_city,
          flight_date: @flight_date,
          free_rebooking: true,
          purpose: '行程灵活，免费改签'
        }
      }
    end
    
    def verify
      add_assertion "创建了航班订单", weight: 20 do
        all_bookings = Booking
          .joins(:flight)
          .includes(:flight, :flight_offer)
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        expect(all_bookings).not_to be_empty, "未找到航班订单"
        @flight_booking = all_bookings.first
      end
      
      return if @flight_booking.nil?
      
      add_assertion "航线正确（#{@departure_city}→#{@destination_city}）", weight: 10 do
        flight = @flight_booking.flight
        expect(flight.departure_city).to eq(@departure_city),
          "出发城市错误。期望: #{@departure_city}, 实际: #{flight.departure_city}"
        expect(flight.destination_city).to eq(@destination_city),
          "目的地城市错误。期望: #{@destination_city}, 实际: #{flight.destination_city}"
      end
      
      add_assertion "出发日期正确（#{@flight_date&.strftime('%Y-%m-%d')}）", weight: 10 do
        flight = @flight_booking.flight
        expect(flight.flight_date).to eq(@flight_date),
          "出发日期错误。期望: #{@flight_date&.strftime('%Y-%m-%d')}, 实际: #{flight.flight_date&.strftime('%Y-%m-%d')}"
      end
      
      add_assertion "选择了改签免费套餐", weight: 10 do
        offer = @flight_booking.flight_offer
        expect(offer).not_to be_nil,
          "订单未关联航班套餐。航班号: #{@flight_booking.flight.flight_number}（提示: 订单应选择支持改签免费的套餐）"
      end
      
      return if @flight_booking.flight_offer.nil?
      
      add_assertion "改签政策为免费（核心要求）", weight: 30 do
        offer = @flight_booking.flight_offer
        is_free_rebooking = offer.refund_policy&.include?('免手续费') || offer.refund_policy&.include?('免费改签')
        
        expect(is_free_rebooking).to eq(true),
          "套餐改签不免费，后续调整行程需支付额外费用。航班号: #{@flight_booking.flight.flight_number}, 套餐: #{offer.provider_name}, 退改政策: #{offer.refund_policy}（期望: 改签免费，如'退改签免手续费'）"
      end
      
      add_assertion "乘客信息正确（#{@expected_passenger_name}）", weight: 15 do
        expect(@flight_booking.passenger_name).to eq(@expected_passenger_name),
          "乘客姓名错误。期望: #{@expected_passenger_name}, 实际: #{@flight_booking.passenger_name}"
        expect(@flight_booking.passenger_id_number).to eq(@expected_passenger_id),
          "乘客身份证号错误。期望: #{@expected_passenger_id}, 实际: #{@flight_booking.passenger_id_number}"
      end
      
      add_assertion "订单状态有效", weight: 5 do
        expect(@flight_booking.status).to be_in(['pending', 'paid', 'completed']),
          "订单状态异常。实际状态: #{@flight_booking.status}"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      passenger = user.passengers.find_by!(name: '张三', data_version: 0)
      
      # 选择第一个改签免费的航班套餐
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
        .where("flight_offers.refund_policy LIKE '%免手续费%' OR flight_offers.refund_policy LIKE '%免费改签%'")
        .to_a
    end
  end
end
