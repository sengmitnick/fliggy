# frozen_string_literal: true

require_relative '../base_validator'

# V313: 给张三、李四和刘强预订西湖自行车环湖骑行（5天后，3人，含门票+自行车）
#
# 任务描述:
#   张三、李四和刘强想5天后去杭州西湖骑自行车环湖，需3人，
#   要景区门票和自行车租赁（1辆双人车+1辆单人车）
#
# 评分标准:
#   - 创建了景点门票订单 (14分)
#   - 景点正确（杭州西湖） (9分)
#   - 门票类型正确（成人票） (5分)
#   - 门票游玩日期正确 (7分)
#   - 门票游客信息正确（张三、李四、刘强） (9分)
#   - 门票联系人信息正确 (4分)
#   - 创建了自行车租赁订单 (14分)
#   - 自行车类型正确（双人车+单人车） (9分)
#   - 自行车租赁日期正确 (5分)
#   - 自行车游客信息正确 (9分)
#   - 自行车订单联系人信息正确 (7分)
#   - 自行车租赁景点正确（西湖） (8分)
module V301V350
  class V313BookBicycleTourRoutePlanningLogisticsValidator < BaseValidator
    self.validator_id = 'v313_book_bicycle_tour_route_planning_logistics_validator'
    self.task_id = '808b3eb8-c5d7-43e8-b730-d9d6c79ab5cb'
    self.title = '张三、李四和刘强想5天后去杭州西湖骑自行车环湖，需3人，要景区门票和自行车租赁（1辆双人车+1辆单人车）'
    self.description = '张三、李四和刘强想5天后去杭州西湖骑自行车环湖，需3人，要景区门票和自行车租赁（1辆双人车+1辆单人车）'
    self.timeout_seconds = 300
    
    def prepare
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # Pre-query existing passengers from demo_user (3 adults for bicycle tour)
      @zhangsan = user.passengers.find_by!(name: '张三', data_version: 0)
      @lisi = user.passengers.find_by!(name: '李四', data_version: 0)
      @liuqiang = user.passengers.find_by!(name: '刘强', data_version: 0)
      
      # Expected contact info (multi-choice: 张三、李四 or 刘强)
      @expected_contact_names = [@zhangsan.name, @lisi.name, @liuqiang.name]
      @expected_contact_phones = {
        @zhangsan.name => @zhangsan.phone,
        @lisi.name => @lisi.phone,
        @liuqiang.name => @liuqiang.phone
      }
      
      @visit_date = Date.current + 5.days
      @participant_count = 3
      @city = '杭州'
      @attraction_name = '西湖'
      
      # 查找杭州西湖景点
      @attraction = Attraction
        .where(name: @attraction_name, city: @city, data_version: 0)
        .first!
      
      # 查找西湖游船门票
      @boat_ticket = @attraction.tickets
        .where(name: '西湖游船票', data_version: 0)
        .first!
      
      # 查找自行车租赁活动（优先双人车）
      @bicycle_activity_double = @attraction.attraction_activities
        .where("name LIKE ?", "%双人%自行车%")
        .where(activity_type: 'ride', data_version: 0)
        .first!
      
      # 查找单人自行车租赁
      @bicycle_activity_single = @attraction.attraction_activities
        .where("name LIKE ?", "%单人%自行车%")
        .where(activity_type: 'ride', data_version: 0)
        .first!
      
      {
        task: "请为#{@participant_count}人预订#{@city}#{@attraction_name}的自行车环湖骑行服务（#{@visit_date.strftime('%Y年%m月%d日')}），包含景区门票和自行车租赁。",
        requirements: {
          city: @city,
          attraction: @attraction_name,
          visit_date: @visit_date,
          participant_count: @participant_count,
          services: ['景区门票（游船）', '自行车租赁']
        },
        hint: "需要预订#{@attraction_name}门票（#{@participant_count}张成人票）和自行车租赁（1辆双人车+1辆单人车，共#{@participant_count}人）。推荐路线：断桥→白堤→平湖秋月→苏堤→雷峰塔。"
      }
    end
    
    def verify
      # 断言1: 创建了景点门票订单 (14分)
      add_assertion "创建了景点门票订单（西湖游船票）", weight: 14 do
        all_ticket_orders = TicketOrder
          .joins(ticket: :attraction)
          .includes(:ticket)
          .where(attractions: { name: @attraction_name, city: @city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        expect(all_ticket_orders).not_to be_empty, "未找到#{@attraction_name}门票订单"
        
        @ticket_orders = all_ticket_orders
      end
      
      return if @ticket_orders.nil? || @ticket_orders.empty?
      
      # 断言2: 景点正确（杭州西湖） (9分)
      add_assertion "景点正确（杭州西湖）", weight: 9 do
        @ticket_orders.each do |order|
          expect(order.ticket.attraction.name).to eq(@attraction_name),
            "景点错误。期望: #{@attraction_name}，实际: #{order.ticket.attraction.name}"
          expect(order.ticket.attraction.city).to eq(@city),
            "城市错误。期望: #{@city}，实际: #{order.ticket.attraction.city}"
        end
      end
      
      # 断言3: 门票类型正确（成人票） (5分)
      add_assertion "门票类型正确（成人票）", weight: 5 do
        adult_tickets = @ticket_orders.select { |o| o.ticket.ticket_type == 'adult' }
        expect(adult_tickets.size).to be >= @participant_count,
          "成人票数量不足。期望至少#{@participant_count}张，实际找到#{adult_tickets.size}张"
      end
      
      # 断言4: 门票游玩日期正确 (7分)
      add_assertion "门票游玩日期正确（#{@visit_date.strftime('%Y-%m-%d')}）", weight: 7 do
        @ticket_orders.each do |order|
          expect(order.visit_date).to eq(@visit_date),
            "门票游玩日期错误。期望: #{@visit_date}（5天后），实际: #{order.visit_date}"
        end
      end
      
      # 断言5: 门票游客信息正确（张三、李四、刘强） (9分)
      add_assertion "门票游客信息正确（张三、李四、刘强）", weight: 9 do
        all_passengers = @ticket_orders.flat_map { |o| o.passengers.to_a }.uniq
        expect(all_passengers.size).to eq(3),
          "门票游客数量错误。期望: 3人（张三、李四、刘强），实际: #{all_passengers.size}人"
        
        passenger_names = all_passengers.map(&:name).sort
        expected_names = [@zhangsan.name, @lisi.name, @liuqiang.name].sort
        expect(passenger_names).to eq(expected_names),
          "门票游客信息错误。期望: #{expected_names.join('、')}，实际: #{passenger_names.join('、')}"
      end
      
      # 断言6: 门票联系人信息正确（张三、李四或刘强） (4分)
      add_assertion "门票联系人信息正确（张三、李四或刘强）", weight: 4 do
        @ticket_orders.each do |order|
          if order.respond_to?(:contact_name) && order.contact_name.present?
            expect(@expected_contact_names).to include(order.contact_name),
              "联系人姓名错误。期望: #{@expected_contact_names.join('、')}, 实际: #{order.contact_name}"
            expected_phone = @expected_contact_phones[order.contact_name]
            if expected_phone
              expect(order.contact_phone).to eq(expected_phone),
                "联系电话错误。期望: #{expected_phone}, 实际: #{order.contact_phone}"
            end
          elsif order.contact_phone.present?
            # 如果没有contact_name字段，只验证电话在期望列表中
            expect(@expected_contact_phones.values).to include(order.contact_phone),
              "联系电话错误。期望: #{@expected_contact_phones.values.join('/')}, 实际: #{order.contact_phone}"
          end
        end
      end
      
      # 断言7: 创建了自行车租赁订单 (14分)
      add_assertion "创建了自行车租赁订单", weight: 14 do
        all_activity_orders = ActivityOrder
          .joins(attraction_activity: :attraction)
          .includes(:attraction_activity)
          .where(attractions: { name: @attraction_name, city: @city })
          .where(attraction_activities: { activity_type: 'ride' })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        expect(all_activity_orders).not_to be_empty, "未找到自行车租赁订单"
        
        @bicycle_orders = all_activity_orders
        total_bicycles = @bicycle_orders.sum(&:quantity)
        
        expect(total_bicycles).to be >= 2,
          "自行车数量不足。期望至少2辆（1辆双人车+1辆单人车），实际找到#{total_bicycles}辆"
      end
      
      return if @bicycle_orders.nil? || @bicycle_orders.empty?
      
      # 断言8: 自行车类型正确（双人车+单人车） (9分)
      add_assertion "自行车类型正确（双人车+单人车）", weight: 9 do
        double_bicycles = @bicycle_orders.select { |o| o.attraction_activity.name =~ /双人/ }
        single_bicycles = @bicycle_orders.select { |o| o.attraction_activity.name =~ /单人/ }
        
        expect(double_bicycles.size).to be >= 1,
          "双人自行车数量不足。期望至少1辆，实际找到#{double_bicycles.size}辆"
        expect(single_bicycles.size).to be >= 1,
          "单人自行车数量不足。期望至少1辆，实际找到#{single_bicycles.size}辆"
      end
      
      # 断言9: 自行车租赁日期正确 (5分)
      add_assertion "自行车租赁日期正确（#{@visit_date.strftime('%Y-%m-%d')}）", weight: 5 do
        @bicycle_orders.each do |order|
          expect(order.visit_date).to eq(@visit_date),
            "自行车租赁日期错误。期望: #{@visit_date}（5天后），实际: #{order.visit_date}"
        end
      end
      
      # 断言10: 自行车游客信息正确（张三、李四、刘强） (9分)
      add_assertion "自行车游客信息正确（张三、李四、刘强）", weight: 9 do
        all_passengers = @bicycle_orders.flat_map { |o| o.passengers.to_a }.uniq
        expect(all_passengers.size).to eq(3),
          "自行车游客数量错误。期望: 3人（张三、李四、刘强），实际: #{all_passengers.size}人"
        
        passenger_names = all_passengers.map(&:name).sort
        expected_names = [@zhangsan.name, @lisi.name, @liuqiang.name].sort
        expect(passenger_names).to eq(expected_names),
          "自行车游客信息错误。期望: #{expected_names.join('、')}，实际: #{passenger_names.join('、')}"
      end
      
      # 断言11: 自行车订单联系人信息正确（张三、李四或刘强） (7分)
      add_assertion "自行车订单联系人信息正确（张三、李四或刘强）", weight: 7 do
        @bicycle_orders.each do |order|
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
      
      # 断言12: 自行车租赁景点正确（西湖） (8分)
      add_assertion "自行车租赁景点正确（西湖）", weight: 8 do
        @bicycle_orders.each do |order|
          expect(order.attraction_activity.attraction.name).to eq(@attraction_name),
            "自行车租赁景点错误。期望: #{@attraction_name}，实际: #{order.attraction_activity.attraction.name}"
        end
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # Randomly select one of the three as contact
      contact_passenger = [@zhangsan, @lisi, @liuqiang].sample
      
      # 1. 创建门票订单（1张门票，3个游客）
      TicketOrder.create!(
        user: user,
        ticket: @boat_ticket,
        visit_date: @visit_date,
        quantity: 3,  # 3张门票
        passenger_ids: [@zhangsan.id, @lisi.id, @liuqiang.id],  # ✅ 关联3个游客
        total_price: @boat_ticket.current_price * 3,
        contact_phone: contact_passenger.phone,
        status: 'paid',
        data_version: @data_version
      )
      
      # 2. 创建自行车租赁订单（1辆双人车）
      ActivityOrder.create!(
        user: user,
        attraction_activity: @bicycle_activity_double,
        visit_date: @visit_date,
        quantity: 2,  # 2个座位（双人车）
        passenger_ids: [@zhangsan.id, @lisi.id],  # ✅ 双人车关联2个游客
        total_price: @bicycle_activity_double.current_price * 2,
        passenger_name: contact_passenger.name,
        contact_phone: contact_passenger.phone,
        status: 'paid',
        notes: '双人自行车租赁，2人使用',
        data_version: @data_version
      )
      
      # 3. 创建自行车租赁订单（1辆单人车）
      ActivityOrder.create!(
        user: user,
        attraction_activity: @bicycle_activity_single,
        visit_date: @visit_date,
        quantity: 1,  # 1辆单人车
        passenger_ids: [@liuqiang.id],  # ✅ 单人车关联1个游客
        total_price: @bicycle_activity_single.current_price,
        passenger_name: contact_passenger.name,
        contact_phone: contact_passenger.phone,
        status: 'paid',
        notes: '单人自行车租赁，1人使用',
        data_version: @data_version
      )
    end
    
    private
    
    def execution_state_data
      {
        visit_date: @visit_date.to_s,
        participant_count: @participant_count,
        city: @city,
        attraction_name: @attraction_name,
        attraction_id: @attraction&.id,
        boat_ticket_id: @boat_ticket&.id,
        bicycle_activity_double_id: @bicycle_activity_double&.id,
        bicycle_activity_single_id: @bicycle_activity_single&.id,
        expected_contact_names: @expected_contact_names,
        expected_contact_phones: @expected_contact_phones
      }
    end
    
    def restore_from_state(data)
      @visit_date = Date.parse(data['visit_date'])
      @participant_count = data['participant_count']
      @city = data['city']
      @attraction_name = data['attraction_name']
      @expected_contact_names = data['expected_contact_names']
      @expected_contact_phones = data['expected_contact_phones']
      
      @attraction = Attraction.find(data['attraction_id']) if data['attraction_id']
      @boat_ticket = Ticket.find(data['boat_ticket_id']) if data['boat_ticket_id']
      @bicycle_activity_double = AttractionActivity.find(data['bicycle_activity_double_id']) if data['bicycle_activity_double_id']
      @bicycle_activity_single = AttractionActivity.find(data['bicycle_activity_single_id']) if data['bicycle_activity_single_id']
    end
  end
end
