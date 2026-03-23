# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例300: 给李四预订8天后成都跟团游（至少3天行程，1人）
#
# 任务描述:
#   李四想8天后去成都旅游。
#   Agent需要预订一个至少3天的成都跟团游产品。
#
# 业务流程（6个关键步骤）：
#   1. 明确出行人信息（李四，1成人）
#   2. 搜索成都的跟团游产品
#   3. 筛选至少3天行程的跟团游（duration >= 3）
#   4. 创建跟团游预订（8天后出发）
#   5. 添加游客信息（李四，包含身份证号）
#   6. 设置联系人信息（李四）
#
# 复杂度分析（6个关键点）：
#   1. 需要理解成都作为旅游目的地
#   2. 需要筛选至少3天行程的跟团游产品（duration >= 3）
#   3. 需要创建跟团游预订并关联游客信息
#   4. 需要验证游客信息完整性（姓名、身份证号匹配）
#   5. 需要验证出行日期正确性（8天后）
#   6. 需要使用真实存在的跟团游产品（data_version: 0）
#   ❌ 不能选择行程过短的产品（必须≥3天）
#
# 评分标准（6项，总计100分）：
#   1. 创建了跟团游预订 (35分)
#   2. 目的地正确（成都） (25分) - 核心业务逻辑
#   3. 游客信息正确（李四） (15分)
#   4. 出行日期正确（8天后） (10分)
#   5. 联系人信息正确（李四） (10分)
#   6. 行程时长≥3天 (5分)
#
# 使用方法:
#   rake validator:simulate_single[v300]
#   或访问 http://localhost:<PORT>/api/tasks 获取任务列表
module V251V300
  class V300BookFoodExperienceTourValidator < BaseValidator
    self.validator_id = 'v300_book_food_experience_tour_validator'
    self.task_id = 'a780cbb3-8b82-49be-bbea-18baaa72e179'
    self.title = '给李四预订8天后成都跟团游（至少3天行程，1人）'
    self.description = '李四想8天后去成都旅游，需要至少3天行程'
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
        task: "请预订#{@destination}的跟团游，#{@travel_date.strftime('%Y年%-m月%-d日')}出发，行程至少3天",
        destination: @destination,
        travel_date: @travel_date.to_s,
        hint: "选择#{@destination}的跟团游产品，行程至少3天"
      }
    end
    
    def verify
      add_assertion "创建了跟团游预订", weight: 35 do
        @tour_booking = TourGroupBooking
          .joins(:tour_group_product)
          .where(tour_group_products: { destination: @destination })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        expect(@tour_booking).not_to be_nil, "未找到#{@destination}的跟团游预订"
      end
      
      return unless @tour_booking
      
      add_assertion "目的地正确（成都）", weight: 25 do
        tour = @tour_booking.tour_group_product
        expect(tour.destination).to eq(@destination),
          "目的地错误。期望: #{@destination}, 实际: #{tour.destination}"
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
      
      # 选择成都跟团游(至少3天)
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
        expected_contact_phone: @expected_contact_phone,
        lisi_id_number: @lisi&.id_number
      }
    end
    
    def restore_from_state(data)
      @destination = data['destination']
      @travel_date = Date.parse(data['travel_date']) if data['travel_date']
      @visit_date = Date.parse(data['visit_date']) if data['visit_date']
      @expected_contact_name = data['expected_contact_name']
      @expected_contact_phone = data['expected_contact_phone']
      
      # Restore @lisi as a simple object with id_number
      if data['lisi_id_number']
        @lisi = OpenStruct.new(
          name: @expected_contact_name,
          phone: @expected_contact_phone,
          id_number: data['lisi_id_number']
        )
      end
    end
  end
end
