# frozen_string_literal: true

require_relative '../base_validator'

# V259: 给张三预订张家口崇礼万龙滑雪场（7天后，1人）：景点门票+滑雪装备租赁活动+包含滑雪场景的运动保险
#
# 任务描述:
#   帮张三预订张家口崇礼万龙滑雪场，游玩日期为7天后，1人。需要购买：1）景点门票（TicketOrder），2）滑雪装备租赁活动（ActivityOrder），3）包含滑雪场景保障的运动保险（InsuranceOrder，保障期至少1天），确保所有订单状态有效
#
# 评分标准:
#   - 创建了景点门票订单（TicketOrder，崇礼万龙滑雪场） (20%)
#   - 游玩日期正确（7天后） (5%)
#   - 人数正确（1人） (5%)
#   - 创建了滑雪装备租赁活动订单（ActivityOrder，滑雪装备租赁） (20%)
#   - 创建了运动保险订单（InsuranceOrder） (15%)
#   - 保险包含滑雪或户外运动场景 (10%)
#   - 保险保障天数至少1天 (5%)
#   - 联系人信息正确（张三） (10%)
#   - 投保人信息正确（张三） (5%)
#   - 所有订单状态有效 (5%)
module V251V300
  class V259BookHighRiskActivityWithInsuranceValidator < BaseValidator
    self.validator_id = 'v259_book_high_risk_activity_with_insurance_validator'
    self.task_id = '252c7d0b-4c3f-4877-9af0-1712884307df'
    self.title = '帮张三预订张家口崇礼万龙滑雪场，游玩日期为7天后，1人。需要购买：1）景点门票，2）滑雪装备租赁活动，3）包含滑雪场景保障的运动保险（保障期至少1天）'
    self.description = '帮张三预订张家口崇礼万龙滑雪场，游玩日期为7天后，1人。需要购买：1）景点门票，2）滑雪装备租赁活动，3）包含滑雪场景保障的运动保险（保障期至少1天）'
    self.timeout_seconds = 300
    
    def prepare
      @attraction_name = '崇礼万龙滑雪场'
      @city = '张家口'
      @visit_date = Date.current + 7.days
      @quantity = 1
      @activity_name = '滑雪装备租赁（全套）'
      
      # 查询 demo_user 和乘客信息（基线数据）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @zhangsan = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_contact_phone = @zhangsan.phone
      @expected_insured_name = @zhangsan.name
      
      # 查找崇礼万龙滑雪场
      @attraction = Attraction.find_by(
        name: @attraction_name,
        city: @city,
        data_version: 0
      )
      raise "未找到#{@city}#{@attraction_name}" unless @attraction
      
      # 查找景点门票
      @ticket = Ticket.find_by(
        attraction_id: @attraction.id,
        ticket_type: 'adult',
        data_version: 0
      )
      raise "未找到#{@attraction_name}门票" unless @ticket
      
      # 查找滑雪装备租赁活动
      @activity = AttractionActivity.find_by(
        attraction_id: @attraction.id,
        name: @activity_name,
        data_version: 0
      )
      raise "未找到#{@activity_name}活动" unless @activity
      
      # 查找包含滑雪场景的保险产品
      @available_insurances = InsuranceProduct
        .where(product_type: 'domestic', data_version: 0)
        .select { |p| p.scenes&.include?('滑雪') || p.scenes&.include?('户外运动') }
      
      raise "未找到包含滑雪场景的保险产品" if @available_insurances.empty?
      
      {
        task: "请为张三预订#{@city}#{@attraction_name}（#{@visit_date.strftime('%Y年%m月%d日')}，#{@quantity}人），需要购买：1）景点门票，2）#{@activity_name}活动，3）包含滑雪场景保障的运动保险（保障期至少1天）。",
        requirements: {
          passenger_name: '张三',
          city: @city,
          attraction_name: @attraction_name,
          visit_date: @visit_date,
          quantity: @quantity,
          ticket_name: @ticket.name,
          activity_name: @activity_name,
          insurance_type: '运动保险',
          insurance_coverage: '滑雪或户外运动',
          insurance_days: '至少1天'
        },
        hint: "滑雪属于高风险运动，建议购买景点门票、滑雪装备租赁活动，以及包含滑雪场景保障的运动保险。"
      }
    end
    
    def verify
      add_assertion "创建了景点门票订单（TicketOrder，#{@attraction_name}）", weight: 20 do
        all_ticket_orders = TicketOrder
          .joins(ticket: :attraction)
          .includes(ticket: :attraction)
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        expect(all_ticket_orders).not_to be_empty, "未找到任何门票订单（TicketOrder）"
        
        @ticket_order = all_ticket_orders.find do |order|
          order.ticket.attraction.name == @attraction_name
        end
        
        expect(@ticket_order).not_to be_nil,
          "未找到#{@attraction_name}的门票订单。找到的订单: #{all_ticket_orders.map { |o| o.ticket.attraction.name }.join(', ')}"
      end
      
      return if @ticket_order.nil?
      
      add_assertion "游玩日期正确（#{@visit_date.strftime('%Y年%m月%d日')}）", weight: 5 do
        expect(@ticket_order.visit_date).to eq(@visit_date),
          "门票游玩日期错误。期望: #{@visit_date}（7天后），实际: #{@ticket_order.visit_date}"
      end
      
      add_assertion "人数正确（#{@quantity}人）", weight: 5 do
        expect(@ticket_order.quantity).to eq(@quantity),
          "门票购买人数错误。期望: #{@quantity}人，实际: #{@ticket_order.quantity}人"
      end
      
      add_assertion "创建了滑雪装备租赁活动订单（ActivityOrder，#{@activity_name}）", weight: 20 do
        all_activity_orders = ActivityOrder
          .joins(attraction_activity: :attraction)
          .includes(attraction_activity: :attraction)
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        expect(all_activity_orders).not_to be_empty, "未找到任何活动订单（ActivityOrder）"
        
        @activity_order = all_activity_orders.find do |order|
          order.attraction_activity.attraction.name == @attraction_name &&
          order.attraction_activity.name == @activity_name
        end
        
        expect(@activity_order).not_to be_nil,
          "未找到#{@attraction_name}的『#{@activity_name}』活动订单。找到的订单: #{all_activity_orders.map { |o| "#{o.attraction_activity.attraction.name}-#{o.attraction_activity.name}" }.join(', ')}"
        
        expect(@activity_order.visit_date).to eq(@visit_date),
          "活动游玩日期错误。期望: #{@visit_date}（7天后），实际: #{@activity_order.visit_date}"
        
        expect(@activity_order.quantity).to eq(@quantity),
          "活动参与人数错误。期望: #{@quantity}人，实际: #{@activity_order.quantity}人"
      end
      
      return if @activity_order.nil?
      
      add_assertion "创建了运动保险订单（InsuranceOrder）", weight: 15 do
        @insurance_order = InsuranceOrder
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@insurance_order).not_to be_nil, "未找到保险订单（InsuranceOrder）"
      end
      
      return if @insurance_order.nil?
      
      add_assertion "保险包含滑雪或户外运动场景", weight: 10 do
        scenes = @insurance_order.insurance_product.scenes || []
        has_ski_coverage = scenes.include?('滑雪') || scenes.include?('户外运动')
        
        expect(has_ski_coverage).to be_truthy,
          "保险不包含滑雪场景保障。保险场景: #{scenes.inspect}，需要包含'滑雪'或'户外运动'"
      end
      
      add_assertion "保险保障天数至少1天", weight: 5 do
        insurance_days = @insurance_order.days
        expect(insurance_days).to be >= 1,
          "保险天数不足。保险天数: #{insurance_days}天，需要至少1天"
      end
      
      add_assertion "联系人信息正确（张三）", weight: 10 do
        expect(@ticket_order.contact_phone).to eq(@expected_contact_phone),
          "门票联系电话错误。期望: #{@expected_contact_phone}，实际: #{@ticket_order.contact_phone}"
        
        expect(@activity_order.contact_phone).to eq(@expected_contact_phone),
          "活动联系电话错误。期望: #{@expected_contact_phone}，实际: #{@activity_order.contact_phone}"
      end
      
      add_assertion "投保人信息正确（张三）", weight: 5 do
        insured = @insurance_order.insured_persons || []
        expect(insured).to include(@expected_insured_name),
          "投保人列表中缺少#{@expected_insured_name}。期望: [#{@expected_insured_name}]，实际: #{insured.inspect}"
      end
      
      add_assertion "所有订单状态有效", weight: 5 do
        expect(@ticket_order.status).to be_in(['pending', 'paid', 'completed']),
          "门票订单状态无效。期望: pending/paid/completed，实际: #{@ticket_order.status}"
        expect(@activity_order.status).to be_in(['pending', 'paid', 'confirmed', 'completed']),
          "活动订单状态无效。期望: pending/paid/confirmed/completed，实际: #{@activity_order.status}"
        expect(@insurance_order.status).to be_in(['pending', 'paid']),
          "保险订单状态无效。期望: pending/paid，实际: #{@insurance_order.status}"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # ✅ Step 1: 检查门票是否有供应商（模拟用户访问 /tickets/:id/suppliers）
      available_suppliers = TicketSupplier
        .where(ticket_id: @ticket.id, data_version: 0)  # TicketSupplier is baseline data
        .where('stock > 0 OR stock = -1')
      
      if available_suppliers.empty?
        raise "门票『#{@ticket.name}』无供应商，用户无法购买。" \
              "请在数据包中为该门票创建 TicketSupplier 记录。" \
              "参考: app/validators/support/data_packs/v1/seasonal_events.rb"
      end
      
      # ✅ Step 2: 选择最便宜的供应商（模拟用户选择）
      cheapest_supplier = available_suppliers.order(:current_price).first
      
      # ✅ Step 3: 使用供应商价格创建订单（模拟真实业务逻辑）
      ticket_order = TicketOrder.create!(
        user: user,
        ticket: @ticket,
        supplier_id: cheapest_supplier.supplier_id,  # 关联供应商
        visit_date: @visit_date,
        quantity: @quantity,
        contact_phone: @zhangsan.phone,
        total_price: cheapest_supplier.current_price * @quantity,  # 使用供应商价格
        status: 'paid',
        data_version: @data_version
      )
      
      # ✅ Step 4: 创建活动订单（ActivityOrder - 滑雪装备租赁）
      activity_order = ActivityOrder.create!(
        user: user,
        attraction_activity: @activity,
        visit_date: @visit_date,
        quantity: @quantity,
        passenger_name: @zhangsan.name,
        contact_phone: @zhangsan.phone,
        total_price: @activity.current_price * @quantity,
        insurance_type: 'none',  # 不使用活动订单自带的保险
        status: 'paid',
        data_version: @data_version
      )
      
      # ✅ Step 5: 查找合适的保险产品
      if @available_insurances.empty?
        raise "未找到包含滑雪场景的运动保险产品。" \
              "请在数据包中创建 InsuranceProduct，scenes 包含 '滑雪' 或 '户外运动'。"
      end
      
      # ✅ Step 6: 创建保险订单（InsuranceOrder）
      insurance_product = @available_insurances.first
      start_date = @visit_date
      end_date = @visit_date
      days = 1
      unit_price = insurance_product.price_per_day * days
      
      InsuranceOrder.create!(
        user: user,
        insurance_product: insurance_product,
        source: 'standalone',
        related_booking_type: 'ActivityOrder',
        related_booking_id: activity_order.id,
        start_date: start_date,
        end_date: end_date,
        days: days,
        destination: @city,
        destination_type: 'domestic',
        insured_persons: [@zhangsan.name],
        unit_price: unit_price,
        quantity: 1,
        total_price: unit_price,
        status: 'paid',
        data_version: @data_version
      )
    end
    
    private
    
    def execution_state_data
      {
        attraction_name: @attraction_name,
        city: @city,
        visit_date: @visit_date.to_s,
        quantity: @quantity,
        activity_name: @activity_name,
        attraction_id: @attraction&.id,
        ticket_id: @ticket&.id,
        activity_id: @activity&.id,
        expected_contact_phone: @expected_contact_phone,
        expected_insured_name: @expected_insured_name
      }
    end
    
    def restore_from_state(data)
      @attraction_name = data['attraction_name']
      @city = data['city']
      @visit_date = Date.parse(data['visit_date'])
      @quantity = data['quantity']
      @activity_name = data['activity_name']
      @expected_contact_phone = data['expected_contact_phone']
      @expected_insured_name = data['expected_insured_name']
      
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @zhangsan = user.passengers.find_by!(name: '张三', data_version: 0)
      
      @attraction = Attraction.find(data['attraction_id']) if data['attraction_id']
      @ticket = Ticket.find(data['ticket_id']) if data['ticket_id']
      @activity = AttractionActivity.find(data['activity_id']) if data['activity_id']
      
      @available_insurances = InsuranceProduct
        .where(product_type: 'domestic', data_version: 0)
        .select { |p| p.scenes&.include?('滑雪') || p.scenes&.include?('户外运动') }
    end
  end
end
