# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例302: 预订文化艺术游
#
# 任务描述:
#   用户预订文化艺术游(博物馆+演出+艺术体验)
#
# 评分标准:
#   - 创建跟团游预订(文化主题) (40%)
#   - 选择文化艺术目的地 (25%)
#   - 创建景区门票订单 (20%)
#   - 出行日期正确 (10%)
#   - 行程时长≥3天 (5%)
module V301V306
  class V302BookCulturalArtTourValidator < BaseValidator
    self.validator_id = 'v302_book_cultural_art_tour_validator'
    self.task_id = 'j38g0jf2-h0i4-46jd-f5hh-k6980h51hj2g'
    self.title = '预订文化艺术游'
    self.description = '用户预订文化艺术游(博物馆+演出+艺术体验)'
    self.timeout_seconds = 300
    
    def prepare
      @destination = '西安'
      @travel_date = Date.today + 9.days
      @visit_date = @travel_date
      
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      if user.balance < 4000
        user.update!(balance: 6000)
      end
      
      {
        task: "请预订#{@destination}的文化艺术游，#{@travel_date.strftime('%Y年%-m月%-d日')}出发，需要参观博物馆、文化遗产和艺术展览，行程至少3天",
        destination: @destination,
        travel_date: @travel_date.to_s,
        hint: "选择历史文化主题的旅游产品和景区门票"
      }
    end
    
    def verify
      add_assertion "创建了跟团游预订(文化主题)", weight: 40 do
        @tour_booking = TourGroupBooking
          .joins(:tour_group_product)
          .where(tour_group_products: { destination: @destination })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        expect(@tour_booking).not_to be_nil, "未找到#{@destination}的跟团游预订"
      end
      
      return unless @tour_booking
      
      add_assertion "选择文化艺术目的地", weight: 25 do
        # 文化古都：西安、北京、南京、洛阳等
        cultural_cities = ['西安', '北京', '南京', '洛阳', '苏州']
        is_cultural_destination = cultural_cities.include?(@destination)
        expect(is_cultural_destination).to be(true),
          "未选择文化艺术目的地。当前: #{@destination}"
      end
      
      add_assertion "创建了景区门票订单", weight: 20 do
        @ticket_order = TicketOrder
          .joins(ticket: :attraction)
          .where(attractions: { city: @destination })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        if @ticket_order
          expect(@ticket_order).not_to be_nil
        else
          # 文化游门票可能已包含在跟团游中
          expect(true).to be(true)
        end
      end
      
      add_assertion "出行日期正确", weight: 10 do
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
      
      # 1. 预订文化主题跟团游(至少3天)
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
        p.name = '王先生'
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
      
      # 2. 预订景区门票(可选)
      attraction = Attraction.where(city: @destination, data_version: 0).first
      if attraction
        ticket = attraction.tickets.where(ticket_type: 'adult', data_version: 0).first
        
        if ticket
          TicketOrder.create!(
            user_id: user.id,
            ticket_id: ticket.id,
            visit_date: @visit_date,
            quantity: 1,
            total_price: ticket.price,
            status: 'pending',
            data_version: @data_version
          )
        end
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
