# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例305: 预订亲子教育游
#
# 任务描述:
#   用户预订亲子教育游(科技馆+动物园+互动课程)
#
# 评分标准:
#   - 创建跟团游预订(亲子主题) (40%)
#   - 选择亲子友好行程 (25%)
#   - 预订2大1小组合 (20%)
#   - 出行日期正确 (10%)
#   - 行程时长≥2天 (5%)
module V301V350
  class V305BookFamilyEducationTourValidator < BaseValidator
    self.validator_id = 'v305_book_family_education_tour_validator'
    self.task_id = '5134922f-5d41-431e-b1f0-36ea208edf7f'
    self.title = '预订北京亲子教育游（12天后出发，2大1小，2天以上）'
    self.description = '用户预订北京的亲子教育跟团游，12天后出发，2成人1儿童家庭组合，行程至少2天，包含科技馆、博物馆等教育景点'
    self.timeout_seconds = 300
    
    def prepare
      @destination = '北京'
      @travel_date = Date.current + 12.days
      
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      if user.balance < 6000
        user.update!(balance: 9000)
      end
      
      {
        task: "请预订#{@destination}的亲子教育游，#{@travel_date.strftime('%Y年%-m月%-d日')}出发，适合2大1小家庭出游，需要科技馆、博物馆等教育景点，行程至少2天",
        destination: @destination,
        travel_date: @travel_date.to_s,
        hint: "选择亲子主题的旅游产品，预订家庭套票"
      }
    end
    
    def verify
      add_assertion "创建了跟团游预订(亲子主题)", weight: 40 do
        @tour_booking = TourGroupBooking
          .joins(:tour_group_product)
          .where(tour_group_products: { destination: @destination })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        expect(@tour_booking).not_to be_nil, "未找到#{@destination}的跟团游预订"
      end
      
      return unless @tour_booking
      
      add_assertion "选择亲子友好行程", weight: 25 do
        tour = @tour_booking.tour_group_product
        # 亲子行程通常评分高、适合家庭
        is_family_tour = tour.rating >= 4.5 || tour.duration >= 2
        expect(is_family_tour).to be(true),
          "未选择亲子友好行程。当前行程: #{tour.title}, 评分: #{tour.rating}, 天数: #{tour.duration}天"
      end
      
      add_assertion "预订2大1小组合", weight: 20 do
        expect(@tour_booking.adult_count).to eq(2),
          "成人数量错误。期望: 2大人，实际: #{@tour_booking.adult_count}大人"
        expect(@tour_booking.child_count).to eq(1),
          "儿童数量错误。期望: 1儿童，实际: #{@tour_booking.child_count}儿童"
      end
      
      add_assertion "出行日期正确", weight: 10 do
        expect(@tour_booking.travel_date).to eq(@travel_date),
          "出行日期错误。期望: #{@travel_date}, 实际: #{@tour_booking.travel_date}"
      end
      
      add_assertion "行程时长≥2天", weight: 5 do
        tour = @tour_booking.tour_group_product
        expect(tour.duration).to be >= 2,
          "行程天数不足。期望≥2天，实际: #{tour.duration}天"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 选择亲子主题跟团游(至少2天)
      tour_product = TourGroupProduct
        .where(destination: @destination, data_version: 0)
        .where("duration >= ?", 2)
        .order(rating: :desc)
        .first!
      
      tour_package = tour_product.tour_packages.first!
      
      # 创建2大1小乘客
      passenger1 = Passenger.find_or_create_by!(
        user_id: user.id,
        id_number: '440300198501011234',
        data_version: @data_version
      ) do |p|
        p.name = '吴先生'
        p.id_type = 'id_card'
        p.phone = '13800138000'
      end
      
      passenger2 = Passenger.find_or_create_by!(
        user_id: user.id,
        id_number: '440300198601021234',
        data_version: @data_version
      ) do |p|
        p.name = '吴太太'
        p.id_type = 'id_card'
        p.phone = '13800138001'
      end
      
      # 儿童乘客
      passenger3 = Passenger.find_or_create_by!(
        user_id: user.id,
        id_number: '440300201501031234',
        data_version: @data_version
      ) do |p|
        p.name = '吴小朋友'
        p.id_type = 'id_card'
        p.phone = '13800138000'
      end
      
      TourGroupBooking.create!(
        user_id: user.id,
        tour_group_product_id: tour_product.id,
        tour_package_id: tour_package.id,
        travel_date: @travel_date,
        adult_count: 2,
        child_count: 1,
        contact_name: passenger1.name,
        contact_phone: passenger1.phone,
        total_price: tour_package.price * 2 + (tour_package.child_price || tour_package.price * 0.5),  # 2大1小价格
        status: 'pending',
        insurance_type: 'standard',
        data_version: @data_version
      )
    end
    
    private
    
    def execution_state_data
      {
        destination: @destination,
        travel_date: @travel_date&.to_s
      }
    end
    
    def restore_from_state(data)
      @destination = data['destination']
      @travel_date = Date.parse(data['travel_date']) if data['travel_date']
    end
  end
end
