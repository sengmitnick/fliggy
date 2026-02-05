# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例306: 预订禅修静心游
#
# 任务描述:
#   用户预订禅修静心游(寺庙+冥想+素食体验)
#
# 评分标准:
#   - 创建跟团游预订(禅修主题) (40%)
#   - 选择禅修/文化主题行程 (30%)
#   - 出行日期正确 (15%)
#   - 行程时长≥3天(深度体验) (10%)
#   - 订单状态正确 (5%)
module V301V350
  class V306BookMeditationRetreatTourValidator < BaseValidator
    self.validator_id = 'v306_book_meditation_retreat_tour_validator'
    self.task_id = '13bb2b29-d9cb-4e2c-adb5-0e345081dbbc'
    self.title = '预订禅修静心游'
    self.description = '用户预订禅修静心游(寺庙+冥想+素食体验)'
    self.timeout_seconds = 300
    
    def prepare
      @destination = '杭州'
      @travel_date = Date.today + 14.days
      
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      if user.balance < 4000
        user.update!(balance: 6000)
      end
      
      {
        task: "请预订#{@destination}的禅修静心游，#{@travel_date.strftime('%Y年%-m月%-d日')}出发，需要寺庙参观、冥想体验和素食，行程至少3天，适合修身养性",
        destination: @destination,
        travel_date: @travel_date.to_s,
        hint: "选择文化/禅修主题的旅游产品，体验传统文化"
      }
    end
    
    def verify
      add_assertion "创建了跟团游预订(禅修主题)", weight: 40 do
        @tour_booking = TourGroupBooking
          .joins(:tour_group_product)
          .where(tour_group_products: { destination: @destination })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        expect(@tour_booking).not_to be_nil, "未找到#{@destination}的跟团游预订"
      end
      
      return unless @tour_booking
      
      add_assertion "选择禅修/文化主题行程", weight: 30 do
        tour = @tour_booking.tour_group_product
        # 禅修主题通常评分高、行程较长、价格适中
        is_meditation_tour = tour.rating >= 4.5 && tour.duration >= 3
        expect(is_meditation_tour).to be(true),
          "未选择禅修主题行程。当前行程: #{tour.title}, 评分: #{tour.rating}, 天数: #{tour.duration}天"
      end
      
      add_assertion "出行日期正确", weight: 15 do
        expect(@tour_booking.travel_date).to eq(@travel_date),
          "出行日期错误。期望: #{@travel_date}, 实际: #{@tour_booking.travel_date}"
      end
      
      add_assertion "行程时长≥3天(深度体验)", weight: 10 do
        tour = @tour_booking.tour_group_product
        expect(tour.duration).to be >= 3,
          "行程天数不足。期望≥3天(深度禅修体验)，实际: #{tour.duration}天"
      end
      
      add_assertion "订单状态正确", weight: 5 do
        valid_statuses = ['pending', 'paid']
        expect(valid_statuses).to include(@tour_booking.status),
          "订单状态错误: #{@tour_booking.status}"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 选择禅修主题跟团游(至少3天，高评分)
      tour_product = TourGroupProduct
        .where(destination: @destination, data_version: 0)
        .where("duration >= ? AND rating >= ?", 3, 4.5)
        .order(rating: :desc)
        .first
      
      # 如果没有满足条件的，降低要求
      tour_product ||= TourGroupProduct
        .where(destination: @destination, data_version: 0)
        .where("duration >= ?", 3)
        .order(rating: :desc)
        .first!
      
      tour_package = tour_product.tour_packages.first!
      
      passenger = Passenger.find_or_create_by!(
        user_id: user.id,
        id_number: '440300199001011234',
        data_version: @data_version
      ) do |p|
        p.name = '陈先生'
        p.id_type = 'id_card'
        p.phone = '13800138000'
      end
      
      TourGroupBooking.create!(
        user_id: user.id,
        tour_group_product_id: tour_product.id,
        tour_package_id: tour_package.id,
        travel_date: @travel_date,
        adult_count: 1,
        child_count: 0,
        contact_name: passenger.name,
        contact_phone: passenger.phone,
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
        travel_date: @travel_date&.to_s
      }
    end
    
    def restore_from_state(data)
      @destination = data['destination']
      @travel_date = Date.parse(data['travel_date']) if data['travel_date']
    end
  end
end
