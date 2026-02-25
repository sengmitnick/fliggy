# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例300: 给李四预订成都美食体验游
#
# 任务描述:
#   李四想预订成都的美食体验游，品尝地道美食、参观特色餐厅和市场
#
# 评分标准:
#   - 创建跟团游预订(美食主题) (35%)
#   - 选择美食目的地(成都/广州等) (25%)
#   - 游客信息正确（李四） (15%)
#   - 出行日期正确 (10%)
#   - 联系人信息正确 (10%)
#   - 行程时长≥3天 (5%)
module V251V300
  class V300BookFoodExperienceTourValidator < BaseValidator
    self.validator_id = 'v300_book_food_experience_tour_validator'
    self.task_id = 'a780cbb3-8b82-49be-bbea-18baaa72e179'
    self.title = '给李四预订成都美食体验游'
    self.description = '给李四预订成都美食体验游'
    self.timeout_seconds = 300
    
    def prepare
      @destination = '成都'
      @travel_date = Date.current + 8.days
      @visit_date = @travel_date
      
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      if user.balance < 4000
        user.update!(balance: 6000)
      end
      
      # Pre-query passenger info
      @lisi = user.passengers.find_by!(name: '李四', data_version: 0)
      @expected_contact_name = @lisi.name
      @expected_contact_phone = @lisi.phone
      
      {
        task: "请预订#{@destination}的美食体验游，#{@travel_date.strftime('%Y年%-m月%-d日')}出发，需要品尝地道美食、参观特色餐厅和市场，行程至少3天",
        destination: @destination,
        travel_date: @travel_date.to_s,
        hint: "选择美食主题的旅游产品，行程至少3天"
      }
    end
    
    def verify
      add_assertion "创建了跟团游预订(美食主题)", weight: 35 do
        @tour_booking = TourGroupBooking
          .joins(:tour_group_product)
          .where(tour_group_products: { destination: @destination })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        expect(@tour_booking).not_to be_nil, "未找到#{@destination}的跟团游预订"
      end
      
      return unless @tour_booking
      
      add_assertion "选择美食目的地", weight: 25 do
        tour = @tour_booking.tour_group_product
        # 美食之都：成都、广州、重庆等
        food_cities = ['成都', '广州', '重庆', '西安', '长沙']
        is_food_destination = food_cities.include?(@destination)
        expect(is_food_destination).to be(true),
          "未选择美食目的地。当前: #{@destination}"
      end
      
      add_assertion "游客信息正确（李四）", weight: 15 do
        travelers = @tour_booking.booking_travelers
        expect(travelers).not_to be_empty, "未找到游客信息"
        
        lisi_traveler = travelers.find { |t| t.traveler_name == @expected_contact_name }
        expect(lisi_traveler).not_to be_nil,
          "游客信息中缺少李四。实际游客: #{travelers.map(&:traveler_name).join(', ')}"
        
        expect(lisi_traveler.id_number).to eq(@lisi.id_number),
          "身份证号码错误。期望: #{@lisi.id_number}, 实际: #{lisi_traveler.id_number}"
      end
      
      add_assertion "出行日期正确", weight: 10 do
        expect(@tour_booking.travel_date).to eq(@travel_date),
          "出行日期错误。期望: #{@travel_date}, 实际: #{@tour_booking.travel_date}"
      end
      
      add_assertion "联系人信息正确（李四）", weight: 10 do
        expect(@tour_booking.contact_name).to eq(@expected_contact_name),
          "联系人姓名错误。期望: #{@expected_contact_name}, 实际: #{@tour_booking.contact_name}"
        expect(@tour_booking.contact_phone).to eq(@expected_contact_phone),
          "联系电话错误。期望: #{@expected_contact_phone}, 实际: #{@tour_booking.contact_phone}"
      end
      
      add_assertion "行程时长≥3天", weight: 5 do
        tour = @tour_booking.tour_group_product
        expect(tour.duration).to be >= 3,
          "行程天数不足。期望≥3天，实际: #{tour.duration}天"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 选择美食主题跟团游(至少3天)
      tour_product = TourGroupProduct
        .where(destination: @destination, data_version: 0)
        .where("duration >= ?", 3)
        .order(rating: :desc)
        .first!
      
      tour_package = tour_product.tour_packages.first!
      
      # 创建跟团游预订
      tour_booking = TourGroupBooking.create!(
        user_id: user.id,
        tour_group_product_id: tour_product.id,
        tour_package_id: tour_package.id,
        travel_date: @travel_date,
        adult_count: 1,
        child_count: 0,
        contact_name: @lisi.name,
        contact_phone: @lisi.phone,
        total_price: tour_package.price,
        status: 'pending',
        insurance_type: 'standard',
        data_version: @data_version
      )
      
      # 添加游客信息
      BookingTraveler.create!(
        tour_group_booking_id: tour_booking.id,
        traveler_name: @lisi.name,
        id_number: @lisi.id_number,
        traveler_type: 'adult',
        data_version: @data_version
      )
    end
    
    private
    
    def execution_state_data
      {
        destination: @destination,
        travel_date: @travel_date&.to_s,
        visit_date: @visit_date&.to_s,
        expected_contact_name: @expected_contact_name,
        expected_contact_phone: @expected_contact_phone
      }
    end
    
    def restore_from_state(data)
      @destination = data['destination']
      @travel_date = Date.parse(data['travel_date']) if data['travel_date']
      @visit_date = Date.parse(data['visit_date']) if data['visit_date']
      @expected_contact_name = data['expected_contact_name']
      @expected_contact_phone = data['expected_contact_phone']
    end
  end
end
