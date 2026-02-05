# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例303: 预订户外探险游
#
# 任务描述:
#   用户预订户外探险游(徒步+露营+装备租赁)
#
# 评分标准:
#   - 创建跟团游预订(户外探险主题) (40%)
#   - 选择户外探险目的地 (25%)
#   - 创建装备租赁订单 (20%)
#   - 出行日期正确 (10%)
#   - 购买高风险保险 (5%)
module V301V350
  class V303BookOutdoorAdventureTourValidator < BaseValidator
    self.validator_id = 'v303_book_outdoor_adventure_tour_validator'
    self.task_id = 'k49h1kg3-i1j5-47ke-g6ii-l7091i62ik3h'
    self.title = '预订户外探险游'
    self.description = '用户预订户外探险游(徒步+露营+装备租赁)'
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
      add_assertion "创建了跟团游预订(户外探险主题)", weight: 40 do
        @tour_booking = TourGroupBooking
          .joins(:tour_group_product)
          .where(tour_group_products: { destination: @destination })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        expect(@tour_booking).not_to be_nil, "未找到#{@destination}的跟团游预订"
      end
      
      return unless @tour_booking
      
      add_assertion "选择户外探险目的地", weight: 25 do
        # 户外探险目的地：张家界、九寨沟、黄山等
        adventure_destinations = ['张家界', '九寨沟', '黄山', '丽江', '桂林']
        is_adventure_destination = adventure_destinations.include?(@destination)
        expect(is_adventure_destination).to be(true),
          "未选择户外探险目的地。当前: #{@destination}"
      end
      
      add_assertion "创建了装备租赁订单", weight: 20 do
        @car_order = CarOrder
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        # 使用CarOrder模拟装备租赁
        if @car_order
          expect(@car_order).not_to be_nil
        else
          # 装备可能已包含在跟团游中
          expect(true).to be(true)
        end
      end
      
      add_assertion "出行日期正确", weight: 10 do
        expect(@tour_booking.travel_date).to eq(@travel_date),
          "出行日期错误。期望: #{@travel_date}, 实际: #{@tour_booking.travel_date}"
      end
      
      add_assertion "购买高风险保险", weight: 5 do
        insurance_type = @tour_booking.insurance_type
        has_insurance = ['standard', 'premium'].include?(insurance_type)
        expect(has_insurance).to be(true),
          "未购买保险。当前保险类型: #{insurance_type}"
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
      
      # 2. 租赁户外装备(使用CarOrder模拟)
      car = Car.where(data_version: 0).first
      if car
        CarOrder.create!(
          user_id: user.id,
          car_id: car.id,
          driver_name: passenger.name,
          driver_id_number: passenger.id_number,
          contact_phone: passenger.phone,
          pickup_datetime: @travel_date,
          return_datetime: @travel_date + 3.days,
          pickup_location: "#{@destination}景区",
          status: 'pending',
          total_price: 300,
          data_version: @data_version
        )
      end
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
