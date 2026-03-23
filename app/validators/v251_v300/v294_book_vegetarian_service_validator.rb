# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例294: 素食主义者张三预订8天后成都3天2晚跟团游，并预订配备早餐设施的酒店（住2晚）
#
# 任务描述:
#   张三是素食主义者，需要预订8天后去成都的3天2晚跟团游，
#   要求酒店配备早餐设施，以便享用素食早餐。
#   Agent需要创建跟团游订单并配套预订提供早餐的酒店。
#
# 业务流程（6个关键步骤）：
#   1. 明确受益人信息（张三，使用其姓名、电话作为联系人）
#   2. 搜索目的地是成都的3天2晚跟团游产品
#   3. 创建跟团游预订（使用真实存在的路线）
#   4. 筛选配备早餐设施的酒店（facilities包含"早餐"或"餐厅"）
#   5. 优先选择评分最高的酒店
#   6. 创建酒店订单（入住日期=出行日期，住2晚）
#
# 复杂度分析（5个关键点）：
#   1. 需要理解素食主义者的餐饮需求，明确筛选条件（酒店配备早餐设施）
#   2. 需要同时创建跟团游订单和酒店订单（两个订单关联）
#   3. 需要在配备早餐的酒店中选择最优选项（评分最高）
#   4. 需要确保跟团游和酒店的日期一致性
#   5. 需要使用真实存在的路线（目的地是成都，3天2晚）
#   ❌ 不能选择不提供早餐的酒店，必须严格满足素食餐饮要求
#
# 评分标准（10项，总计100分）：
#   1. 创建了跟团游预订（15分）
#   2. 目的地正确（成都）（10分）
#   3. 天数正确（3天2晚）（10分）
#   4. 创建了酒店预订（15分）
#   5. 酒店配备早餐设施（20分）- 核心业务逻辑
#   6. 酒店入住时长正确（2晚）（10分）
#   7. 入住人信息正确（张三）（5分）
#   8. 联系人信息正确（张三）（5分）
#   9. 出行日期正确（8天后）（5分）
#   10. 订单状态正确（5分）
#
# 使用方法:
#   rake validator:simulate_single[v294]
#   或访问 http://localhost:<PORT>/api/tasks 获取任务列表
#
module V251V300
  class V294BookVegetarianServiceValidator < BaseValidator
    self.validator_id = 'v294_book_vegetarian_service_validator'
    self.task_id = 'cd8e4f2a-3b5c-4d1e-9f7a-8b6c5d4e3f2a'
    self.title = '素食主义者张三预订8天后成都3天2晚跟团游，并预订配备早餐设施的酒店（住2晚）'
    self.description = '张三是素食主义者，预订8天后去成都的3天2晚跟团游，并预订提供早餐的酒店'
    self.timeout_seconds = 300
    
    def prepare
      @destination = '成都'
      @travel_date = Date.current + 8.days
      @duration = 3
      @nights = 2
      
      # 预查询受益人信息（张三）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @zhangsan = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_contact_name = @zhangsan.name
      @expected_contact_phone = @zhangsan.phone
      
      # 确保用户余额充足
      if user.balance < 3000
        user.update!(balance: 5000)
      end
      
      # 查找配备早餐设施的酒店
      @available_hotels = Hotel.where(data_version: 0)
        .select { |h| h.facilities.to_s.match?(/早餐|餐厅|免费早餐/i) }
        .sort_by { |h| -h.rating.to_f }
      
      raise "未找到配备早餐设施的酒店" if @available_hotels.empty?
      
      {
        task: "请为张三预订#{@travel_date.strftime('%Y年%m月%d日')}（8天后）去#{@destination}的#{@duration}天#{@nights}晚跟团游，需要配备早餐的酒店。张三是素食主义者，需要早餐方便素食。",
        requirements: {
          beneficiary: '张三',
          destination: @destination,
          travel_date: @travel_date.to_s,
          duration: "#{@duration}天#{@nights}晚",
          hotel_requirement: '必须配备早餐（设施包含早餐或餐厅）',
          dietary_preference: '素食主义者',
          tour_type: '跟团游',
          adults: 1,
          children: 0
        },
        hint: "创建目的地是#{@destination}的#{@duration}天#{@nights}晚跟团游预订，并筛选配备早餐设施的酒店（facilities包含'早餐'或'餐厅'），优先选择评分最高的酒店。",
        statistics: {
          available_hotels_with_breakfast: @available_hotels.count,
          top_hotel: @available_hotels.first&.name,
          hotel_rating_range: {
            min: @available_hotels.map(&:rating).compact.min,
            max: @available_hotels.map(&:rating).compact.max
          },
          travel_date: @travel_date.to_s
        }
      }
    end
    
    def verify
      # 断言1: 创建了跟团游预订（15分）
      add_assertion "创建了跟团游预订", weight: 15 do
        @tour_booking = TourGroupBooking
          .joins(:tour_group_product)
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        expect(@tour_booking).not_to be_nil, "未找到跟团游预订"
      end
      
      return unless @tour_booking
      
      # 断言2: 目的地正确（成都）（10分）
      add_assertion "目的地正确（#{@destination}）", weight: 10 do
        expect(@tour_booking.tour_group_product.destination).to eq(@destination),
          "目的地错误。期望: #{@destination}, 实际: #{@tour_booking.tour_group_product.destination}"
      end
      
      # 断言3: 天数正确（4天3晚）（10分）
      add_assertion "天数正确（#{@duration}天#{@nights}晚）", weight: 10 do
        expect(@tour_booking.tour_group_product.duration).to eq(@duration),
          "天数错误。期望: #{@duration}天, 实际: #{@tour_booking.tour_group_product.duration}天"
      end
      
      # 断言4: 创建了酒店预订（15分）
      add_assertion "创建了酒店预订", weight: 15 do
        @hotel_booking = HotelBooking
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        expect(@hotel_booking).not_to be_nil, "未找到酒店预订"
      end
      
      return unless @hotel_booking
      
      # 断言5: 酒店配备早餐设施（20分）- 核心业务逻辑
      add_assertion "酒店配备早餐设施（核心要求）", weight: 20 do
        hotel = @hotel_booking.hotel
        expect(hotel.facilities).to be_present, "酒店未配置设施信息"
        
        has_breakfast = hotel.facilities.to_s.match?(/早餐|餐厅|免费早餐/i)
        expect(has_breakfast).to be(true), 
          "酒店未配备早餐设施。酒店: #{hotel.name}, 当前设施: #{hotel.facilities}"
      end
      
      # 断言6: 酒店入住时长正确（3晚）（10分）
      add_assertion "酒店入住时长正确（#{@nights}晚）", weight: 10 do
        actual_nights = (@hotel_booking.check_out_date - @hotel_booking.check_in_date).to_i
        expect(actual_nights).to eq(@nights),
          "入住时长错误。期望: #{@nights}晚（跟团游#{@duration}天#{@nights}晚），实际: #{actual_nights}晚"
      end
      
      # 断言7: 入住人信息正确（张三）（5分）
      add_assertion "入住人信息正确（张三）", weight: 5 do
        expect(@hotel_booking.guest_name).to eq(@expected_contact_name),
          "入住人姓名错误。期望: #{@expected_contact_name}（张三），实际: #{@hotel_booking.guest_name}"
        expect(@hotel_booking.guest_phone).to eq(@expected_contact_phone),
          "入住人电话错误。期望: #{@expected_contact_phone}, 实际: #{@hotel_booking.guest_phone}"
      end
      
      # 断言8: 联系人信息正确（张三）（5分）
      add_assertion "联系人信息正确（张三）", weight: 5 do
        expect(@tour_booking.contact_name).to eq(@expected_contact_name),
          "联系人姓名错误。期望: #{@expected_contact_name}, 实际: #{@tour_booking.contact_name}"
        expect(@tour_booking.contact_phone).to eq(@expected_contact_phone),
          "联系电话错误。期望: #{@expected_contact_phone}, 实际: #{@tour_booking.contact_phone}"
      end
      
      # 断言9: 出行日期正确（8天后）（5分）
      add_assertion "出行日期正确（#{@travel_date.strftime('%m月%d日')}）", weight: 5 do
        expect(@tour_booking.travel_date).to eq(@travel_date),
          "出行日期错误。期望: #{@travel_date}（8天后）, 实际: #{@tour_booking.travel_date}"
      end
      
      # 断言10: 订单状态正确（5分）
      add_assertion "订单状态正确", weight: 5 do
        valid_tour_statuses = ['pending', 'confirmed', 'paid']
        valid_hotel_statuses = ['pending', 'confirmed', 'paid']
        
        expect(valid_tour_statuses).to include(@tour_booking.status),
          "跟团游订单状态无效: #{@tour_booking.status}"
        expect(valid_hotel_statuses).to include(@hotel_booking.status),
          "酒店订单状态无效: #{@hotel_booking.status}"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      zhangsan = user.passengers.find_by!(name: '张三', data_version: 0)
      
      # 1. 预订跟团游（目的地是成都）
      tour_product = TourGroupProduct.where(
        destination: @destination,
        duration: @duration,
        data_version: 0
      ).order(rating: :desc).first!
      
      tour_package = tour_product.tour_packages.first!
      
      TourGroupBooking.create!(
        user_id: user.id,
        tour_group_product_id: tour_product.id,
        tour_package_id: tour_package.id,
        travel_date: @travel_date,
        adult_count: 1,
        child_count: 0,
        contact_name: zhangsan.name,
        contact_phone: zhangsan.phone,
        insurance_type: 'none',
        total_price: tour_package.price,
        status: 'confirmed',
        data_version: @data_version
      )
      
      # 2. 预订配备早餐的酒店
      hotel = @available_hotels.max_by(&:rating)
      raise "未找到配备早餐设施的酒店" if hotel.nil?
      
      HotelBooking.create!(
        hotel_room_id: hotel.hotel_rooms.first!.id,
        user_id: user.id,
        rooms_count: 1,
        adults_count: 1,
        children_count: 0,
        hotel_id: hotel.id,
        check_in_date: @travel_date,
        check_out_date: @travel_date + @nights.days,
        guest_name: zhangsan.name,
        guest_phone: zhangsan.phone,
        payment_method: '花呗',
        total_price: hotel.price * @nights,
        status: 'pending',
        data_version: @data_version
      )
    end
    
    private
    
    def execution_state_data
      {
        destination: @destination,
        travel_date: @travel_date&.to_s,
        duration: @duration,
        nights: @nights,
        expected_contact_name: @expected_contact_name,
        expected_contact_phone: @expected_contact_phone
      }
    end
    
    def restore_from_state(data)
      @destination = data['destination']
      @travel_date = Date.parse(data['travel_date']) if data['travel_date']
      @duration = data['duration']
      @nights = data['nights']
      @expected_contact_name = data['expected_contact_name']
      @expected_contact_phone = data['expected_contact_phone']
      
      # 重新加载乘客信息
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @zhangsan = user.passengers.find_by!(name: @expected_contact_name, data_version: 0)
      
      # 重新加载配备早餐的酒店
      @available_hotels = Hotel.where(data_version: 0)
        .select { |h| h.facilities.to_s.match?(/早餐|餐厅|免费早餐/i) }
        .sort_by { |h| -h.rating.to_f }
    end
  end
end
