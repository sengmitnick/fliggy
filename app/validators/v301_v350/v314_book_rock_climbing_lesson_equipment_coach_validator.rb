# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例314: 预订西安华山攀岩活动+购买境内旅游险（刘强、陈静，6天后，2人，教学+装备+教练+保险）
#
# 任务描述:
#   刘强和陈静预订华山的攀岩活动，并购买境内旅游险。
#   要求：6天后，2人，包含专业教学、安全装备、教练陪同，并购买1天境内旅游险（活动当天）。
#   Agent 需要创建两个订单：
#   1) 景点活动订单（ActivityOrder）- 华山攀岩活动，2人
#   2) 保险订单（InsuranceOrder）- 境内旅游险-进阶款，2人，1天（活动当天）
#   联系人使用刘强或陈静的信息。
#
# 业务流程（6个关键步骤）：
#   1. 搜索华山景点
#   2. 查找攀岩活动（名称包含"攀岩"）
#   3. 搜索境内旅游险产品（场景包含"户外运动"）
#   4. 确定活动日期（6天后）和人数（2人）
#   5. 创建攀岩活动订单（ActivityOrder）
#   6. 创建保险订单（InsuranceOrder），保障日期为活动当天
#
# 复杂度分析（5个关键点）：
#   1. 需要理解攀岩活动需要配套购买旅游保险
#   2. 需要创建两个独立订单：ActivityOrder + InsuranceOrder
#   3. 需要查找适合攀岩场景的保险产品（境内旅游险，场景包含户外运动）
#   4. 需要计算正确的活动日期和保险日期（6天后，1天保障）
#   5. 需要选择demo用户的乘客（刘强或陈静）作为联系人和被保人
#
# 评分标准（14项，总计100%）：
#   - 创建了华山攀岩活动订单 (15%)
#   - 景点正确（华山） (6%)
#   - 活动名称正确（包含'攀岩'） (5%)
#   - 攀岩活动游客信息正确（刘强+陈静） (6%)
#   - 活动日期正确（6天后） (8%)
#   - 活动人数正确（2人） (6%)
#   - 联系人信息正确（刘强或陈静） (8%)
#   - 创建了保险订单（InsuranceOrder） (12%)
#   - 保险产品正确（境内旅游险-进阶款，场景包含户外运动） (10%)
#   - 保险日期正确（活动当天，1天） (8%)
#   - 保险人数正确（2人） (6%)
#   - 被保人信息正确（刘强+陈静） (5%)
#   - 保险订单状态正确（paid） (3%)
#   - 活动订单状态和价格有效 (2%)
module V301V350
  class V314BookRockClimbingLessonEquipmentCoachValidator < BaseValidator
    self.validator_id = 'v314_book_rock_climbing_lesson_equipment_coach_validator'
    self.task_id = '58118f22-f2ac-492b-bf85-a73a4786c8aa'
    self.title = '预订西安华山攀岩活动+购买境内旅游险（刘强、陈静，6天后，2人，教学+装备+教练+保险）'
    self.description = '预订华山的攀岩活动，刘强和陈静，6天后，2人，要专业教学、安全装备、教练陪同，并购买境内旅游险（活动当天）'
    self.timeout_seconds = 300
    
    def prepare
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # Pre-query existing passengers from demo_user (couple for rock climbing)
      @liuqiang = user.passengers.find_by!(name: '刘强', data_version: 0)
      @chenjing = user.passengers.find_by!(name: '陈静', data_version: 0)
      
      # Expected contact info (multi-choice: 刘强 or 陈静)
      @expected_contact_names = [@liuqiang.name, @chenjing.name]
      @expected_contact_phones = {
        @liuqiang.name => @liuqiang.phone,
        @chenjing.name => @chenjing.phone
      }
      
      @activity_date = Date.current + 6.days
      @participant_count = 2
      @attraction_name = '华山'
      
      # 查找华山景点
      @attraction = Attraction
        .where(name: @attraction_name, data_version: 0)
        .first!
      
      # 查找华山攀岩活动（攀岩教学+安全装备+教练陪同）
      @climbing_activity = @attraction.attraction_activities
        .where("name LIKE ?", "%攀岩%")
        .where(data_version: 0)
        .first!
      
      # 查找境内旅游险-进阶款（code: PA-DOM-006，7元/天，场景包含户外运动）
      @insurance_product = InsuranceProduct
        .where(data_version: 0)
        .where(code: 'PA-DOM-006')
        .first
      
      raise "未找到境内旅游险-进阶款" unless @insurance_product
      
      {
        task: "请为#{@participant_count}人预订华山攀岩服务（#{@activity_date.strftime('%Y年%m月%d日')}），包含专业教学、安全装备、教练陪同，并购买境内旅游险（活动当天）。",
        requirements: {
          attraction: @attraction_name,
          activity_date: @activity_date,
          participant_count: @participant_count,
          services: ['攀岩教学', '安全装备', '教练陪同', '境内旅游险']
        },
        hint: "需要预订华山攀岩活动，并购买境内旅游险确保安全。推荐路线：东峰→南峰天然岩壁区。"
      }
    end
    
    def verify
      # 断言1: 创建了攀岩活动订单 (15%)
      add_assertion "创建了华山攀岩活动订单", weight: 15 do
        all_activity_orders = ActivityOrder
          .joins(attraction_activity: :attraction)
          .includes(:attraction_activity)
          .where(attractions: { name: @attraction_name })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        expect(all_activity_orders).not_to be_empty, "未找到华山的活动订单"
        
        @climbing_orders = all_activity_orders.select { |o| o.attraction_activity.name =~ /攀岩/ }
        expect(@climbing_orders).not_to be_empty, "未找到华山攀岩活动订单"
      end
      
      return if @climbing_orders.nil? || @climbing_orders.empty?
      
      # 断言2: 景点正确（华山） (6%)
      add_assertion "景点正确（华山）", weight: 6 do
        @climbing_orders.each do |order|
          expect(order.attraction_activity.attraction.name).to eq(@attraction_name),
            "景点错误。期望: #{@attraction_name}，实际: #{order.attraction_activity.attraction.name}"
        end
      end
      
      # 断言3: 活动名称正确（包含'攀岩'） (5%)
      add_assertion "活动名称正确（包含'攀岩'）", weight: 5 do
        @climbing_orders.each do |order|
          expect(order.attraction_activity.name).to match(/攀岩/),
            "活动名称错误。期望包含'攀岩'，实际: #{order.attraction_activity.name}"
        end
      end
      
      # 断言4: 攀岩活动游客信息正确（刘强+陈静） (6%)
      add_assertion "攀岩活动游客信息正确（刘强+陈静）", weight: 6 do
        all_passengers = @climbing_orders.flat_map { |o| o.passengers.to_a }.uniq
        expect(all_passengers.size).to eq(2),
          "攀岩游客数量错误。期望: 2人（刘强+陈静），实际: #{all_passengers.size}人"
        
        passenger_names = all_passengers.map { |p| p.respond_to?(:name) ? p.name : p }.compact.sort
        expected_names = [@liuqiang.name, @chenjing.name].sort
        expect(passenger_names).to eq(expected_names),
          "攀岩游客信息错误。期望: #{expected_names.join('、')}，实际: #{passenger_names.join('、')}"
      end
      
      # 断言5: 活动日期正确 (8%)
      add_assertion "活动日期正确（#{@activity_date.strftime('%Y-%m-%d')}）", weight: 8 do
        @climbing_orders.each do |order|
          expect(order.visit_date).to eq(@activity_date),
            "攀岩活动日期错误。期望: #{@activity_date}（6天后），实际: #{order.visit_date}"
        end
      end
      
      # 断言6: 活动人数正确（2人） (6%)
      add_assertion "活动人数正确（2人）", weight: 6 do
        total_participants = @climbing_orders.sum(&:quantity)
        expect(total_participants).to eq(@participant_count),
          "攀岩活动人数错误。期望: #{@participant_count}人，实际: #{total_participants}人"
      end
      
      # 断言7: 联系人信息正确（刘强或陈静） (8%)
      add_assertion "联系人信息正确（刘强或陈静）", weight: 8 do
        @climbing_orders.each do |order|
          if order.respond_to?(:contact_name) && order.contact_name.present?
            expect(@expected_contact_names).to include(order.contact_name),
              "联系人姓名错误。期望: #{@expected_contact_names.join('或')}, 实际: #{order.contact_name}"
            expected_phone = @expected_contact_phones[order.contact_name]
            if expected_phone
              expect(order.contact_phone).to eq(expected_phone),
                "联系电话错误。期望: #{expected_phone}, 实际: #{order.contact_phone}"
            end
          elsif order.respond_to?(:passenger_name) && order.passenger_name.present?
            # 如果是passenger_name字段
            expect(@expected_contact_names).to include(order.passenger_name),
              "乘客姓名错误。期望: #{@expected_contact_names.join('或')}, 实际: #{order.passenger_name}"
          end
          
          if order.contact_phone.present?
            expect(@expected_contact_phones.values).to include(order.contact_phone),
              "联系电话错误。期望: #{@expected_contact_phones.values.join('/')}, 实际: #{order.contact_phone}"
          end
        end
      end
      
      # 断言8: 创建了保险订单（InsuranceOrder） (12%)
      add_assertion "创建了保险订单（InsuranceOrder）", weight: 12 do
        @insurance_orders = InsuranceOrder
          .joins(:insurance_product)
          .includes(:insurance_product)
          .where(insurance_products: { name: @insurance_product.name })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        expect(@insurance_orders).not_to be_empty, "未找到保险订单"
      end
      
      return if @insurance_orders.nil? || @insurance_orders.empty?
      
      # 断言9: 保险产品正确（境内旅游险-进阶款，场景包含户外运动） (10%)
      add_assertion "保险产品正确（境内旅游险-进阶款，场景包含户外运动）", weight: 10 do
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
      
      # 断言11: 保险人数正确（2人） (6%)
      add_assertion "保险人数正确（2人）", weight: 6 do
        total_insured = @insurance_orders.sum(&:quantity)
        expect(total_insured).to eq(@participant_count),
          "保险人数错误。期望: #{@participant_count}人，实际: #{total_insured}人"
      end
      
      # 断言12: 被保人信息正确（刘强+陈静） (5%)
      add_assertion "被保人信息正确（刘强+陈静）", weight: 5 do
        all_insured = @insurance_orders.flat_map { |o| o.insured_persons || [] }.uniq
        expect(all_insured.size).to eq(2),
          "被保人数量错误。期望: 2人，实际: #{all_insured.size}人"
        
        insured_names = all_insured.map { |p| p['name'] }.compact.sort
        expected_names = [@liuqiang.name, @chenjing.name].sort
        expect(insured_names).to eq(expected_names),
          "被保人信息错误。期望: #{expected_names.join('、')}，实际: #{insured_names.join('、')}"
      end
      
      # 断言13: 保险订单状态正确（paid） (3%)
      add_assertion "保险订单状态正确（paid）", weight: 3 do
        @insurance_orders.each do |order|
          expect(order.status).to eq('paid'),
            "保险订单状态错误。期望: paid，实际: #{order.status}"
        end
      end
      
      # 断言14: 活动订单状态和价格有效 (2%)
      add_assertion "活动订单状态和价格有效", weight: 2 do
        @climbing_orders.each do |order|
          expect(['pending', 'paid', 'confirmed']).to include(order.status),
            "订单状态无效。期望: pending/paid/confirmed，实际: #{order.status}"
          expect(order.total_price).to be > 0,
            "订单价格无效。期望: >0，实际: #{order.total_price}"
        end
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # Randomly select one of the couple as contact
      contact_person = [@liuqiang, @chenjing].sample
      
      # 创建攀岩活动订单（包含教学、装备、教练）
      ActivityOrder.create!(
        user: user,
        attraction_activity: @climbing_activity,
        visit_date: @activity_date,
        quantity: @participant_count,
        passenger_ids: [@liuqiang.id, @chenjing.id],
        total_price: @climbing_activity.current_price * @participant_count,
        passenger_name: contact_person.name,
        contact_phone: contact_person.phone,
        status: 'paid',
        data_version: @data_version
      )
      
      # 创建境内旅游险订单（活动当天，1天）
      InsuranceOrder.create!(
        user: user,
        insurance_product: @insurance_product,
        start_date: @activity_date,
        end_date: @activity_date,
        days: 1,
        quantity: @participant_count,
        unit_price: @insurance_product.price_per_day,
        insured_persons: [
          { name: @liuqiang.name, id_card: @liuqiang.id_number },
          { name: @chenjing.name, id_card: @chenjing.id_number }
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
        climbing_activity_id: @climbing_activity&.id,
        insurance_product_id: @insurance_product&.id,
        expected_contact_names: @expected_contact_names,
        expected_contact_phones: @expected_contact_phones
      }
    end
    
    def restore_from_state(data)
      @activity_date = Date.parse(data['activity_date'])
      @participant_count = data['participant_count']
      @attraction_name = data['attraction_name']
      @expected_contact_names = data['expected_contact_names']
      @expected_contact_phones = data['expected_contact_phones']
      
      @attraction = Attraction.find(data['attraction_id']) if data['attraction_id']
      @climbing_activity = AttractionActivity.find(data['climbing_activity_id']) if data['climbing_activity_id']
      @insurance_product = InsuranceProduct.find(data['insurance_product_id']) if data['insurance_product_id']
      
      # Restore passenger objects for use in verify assertions
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @liuqiang = user.passengers.find_by!(name: '刘强', data_version: 0)
      @chenjing = user.passengers.find_by!(name: '陈静', data_version: 0)
    end
  end
end
