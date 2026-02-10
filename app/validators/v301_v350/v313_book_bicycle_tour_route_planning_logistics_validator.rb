# frozen_string_literal: true

require_relative '../base_validator'

# V313: 给张三、李四和刘强预订西湖自行车环湖骑行（5天后，3人，含门票+自行车）
#
# 任务描述:
#   张三、李四和刘强想5天后去杭州西湖骑自行车环湖，需3人，
#   要景区门票和自行车租赁（1辆双人车+1辆单人车）
#
# 评分标准:
#   - 创建了景点门票订单（35%)
#   - 创建了自行车租赁订单（30%)
#   - 景点和日期正确 (15%)
#   - 联系人信息正确 (10%)
#   - 订单状态和价格有效 (10%)
module V301V350
  class V313BookBicycleTourRoutePlanningLogisticsValidator < BaseValidator
    self.validator_id = 'v313_book_bicycle_tour_route_planning_logistics_validator'
    self.task_id = '808b3eb8-c5d7-43e8-b730-d9d6c79ab5cb'
    self.title = '给张三、李四和刘强预订西湖自行车环湖骑行（5天后，3人，含门票+自行车）'
    self.description = '张三、李四和刘强想5天后去杭州西湖骑自行车环湖，需3人，要景区门票和自行车租赁（1辆双人车+1辆单人车）'
    self.timeout_seconds = 300
    
    def prepare
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # Pre-query existing passengers from demo_user (3 adults for bicycle tour)
      @zhangsan = user.passengers.find_by!(name: '张三', data_version: 0)
      @lisi = user.passengers.find_by!(name: '李四', data_version: 0)
      @liuqiang = user.passengers.find_by!(name: '刘强', data_version: 0)
      
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
      add_assertion "创建了景区门票订单（西湖游船票）", weight: 35 do
        all_ticket_orders = TicketOrder
          .joins(ticket: :attraction)
          .includes(:ticket)
          .where(attractions: { name: @attraction_name, city: @city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        expect(all_ticket_orders).not_to be_empty, "未找到#{@attraction_name}门票订单"
        
        @ticket_orders = all_ticket_orders.select { |o| o.ticket.ticket_type == 'adult' }
        expect(@ticket_orders.size).to be >= @participant_count,
          "门票数量不足。期望至少#{@participant_count}张，实际找到#{@ticket_orders.size}张"
      end
      
      return if @ticket_orders.nil? || @ticket_orders.empty?
      
      add_assertion "创建了自行车租赁订单", weight: 30 do
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
      
      add_assertion "景点和游玩日期正确", weight: 15 do
        @ticket_orders.each do |order|
          expect(order.ticket.attraction.name).to eq(@attraction_name),
            "景点错误。期望: #{@attraction_name}，实际: #{order.ticket.attraction.name}"
          
          expect(order.visit_date).to eq(@visit_date),
            "门票游玩日期错误。期望: #{@visit_date}（5天后），实际: #{order.visit_date}"
        end
        
        if @bicycle_orders
          @bicycle_orders.each do |order|
            expect(order.attraction_activity.attraction.name).to eq(@attraction_name),
              "自行车租赁景点错误。期望: #{@attraction_name}，实际: #{order.attraction_activity.attraction.name}"
            
            expect(order.visit_date).to eq(@visit_date),
              "自行车租赁日期错误。期望: #{@visit_date}（5天后），实际: #{order.visit_date}"
          end
        end
      end
      
      add_assertion "联系人信息正确（张三/李四/刘强）", weight: 10 do
        expected_phones = [@zhangsan.phone, @lisi.phone, @liuqiang.phone]
        expected_names = [@zhangsan.name, @lisi.name, @liuqiang.name]
        
        @ticket_orders.each do |order|
          expect(order.contact_phone).to be_in(expected_phones),
            "门票订单联系电话错误。期望: #{expected_phones.join('/')}，实际: #{order.contact_phone}"
        end
        
        if @bicycle_orders
          @bicycle_orders.each do |order|
            expect(order.contact_phone).to be_in(expected_phones),
              "自行车订单联系电话错误。期望: #{expected_phones.join('/')}，实际: #{order.contact_phone}"
            expect(order.passenger_name).to be_in(expected_names),
              "乘客姓名错误。期望: #{expected_names.join('/')}，实际: #{order.passenger_name}"
          end
        end
      end
      
      add_assertion "订单状态和价格有效", weight: 10 do
        @ticket_orders.each do |order|
          expect(order.status).to be_in(['pending', 'paid', 'confirmed']),
            "门票订单状态异常: #{order.status}"
          expect(order.total_price).to be > 0,
            "门票订单价格无效: #{order.total_price}"
        end
        
        if @bicycle_orders
          @bicycle_orders.each do |order|
            expect(order.status).to be_in(['pending', 'paid', 'confirmed']),
              "自行车租赁订单状态异常: #{order.status}"
            expect(order.total_price).to be > 0,
              "自行车租赁订单价格无效: #{order.total_price}"
          end
        end
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 1. 创建门票订单（3张成人票）
      contact_passenger = [@zhangsan, @lisi, @liuqiang].sample
      @participant_count.times do
        TicketOrder.create!(
          user: user,
          ticket: @boat_ticket,
          visit_date: @visit_date,
          quantity: 1,
          total_price: @boat_ticket.current_price,
          contact_phone: contact_passenger.phone,
          passenger_id: user.id,
          passenger_ids: [user.id],
          status: 'paid',
          data_version: @data_version
        )
      end
      
      # 2. 创建自行车租赁订单（1辆双人车）
      ActivityOrder.create!(
        user: user,
        attraction_activity: @bicycle_activity_double,
        visit_date: @visit_date,
        quantity: 1,  # 1辆双人车
        total_price: @bicycle_activity_double.current_price,
        passenger_name: contact_passenger.name,
        contact_phone: contact_passenger.phone,
        passenger_ids: [user.id],
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
        total_price: @bicycle_activity_single.current_price,
        passenger_name: contact_passenger.name,
        contact_phone: contact_passenger.phone,
        passenger_ids: [user.id],
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
        zhangsan_name: @zhangsan&.name,
        zhangsan_phone: @zhangsan&.phone,
        lisi_name: @lisi&.name,
        lisi_phone: @lisi&.phone,
        liuqiang_name: @liuqiang&.name,
        liuqiang_phone: @liuqiang&.phone
      }
    end
    
    def restore_from_state(data)
      @visit_date = Date.parse(data['visit_date'])
      @participant_count = data['participant_count']
      @city = data['city']
      @attraction_name = data['attraction_name']
      
      @attraction = Attraction.find(data['attraction_id']) if data['attraction_id']
      @boat_ticket = Ticket.find(data['boat_ticket_id']) if data['boat_ticket_id']
      @bicycle_activity_double = AttractionActivity.find(data['bicycle_activity_double_id']) if data['bicycle_activity_double_id']
      @bicycle_activity_single = AttractionActivity.find(data['bicycle_activity_single_id']) if data['bicycle_activity_single_id']
      
      if data['zhangsan_name']
        @zhangsan = OpenStruct.new(name: data['zhangsan_name'], phone: data['zhangsan_phone'])
      end
      if data['lisi_name']
        @lisi = OpenStruct.new(name: data['lisi_name'], phone: data['lisi_phone'])
      end
      if data['liuqiang_name']
        @liuqiang = OpenStruct.new(name: data['liuqiang_name'], phone: data['liuqiang_phone'])
      end
    end
  end
end
