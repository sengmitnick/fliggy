# frozen_string_literal: true

module V251V300
  class V299BookPhotographyThemeTourValidator < BaseValidator
    self.validator_id = 299
    self.task_id = 'c0a80165-0299-4000-a000-000000000299'
    self.title = '预订摄影主题游'
    self.description = '用户想要去云南进行摄影主题旅游，需要选择风景优美的跟团游产品（评分≥4.5），出发日期为7天后'
    self.timeout_seconds = 300
    
    def prepare
      @destination = '云南'
      @travel_date = Date.today + 7.days
      @visit_date = Date.today + 8.days
      
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
      add_assertion "创建了跟团游预订(摄影主题)", weight: 50 do
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
      
      add_assertion "预订日期正确", weight: 15 do
        expect(@tour_booking.travel_date).to eq(@travel_date),
          "出行日期错误。期望: #{@travel_date}, 实际: #{@tour_booking.travel_date}"
      end
      
      add_assertion "预订人数正确(1人)", weight: 10 do
        total_passengers = @tour_booking.adult_count + @tour_booking.child_count
        expect(total_passengers).to eq(1),
          "预订人数错误。期望: 1人，实际: #{total_passengers}人"
      end
      
      # 可选项:景区活动订单(摄影服务)
      @activity_order = ActivityOrder
        .joins(attraction_activity: :attraction)
        .where(attractions: { city: @destination })
        .where(data_version: @data_version)
        .order(created_at: :desc)
        .first
      
      if @activity_order
        # 如果创建了活动订单,则额外加分(不影响基础分数)
        add_assertion "额外预订了景区摄影服务活动(加分项)", weight: 0 do
          expect(@activity_order).not_to be_nil
        end
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 1. 预订摄影主题跟团游
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
        p.name = '张小姐'
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
      
      # 2. 预订景区摄影服务活动(可选)
      attraction = Attraction.where(city: @destination, data_version: 0).first
      if attraction
        activity = attraction.attraction_activities
          .where(activity_type: 'photo_service', data_version: 0)
          .first
        
        # 如果没有摄影服务，选择其他体验活动
        activity ||= attraction.attraction_activities.where(data_version: 0).first
        
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
