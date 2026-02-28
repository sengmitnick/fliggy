# frozen_string_literal: true

require_relative '../base_validator'

# V314: 给刘强和陈静预订华山攀岩（6天后，2人，含教学+装备+教练+保险）
#
# 任务描述:
#   刘强和陈静想6天后去华山攀岩，需2人，要专业教学、安全装备、教练陪同和保险保障
#
# 评分标准:
#   - 创建攀岩活动订单+景点正确 (30%)
#   - 活动名称正确（攀岩）+游客信息 (15%)
#   - 活动日期正确 (15%)
#   - 活动人数正确（2人） (10%)
#   - 联系人信息正确（刘强或陈静） (15%)
#   - 包含保险（安全保障） (10%)
#   - 订单状态和价格有效 (5%)
module V301V350
  class V314BookRockClimbingLessonEquipmentCoachValidator < BaseValidator
    self.validator_id = 'v314_book_rock_climbing_lesson_equipment_coach_validator'
    self.task_id = '58118f22-f2ac-492b-bf85-a73a4786c8aa'
    self.title = '给张三刘强和陈静想6天后去华山攀岩，需2人，要专业教学、安全装备、教练陪同和保险保障'
    self.description = '刘强和陈静想6天后去华山攀岩，需2人，要专业教学、安全装备、教练陪同和保险保障'
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
      
      {
        task: "请为#{@participant_count}人预订华山攀岩服务（#{@activity_date.strftime('%Y年%m月%d日')}），包含专业教学、安全装备、教练陪同和保险。",
        requirements: {
          attraction: @attraction_name,
          activity_date: @activity_date,
          participant_count: @participant_count,
          services: ['攀岩教学', '安全装备', '教练陪同', '保险']
        },
        hint: "需要预订华山攀岩活动，并购买保险确保安全。推荐路线：东峰→南峰天然岩壁区。"
      }
    end
    
    def verify
      # 断言1: 创建了攀岩活动订单 (20%)
      add_assertion "创建了华山攀岩活动订单", weight: 20 do
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
      
      # 断言2: 景点正确（华山） (10%)
      add_assertion "景点正确（华山）", weight: 10 do
        @climbing_orders.each do |order|
          expect(order.attraction_activity.attraction.name).to eq(@attraction_name),
            "景点错误。期望: #{@attraction_name}，实际: #{order.attraction_activity.attraction.name}"
        end
      end
      
      # 断言3: 活动名称正确（包含'攀岩'） (8%)
      add_assertion "活动名称正确（包含'攀岩'）", weight: 8 do
        @climbing_orders.each do |order|
          expect(order.attraction_activity.name).to match(/攀岩/),
            "活动名称错误。期望包含'攀岩'，实际: #{order.attraction_activity.name}"
        end
      end
      
      # 断言4: 攀岩活动游客信息正确（刘强+陈静） (7%)
      add_assertion "攀岩活动游客信息正确（刘强+陈静）", weight: 7 do
        all_passengers = @climbing_orders.flat_map { |o| o.passengers.to_a }.uniq
        expect(all_passengers.size).to eq(2),
          "攀岩游客数量错误。期望: 2人（刘强+陈静），实际: #{all_passengers.size}人"
        
        passenger_names = all_passengers.map(&:name).sort
        expected_names = [@liuqiang.name, @chenjing.name].sort
        expect(passenger_names).to eq(expected_names),
          "攀岩游客信息错误。期望: #{expected_names.join('、')}，实际: #{passenger_names.join('、')}"
      end
      
      # 断言5: 活动日期正确 (15%)
      add_assertion "活动日期正确（#{@activity_date.strftime('%Y-%m-%d')}）", weight: 15 do
        @climbing_orders.each do |order|
          expect(order.visit_date).to eq(@activity_date),
            "攀岩活动日期错误。期望: #{@activity_date}（6天后），实际: #{order.visit_date}"
        end
      end
      
      # 断言6: 活动人数正确（2人） (10%)
      add_assertion "活动人数正确（2人）", weight: 10 do
        total_participants = @climbing_orders.sum(&:quantity)
        expect(total_participants).to eq(@participant_count),
          "攀岩活动人数错误。期望: #{@participant_count}人，实际: #{total_participants}人"
      end
      
      # 断言7: 联系人信息正确（刘强或陈静） (15%)
      add_assertion "联系人信息正确（刘强或陈静）", weight: 15 do
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
      
      # 断言8: 活动包含保险（安全保障） (10%)
      add_assertion "活动包含保险（安全保障）", weight: 10 do
        @climbing_orders.each do |order|
          insurance_type = order.insurance_type
          expect(insurance_type).not_to eq('none'),
            "攀岩活动未购买保险。期望: basic或premium，实际: #{insurance_type}"
        end
      end
      
      # 断言9: 订单状态和价格有效 (5%)
      add_assertion "订单状态和价格有效", weight: 5 do
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
        insurance_type: 'premium',
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
    end
  end
end