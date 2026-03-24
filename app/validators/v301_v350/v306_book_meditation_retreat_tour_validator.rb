# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例306: 预订杭州禅修静心跟团游（王芳，14天后出发，≥3天）
#
# 任务描述:
#   王芳预订杭州的禅修静心跟团游。
#   要求：14天后出发，包含寺庙参观、冥想体验和素食，行程≥3天，适合修身养性。
#   Agent 需要预订禅修/文化主题的跟团游产品，联系人使用王芳的信息。
#
# 业务流程（5个关键步骤）：
#   1. 搜索杭州的禅修/文化主题跟团游产品
#   2. 筛选包含寺庙、冥想、素食等关键词的行程
#   3. 确定出行日期（14天后）
#   4. 选择行程时长≥3天的产品
#   5. 填写预订信息和联系人（王芳的姓名和电话）
#
# 复杂度分析（4个关键点）：
#   1. 需要理解禅修静心游的特点：包含寺庙、冥想、素食等元素
#   2. 需要计算正确的出行日期（14天后）
#   3. 需要选择demo用户的乘客（王芳）作为联系人
#   4. 需要确保行程时长≥3天（深度体验）
#
# 评分标准（7项，总计100分）：
#   - 创建了跟团游预订 (20%)
#   - 目的地正确（杭州） (10%)
#   - 选择禅修/文化主题行程 (30%)
#   - 出行日期正确（14天后） (10%)
#   - 联系人信息正确（王芳） (10%)
#   - 行程时长≥3天(深度体验) (15%)
#   - 订单状态正确 (5%)
module V301V350
  class V306BookMeditationRetreatTourValidator < BaseValidator
    self.validator_id = 'v306_book_meditation_retreat_tour_validator'
    self.task_id = '13bb2b29-d9cb-4e2c-adb5-0e345081dbbc'
    self.title = '预订杭州禅修静心跟团游（王芳，14天后出发，≥3天）'
    self.description = '预订杭州禅修静心跟团游，王芳，14天后出发，要寺庙参观、冥想体验和素食，行程至少3天，适合修身养性'
    self.timeout_seconds = 300
    
    def prepare
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # Pre-query existing passenger from demo_user
      @wangfang = user.passengers.find_by!(name: '王芳', data_version: 0)
      
      # Expected contact info
      @expected_contact_name = @wangfang.name
      @expected_contact_phone = @wangfang.phone
      
      @destination = '杭州'
      @travel_date = Date.current + 14.days
      
      if user.balance < 4000
        user.update!(balance: 6000)
      end
      
      {
        task: "请预订#{@destination}的禅修静心跟团游，#{@travel_date.strftime('%Y年%-m月%-d日')}出发，需要寺庙参观、冥想体验和素食，行程至少3天，适合修身养性",
        destination: @destination,
        travel_date: @travel_date.to_s,
        hint: "选择文化/禅修主题的旅游产品，体验传统文化"
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
      
      add_assertion "目的地正确（#{@destination}）", weight: 10 do
        expect(@tour_booking.tour_group_product.destination).to eq(@destination),
          "目的地错误。期望: #{@destination}，实际: #{@tour_booking.tour_group_product.destination}"
      end
      
      add_assertion "选择禅修/文化主题行程", weight: 30 do
        tour = @tour_booking.tour_group_product
        # 禅修主题必须包含相关关键词：禅修/寺庙/冥想/素食
        is_meditation_tour = tour.title.match?(/(禅修|灵隐寺|法喜寺|径山寺|冥想|素食|禅茶|抄经|养生|静心)/)
        expect(is_meditation_tour).to be(true),
          "未选择禅修主题行程。当前行程: #{tour.title}, 评分: #{tour.rating}, 天数: #{tour.duration}天"
      end
      
      add_assertion "出行日期正确", weight: 10 do
        expect(@tour_booking.travel_date).to eq(@travel_date),
          "出行日期错误。期望: #{@travel_date}（14天后），实际: #{@tour_booking.travel_date}"
      end
      
      add_assertion "联系人信息正确（王芳）", weight: 10 do
        expect(@tour_booking.contact_name).to eq(@expected_contact_name),
          "联系人姓名错误。期望: #{@expected_contact_name}（王芳），实际: #{@tour_booking.contact_name}"
        expect(@tour_booking.contact_phone).to eq(@expected_contact_phone),
          "联系电话错误。期望: #{@expected_contact_phone}，实际: #{@tour_booking.contact_phone}"
      end
      
      add_assertion "行程时长≥3天(深度体验)", weight: 15 do
        tour = @tour_booking.tour_group_product
        expect(tour.duration).to be >= 3,
          "行程天数不足。期望≥3天(深度禅修体验)，实际: #{tour.duration}天"
      end
      
      add_assertion "订单状态正确", weight: 5 do
        valid_statuses = ['pending', 'confirmed', 'paid']
        expect(valid_statuses).to include(@tour_booking.status),
          "订单状态错误: #{@tour_booking.status}"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 选择禅修主题跟团游(至少3天，包含寺庙/禅修关键词)
      tour_product = TourGroupProduct
        .where(destination: @destination, data_version: 0)
        .where("duration >= ? AND (title LIKE ? OR title LIKE ? OR title LIKE ? OR title LIKE ?)", 
               3, '%禅修%', '%寺%', '%冥想%', '%素食%')
        .order(rating: :desc)
        .first
      
      # 如果没有禅修主题，降低要求（只需行程≥3天、评分高≥4.5）
      tour_product ||= TourGroupProduct
        .where(destination: @destination, data_version: 0)
        .where("duration >= ? AND rating >= ?", 3, 4.5)
        .order(rating: :desc)
        .first!
      
      tour_package = tour_product.tour_packages.first!
      
      # Use existing passenger from demo_user (no NEW creation)
      TourGroupBooking.create!(
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
    end
    
    private
    
    def execution_state_data
      {
        destination: @destination,
        travel_date: @travel_date&.to_s,
        expected_contact_name: @expected_contact_name,
        expected_contact_phone: @expected_contact_phone
      }
    end
    
    def restore_from_state(data)
      @destination = data['destination']
      @travel_date = Date.parse(data['travel_date']) if data['travel_date']
      @expected_contact_name = data['expected_contact_name']
      @expected_contact_phone = data['expected_contact_phone']
    end
  end
end
