# frozen_string_literal: true

require_relative '../base_validator'

# V316: 给刘强和陈静预订八达岭国际马场骑马（7天后，2人，必须保险）
#
# 任务描述:
#   刘强和陈静想7天后去八达岭国际马场骑马，需2人，必须购买骑马运动保险以确保安全
#
# 评分标准:
#   - 创建马术活动订单+景点正确 (25%)
#   - 活动名称正确（马术） (8%)
#   - 活动游客信息正确（刘强+陈静） (10%)
#   - 活动日期正确（7天后） (10%)
#   - 活动人数正确（2人） (8%)
#   - 联系人信息正确（刘强或陈静） (12%)
#   - 购买了保险（安全保障） (10%)
#   - 保险被投保人正确（刘强+陈静） (12%)
#   - 订单状态和价格有效 (5%)
module V301V350
  class V316BookEquestrianExperienceCoachServicesValidator < BaseValidator
    self.validator_id = 'v316_book_equestrian_experience_coach_services_validator'
    self.task_id = '244a3782-51c5-4cc3-a3bd-393309099f3b'
    self.title = '给张三刘强和陈静想7天后去八达岭国际马场骑马，需2人，必须购买骑马运动保险以确保安全'
    self.description = '刘强和陈静想7天后去八达岭国际马场骑马，需2人，必须购买骑马运动保险以确保安全'
    self.timeout_seconds = 300
    
    def prepare
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # Pre-query existing passengers from demo_user (couple for equestrian)
      @liuqiang = user.passengers.find_by!(name: '刘强', data_version: 0)
      @chenjing = user.passengers.find_by!(name: '陈静', data_version: 0)
      
      # Expected contact info (multi-choice: 刘强 or 陈静)
      @expected_contact_names = [@liuqiang.name, @chenjing.name]
      @expected_contact_phones = {
        @liuqiang.name => @liuqiang.phone,
        @chenjing.name => @chenjing.phone
      }
      
      @activity_date = Date.current + 7.days
      @participant_count = 2
      @attraction_name = '八达岭国际马场'
      
      # 查找八达岭国际马场景点
      @attraction = Attraction.find_by!(
        name: @attraction_name,
        data_version: 0
      )
      
      # 查找马术体验课程
      @equestrian_activity = @attraction.attraction_activities
        .where("name LIKE ?", '%马术体验%')
        .where(data_version: 0)
        .first!
      
      {
        task: "请为#{@participant_count}人预订#{@attraction_name}的马术体验课程（#{@activity_date.strftime('%Y年%m月%d日')}）。注意：骑马是高风险运动，必须购买保险以确保安全。",
        requirements: {
          attraction: @attraction_name,
          activity_name: '马术体验课程',
          activity_date: @activity_date,
          participant_count: @participant_count,
          insurance_required: true,
          services: ['专业教练指导', '马场服务', '骑马装备租赁', '运动保险']
        },
        hint: "骑马活动存在风险，强烈建议购买保险。推荐体验：初级马术训练场→草原骑行→照片留念。"
      }
    end
    
    def verify
      # 断言1: 创建了马术活动订单 (15%)
      add_assertion "创建了八达岭国际马场的马术活动订单", weight: 15 do
        all_activity_orders = ActivityOrder
          .joins(attraction_activity: :attraction)
          .includes(:attraction_activity)
          .where(attractions: { name: @attraction_name })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        expect(all_activity_orders).not_to be_empty, "未找到#{@attraction_name}的活动订单"
        
        @equestrian_orders = all_activity_orders.select { |o| o.attraction_activity.name =~ /马术/ }
        expect(@equestrian_orders).not_to be_empty, "未找到马术体验订单"
      end
      
      return if @equestrian_orders.nil? || @equestrian_orders.empty?
      
      # 断言2: 景点正确（八达岭国际马场） (10%)
      add_assertion "景点正确（八达岭国际马场）", weight: 10 do
        @equestrian_orders.each do |order|
          expect(order.attraction_activity.attraction.name).to eq(@attraction_name),
            "景点错误。期望: #{@attraction_name}，实际: #{order.attraction_activity.attraction.name}"
        end
      end
      
      # 断言3: 活动名称正确（包含'马术'） (8%)
      add_assertion "活动名称正确（包含'马术'）", weight: 8 do
        @equestrian_orders.each do |order|
          expect(order.attraction_activity.name).to match(/马术/),
            "活动名称错误。期望包含'马术'，实际: #{order.attraction_activity.name}"
        end
      end
      
      # 断言4: 马术活动游客信息正确（刘强+陈静） (10%)
      add_assertion "马术活动游客信息正确（刘强+陈静）", weight: 10 do
        all_passengers = @equestrian_orders.flat_map { |o| o.passengers.to_a }.uniq
        expect(all_passengers.size).to eq(2),
          "马术活动游客数量错误。期望: 2人（刘强+陈静），实际: #{all_passengers.size}人"
        
        passenger_names = all_passengers.map(&:name).sort
        expected_names = [@liuqiang.name, @chenjing.name].sort
        expect(passenger_names).to eq(expected_names),
          "马术活动游客信息错误。期望: #{expected_names.join('、')}，实际: #{passenger_names.join('、')}"
      end
      
      # 断言5: 活动日期正确（7天后） (10%)
      add_assertion "活动日期正确（#{@activity_date.strftime('%Y-%m-%d')}）", weight: 10 do
        @equestrian_orders.each do |order|
          expect(order.visit_date).to eq(@activity_date),
            "马术活动日期错误。期望: #{@activity_date}（7天后），实际: #{order.visit_date}"
        end
      end
      
      # 断言6: 活动人数正确（2人） (8%)
      add_assertion "活动人数正确（2人）", weight: 8 do
        total_participants = @equestrian_orders.sum(&:quantity)
        expect(total_participants).to eq(@participant_count),
          "马术活动人数错误。期望: #{@participant_count}人，实际: #{total_participants}人"
      end
      
      # 断言7: 联系人信息正确（刘强或陈静） (12%)
      add_assertion "联系人信息正确（刘强或陈静）", weight: 12 do
        @equestrian_orders.each do |order|
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
      
      # 断言8: 马术活动购买了保险（安全保障） (10%)
      add_assertion "马术活动购买了保险（安全保障）", weight: 10 do
        @equestrian_orders.each do |order|
          insurance_type = order.insurance_type
          expect(insurance_type).not_to eq('none'),
            "马术活动未购买保险。期望: basic或premium，实际: #{insurance_type}"
        end
      end
      
      # 断言9: 保险被投保人正确（刘强+陈静） (12%)
      add_assertion "保险被投保人正确（刘强+陈静）", weight: 12 do
        @equestrian_orders.each do |order|
          # 验证购买保险的订单，被投保人（passenger_ids）必须包含刘强和陈静
          if order.insurance_type != 'none'
            insured_passengers = order.passengers.to_a
            expect(insured_passengers.size).to eq(2),
              "保险被投保人数量错误。期望: 2人（刘强+陈静），实际: #{insured_passengers.size}人"
            
            insured_names = insured_passengers.map(&:name).sort
            expected_insured = [@liuqiang.name, @chenjing.name].sort
            expect(insured_names).to eq(expected_insured),
              "保险被投保人信息错误。期望: #{expected_insured.join('、')}，实际: #{insured_names.join('、')}"
          end
        end
      end
      
      # 断言10: 订单状态和价格有效 (5%)
      add_assertion "订单状态和价格有效", weight: 5 do
        @equestrian_orders.each do |order|
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
      
      # 创建马术活动订单（包含教练和马场服务）
      ActivityOrder.create!(
        user: user,
        attraction_activity: @equestrian_activity,  # ✅ From data pack (data_version: 0)
        visit_date: @activity_date,
        quantity: @participant_count,
        passenger_ids: [@liuqiang.id, @chenjing.id],  # ✅ 关联2个游客（同时也是被投保人）
        total_price: @equestrian_activity.current_price * @participant_count,
        contact_name: contact_person.name,
        contact_phone: contact_person.phone,
        insurance_type: 'premium',  # 骑马活动建议购买保险
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
        equestrian_activity_id: @equestrian_activity&.id,
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
      @equestrian_activity = AttractionActivity.find(data['equestrian_activity_id']) if data['equestrian_activity_id']
    end
  end
end