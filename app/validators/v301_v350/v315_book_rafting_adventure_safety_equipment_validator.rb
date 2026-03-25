# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例315: 预订重庆长江索道漂流活动（张三、李四、刘强、王芳，5天后，4人，安全保障+装备+境内旅游险-进阶款）
#
# 任务描述:
#   张三、李四、刘强、王芳预订重庆长江索道的漂流体验活动。
#   要求：5天后，4人，包含安全保障、装备提供和境内旅游险-进阶款（活动当天，1天）。
#   Agent 需要创建两个订单：
#   1) 景点活动订单（ActivityOrder）- 长江索道漂流活动，4人
#   2) 保险订单（InsuranceOrder）- 境内旅游险-进阶款（PA-DOM-006，7元/天），4人，活动当天1天
#   联系人使用4人中任意一人的信息。
#
# 业务流程（6个关键步骤）：
#   1. 搜索重庆长江索道景点
#   2. 查找漂流活动（名称包含"漂流"）
#   3. 查找境内旅游险-进阶款产品（code: PA-DOM-006，场景包含户外运动）
#   4. 确定活动日期（5天后）和人数（4人）
#   5. 创建漂流活动订单
#   6. 创建境内旅游险-进阶款订单（活动当天，1天）
#
# 复杂度分析（5个关键点）：
#   1. 需要理解漂流活动的服务组合：安全保障+装备+独立保险订单
#   2. 需要创建一个ActivityOrder并正确配置4人的游客信息
#   3. 需要创建一个InsuranceOrder并正确配置4人的被保人信息
#   4. 需要计算正确的活动日期（5天后）
#   5. 需要从4人中选择任意1人作为联系人
#
# 评分标准（13项，总计100%）：
#   - 创建了长江索道漂流活动订单 (15%)
#   - 景点正确（长江索道） (8%)
#   - 活动名称正确（包含'漂流'） (5%)
#   - 漂流活动游客信息正确（张三、李四、刘强、王芳） (8%)
#   - 活动日期正确（5天后） (8%)
#   - 活动人数正确（4人） (6%)
#   - 联系人信息正确（4人中任意一人） (8%)
#   - 创建了保险订单（InsuranceOrder） (10%)
#   - 保险产品正确（境内旅游险-进阶款 PA-DOM-006，场景包含户外运动） (8%)
#   - 保险日期正确（活动当天，1天） (8%)
#   - 保险人数正确（4人） (6%)
#   - 被保人信息正确（张三、李四、刘强、王芳） (5%)
#   - 活动订单状态和价格有效 (5%)
module V301V350
  class V315BookRaftingAdventureSafetyEquipmentValidator < BaseValidator
    self.validator_id = 'v315_book_rafting_adventure_safety_equipment_validator'
    self.task_id = 'aa4e64f9-e897-40dd-9c3e-c0c7fbcf8a58'
    self.title = '预订重庆长江索道漂流活动（张三、李四、刘强、王芳，5天后，4人，安全保障+装备+境内旅游险-进阶款）'
    self.description = '预订重庆长江索道的漂流体验活动，张三、李四、刘强、王芳，5天后，4人，要安全保障、装备提供和境内旅游险-进阶款（活动当天，1天）'
    self.timeout_seconds = 300
    
    def prepare
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # Pre-query existing passengers from demo_user (4 adults for rafting)
      @zhangsan = user.passengers.find_by!(name: '张三', data_version: 0)
      @lisi = user.passengers.find_by!(name: '李四', data_version: 0)
      @liuqiang = user.passengers.find_by!(name: '刘强', data_version: 0)
      @wangfang = user.passengers.find_by!(name: '王芳', data_version: 0)
      
      # Expected contact info (multi-choice: 张三、李四、刘强 or 王芳)
      @expected_contact_names = [@zhangsan.name, @lisi.name, @liuqiang.name, @wangfang.name]
      @expected_contact_phones = {
        @zhangsan.name => @zhangsan.phone,
        @lisi.name => @lisi.phone,
        @liuqiang.name => @liuqiang.phone,
        @wangfang.name => @wangfang.phone
      }
      
      @activity_date = Date.current + 5.days
      @participant_count = 4
      @attraction_name = '长江索道'
      
      # 查找长江索道景点
      @attraction = Attraction
        .where(name: @attraction_name, data_version: 0)
        .first!
      
      # 查找长江索道漂流体验活动
      @rafting_activity = @attraction.attraction_activities
        .where("name LIKE ?", "%漂流%")
        .where(data_version: 0)
        .first!
      
      # 查找境内旅游险-进阶款（code: PA-DOM-006，7元/天，场景包含户外运动）
      @insurance_product = InsuranceProduct
        .where(data_version: 0)
        .where(code: 'PA-DOM-006')
        .first
      
      raise "未找到境内旅游险-进阶款" unless @insurance_product
      
      {
        task: "请为#{@participant_count}人预订重庆长江索道漂流体验活动（#{@activity_date.strftime('%Y年%m月%d日')}），包含安全保障、全套装备和境内旅游险-进阶款（活动当天，1天）。",
        requirements: {
          attraction: @attraction_name,
          activity_date: @activity_date,
          participant_count: @participant_count,
          services: ['漂流体验', '安全保障', '装备提供', '境内旅游险-进阶款']
        },
        hint: "需要预订重庆长江索道漂流体验活动，并购买境内旅游险-进阶款（7元/天，包含户外运动场景）确保安全。推荐路线：上游出发点→中游激流区→下游观景点。"
      }
    end
    
    def verify
      # 断言1: 创建了漂流活动订单 (15%)
      add_assertion "创建了长江索道漂流活动订单", weight: 15 do
        all_activity_orders = ActivityOrder
          .joins(attraction_activity: :attraction)
          .includes(:attraction_activity)
          .where(attractions: { name: @attraction_name })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        expect(all_activity_orders).not_to be_empty, "未找到长江索道的活动订单"
        
        @rafting_orders = all_activity_orders.select { |o| o.attraction_activity.name =~ /漂流/ }
        expect(@rafting_orders).not_to be_empty, "未找到长江索道漂流活动订单"
      end
      
      return if @rafting_orders.nil? || @rafting_orders.empty?
      
      # 断言2: 景点正确（长江索道） (8%)
      add_assertion "景点正确（长江索道）", weight: 8 do
        @rafting_orders.each do |order|
          expect(order.attraction_activity.attraction.name).to eq(@attraction_name),
            "景点错误。期望: #{@attraction_name}，实际: #{order.attraction_activity.attraction.name}"
        end
      end
      
      # 断言3: 活动名称正确（包含"漂流"） (5%)
      add_assertion "活动名称正确（包含'漂流'）", weight: 5 do
        @rafting_orders.each do |order|
          expect(order.attraction_activity.name).to match(/漂流/),
            "活动名称错误。期望包含'漂流'，实际: #{order.attraction_activity.name}"
        end
      end
      
      # 断言4: 漂流活动游客信息正确（张三、李四、刘强、王芳） (8%)
      add_assertion "漂流活动游客信息正确（张三、李四、刘强、王芳）", weight: 8 do
        all_passengers = @rafting_orders.flat_map { |o| o.passengers.to_a }.uniq
        expect(all_passengers.size).to eq(4),
          "漂流游客数量错误。期望: 4人（张三、李四、刘强、王芳），实际: #{all_passengers.size}人"
        
        passenger_names = all_passengers.map(&:name).sort
        expected_names = [@zhangsan.name, @lisi.name, @liuqiang.name, @wangfang.name].sort
        expect(passenger_names).to eq(expected_names),
          "漂流游客信息错误。期望: #{expected_names.join('、')}，实际: #{passenger_names.join('、')}"
      end
      
      # 断言5: 活动日期正确 (8%)
      add_assertion "活动日期正确（#{@activity_date.strftime('%Y-%m-%d')}）", weight: 8 do
        @rafting_orders.each do |order|
          expect(order.visit_date).to eq(@activity_date),
            "漂流活动日期错误。期望: #{@activity_date}（5天后），实际: #{order.visit_date}"
        end
      end
      
      # 断言6: 活动人数正确（4人） (6%)
      add_assertion "活动人数正确（4人）", weight: 6 do
        total_participants = @rafting_orders.sum(&:quantity)
        expect(total_participants).to eq(@participant_count),
          "漂流活动人数错误。期望: #{@participant_count}人，实际: #{total_participants}人"
      end
      
      # 断言7: 联系人信息正确（张三、李四、刘强或王芳） (8%)
      add_assertion "联系人信息正确（张三、李四、刘强或王芳）", weight: 8 do
        @rafting_orders.each do |order|
          if order.respond_to?(:contact_name) && order.contact_name.present?
            expect(@expected_contact_names).to include(order.contact_name),
              "联系人姓名错误。期望: #{@expected_contact_names.join('、')}, 实际: #{order.contact_name}"
            expected_phone = @expected_contact_phones[order.contact_name]
            if expected_phone
              expect(order.contact_phone).to eq(expected_phone),
                "联系电话错误。期望: #{expected_phone}, 实际: #{order.contact_phone}"
            end
          elsif order.respond_to?(:passenger_name) && order.passenger_name.present?
            # 如果是passenger_name字段
            expect(@expected_contact_names).to include(order.passenger_name),
              "乘客姓名错误。期望: #{@expected_contact_names.join('、')}, 实际: #{order.passenger_name}"
          end
          
          if order.contact_phone.present?
            expect(@expected_contact_phones.values).to include(order.contact_phone),
              "联系电话错误。期望: #{@expected_contact_phones.values.join('/')}, 实际: #{order.contact_phone}"
          end
        end
      end
      
      # 断言8: 创建了保险订单（InsuranceOrder） (10%)
      add_assertion "创建了保险订单（InsuranceOrder）", weight: 10 do
        @insurance_orders = InsuranceOrder
          .joins(:insurance_product)
          .includes(:insurance_product)
          .where(insurance_products: { code: 'PA-DOM-006' })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        expect(@insurance_orders).not_to be_empty, "未找到保险订单"
      end
      
      return if @insurance_orders.nil? || @insurance_orders.empty?
      
      # 断言9: 保险产品正确（境内旅游险，场景包含户外运动） (8%)
      add_assertion "保险产品正确（境内旅游险-进阶款，场景包含户外运动）", weight: 8 do
        @insurance_orders.each do |order|
          expect(order.insurance_product.code).to eq('PA-DOM-006'),
            "保险产品错误。期望: 境内旅游险-进阶款 (PA-DOM-006)，实际: #{order.insurance_product.name} (#{order.insurance_product.code})"
          
          expect(order.insurance_product.scenes).to include('户外运动'),
            "保险产品场景不包含户外运动。实际场景: #{order.insurance_product.scenes.join('、')}"
        end
      end
      
      # 断言10: 保险日期正确（活动当天，1天） (8%)
      add_assertion "保险日期正确（#{@activity_date.strftime('%Y-%m-%d')}，1天）", weight: 8 do
        @insurance_orders.each do |order|
          expect(order.start_date).to eq(@activity_date),
            "保险开始日期错误。期望: #{@activity_date}（活动当天），实际: #{order.start_date}"
          
          expect(order.end_date).to eq(@activity_date),
            "保险结束日期错误。期望: #{@activity_date}（活动当天），实际: #{order.end_date}"
          
          expect(order.days).to eq(1),
            "保险天数错误。期望: 1天，实际: #{order.days}天"
        end
      end
      
      # 断言11: 保险人数正确（4人） (6%)
      add_assertion "保险人数正确（4人）", weight: 6 do
        total_insured = @insurance_orders.sum(&:quantity)
        expect(total_insured).to eq(@participant_count),
          "保险人数错误。期望: #{@participant_count}人，实际: #{total_insured}人"
      end
      
      # 断言12: 被保人信息正确（张三、李四、刘强、王芳） (5%)
      add_assertion "被保人信息正确（张三、李四、刘强、王芳）", weight: 5 do
        all_insured = @insurance_orders.flat_map { |o| o.insured_persons || [] }.uniq
        expect(all_insured.size).to eq(4),
          "被保人数量错误。期望: 4人，实际: #{all_insured.size}人"
        
        insured_names = all_insured.map { |p| p['name'] }.compact.sort
        expected_names = [@zhangsan.name, @lisi.name, @liuqiang.name, @wangfang.name].sort
        expect(insured_names).to eq(expected_names),
          "被保人信息错误。期望: #{expected_names.join('、')}，实际: #{insured_names.join('、')}"
      end
      
      # 断言13: 活动订单状态和价格有效 (5%)
      add_assertion "活动订单状态和价格有效", weight: 5 do
        @rafting_orders.each do |order|
          expect(['pending', 'paid', 'confirmed']).to include(order.status),
            "订单状态无效。期望: pending/paid/confirmed，实际: #{order.status}"
          expect(order.total_price).to be > 0,
            "订单价格无效。期望: >0，实际: #{order.total_price}"
        end
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # Randomly select one of the four as contact
      contact_person = [@zhangsan, @lisi, @liuqiang, @wangfang].sample
      
      # 创建漂流体验活动订单（包含安全保障和装备）
      ActivityOrder.create!(
        user: user,
        attraction_activity: @rafting_activity,
        visit_date: @activity_date,
        quantity: @participant_count,
        passenger_ids: [@zhangsan.id, @lisi.id, @liuqiang.id, @wangfang.id],
        total_price: @rafting_activity.current_price * @participant_count,
        passenger_name: contact_person.name,
        contact_phone: contact_person.phone,
        status: 'paid',
        data_version: @data_version
      )
      
      # 创建境内旅游险-进阶款订单（活动当天，1天）
      InsuranceOrder.create!(
        user: user,
        insurance_product: @insurance_product,
        start_date: @activity_date,
        end_date: @activity_date,
        days: 1,
        quantity: @participant_count,
        unit_price: @insurance_product.price_per_day,
        insured_persons: [
          { name: @zhangsan.name, id_card: @zhangsan.id_number },
          { name: @lisi.name, id_card: @lisi.id_number },
          { name: @liuqiang.name, id_card: @liuqiang.id_number },
          { name: @wangfang.name, id_card: @wangfang.id_number }
        ],
        total_price: @insurance_product.price_per_day * @participant_count * 1,
        source: 'standalone',
        status: 'paid',
        data_version: @data_version
      )
    end
    
    private
    
    def execution_state_data
      {
        activity_date: @activity_date.to_s,
        participant_count: @participant_count,
        attraction_name: @attraction_name,
        attraction_id: @attraction&.id,
        rafting_activity_id: @rafting_activity&.id,
        insurance_product_id: @insurance_product&.id,
        expected_contact_names: @expected_contact_names,
        expected_contact_phones: @expected_contact_phones,
        zhangsan_id: @zhangsan&.id,
        lisi_id: @lisi&.id,
        liuqiang_id: @liuqiang&.id,
        wangfang_id: @wangfang&.id
      }
    end
    
    def restore_from_state(data)
      @activity_date = Date.parse(data['activity_date'])
      @participant_count = data['participant_count']
      @attraction_name = data['attraction_name']
      @expected_contact_names = data['expected_contact_names']
      @expected_contact_phones = data['expected_contact_phones']
      
      @attraction = Attraction.find(data['attraction_id']) if data['attraction_id']
      @rafting_activity = AttractionActivity.find(data['rafting_activity_id']) if data['rafting_activity_id']
      @insurance_product = InsuranceProduct.find(data['insurance_product_id']) if data['insurance_product_id']
      
      @zhangsan = Passenger.find(data['zhangsan_id']) if data['zhangsan_id']
      @lisi = Passenger.find(data['lisi_id']) if data['lisi_id']
      @liuqiang = Passenger.find(data['liuqiang_id']) if data['liuqiang_id']
      @wangfang = Passenger.find(data['wangfang_id']) if data['wangfang_id']
    end
  end
end
