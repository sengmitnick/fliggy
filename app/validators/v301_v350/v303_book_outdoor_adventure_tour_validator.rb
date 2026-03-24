# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例303: 刘强10天后要去张家界户外探险，需要预订1天的自由出行（包含徒步登山和露营体验），并购买1天的境内旅游险-进阶款
# 
# 任务描述:
#   刘强是户外运动爱好者，计划10天后到张家界进行户外探险，体验徒步登山和露营。
#   Agent 需要搜索张家界的户外探险主题自由出行产品（一日游），包含专业装备，并购买境内旅游险-进阶款保障，完成1人的预订。
# 
# 业务流程（8个关键步骤）：
#   1. 搜索张家界地区的自由出行产品（一日游）
#   2. 筛选户外探险主题的行程（通过评分和时长判断）
#   3. 选择符合条件的探险产品（评分最高的产品体验更专业）
#   4. 设置出行日期（10天后）
#   5. 搜索境内旅游险-进阶款保险产品
#   6. 创建InsuranceOrder购买保险（户外探险风险高，需要进阶款保险）
#   7. 填写联系人信息（刘强的姓名、电话）
#   8. 创建游客记录（刘强的姓名、身份证号）
# 
# 复杂度分析（8个关键点）：
#   1. 需要理解目的地筛选：张家界地区的自由出行产品
#   2. 需要理解主题匹配：户外探险主题（通过评分≥4.5或时长=1天判断）
#   3. 需要理解保险产品搜索：搜索境内旅游险-进阶款产品
#   4. 需要理解保险订单创建：创建InsuranceOrder关联保险产品和旅游预订
#   5. 需要理解出行日期计算：travel_date=10天后
#   6. 需要理解联系人信息：使用乘客信息中的刘强（姓名、电话）
#   7. 需要理解游客信息：创建BookingTraveler记录（姓名、身份证号）
#   8. 需要理解数据关联：TourGroupBooking关联TourGroupProduct、TourPackage、BookingTraveler，InsuranceOrder关联InsuranceProduct和TourGroupBooking
#   ❌ 不能随机选择：必须精确选择张家界户外探险主题、正确购买境内旅游险-进阶款、正确计算出行日期
# 
# 评分标准（9项，总计100分）：
#   1. 创建了旅游产品预订（15分）
#   2. 目的地为张家界（10分）
#   3. 选择户外探险主题行程且旅游类型正确（20分）- 旅游类型=自由出行、时长=1天、评分≥4.5（核心业务逻辑）
#   4. 出行日期正确（10天后）（10分）
#   5. 联系人信息正确（刘强的姓名、电话）（10分）
#   6. 创建了保险订单（15分）- 户外探险风险高，需要购买保险
#   7. 保险产品为境内旅游险-进阶款（10分）
#   8. 游客信息正确（刘强的姓名、身份证号）（5分）
#   9. 订单状态正确（5分）
# 
# 使用方法:
#   rake validator:simulate_single[v303_book_outdoor_adventure_tour_validator]
#   或访问 http://localhost:<PORT>/api/tasks 获取任务列表
module V301V350
  class V303BookOutdoorAdventureTourValidator < BaseValidator
    self.validator_id = 'v303_book_outdoor_adventure_tour_validator'
    self.task_id = 'd11ffc15-c4d4-478c-a93f-67e8662ba77f'
    self.title = '刘强10天后要去张家界户外探险，需要预订1天的自由出行（包含徒步登山和露营体验），并购买1天的境内旅游险-进阶款'
    self.description = '刘强要去张家界户外探险，需要预订1天的自由出行（包含徒步登山和露营体验），并购买1天的境内旅游险-进阶款'
    self.timeout_seconds = 300
    
    def prepare
      # 数据已通过 load_all_data_packs 自动加载（v1 目录下所有数据包）
      @destination = '张家界'
      @travel_date = Date.current + 10.days  # 10天后出发
      @tour_duration = 1  # 自由出行行程1天（一日游）
      @insurance_duration = 1  # 保险1天
      @travel_type = '自由出行'  # 旅游类型：自由出行（一日游）
      
      # 预查询乘客信息（刘强）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @liuqiang = user.passengers.find_by!(name: '刘强', data_version: 0)
      @expected_contact_name = @liuqiang.name
      @expected_contact_phone = @liuqiang.phone
      @expected_traveler_name = @liuqiang.name
      @expected_id_number = @liuqiang.id_number
      
      # 预查询保险产品（境内旅游险-进阶款）
      @insurance_product = InsuranceProduct.find_by!(
        name: '境内旅游险-进阶款',
        product_type: 'domestic',
        data_version: 0
      )
      @expected_insurance_name = @insurance_product.name
      
      # 确保用户余额充足
      if user.balance < 5000
        user.update!(balance: 8000)
      end
      
      # 返回给 Agent 的任务信息
      {
        task: "刘强10天后要去#{@destination}进行户外探险，需要预订#{@tour_duration}天的自由出行（包含徒步登山和露营体验），并购买#{@insurance_duration}天的境内旅游险-进阶款。#{@travel_date.strftime('%Y年%-m月%-d日')}（10天后）出发，适合户外探险爱好者。重要：由于户外探险风险高，必须购买境内旅游险-进阶款保险产品。",
        requirements: {
          beneficiary: '刘强',
          destination: @destination,
          travel_type: @travel_type,
          theme: '户外探险（徒步登山、露营体验）',
          travel_date: @travel_date.to_s,
          tour_duration: "#{@tour_duration}天",
          insurance_required: "境内旅游险-进阶款（#{@insurance_duration}天）",
          purpose: '户外探险体验'
        },
        hint: "在#{@destination}筛选户外探险主题的自由出行产品（#{@tour_duration}天行程，当天往返）。选择高评分的探险产品。必须购买#{@insurance_duration}天的境内旅游险-进阶款保险产品（户外探险风险高）。联系人和游客信息填写刘强的姓名、电话、身份证号。"
      }
    end
    
    def verify
      # 断言1: 创建了旅游产品预订（15分）
      # 作用: 查询本次会话的旅游产品预订记录，确保预订成功
      # 查询逻辑: 
      #   - 必须包含 data_version: @data_version（会话隔离）
      #   - 通过 joins(:tour_group_product) 关联查询，筛选张家界的自由出行产品
      #   - 按创建时间倒序，获取最新的预订
      add_assertion "创建了旅游产品预订", weight: 15 do
        @tour_booking = TourGroupBooking
          .joins(:tour_group_product)
          .where(tour_group_products: { destination: @destination, travel_type: @travel_type })  # 核心实体过滤
          .where(data_version: @data_version)  # 会话隔离（必须）
          .order(created_at: :desc)
          .first
        expect(@tour_booking).not_to be_nil, "未找到#{@destination}的#{@travel_type}预订"
      end
      
      return unless @tour_booking  # 保护后续断言
      
      # 断言2: 目的地为张家界（10分）
      # 作用: 验证旅游产品的目的地是否正确
      add_assertion "目的地为张家界", weight: 10 do
        expect(@tour_booking.tour_group_product.destination).to eq(@destination),
          "目的地错误。期望: #{@destination}（张家界），实际: #{@tour_booking.tour_group_product.destination}"
      end
      
      # 断言3: 选择户外探险主题行程且旅游类型正确（20分）- 核心业务逻辑
      # 作用: 验证旅游产品是否为户外探险主题、旅游类型和天数正确
      # 验证逻辑:
      #   - 旅游类型必须为"自由出行"（一日游）
      #   - 行程时长为1天
      #   - 户外探险主题通常评分高（≥4.5星）
      add_assertion "选择户外探险主题行程且旅游类型正确（核心要求）", weight: 20 do
        tour = @tour_booking.tour_group_product
        
        # 验证旅游类型
        expect(tour.travel_type).to eq(@travel_type),
          "旅游类型错误。期望: #{@travel_type}（一日游），实际: #{tour.travel_type}"
        
        # 验证行程天数
        expect(tour.duration).to eq(@tour_duration),
          "行程天数错误。期望: #{@tour_duration}天（一日游），实际: #{tour.duration}天"
        
        # 户外探险主题通常评分高
        is_outdoor_tour = tour.rating >= 4.5
        expect(is_outdoor_tour).to be(true),
          "未选择户外探险主题行程。当前行程: #{tour.title}，评分: #{tour.rating}星（要求: 评分≥4.5星）"
      end
      
      # 断言4: 出行日期正确（10天后）（10分）
      # 作用: 验证出行日期是否正确
      add_assertion "出行日期正确（#{@travel_date}）", weight: 10 do
        expect(@tour_booking.travel_date).to eq(@travel_date),
          "出行日期错误。期望: #{@travel_date}（10天后），实际: #{@tour_booking.travel_date}"
      end
      
      # 断言5: 联系人信息正确（刘强的姓名、电话）（10分）
      # 作用: 验证联系人姓名和电话是否正确
      add_assertion "联系人信息正确（#{@expected_contact_name}）", weight: 10 do
        expect(@tour_booking.contact_name).to eq(@expected_contact_name),
          "联系人姓名错误。期望: #{@expected_contact_name}（刘强），实际: #{@tour_booking.contact_name}"
        expect(@tour_booking.contact_phone).to eq(@expected_contact_phone),
          "联系电话错误。期望: #{@expected_contact_phone}（刘强手机号），实际: #{@tour_booking.contact_phone}"
      end
      
      # 断言6: 创建了保险订单（15分）- 户外探险风险高
      # 作用: 验证是否创建了保险订单且天数正确
      # 查询逻辑:
      #   - 必须包含 data_version: @data_version（会话隔离）
      #   - 通过 related_booking 关联查询旅游预订
      #   - 或通过时间范围查询（start_date和end_date与travel_date匹配）
      add_assertion "创建了保险订单", weight: 15 do
        @insurance_order = InsuranceOrder
          .where(data_version: @data_version)
          .where('start_date <= ? AND end_date >= ?', @travel_date, @travel_date)
          .order(created_at: :desc)
          .first
        
        expect(@insurance_order).not_to be_nil,
          "未找到保险订单。户外探险风险高，必须购买保险产品"
        
        # 验证保险天数
        expect(@insurance_order.days).to eq(@insurance_duration),
          "保险天数错误。期望: #{@insurance_duration}天，实际: #{@insurance_order.days}天"
      end
      
      return unless @insurance_order  # 保护后续断言
      
      # 断言7: 保险产品为境内旅游险-进阶款（10分）
      # 作用: 验证保险产品是否为指定的境内旅游险-进阶款
      # 验证逻辑:
      #   - 检查 insurance_product 关联
      #   - 验证产品名称为"境内旅游险-进阶款"
      add_assertion "保险产品为境内旅游险-进阶款", weight: 10 do
        insurance_product = @insurance_order.insurance_product
        expect(insurance_product.name).to eq(@expected_insurance_name),
          "保险产品错误。期望: #{@expected_insurance_name}（户外探险风险高，需要进阶款保险），实际: #{insurance_product&.name || '无'}"
      end
      
      # 断言8: 游客信息正确（刘强的姓名、身份证号）（5分）
      # 作用: 验证BookingTraveler记录中的游客信息是否正确
      # 验证逻辑:
      #   - 查询本次会话的游客记录（data_version: @data_version）
      #   - 验证游客数量为1人
      #   - 验证游客姓名和身份证号
      add_assertion "游客信息正确（#{@expected_traveler_name}）", weight: 5 do
        travelers = @tour_booking.booking_travelers.where(data_version: @data_version).to_a
        
        expect(travelers.size).to eq(1),
          "游客数量不正确。期望: 1个游客（刘强），实际: #{travelers.size}个游客"
        
        traveler = travelers.first
        expect(traveler.traveler_name).to eq(@expected_traveler_name),
          "游客姓名错误。期望: #{@expected_traveler_name}（刘强），实际: #{traveler.traveler_name}"
        
        expect(traveler.id_number).to eq(@expected_id_number),
          "身份证号错误。期望: #{@expected_id_number}（刘强身份证），实际: #{traveler.id_number}"
      end
      
      # 断言9: 订单状态正确（5分）
      # 作用: 验证订单状态是否有效
      add_assertion "订单状态正确", weight: 5 do
        valid_statuses = ['pending', 'confirmed', 'paid']
        expect(valid_statuses).to include(@tour_booking.status),
          "订单状态错误: #{@tour_booking.status}"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      liuqiang = user.passengers.find_by!(name: '刘强', data_version: 0)
      
      # 1. 查询户外探险主题自由出行产品（一日游）
      # 注意: 筛选条件为 destination=张家界, travel_type=自由出行, duration=1天
      tour_product = TourGroupProduct
        .where(destination: @destination, travel_type: @travel_type, duration: @tour_duration, data_version: 0)
        .order(rating: :desc)  # 按评分降序，选择高评分的户外探险产品
        .first!
      
      tour_package = tour_product.tour_packages.first!
      
      # 2. 创建自由出行预订（不使用内置insurance_type）
      booking = TourGroupBooking.create!(
        user_id: user.id,
        tour_group_product_id: tour_product.id,
        tour_package_id: tour_package.id,
        travel_date: @travel_date,
        adult_count: 1,
        child_count: 0,
        contact_name: liuqiang.name,
        contact_phone: liuqiang.phone,
        total_price: tour_package.price,
        status: 'pending',
        insurance_type: 'none',  # 不使用内置保险，改为单独购买InsuranceProduct
        data_version: @data_version
      )
      
      # 3. 创建游客记录（刘强）
      BookingTraveler.create!(
        tour_group_booking_id: booking.id,
        traveler_name: liuqiang.name,
        id_number: liuqiang.id_number,
        traveler_type: 'adult',
        data_version: @data_version
      )
      
      # 4. 搜索境内旅游险-进阶款保险产品
      insurance_product = InsuranceProduct.find_by!(
        name: '境内旅游险-进阶款',
        product_type: 'domestic',
        data_version: 0
      )
      
      # 5. 创建保险订单（明确1天保险）
      InsuranceOrder.create!(
        user_id: user.id,
        insurance_product_id: insurance_product.id,
        related_booking: booking,  # 关联旅游预订
        start_date: @travel_date,
        end_date: @travel_date,  # 1天保险，开始日期=结束日期
        days: @insurance_duration,  # 明确1天
        unit_price: insurance_product.price_per_day,
        quantity: 1,  # 1人
        total_price: insurance_product.price_per_day * @insurance_duration,
        status: 'pending',
        source: 'embedded',  # 随订单购买
        data_version: @data_version
      )
      
      # 自由出行一日游已包含专业装备，无需单独租赁
    end
    
    private
    
    # 保存执行状态数据
    def execution_state_data
      {
        destination: @destination,
        travel_date: @travel_date&.to_s,
        travel_type: @travel_type,
        tour_duration: @tour_duration,
        insurance_duration: @insurance_duration,
        expected_contact_name: @expected_contact_name,
        expected_contact_phone: @expected_contact_phone,
        expected_traveler_name: @expected_traveler_name,
        expected_id_number: @expected_id_number,
        expected_insurance_name: @expected_insurance_name,
        insurance_product_id: @insurance_product&.id
      }
    end
    
    # 恢复执行状态数据
    def restore_from_state(data)
      @destination = data['destination']
      @travel_date = data['travel_date'] ? Date.parse(data['travel_date']) : nil
      @travel_type = data['travel_type']
      @tour_duration = data['tour_duration']
      @insurance_duration = data['insurance_duration']
      @expected_contact_name = data['expected_contact_name']
      @expected_contact_phone = data['expected_contact_phone']
      @expected_traveler_name = data['expected_traveler_name']
      @expected_id_number = data['expected_id_number']
      @expected_insurance_name = data['expected_insurance_name']
      
      # 恢复保险产品对象
      if data['insurance_product_id']
        @insurance_product = InsuranceProduct.find_by(id: data['insurance_product_id'])
      end
    end
  end
end
