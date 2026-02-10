# frozen_string_literal: true

require_relative '../base_validator'

# V315: 给张三、李四、刘强、王芳预订长江索道漂流（5天后，4人，含安全保障+装备）
#
# 任务描述:
#   张三、李四、刘强、王芳想5天后去长江索道漂流，需4人，要安全保障和装备提供
#
# 评分标准:
#   - 创建漂流活动订单+景点正确+活动名称 (35%)
#   - 游客信息正确（4人） (10%)
#   - 活动日期和人数正确 (20%)
#   - 联系人信息正确（4人中任意一人） (15%)
#   - 包含保险（安全保障） (15%)
#   - 订单状态和价格有效 (5%)
module V301V350
  class V315BookRaftingAdventureSafetyEquipmentValidator < BaseValidator
    self.validator_id = 'v315_book_rafting_adventure_safety_equipment_validator'
    self.task_id = 'aa4e64f9-e897-40dd-9c3e-c0c7fbcf8a58'
    self.title = '给张三、李四、刘强、王芳预订长江索道漂流（5天后，4人，含安全保障+装备）'
    self.description = '张三、李四、刘强、王芳想5天后去长江索道漂流，需4人，要安全保障和装备提供'
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
      
      {
        task: "请为#{@participant_count}人预订长江索道漂流体验活动（#{@activity_date.strftime('%Y年%m月%d日')}），包含安全保障和全套装备。",
        requirements: {
          attraction: @attraction_name,
          activity_date: @activity_date,
          participant_count: @participant_count,
          services: ['漂流体验', '安全保障', '装备提供', '保险']
        },
        hint: "需要预订长江索道漂流体验活动，并购买保险确保安全。推荐路线：上游出发点→中游激流区→下游观景点。"
      }
    end
    
    def verify
      # 断言1: 创建了漂流活动订单 (20%)
      add_assertion "创建了长江索道漂流活动订单", weight: 20 do
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
      
      # 断言2: 景点正确（长江索道） (10%)
      add_assertion "景点正确（长江索道）", weight: 10 do
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
      
      # 断言4: 漂流活动游客信息正确（张三、李四、刘强、王芳） (10%)
      add_assertion "漂流活动游客信息正确（张三、李四、刘强、王芳）", weight: 10 do
        all_passengers = @rafting_orders.flat_map { |o| o.passengers.to_a }.uniq
        expect(all_passengers.size).to eq(4),
          "漂流游客数量错误。期望: 4人（张三、李四、刘强、王芳），实际: #{all_passengers.size}人"
        
        passenger_names = all_passengers.map(&:name).sort
        expected_names = [@zhangsan.name, @lisi.name, @liuqiang.name, @wangfang.name].sort
        expect(passenger_names).to eq(expected_names),
          "漂流游客信息错误。期望: #{expected_names.join('、')}，实际: #{passenger_names.join('、')}"
      end
      
      # 断言5: 活动日期正确 (10%)
      add_assertion "活动日期正确（#{@activity_date.strftime('%Y-%m-%d')}）", weight: 10 do
        @rafting_orders.each do |order|
          expect(order.visit_date).to eq(@activity_date),
            "漂流活动日期错误。期望: #{@activity_date}（5天后），实际: #{order.visit_date}"
        end
      end
      
      # 断言6: 活动人数正确（4人） (10%)
      add_assertion "活动人数正确（4人）", weight: 10 do
        total_participants = @rafting_orders.sum(&:quantity)
        expect(total_participants).to eq(@participant_count),
          "漂流活动人数错误。期望: #{@participant_count}人，实际: #{total_participants}人"
      end
      
      # 断言7: 联系人信息正确（张三、李四、刘强或王芳） (15%)
      add_assertion "联系人信息正确（张三、李四、刘强或王芳）", weight: 15 do
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
      
      # 断言8: 活动包含保险（安全保障） (15%)
      add_assertion "活动包含保险（安全保障）", weight: 15 do
        @rafting_orders.each do |order|
          insurance_type = order.insurance_type
          expect(insurance_type).not_to eq('none'),
            "漂流活动未购买保险。期望: basic或premium，实际: #{insurance_type}"
        end
      end
      
      # 断言9: 订单状态和价格有效 (5%)
      add_assertion "订单状态和价格有效", weight: 5 do
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
        attraction_activity: @rafting_activity,  # ✅ From data pack (data_version: 0)
        visit_date: @activity_date,
        quantity: @participant_count,
        passenger_ids: [@zhangsan.id, @lisi.id, @liuqiang.id, @wangfang.id],  # ✅ 关联4个游客
        total_price: @rafting_activity.current_price * @participant_count,
        contact_name: contact_person.name,
        contact_phone: contact_person.phone,
        insurance_type: 'premium',  # 水上活动建议购买高级保险
        status: 'paid',
        data_version: @data_version  # ✅ Session-scoped
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
      @rafting_activity = AttractionActivity.find(data['rafting_activity_id']) if data['rafting_activity_id']
    end
  end
end
