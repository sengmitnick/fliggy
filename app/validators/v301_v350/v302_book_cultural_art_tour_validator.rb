# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例302: 给王芳预订西安文化艺术游
#
# 任务描述:
#   王芳对历史文化感兴趣，想预订西安的文化艺术游，参观博物馆和文化遗产
#
# 评分标准:
#   - 创建了跟团游预订 (20%)
#   - 目的地为西安 (10%)
#   - 选择文化艺术主题行程 (25%)
#   - 出行日期正确 (10%)
#   - 联系人信息正确（王芳） (10%)
#   - 行程时长≥3天 (10%)
#   - 游客信息正确（王芳） (15%)
module V301V350
  class V302BookCulturalArtTourValidator < BaseValidator
    self.validator_id = 'v302_book_cultural_art_tour_validator'
    self.task_id = 'f24660cb-1708-4a34-a89f-6108f9775035'
    self.title = '给王芳预订西安文化艺术游'
    self.description = '给王芳预订西安文化艺术游'
    self.timeout_seconds = 300
    
    def prepare
      @destination = '西安'
      @travel_date = Date.current + 9.days
      @visit_date = @travel_date
      
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      if user.balance < 4000
        user.update!(balance: 6000)
      end
      
      # Pre-query passenger info
      @wangfang = user.passengers.find_by!(name: '王芳', data_version: 0)
      @expected_contact_name = @wangfang.name
      @expected_contact_phone = @wangfang.phone
      @expected_traveler_name = @wangfang.name
      @expected_id_number = @wangfang.id_number
      
      {
        task: "请为王芳预订#{@destination}的文化艺术游，#{@travel_date.strftime('%Y年%-m月%-d日')}出发，需要参观博物馆、文化遗产和艺术展览，行程至少3天",
        destination: @destination,
        travel_date: @travel_date.to_s,
        passenger: '王芳',
        hint: "选择历史文化主题的旅游产品，联系人和游客使用demo_user的出行人王芳"
      }
    end
    
    def verify
      add_assertion "创建了跟团游预订", weight: 20 do
        @tour_booking = TourGroupBooking
          .joins(:tour_group_product)
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        expect(@tour_booking).not_to be_nil, "未找到跟团游预订"
      end
      
      return unless @tour_booking
      
      add_assertion "目的地为西安", weight: 10 do
        expect(@tour_booking.tour_group_product.destination).to eq(@destination),
          "目的地错误。期望: #{@destination}（西安），实际: #{@tour_booking.tour_group_product.destination}"
      end
      
      add_assertion "选择文化艺术主题行程", weight: 25 do
        tour = @tour_booking.tour_group_product
        # 文化主题通常评分高、时长适中
        is_cultural_tour = tour.rating >= 4.5 || tour.duration >= 3
        expect(is_cultural_tour).to be(true),
          "未选择文化艺术主题行程。当前行程: #{tour.title}, 评分: #{tour.rating}, 天数: #{tour.duration}天"
      end
      
      add_assertion "出行日期正确", weight: 10 do
        expect(@tour_booking.travel_date).to eq(@travel_date),
          "出行日期错误。期望: #{@travel_date}（9天后），实际: #{@tour_booking.travel_date}"
      end
      
      add_assertion "联系人信息正确（王芳）", weight: 10 do
        expect(@tour_booking.contact_name).to eq(@expected_contact_name),
          "联系人姓名错误。期望: #{@expected_contact_name}（王芳），实际: #{@tour_booking.contact_name}"
        expect(@tour_booking.contact_phone).to eq(@expected_contact_phone),
          "联系电话错误。期望: #{@expected_contact_phone}，实际: #{@tour_booking.contact_phone}"
      end
      
      add_assertion "行程时长≥3天", weight: 10 do
        tour = @tour_booking.tour_group_product
        expect(tour.duration).to be >= 3,
          "行程天数不足。期望≥3天，实际: #{tour.duration}天"
      end
      
      add_assertion "游客信息正确（王芳）", weight: 15 do
        travelers = @tour_booking.booking_travelers.where(data_version: @data_version).to_a
        
        expect(travelers.size).to eq(1),
          "游客数量不正确。期望: 1个游客（王芳），实际: #{travelers.size}个游客"
        
        traveler = travelers.first
        expect(traveler.traveler_name).to eq(@expected_traveler_name),
          "游客姓名错误。期望: #{@expected_traveler_name}（王芳），实际: #{traveler.traveler_name}"
        
        expect(traveler.id_number).to eq(@expected_id_number),
          "身份证号错误。期望: #{@expected_id_number}，实际: #{traveler.id_number}"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 1. 预订文化主题跟团游(至少3天)
      tour_product = TourGroupProduct
        .where(destination: @destination, data_version: 0)
        .where("duration >= ?", 3)
        .order(rating: :desc)
        .first!
      
      tour_package = tour_product.tour_packages.first!
      
      # Use existing passenger from demo_user
      booking = TourGroupBooking.create!(
        user_id: user.id,
        tour_group_product_id: tour_product.id,
        tour_package_id: tour_package.id,
        travel_date: @travel_date,
        adult_count: 1,
        child_count: 0,
        contact_name: @wangfang.name,
        contact_phone: @wangfang.phone,
        total_price: tour_package.price,
        status: 'pending',
        insurance_type: 'standard',
        data_version: @data_version
      )
      
      # Create traveler record for 王芳
      BookingTraveler.create!(
        tour_group_booking_id: booking.id,
        traveler_name: @wangfang.name,
        id_number: @wangfang.id_number,
        traveler_type: 'adult',
        data_version: @data_version
      )
      
      # 跟团游已包含景区门票，无需单独预订
    end
    
    private
    
    def execution_state_data
      {
        destination: @destination,
        travel_date: @travel_date&.to_s,
        visit_date: @visit_date&.to_s,
        expected_contact_name: @expected_contact_name,
        expected_contact_phone: @expected_contact_phone,
        expected_traveler_name: @expected_traveler_name,
        expected_id_number: @expected_id_number
      }
    end
    
    def restore_from_state(data)
      @destination = data['destination']
      @travel_date = Date.parse(data['travel_date']) if data['travel_date']
      @visit_date = Date.parse(data['visit_date']) if data['visit_date']
      @expected_contact_name = data['expected_contact_name']
      @expected_contact_phone = data['expected_contact_phone']
      @expected_traveler_name = data['expected_traveler_name']
      @expected_id_number = data['expected_id_number']
      
      # Restore passenger reference
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @wangfang = user.passengers.find_by!(name: '王芳', data_version: 0)
    end
  end
end
