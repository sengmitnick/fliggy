# frozen_string_literal: true

require_relative '../base_validator'

# V309: 预订北京故宫博物院文化之旅+文化深度游路线包车游（张三、李四、刘强、王芳，5天后，4人，舒适7座，8小时）
#
# 任务描述:
#   张三、李四、刘强、王芳预订北京故宫博物院文化之旅的深度旅行+服务。
#   要求：5天后，4人，包含金牌导游讲解、北京包车游服务（舒适7座，8小时）。
#   Agent 需要创建两个订单：
#   1) 深度旅行+订单（DeepTravelBooking）- 北京故宫博物院文化之旅（导游讲解）
#   2) 包车游订单（CharterBooking）- 北京文化深度游路线（舒适7座，8小时）
#   联系人使用张三、李四、刘强或王芳的信息。
#
# 业务流程（7个关键步骤）：
#   1. 搜索北京故宫博物院文化之旅产品（深度旅行+）
#   2. 验证产品包含金牌导游和故宫讲解服务
#   3. 搜索北京包车游路线（文化深度游）
#   4. 选择舒适7座车型（适合4人），8小时服务时长
#   5. 确定服务日期（5天后）和人数（4人成人）
#   6. 创建深度旅行+订单（故宫文化之旅）
#   7. 创建包车游订单（北京文化深度游，同一天）
#
# 复杂度分析（6个关键点）：
#   1. 需要理解深度旅行+的服务组合：金牌导游+故宫讲解+包车游
#   2. 需要创建两种不同类型的订单（DeepTravelBooking + CharterBooking）
#   3. 需要计算正确的服务日期（5天后）
#   4. 需要选择demo用户的4位乘客中的任意一位作为联系人
#   5. 需要确保两个订单的日期、人数、联系人一致
#   6. 需要验证每个订单的状态和价格有效性
#
# 评分标准（7项，总计100分）：
#   - 创建了深度旅行+订单（故宫文化之旅） (20%)
#   - 地点正确（北京） (10%)
#   - 创建了包车游订单（文化深度游路线） (25%)
#   - 包车车型正确（舒适7座） (15%)
#   - 服务时长正确（8小时） (10%)
#   - 服务日期正确（5天后） (10%)
#   - 联系人信息正确（张三、李四、刘强或王芳） (10%)
module V301V350
  class V309BookLocalGuideCarCommentaryValidator < BaseValidator
    self.validator_id = 'v309_book_local_guide_car_commentary_validator'
    self.task_id = 'f4d35905-7889-4569-8f32-a0b6c76a7873'
    self.title = '预订北京故宫博物院文化之旅+文化深度游路线包车游（张三、李四、刘强、王芳，5天后，4人，舒适7座，8小时）'
    self.description = '预订北京故宫博物院文化之旅的深度旅行+服务，张三、李四、刘强、王芳，5天后，4人，要金牌导游讲解和北京包车游服务（舒适7座，8小时）'
    self.timeout_seconds = 300
    
    def prepare
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # Pre-query existing passengers from demo_user (4 adults for deep travel)
      @zhangsan = user.passengers.find_by!(name: '张三', data_version: 0)
      @lisi = user.passengers.find_by!(name: '李四', data_version: 0)
      @liuqiang = user.passengers.find_by!(name: '刘强', data_version: 0)
      @wangfang = user.passengers.find_by!(name: '王芳', data_version: 0)
      
      # Expected contact info (any of the 4 travelers can be contact)
      @expected_contact_names = [@zhangsan.name, @lisi.name, @liuqiang.name, @wangfang.name]
      @expected_contact_phones = {
        @zhangsan.name => @zhangsan.phone,
        @lisi.name => @lisi.phone,
        @liuqiang.name => @liuqiang.phone,
        @wangfang.name => @wangfang.phone
      }
      @expected_id_numbers = {
        @zhangsan.name => @zhangsan.id_number,
        @lisi.name => @lisi.id_number,
        @liuqiang.name => @liuqiang.id_number,
        @wangfang.name => @wangfang.id_number
      }
      
      @travel_date = Date.current + 5.days
      @participant_count = 4
      @location = '北京'
      
      @product_name = '北京故宫博物院文化之旅'
      
      # 查找北京故宫博物院文化之旅产品
      @deep_travel_product = DeepTravelProduct
        .joins(:deep_travel_guide)
        .where(location: @location, data_version: 0)
        .where('deep_travel_products.title LIKE ?', '%故宫博物院文化之旅%')
        .first
      
      @deep_travel_product ||= DeepTravelProduct
        .joins(:deep_travel_guide)
        .where(location: @location, data_version: 0)
        .where('deep_travel_products.title LIKE ?', '%故宫%')
        .first
      
      raise "未找到#{@location}#{@product_name}产品" unless @deep_travel_product
      
      @guide = @deep_travel_product.deep_travel_guide
      
      # 查找包车游路线（北京文化深度游）
      @charter_route_keyword = '文化深度游'
      @charter_route = CharterRoute
        .joins(:city)
        .where('cities.name = ?', @location)
        .where('charter_routes.name LIKE ?', "%#{@charter_route_keyword}%")
        .where(data_version: 0)
        .first
      
      raise "未找到#{@location}#{@charter_route_keyword}包车路线" unless @charter_route
      
      # 查找包车车型（舒适7座）
      @vehicle_type_name = '舒适7座'
      @duration_hours = 8
      @vehicle_type = VehicleType.find_by(name: @vehicle_type_name, data_version: 0)
      raise "未找到#{@vehicle_type_name}车型" unless @vehicle_type
      
      {
        task: "请预订#{@location}的『#{@product_name}』深度旅行+服务（5天后的#{@travel_date.strftime('%Y年%m月%d日')}，#{@participant_count}人），并预订#{@location}包车游服务（#{@charter_route_keyword}路线，#{@vehicle_type_name}，#{@duration_hours}小时）。",
        requirements: {
          location: @location,
          product_name: @product_name,
          travel_date: @travel_date,
          participant_count: @participant_count,
          services: ['金牌导游', '故宫讲解', "#{@location}包车游（#{@vehicle_type_name}，#{@duration_hours}小时）"]
        },
        hint: "需要预订『北京故宫博物院文化之旅』深度旅行+产品和北京包车游服务（文化深度游路线，舒适7座，8小时）。"
      }
    end
    
    def verify
      add_assertion "创建了深度旅行+订单（故宫文化之旅）", weight: 20 do
        @deep_travel_booking = DeepTravelBooking
          .joins(:deep_travel_product)
          .where(data_version: @data_version)
          .first
        
        expect(@deep_travel_booking).not_to be_nil, "未找到深度旅行+订单"
      end
      
      return if @deep_travel_booking.nil?
      
      add_assertion "地点正确（#{@location}）", weight: 10 do
        expect(@deep_travel_booking.deep_travel_product.location).to eq(@location),
          "地点错误。期望: #{@location}，实际: #{@deep_travel_booking.deep_travel_product.location}"
      end
      
      add_assertion "创建了包车游订单（文化深度游路线）", weight: 25 do
        @charter_booking = CharterBooking
          .joins(charter_route: :city)
          .where('cities.name = ?', @location)
          .where('charter_routes.name LIKE ?', "%#{@charter_route_keyword}%")
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@charter_booking).not_to be_nil, "未找到包车游订单"
      end
      
      return if @charter_booking.nil?
      
      add_assertion "包车车型正确（#{@vehicle_type_name}）", weight: 15 do
        expect(@charter_booking.vehicle_type.name).to eq(@vehicle_type_name),
          "车型错误。期望: #{@vehicle_type_name}，实际: #{@charter_booking.vehicle_type.name}"
      end
      
      add_assertion "服务时长正确（#{@duration_hours}小时）", weight: 10 do
        expect(@charter_booking.duration_hours).to eq(@duration_hours),
          "服务时长错误。期望: #{@duration_hours}小时，实际: #{@charter_booking.duration_hours}小时"
      end
      
      add_assertion "服务日期正确（5天后）", weight: 10 do
        expect(@deep_travel_booking.travel_date).to eq(@travel_date),
          "深度旅行+日期错误。期望: #{@travel_date}（5天后），实际: #{@deep_travel_booking.travel_date}"
        
        expect(@charter_booking.departure_date).to eq(@travel_date),
          "包车游日期错误。期望: #{@travel_date}（5天后），实际: #{@charter_booking.departure_date}"
      end
      
      add_assertion "联系人信息正确（张三、李四、刘强或王芳）", weight: 10 do
        expect(@expected_contact_names).to include(@deep_travel_booking.contact_name),
          "深度旅行+联系人姓名错误。期望: #{@expected_contact_names.join('、')}中的一个, 实际: #{@deep_travel_booking.contact_name}"
        expected_phone = @expected_contact_phones[@deep_travel_booking.contact_name]
        expect(@deep_travel_booking.contact_phone).to eq(expected_phone),
          "深度旅行+联系电话错误。期望: #{expected_phone}（#{@deep_travel_booking.contact_name}）, 实际: #{@deep_travel_booking.contact_phone}"
        
        expect(@expected_contact_names).to include(@charter_booking.contact_name),
          "包车游联系人姓名错误。期望: #{@expected_contact_names.join('、')}中的一个, 实际: #{@charter_booking.contact_name}"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 随机选择一位作为联系人
      contact_person = [@zhangsan, @lisi, @liuqiang, @wangfang].sample
      
      # 1. 创建深度旅行+订单（故宫文化之旅）- Use randomly selected contact
      DeepTravelBooking.create!(
        user: user,
        deep_travel_guide: @guide,
        deep_travel_product: @deep_travel_product,
        travel_date: @travel_date,
        adult_count: @participant_count,
        child_count: 0,
        contact_name: contact_person.name,
        contact_phone: contact_person.phone,
        total_price: @deep_travel_product.price,
        insurance_price: 0,
        status: 'paid',
        data_version: @data_version
      )
      
      # 2. 创建包车游订单（北京文化深度游路线）- Use randomly selected contact
      charter_price = CharterPriceCalculatorService.call(
        route: @charter_route,
        vehicle_type: @vehicle_type,
        duration_hours: @duration_hours,
        departure_date: @travel_date
      )
      
      CharterBooking.create!(
        user_id: user.id,
        charter_route_id: @charter_route.id,
        vehicle_type_id: @vehicle_type.id,
        departure_date: @travel_date,
        departure_time: '09:00',
        duration_hours: @duration_hours,
        booking_mode: 'by_route',
        passengers_count: @participant_count,
        contact_name: contact_person.name,
        contact_phone: contact_person.phone,
        total_price: charter_price,
        status: 'pending',
        data_version: @data_version
      )
    end
    
    private
    
    def execution_state_data
      {
        travel_date: @travel_date.to_s,
        participant_count: @participant_count,
        location: @location,
        product_name: @product_name,
        deep_travel_product_id: @deep_travel_product&.id,
        guide_id: @guide&.id,
        charter_route_id: @charter_route&.id,
        charter_route_keyword: @charter_route_keyword,
        vehicle_type_id: @vehicle_type&.id,
        vehicle_type_name: @vehicle_type_name,
        duration_hours: @duration_hours,
        expected_contact_names: @expected_contact_names,
        expected_contact_phones: @expected_contact_phones,
        expected_id_numbers: @expected_id_numbers
      }
    end
    
    def restore_from_state(data)
      @travel_date = Date.parse(data['travel_date'])
      @participant_count = data['participant_count']
      @location = data['location']
      @product_name = data['product_name']
      @charter_route_keyword = data['charter_route_keyword']
      @vehicle_type_name = data['vehicle_type_name']
      @duration_hours = data['duration_hours']
      @expected_contact_names = data['expected_contact_names']
      @expected_contact_phones = data['expected_contact_phones']
      @expected_id_numbers = data['expected_id_numbers']
      
      @deep_travel_product = DeepTravelProduct.find(data['deep_travel_product_id']) if data['deep_travel_product_id']
      @guide = DeepTravelGuide.find(data['guide_id']) if data['guide_id']
      @charter_route = CharterRoute.find(data['charter_route_id']) if data['charter_route_id']
      @vehicle_type = VehicleType.find(data['vehicle_type_id']) if data['vehicle_type_id']
    end
  end
end
