# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例303: 预订户外探险游
#
# 任务描述:
#   用户预订户外探险游(徒步+露营+装备租赁)
#
# 评分标准:
#   - 创建了张家界跟团游预订 (50%)
#   - 目的地为张家界 (30%)
#   - 出行日期正确 (15%)
#   - 购买了旅游保险 (5%)
module V301V350
  class V303BookOutdoorAdventureTourValidator < BaseValidator
    self.validator_id = 'v303_book_outdoor_adventure_tour_validator'
    self.task_id = 'd11ffc15-c4d4-478c-a93f-67e8662ba77f'
    self.title = '预订张家界跟团游（10天后出发）'
    self.description = '预订张家界的跟团游产品，10天后出发，需要购买旅游保险'
    self.timeout_seconds = 300
    
    def prepare
      @destination = '张家界'
      @travel_date = Date.current + 10.days
      
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      if user.balance < 5000
        user.update!(balance: 8000)
      end
      
      {
        task: "请预订#{@destination}的户外探险游，#{@travel_date.strftime('%Y年%-m月%-d日')}出发，需要徒步登山、露营体验和专业装备，适合户外探险爱好者",
        destination: @destination,
        travel_date: @travel_date.to_s,
        hint: "选择户外探险主题的旅游产品，租赁装备，购买保险"
      }
    end
    
    def verify
      add_assertion "创建了张家界跟团游预订", weight: 50 do
        @tour_booking = TourGroupBooking
          .joins(:tour_group_product)
          .where(tour_group_products: { destination: @destination })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        expect(@tour_booking).not_to be_nil, "未找到#{@destination}的跟团游预订"
      end
      
      return unless @tour_booking
      
      add_assertion "目的地为张家界", weight: 30 do
        expect(@tour_booking.tour_group_product.destination).to eq(@destination),
          "目的地错误。期望: #{@destination}（张家界），实际: #{@tour_booking.tour_group_product.destination}"
      end
      
      add_assertion "出行日期正确", weight: 15 do
        expect(@tour_booking.travel_date).to eq(@travel_date),
          "出行日期错误。期望: #{@travel_date}, 实际: #{@tour_booking.travel_date}"
      end
      
      add_assertion "购买了旅游保险", weight: 5 do
        insurance_type = @tour_booking.insurance_type
        has_insurance = ['standard', 'premium'].include?(insurance_type)
        expect(has_insurance).to be(true),
          "未购买保险。当前保险类型: #{insurance_type || 'none'}"
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
      
      passenger = Passenger.find_or_create_by!(
        user_id: user.id,
        id_number: '440300199001011234',
        data_version: @data_version
      ) do |p|
        p.name = '刘先生'
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
        insurance_type: 'premium',  # 高风险保险
        data_version: @data_version
      )
      
      # 跟团游已包含装备，无需单独租赁
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
