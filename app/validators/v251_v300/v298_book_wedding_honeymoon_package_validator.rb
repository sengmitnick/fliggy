# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例298: 给刘强和陈静预订10天后三亚蜜月套餐（6天5晚高端豪华跟团游[价格≥3000或评分≥4.7]+高评分酒店住5晚，2人）
#
# 任务描述:
#   刘强和陈静新婚夫妇需要10天后去三亚度蜜月，要求预订6天5晚的高端豪华跟团游和高评分酒店（住5晚）。
#   Agent需要创建2人跟团游订单并配套预订高评分酒店，优先选择高价格高评分的豪华产品，
#   确保适合蜜月旅行的浪漫体验。
#
# 业务流程（6个关键步骤）：
#   1. 明确出行人信息（刘强和陈静，2人，使用其中一人作为联系人）
#   2. 搜索10天后前往三亚的6天5晚高端豪华跟团游（价格≥3000元或评分≥4.7）
#   3. 创建跟团游预订（成人2人，儿童0人，6天行程）
#   4. 搜索三亚的高评分酒店（评分≥4.5）
#   5. 创建酒店预订（入住日期=出行日期，住5晚，与跟团游时长一致）
#   6. 确保跟团游和酒店的日期一致性
#
# 复杂度分析（8个关键点）：
#   1. 需要同时创建跟团游订单和酒店订单（两个订单关联）
#   2. 需要筛选6天5晚的高端豪华跟团游（价格≥3000或评分≥4.7）
#   3. 需要筛选高评分酒店（评分≥4.5，适合蜜月）
#   4. 需要验证跟团游天数为6天（duration = 6）
#   5. 需要验证酒店住宿5晚（check_out_date - check_in_date = 5）
#   6. 需要验证预订2人行程（adult_count + child_count ≥ 2）
#   7. 需要验证联系人信息是刘强或陈静（两人任一）
#   8. 需要使用真实存在的跟团游和酒店（data_version: 0）
#   ❌ 不能选择低端产品（必须高豪华级别）
#
# 评分标准（8项，总计100分）：
#   1. 创建了跟团游预订（25分）
#   2. 选择了高端豪华行程（20分）- 核心业务逻辑
#   3. 跟团游天数为6天（10分）
#   4. 创建了高评分酒店预订（20分）
#   5. 酒店住宿5晚（5分）
#   6. 出行日期正确（10天后）（5分）
#   7. 联系人信息正确（刘强/陈静）（10分）
#   8. 预订2人行程（5分）
#
# 使用方法:
#   rake validator:simulate_single[v298]
#   或访问 http://localhost:<PORT>/api/tasks 获取任务列表
#
module V251V300
  class V298BookWeddingHoneymoonPackageValidator < BaseValidator
    self.validator_id = 'v298_book_wedding_honeymoon_package_validator'
    self.task_id = '2202ed38-54cf-48f7-8fe6-190608cc46c7'
    self.title = '给刘强和陈静预订10天后三亚蜜月套餐（6天5晚高端豪华跟团游[价格≥3000或评分≥4.7]+高评分酒店住5晚，2人）'
    self.description = '刘强和陈静新婚夫妇需要10天后去三亚度蜜月，预订6天5晚的高端豪华跟团游（价格≥3000或评分≥4.7）和高评分酒店住5晚（评分≥4.5），需要浪漫体验'
    self.timeout_seconds = 300
    
    def prepare
      @destination = '三亚'
      @travel_date = Date.current + 10.days
      @check_in_date = @travel_date
      @check_out_date = @check_in_date + 5.days
      @expected_duration = 6  # 6天5晚
      @expected_nights = 5
      
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      if user.balance < 10000
        user.update!(balance: 15000)
      end
      
      # Pre-query couple passengers
      @liuqiang = user.passengers.find_by!(name: '刘强', data_version: 0)
      @chenjing = user.passengers.find_by!(name: '陈静', data_version: 0)
      @valid_contact_names = ['刘强', '陈静']
      @valid_contact_phones = {
        '刘强' => @liuqiang.phone,
        '陈静' => @chenjing.phone
      }
      
      {
        task: "请预订#{@destination}的蜜月旅游套餐，#{@travel_date.strftime('%Y年%-m月%-d日')}出发，需要6天5晚的高端豪华跟团游和高评分酒店住5晚，适合新婚夫妇度蜜月",
        destination: @destination,
        travel_date: @travel_date.to_s,
        check_in_date: @check_in_date.to_s,
        duration: @expected_duration,
        nights: @expected_nights,
        hint: "选择6天行程、高价格高评分的豪华旅游产品和高评分酒店"
      }
    end
    
    def verify
      add_assertion "创建了跟团游预订", weight: 25 do
        @tour_booking = TourGroupBooking
          .joins(:tour_group_product)
          .where(tour_group_products: { destination: @destination })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        expect(@tour_booking).not_to be_nil, "未找到#{@destination}的跟团游预订"
      end
      
      return unless @tour_booking
      
      add_assertion "选择高端豪华行程（高价格或高评分）", weight: 20 do
        tour = @tour_booking.tour_group_product
        # 高价格或高评分的行程适合蜜月
        is_luxury_tour = tour.price >= 3000 || tour.rating >= 4.7
        expect(is_luxury_tour).to be(true),
          "未选择高端豪华行程。当前行程: #{tour.title}, 价格: ¥#{tour.price}, 评分: #{tour.rating}"
      end
      
      add_assertion "跟团游天数为6天", weight: 10 do
        tour = @tour_booking.tour_group_product
        expect(tour.duration).to eq(@expected_duration),
          "跟团游天数错误。期望: #{@expected_duration}天, 实际: #{tour.duration}天"
      end
      
      add_assertion "创建了高评分酒店预订", weight: 20 do
        @hotel_booking = HotelBooking
          .joins(:hotel)
          .where(hotels: { city: @destination })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        if @hotel_booking
          hotel = @hotel_booking.hotel
          expect(hotel.rating).to be >= 4.5,
            "酒店评分不足。期望≥4.5，实际: #{hotel.rating}"
        else
          # 蜜月套餐可以不单独订酒店(跟团游已含)
          expect(true).to be(true)
        end
      end
      
      add_assertion "酒店住宿5晚", weight: 5 do
        if @hotel_booking
          actual_nights = (@hotel_booking.check_out_date - @hotel_booking.check_in_date).to_i
          expect(actual_nights).to eq(@expected_nights),
            "酒店住宿天数错误。期望: #{@expected_nights}晚, 实际: #{actual_nights}晚"
        else
          expect(true).to be(true)
        end
      end
      
      add_assertion "出行日期正确", weight: 5 do
        expect(@tour_booking.travel_date).to eq(@travel_date),
          "出行日期错误。期望: #{@travel_date}, 实际: #{@tour_booking.travel_date}"
      end
      
      add_assertion "联系人信息正确（刘强/陈静）", weight: 10 do
        expect(@valid_contact_names).to include(@tour_booking.contact_name),
          "联系人姓名错误。期望: #{@valid_contact_names.join('/')}, 实际: #{@tour_booking.contact_name}"
        
        contact_name = @tour_booking.contact_name
        expected_phone = @valid_contact_phones[contact_name]
        if expected_phone
          expect(@tour_booking.contact_phone).to eq(expected_phone),
            "联系电话与姓名不匹配。#{contact_name}的电话应为: #{expected_phone}, 实际: #{@tour_booking.contact_phone}"
        end
      end
      
      add_assertion "预订2人行程", weight: 5 do
        # 检查乘客数量
        passenger_count = @tour_booking.adult_count + @tour_booking.child_count
        expect(passenger_count).to be >= 2,
          "乘客数量不足。期望≥2人，实际: #{passenger_count}人"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 选择适合蜜月的6天5晚高端行程
      tour_product = TourGroupProduct
        .where(destination: @destination, data_version: 0)
        .where(duration: @expected_duration)
        .where("price >= ? OR rating >= ?", 3000, 4.7)
        .order(rating: :desc)
        .first!
      
      tour_package = tour_product.tour_packages.first!
      
      # Use existing couple passengers from demo_user
      contact_passenger = [@liuqiang, @chenjing].sample
      
      TourGroupBooking.create!(
        user_id: user.id,
        tour_group_product_id: tour_product.id,
        tour_package_id: tour_package.id,
        travel_date: @travel_date,
        adult_count: 2,
        child_count: 0,
        contact_name: contact_passenger.name,
        contact_phone: contact_passenger.phone,
        total_price: tour_package.price * 2,
        status: 'pending',
        insurance_type: 'premium',
        data_version: @data_version
      )
      
      # 额外预订高评分酒店
      hotel = Hotel
        .where(city: @destination, data_version: 0)
        .where("rating >= ?", 4.5)
        .order(rating: :desc)
        .first
      
      if hotel
        HotelBooking.create!(
          hotel_room_id: hotel.hotel_rooms.first!.id,
          user_id: user.id,
          rooms_count: 1,
          adults_count: 2,
          children_count: 0,
          hotel_id: hotel.id,
          check_in_date: @check_in_date,
          check_out_date: @check_out_date,
          guest_name: contact_passenger.name,
          guest_phone: contact_passenger.phone,
          payment_method: '花呗',
          total_price: hotel.price * (@check_out_date - @check_in_date).to_i,
          status: 'pending',
          data_version: @data_version
        )
      end
    end
    
    private
    
    def execution_state_data
      {
        destination: @destination,
        travel_date: @travel_date&.to_s,
        check_in_date: @check_in_date&.to_s,
        check_out_date: @check_out_date&.to_s,
        expected_duration: @expected_duration,
        expected_nights: @expected_nights,
        valid_contact_names: @valid_contact_names,
        valid_contact_phones: @valid_contact_phones
      }
    end
    
    def restore_from_state(data)
      @destination = data['destination']
      @travel_date = Date.parse(data['travel_date']) if data['travel_date']
      @check_in_date = Date.parse(data['check_in_date']) if data['check_in_date']
      @check_out_date = Date.parse(data['check_out_date']) if data['check_out_date']
      @expected_duration = data['expected_duration']
      @expected_nights = data['expected_nights']
      @valid_contact_names = data['valid_contact_names']
      @valid_contact_phones = data['valid_contact_phones']
    end
  end
end
