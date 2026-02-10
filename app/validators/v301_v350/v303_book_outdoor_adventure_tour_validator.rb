# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例303: 给刘强预订张家界户外探险游
#
# 任务描述:
#   刘强热爱户外运动，想预订张家界的户外探险游，包含徒步、露营和专业装备
#
# 评分标准:
#   - 创建了跟团游预订 (20%)
#   - 目的地为张家界 (10%)
#   - 选择户外探险主题行程 (20%)
#   - 出行日期正确 (10%)
#   - 联系人信息正确（刘强） (10%)
#   - 购买了旅游保险 (10%)
#   - 游客信息正确（刘强） (15%)
#   - 订单状态正确 (5%)
module V301V350
  class V303BookOutdoorAdventureTourValidator < BaseValidator
    self.validator_id = 'v303_book_outdoor_adventure_tour_validator'
    self.task_id = 'd11ffc15-c4d4-478c-a93f-67e8662ba77f'
    self.title = '给刘强预订张家界户外探险游（10天后）'
    self.description = '刘强热爱户外运动，想订张家界的户外探险游，要徒步露营和专业装备'
    self.timeout_seconds = 300
    
    def prepare
      @destination = '张家界'
      @travel_date = Date.current + 10.days
      
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      if user.balance < 5000
        user.update!(balance: 8000)
      end
      
      # Pre-query passenger info
      @liuqiang = user.passengers.find_by!(name: '刘强', data_version: 0)
      @expected_contact_name = @liuqiang.name
      @expected_contact_phone = @liuqiang.phone
      @expected_traveler_name = @liuqiang.name
      @expected_id_number = @liuqiang.id_number
      
      {
        task: "请为刘强预订#{@destination}的户外探险游，#{@travel_date.strftime('%Y年%-m月%-d日')}出发，需要徒步登山、露营体验和专业装备，适合户外探险爱好者",
        destination: @destination,
        travel_date: @travel_date.to_s,
        passenger: '刘强',
        hint: "选择户外探险主题的旅游产品，联系人和游客使用demo_user的出行人刘强，购买保险"
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
      
      add_assertion "目的地为张家界", weight: 10 do
        expect(@tour_booking.tour_group_product.destination).to eq(@destination),
          "目的地错误。期望: #{@destination}（张家界），实际: #{@tour_booking.tour_group_product.destination}"
      end
      
      add_assertion "选择户外探险主题行程", weight: 20 do
        tour = @tour_booking.tour_group_product
        # 户外探险主题通常评分高或价格适中
        is_outdoor_tour = tour.rating >= 4.5 || tour.duration >= 2
        expect(is_outdoor_tour).to be(true),
          "未选择户外探险主题行程。当前行程: #{tour.title}, 评分: #{tour.rating}, 天数: #{tour.duration}天"
      end
      
      add_assertion "出行日期正确", weight: 10 do
        expect(@tour_booking.travel_date).to eq(@travel_date),
          "出行日期错误。期望: #{@travel_date}（10天后），实际: #{@tour_booking.travel_date}"
      end
      
      add_assertion "联系人信息正确（刘强）", weight: 10 do
        expect(@tour_booking.contact_name).to eq(@expected_contact_name),
          "联系人姓名错误。期望: #{@expected_contact_name}（刘强），实际: #{@tour_booking.contact_name}"
        expect(@tour_booking.contact_phone).to eq(@expected_contact_phone),
          "联系电话错误。期望: #{@expected_contact_phone}，实际: #{@tour_booking.contact_phone}"
      end
      
      add_assertion "购买了旅游保险", weight: 10 do
        insurance_type = @tour_booking.insurance_type
        has_insurance = ['standard', 'premium'].include?(insurance_type)
        expect(has_insurance).to be(true),
          "未购买保险。当前保险类型: #{insurance_type || 'none'}"
      end
      
      add_assertion "游客信息正确（刘强）", weight: 15 do
        travelers = @tour_booking.booking_travelers.where(data_version: @data_version).to_a
        
        expect(travelers.size).to eq(1),
          "游客数量不正确。期望: 1个游客（刘强），实际: #{travelers.size}个游客"
        
        traveler = travelers.first
        expect(traveler.traveler_name).to eq(@expected_traveler_name),
          "游客姓名错误。期望: #{@expected_traveler_name}（刘强），实际: #{traveler.traveler_name}"
        
        expect(traveler.id_number).to eq(@expected_id_number),
          "身份证号错误。期望: #{@expected_id_number}，实际: #{traveler.id_number}"
      end
      
      add_assertion "订单状态正确", weight: 5 do
        valid_statuses = ['pending', 'confirmed', 'paid']
        expect(valid_statuses).to include(@tour_booking.status),
          "订单状态错误: #{@tour_booking.status}"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 1. 预订户外探险跟团游
      tour_product = TourGroupProduct
        .where(destination: @destination, data_version: 0)
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
        contact_name: @liuqiang.name,
        contact_phone: @liuqiang.phone,
        total_price: tour_package.price,
        status: 'pending',
        insurance_type: 'premium',  # 高风险保险
        data_version: @data_version
      )
      
      # Create traveler record for 刘强
      BookingTraveler.create!(
        tour_group_booking_id: booking.id,
        traveler_name: @liuqiang.name,
        id_number: @liuqiang.id_number,
        traveler_type: 'adult',
        data_version: @data_version
      )
      
      # 跟团游已包含装备，无需单独租赁
    end
    
    private
    
    def execution_state_data
      {
        destination: @destination,
        travel_date: @travel_date&.to_s,
        expected_contact_name: @expected_contact_name,
        expected_contact_phone: @expected_contact_phone,
        expected_traveler_name: @expected_traveler_name,
        expected_id_number: @expected_id_number
      }
    end
    
    def restore_from_state(data)
      @destination = data['destination']
      @travel_date = Date.parse(data['travel_date']) if data['travel_date']
      @expected_contact_name = data['expected_contact_name']
      @expected_contact_phone = data['expected_contact_phone']
      @expected_traveler_name = data['expected_traveler_name']
      @expected_id_number = data['expected_id_number']
      
      # Restore passenger reference
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @liuqiang = user.passengers.find_by!(name: '刘强', data_version: 0)
    end
  end
end
