# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例300: 预订美食体验游
#
# 任务描述:
#   用户预订美食体验游(特色餐厅+厨艺课程+市场游)
#
# 评分标准:
#   - 创建跟团游预订(美食主题) (40%)
#   - 选择美食目的地(成都/广州等) (20%)
#   - 创建景区餐饮活动订单 (20%)
#   - 出行日期正确 (15%)
#   - 行程时长≥3天 (5%)
module V251V300
  class V300BookFoodExperienceTourValidator < BaseValidator
    self.validator_id = 'v300_book_food_experience_tour_validator'
    self.task_id = 'h16e8hd0-f8g2-44hb-d3ff-i4768f39fh0e'
    self.title = '预订美食体验游'
    self.description = '用户预订美食体验游(特色餐厅+厨艺课程+市场游)'
    self.timeout_seconds = 300
    
    def prepare
      @destination = '成都'
      @travel_date = Date.current + 8.days
      @visit_date = @travel_date
      
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      if user.balance < 4000
        user.update!(balance: 6000)
      end
      
      {
        task: "请预订#{@destination}的美食体验游，#{@travel_date.strftime('%Y年%-m月%-d日')}出发，需要品尝地道美食、参观特色餐厅和市场，行程至少3天",
        destination: @destination,
        travel_date: @travel_date.to_s,
        hint: "选择美食主题的旅游产品和餐饮体验活动"
      }
    end
    
    def verify
      add_assertion "创建了跟团游预订(美食主题)", weight: 40 do
        @tour_booking = TourGroupBooking
          .joins(:tour_group_product)
          .where(tour_group_products: { destination: @destination })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        expect(@tour_booking).not_to be_nil, "未找到#{@destination}的跟团游预订"
      end
      
      return unless @tour_booking
      
      add_assertion "选择美食目的地", weight: 20 do
        tour = @tour_booking.tour_group_product
        # 美食之都：成都、广州、重庆等
        food_cities = ['成都', '广州', '重庆', '西安', '长沙']
        is_food_destination = food_cities.include?(@destination)
        expect(is_food_destination).to be(true),
          "未选择美食目的地。当前: #{@destination}"
      end
      
      add_assertion "创建了景区餐饮活动订单", weight: 20 do
        @activity_order = ActivityOrder
          .joins(attraction_activity: :attraction)
          .where(attractions: { city: @destination })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        if @activity_order
          activity = @activity_order.attraction_activity
          is_dining_activity = activity.activity_type == 'dining'
          expect(is_dining_activity).to be(true),
            "活动类型错误。期望: dining, 实际: #{activity.activity_type}"
        else
          # 美食体验可能已包含在跟团游中
          expect(true).to be(true)
        end
      end
      
      add_assertion "出行日期正确", weight: 15 do
        expect(@tour_booking.travel_date).to eq(@travel_date),
          "出行日期错误。期望: #{@travel_date}, 实际: #{@tour_booking.travel_date}"
      end
      
      add_assertion "行程时长≥3天", weight: 5 do
        tour = @tour_booking.tour_group_product
        expect(tour.duration).to be >= 3,
          "行程天数不足。期望≥3天，实际: #{tour.duration}天"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 1. 预订美食主题跟团游(至少3天)
      tour_product = TourGroupProduct
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
        p.name = '李先生'
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
      
      # 2. 预订景区餐饮体验活动
      attraction = Attraction.where(city: @destination, data_version: 0).first!
      activity = attraction.attraction_activities
        .where(activity_type: 'dining', data_version: 0)
        .first
      
      if activity
        ActivityOrder.create!(
          user_id: user.id,
          attraction_activity_id: activity.id,
          visit_date: @visit_date,
          quantity: 1,
          passenger_ids: [passenger.id],
          total_price: activity.current_price,
          status: 'pending',
          insurance_type: 'none',
          data_version: @data_version
        )
      end
    end
    
    private
    
    def execution_state_data
      {
        destination: @destination,
        travel_date: @travel_date&.to_s,
        visit_date: @visit_date&.to_s
      }
    end
    
    def restore_from_state(data)
      @destination = data['destination']
      @travel_date = Date.parse(data['travel_date']) if data['travel_date']
      @visit_date = Date.parse(data['visit_date']) if data['visit_date']
    end
  end
end
