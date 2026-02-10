# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例299: 给王芳预订云南摄影主题游
#
# 任务描述:
#   王芳想去云南进行摄影主题旅游，需要选择风景优美的跟团游产品（评分≥4.5）
#
# 评分标准:
#   - 创建跟团游预订 (30%)
#   - 选择风景优美目的地 (25%)
#   - 游客信息正确（王芳） (15%)
#   - 预订日期正确 (10%)
#   - 联系人信息正确 (10%)
#   - 预订人数正确(1人) (10%)
module V251V300
  class V299BookPhotographyThemeTourValidator < BaseValidator
    self.validator_id = 'v299_book_photography_theme_tour_validator'
    self.task_id = 'feeaef15-74e2-4fb2-a7fa-1b6c5bc2273f'
    self.title = '给王芳预订云南摄影主题游（7天后，1人）'
    self.description = '王芳想去云南进行摄影主题旅游，选风景优美的跟团游（评分≥4.5）'
    self.timeout_seconds = 300
    
    def prepare
      @destination = '云南'
      @travel_date = Date.today + 7.days
      @visit_date = Date.today + 8.days
      
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # Pre-query passenger info
      @wangfang = user.passengers.find_by!(name: '王芳', data_version: 0)
      @expected_contact_name = @wangfang.name
      @expected_contact_phone = @wangfang.phone
      
      # 检查是否有摄影主题跟团游产品
      tour_count = TourGroupProduct.where(destination: @destination, data_version: 0).count
      raise "测试数据不足: #{@destination}地区没有跟团游产品，当前数量: #{tour_count}" if tour_count == 0
      
      {
        destination: @destination,
        travel_date: @travel_date,
        task_description: "预订#{@destination}摄影主题游，#{@travel_date.strftime('%Y年%m月%d日')}出发"
      }
    end
    
    def verify
      add_assertion "创建了跟团游预订", weight: 30 do
        @tour_booking = TourGroupBooking
          .joins(:tour_group_product)
          .where(tour_group_products: { destination: @destination })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@tour_booking).not_to be_nil, "未找到#{@destination}的跟团游预订"
      end
      
      return unless @tour_booking
      
      add_assertion "选择风景优美目的地", weight: 25 do
        tour = @tour_booking.tour_group_product
        # 摄影主题游通常选择评分高的自然风光
        is_scenic_tour = tour.rating >= 4.5
        expect(is_scenic_tour).to be(true),
          "未选择风景优美的目的地。当前评分: #{tour.rating}"
      end
      
      add_assertion "游客信息正确（王芳）", weight: 15 do
        travelers = @tour_booking.booking_travelers
        expect(travelers).not_to be_empty, "未找到游客信息"
        
        wangfang_traveler = travelers.find { |t| t.traveler_name == @expected_contact_name }
        expect(wangfang_traveler).not_to be_nil,
          "游客信息中缺少王芳。实际游客: #{travelers.map(&:traveler_name).join(', ')}"
        
        expect(wangfang_traveler.id_number).to eq(@wangfang.id_number),
          "身份证号码错误。期望: #{@wangfang.id_number}, 实际: #{wangfang_traveler.id_number}"
      end
      
      add_assertion "预订日期正确", weight: 10 do
        expect(@tour_booking.travel_date).to eq(@travel_date),
          "出行日期错误。期望: #{@travel_date}, 实际: #{@tour_booking.travel_date}"
      end
      
      add_assertion "联系人信息正确（王芳）", weight: 10 do
        expect(@tour_booking.contact_name).to eq(@expected_contact_name),
          "联系人姓名错误。期望: #{@expected_contact_name}, 实际: #{@tour_booking.contact_name}"
        expect(@tour_booking.contact_phone).to eq(@expected_contact_phone),
          "联系电话错误。期望: #{@expected_contact_phone}, 实际: #{@tour_booking.contact_phone}"
      end
      
      add_assertion "预订人数正确(1人)", weight: 10 do
        total_passengers = @tour_booking.adult_count + @tour_booking.child_count
        expect(total_passengers).to eq(1),
          "预订人数错误。期望: 1人，实际: #{total_passengers}人"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 选择风景优美的跟团游（高评分）
      tour_product = TourGroupProduct
        .where(destination: @destination, data_version: 0)
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
        contact_name: @wangfang.name,
        contact_phone: @wangfang.phone,
        total_price: tour_package.price,
        status: 'pending',
        insurance_type: 'standard',
        data_version: @data_version
      )
      
      # 添加游客信息
      BookingTraveler.create!(
        tour_group_booking_id: tour_booking.id,
        traveler_name: @wangfang.name,
        id_number: @wangfang.id_number,
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
