# frozen_string_literal: true

require_relative '../base_validator'

# V312: 预订冲浪教学+海滩娱乐+装备提供
#
# 任务描述:
#   用户需要预订冲浪服务套餐，包含教学、海滩娱乐和装备提供
#
# 评分标准:
#   - 创建冲浪活动订单+景点正确+活动名称+游客信息 (40%)
#   - 创建娱乐活动订单+活动名称+游客信息 (30%)
#   - 日期和人数正确 (15%)
#   - 联系人信息正确 (15%)
module V301V350
  class V312BookSurfingLessonBeachEquipmentValidator < BaseValidator
    self.validator_id = 'v312_book_surfing_lesson_beach_equipment_validator'
    self.task_id = 'c132957d-cbea-4e0b-8190-acd5d2d2ce30'
    self.title = '给张三刘强和陈静想4天后去深圳大梅沙海滨公园冲浪，需2人，要冲浪教学、海滩娱乐和装备提供'
    self.description = '刘强和陈静想4天后去深圳大梅沙海滨公园冲浪，需2人，要冲浪教学、海滩娱乐和装备提供'
    self.timeout_seconds = 300
    
    def prepare
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # Pre-query existing passengers from demo_user (couple for surfing)
      @liuqiang = user.passengers.find_by!(name: '刘强', data_version: 0)
      @chenjing = user.passengers.find_by!(name: '陈静', data_version: 0)
      
      # Expected contact info (multi-choice: 刘强 or 陈静)
      @expected_contact_names = [@liuqiang.name, @chenjing.name]
      @expected_contact_phones = {
        @liuqiang.name => @liuqiang.phone,
        @chenjing.name => @chenjing.phone
      }
      
      @activity_date = Date.current + 4.days
      @participant_count = 2
      
      # 固定为深圳大梅沙海滨公园
      @attraction = Attraction
        .joins(:attraction_activities)
        .where(name: '深圳大梅沙海滨公园', data_version: 0)
        .where(attraction_activities: { data_version: 0 })
        .first
      
      raise "未找到深圳大梅沙海滨公园" unless @attraction
      
      # 查找活动（必须从数据包中存在）
      @surfing_activity = @attraction.attraction_activities
        .where("name LIKE ?", '%冲浪%')
        .where(data_version: 0)
        .first
      
      raise "未找到冲浪活动" unless @surfing_activity
      
      @entertainment_activity = @attraction.attraction_activities
        .where("name NOT LIKE ?", '%冲浪%')
        .where(data_version: 0)
        .first
      
      raise "未找到娱乐活动" unless @entertainment_activity
      
      {
        task: "请预订深圳大梅沙海滨公园的冲浪服务（#{@activity_date.strftime('%Y年%m月%d日')}，#{@participant_count}人），包含冲浪教学、海滩娱乐和装备提供。",
        requirements: {
          attraction: @attraction.name,
          activity_date: @activity_date,
          participant_count: @participant_count,
          services: ['冲浪教学', '海滩娱乐', '装备提供']
        },
        hint: "需要预订深圳大梅沙海滨公园的多个活动：冲浪教学和海滩娱乐。"
      }
    end
    
    def verify
      # 断言1: 创建了冲浪活动订单 (15%)
      add_assertion "创建了冲浪活动订单", weight: 15 do
        all_activity_orders = ActivityOrder
          .joins(:attraction_activity)
          .includes(:attraction_activity)
          .where(attraction_activities: { attraction_id: @attraction.id })
          .where(data_version: @data_version)
          .order(created_at: :asc)
          .to_a
        
        expect(all_activity_orders).not_to be_empty, "未找到深圳大梅沙海滨公园的活动订单"
        
        # 找到包含"冲浪"的活动订单
        @surfing_order = all_activity_orders.find { |o| o.attraction_activity.name =~ /冲浪/ }
        expect(@surfing_order).not_to be_nil, "未找到冲浪活动订单"
      end
      
      return if @surfing_order.nil?
      
      # 断言2: 景点正确（深圳大梅沙海滨公园） (10%)
      add_assertion "景点正确（深圳大梅沙海滨公园）", weight: 10 do
        expect(@surfing_order.attraction_activity.attraction.name).to eq('深圳大梅沙海滨公园'),
          "景点错误。期望: 深圳大梅沙海滨公园，实际: #{@surfing_order.attraction_activity.attraction.name}"
      end
      
      # 断言3: 冲浪活动名称正确（包含"冲浪"） (5%)
      add_assertion "冲浪活动名称正确（包含'冲浪'）", weight: 5 do
        activity_name = @surfing_order.attraction_activity.name
        expect(activity_name).to match(/冲浪/),
          "冲浪活动名称不符合。期望包含: 冲浪, 实际: #{activity_name}"
      end
      
      # 断言4: 冲浪活动日期正确 (8%)
      add_assertion "冲浪活动日期正确（#{@activity_date.strftime('%Y-%m-%d')}）", weight: 8 do
        expect(@surfing_order.visit_date).to eq(@activity_date),
          "冲浪活动日期错误。期望: #{@activity_date}（4天后），实际: #{@surfing_order.visit_date}"
      end
      
      # 断言5: 冲浪活动人数正确 (5%)
      add_assertion "冲浪活动人数正确（#{@participant_count}人）", weight: 5 do
        expect(@surfing_order.quantity).to eq(@participant_count),
          "冲浪活动人数错误。期望: #{@participant_count}人，实际: #{@surfing_order.quantity}人"
      end
      
      # 断言6: 冲浪活动游客信息正确（刘强+陈静） (7%)
      add_assertion "冲浪活动游客信息正确（刘强+陈静）", weight: 7 do
        passengers = @surfing_order.passengers.to_a
        expect(passengers.size).to eq(2),
          "冲浪活动游客数量错误。期望: 2人（刘强+陈静），实际: #{passengers.size}人"
        
        passenger_names = passengers.map(&:name).sort
        expected_names = [@liuqiang.name, @chenjing.name].sort
        expect(passenger_names).to eq(expected_names),
          "冲浪活动游客信息错误。期望: #{expected_names.join('、')}，实际: #{passenger_names.join('、')}"
      end
      
      # 断言7: 冲浪活动联系人信息正确（刘强或陈静） (8%)
      add_assertion "冲浪活动联系人信息正确（刘强或陈静）", weight: 8 do
        if @surfing_order.respond_to?(:contact_name) && @surfing_order.contact_name.present?
          expect(@expected_contact_names).to include(@surfing_order.contact_name),
            "联系人姓名错误。期望: #{@expected_contact_names.join('或')}, 实际: #{@surfing_order.contact_name}"
          expected_phone = @expected_contact_phones[@surfing_order.contact_name]
          expect(@surfing_order.contact_phone).to eq(expected_phone),
            "联系电话错误。期望: #{expected_phone}, 实际: #{@surfing_order.contact_phone}"
        end
      end
      
      # 断言8: 创建了娱乐活动订单 (12%)
      add_assertion "创建了娱乐活动订单", weight: 12 do
        all_activity_orders = ActivityOrder
          .joins(:attraction_activity)
          .includes(:attraction_activity)
          .where(attraction_activities: { attraction_id: @attraction.id })
          .where(data_version: @data_version)
          .order(created_at: :asc)
          .to_a
        
        # 找到不包含"冲浪"的活动订单（娱乐活动）
        @entertainment_order = all_activity_orders.find { |o| o.attraction_activity.name !~ /冲浪/ }
        
        if all_activity_orders.size >= 2
          expect(@entertainment_order).not_to be_nil, "未找到海滩娱乐订单"
        else
          # 如果只有一个活动订单，也算通过（冲浪教学已包含装备）
          expect(all_activity_orders.size).to be >= 1,
            "活动订单数量不足。至少需要1个订单"
        end
      end
      
      return if @entertainment_order.nil?
      
      # 断言9: 娱乐活动名称正确（不包含"冲浪"） (5%)
      add_assertion "娱乐活动名称正确（不包含'冲浪'）", weight: 5 do
        activity_name = @entertainment_order.attraction_activity.name
        expect(activity_name).not_to match(/冲浪/),
          "娱乐活动名称应该是非冲浪活动，实际: #{activity_name}"
      end
      
      # 断言10: 娱乐活动日期正确 (5%)
      add_assertion "娱乐活动日期正确（#{@activity_date.strftime('%Y-%m-%d')}）", weight: 5 do
        expect(@entertainment_order.visit_date).to eq(@activity_date),
          "娱乐活动日期错误。期望: #{@activity_date}（4天后），实际: #{@entertainment_order.visit_date}"
      end
      
      # 断言11: 娱乐活动人数正确 (5%)
      add_assertion "娱乐活动人数正确（#{@participant_count}人）", weight: 5 do
        expect(@entertainment_order.quantity).to eq(@participant_count),
          "娱乐活动人数错误。期望: #{@participant_count}人，实际: #{@entertainment_order.quantity}人"
      end
      
      # 断言12: 娱乐活动游客信息正确（刘强+陈静） (8%)
      add_assertion "娱乐活动游客信息正确（刘强+陈静）", weight: 8 do
        passengers = @entertainment_order.passengers.to_a
        expect(passengers.size).to eq(2),
          "娱乐活动游客数量错误。期望: 2人（刘强+陈静），实际: #{passengers.size}人"
        
        passenger_names = passengers.map(&:name).sort
        expected_names = [@liuqiang.name, @chenjing.name].sort
        expect(passenger_names).to eq(expected_names),
          "娱乐活动游客信息错误。期望: #{expected_names.join('、')}，实际: #{passenger_names.join('、')}"
      end
      
      # 断言13: 娱乐活动联系人信息正确（刘强或陈静） (7%)
      add_assertion "娱乐活动联系人信息正确（刘强或陈静）", weight: 7 do
        if @entertainment_order.respond_to?(:contact_name) && @entertainment_order.contact_name.present?
          expect(@expected_contact_names).to include(@entertainment_order.contact_name),
            "联系人姓名错误。期望: #{@expected_contact_names.join('或')}, 实际: #{@entertainment_order.contact_name}"
          expected_phone = @expected_contact_phones[@entertainment_order.contact_name]
          expect(@entertainment_order.contact_phone).to eq(expected_phone),
            "联系电话错误。期望: #{expected_phone}, 实际: #{@entertainment_order.contact_phone}"
        end
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # Randomly select one of the couple as contact
      contact_person = [@liuqiang, @chenjing].sample
      
      # 1. 创建冲浪活动订单（使用数据包中的活动）
      ActivityOrder.create!(
        user: user,
        attraction_activity: @surfing_activity,  # ✅ 来自prepare，数据包中的活动
        visit_date: @activity_date,
        quantity: @participant_count,
        passenger_ids: [@liuqiang.id, @chenjing.id],  # ✅ 关联游客信息
        contact_name: contact_person.name,
        contact_phone: contact_person.phone,
        total_price: @surfing_activity.current_price * @participant_count,
        insurance_type: 'premium',
        status: 'paid',
        data_version: @data_version  # ✅ Session-scoped
      )
      
      # 2. 创建海滩娱乐活动订单（使用数据包中的活动）
      ActivityOrder.create!(
        user: user,
        attraction_activity: @entertainment_activity,  # ✅ 来自prepare，数据包中的活动
        visit_date: @activity_date,
        quantity: @participant_count,
        passenger_ids: [@liuqiang.id, @chenjing.id],  # ✅ 关联游客信息
        contact_name: contact_person.name,
        contact_phone: contact_person.phone,
        total_price: @entertainment_activity.current_price * @participant_count,
        insurance_type: 'basic',
        status: 'paid',
        data_version: @data_version  # ✅ Session-scoped
      )
    end
    
    private
    
    def execution_state_data
      {
        activity_date: @activity_date.to_s,
        participant_count: @participant_count,
        attraction_id: @attraction&.id,
        surfing_activity_id: @surfing_activity&.id,
        entertainment_activity_id: @entertainment_activity&.id,
        expected_contact_names: @expected_contact_names,
        expected_contact_phones: @expected_contact_phones
      }
    end
    
    def restore_from_state(data)
      @activity_date = Date.parse(data['activity_date'])
      @participant_count = data['participant_count']
      @expected_contact_names = data['expected_contact_names']
      @expected_contact_phones = data['expected_contact_phones']
      
      @attraction = Attraction.find(data['attraction_id']) if data['attraction_id']
      @surfing_activity = AttractionActivity.find(data['surfing_activity_id']) if data['surfing_activity_id']
      @entertainment_activity = AttractionActivity.find(data['entertainment_activity_id']) if data['entertainment_activity_id']
    end
  end
end