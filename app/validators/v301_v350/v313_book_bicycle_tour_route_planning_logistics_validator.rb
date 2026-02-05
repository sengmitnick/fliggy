# frozen_string_literal: true

require_relative '../base_validator'

# V313: 预订自行车骑行+路线规划+后勤支持
#
# 任务描述:
#   用户需要预订自行车骑行服务，包含路线规划和后勤支持
#
# 评分标准:
#   - 创建了深度旅行订单（骑行向导）(40%)
#   - 创建了租车订单（自行车租赁）(35%)
#   - 服务日期正确 (15%)
#   - 订单状态和价格有效 (10%)
module V301V350
  class V313BookBicycleTourRoutePlanningLogisticsValidator < BaseValidator
    self.validator_id = 'v313_book_bicycle_tour_route_planning_logistics_validator'
    self.task_id = 'f313a001-0001-4001-8001-000000000313'
    self.title = '预订自行车骑行+路线规划+后勤支持'
    self.description = '用户需要预订自行车骑行服务，包含路线规划和后勤支持'
    self.timeout_seconds = 300
    
    def prepare
      @tour_date = Date.current + 5.days
      @participant_count = 3
      @location = '华东'
      
      # 查找华东地区的深度旅行产品（路线规划）
      @deep_travel_product = DeepTravelProduct
        .joins(:deep_travel_guide)
        .where("deep_travel_products.location LIKE ?", "%#{@location}%")
        .where(data_version: 0)
        .first
      
      @deep_travel_product ||= DeepTravelProduct
        .joins(:deep_travel_guide)
        .where(data_version: 0)
        .first
      
      raise "未找到深度旅行产品" unless @deep_travel_product
      
      @guide = @deep_travel_product.deep_travel_guide
      
      # 查找租车服务（自行车租赁）
      @car = Car.where(data_version: 0, category: 'sedan').first
      @car ||= Car.where(data_version: 0).first
      raise "未找到可用车辆（自行车租赁）" unless @car
      
      {
        task: "请预订自行车骑行服务（#{@tour_date.strftime('%Y年%m月%d日')}，#{@participant_count}人），包含专业路线规划和后勤支持。",
        requirements: {
          tour_date: @tour_date,
          participant_count: @participant_count,
          services: ['路线规划', '骑行向导', '自行车租赁', '后勤支持']
        },
        hint: "需要预订深度旅行产品（向导+规划）和租车服务（自行车）。"
      }
    end
    
    def verify
      add_assertion "创建了深度旅行订单（骑行向导）", weight: 40 do
        @deep_travel_booking = DeepTravelBooking
          .where(data_version: @data_version)
          .first
        
        expect(@deep_travel_booking).not_to be_nil, "未找到深度旅行订单（骑行向导）"
      end
      
      return if @deep_travel_booking.nil?
      
      add_assertion "创建了租车订单（自行车租赁）", weight: 35 do
        @car_order = CarOrder
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@car_order).not_to be_nil, "未找到租车订单（自行车租赁）"
      end
      
      add_assertion "服务日期正确", weight: 15 do
        expect(@deep_travel_booking.travel_date).to eq(@tour_date),
          "深度旅行日期错误。期望: #{@tour_date}，实际: #{@deep_travel_booking.travel_date}"
        
        if @car_order
          expect(@car_order.pickup_datetime.to_date).to eq(@tour_date),
            "租车日期错误。期望: #{@tour_date}，实际: #{@car_order.pickup_datetime.to_date}"
        end
      end
      
      add_assertion "订单状态和价格有效", weight: 10 do
        expect(@deep_travel_booking.status).to be_in(['pending', 'paid', 'confirmed'])
        expect(@deep_travel_booking.total_price).to be > 0
        
        if @car_order
          expect(@car_order.status).to be_in(['pending', 'paid', 'confirmed'])
          expect(@car_order.total_price).to be > 0
        end
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 1. 创建深度旅行订单（骑行向导+路线规划）
      DeepTravelBooking.create!(
        user: user,
        deep_travel_guide: @guide,
        deep_travel_product: @deep_travel_product,
        travel_date: @tour_date,
        adult_count: @participant_count,
        child_count: 0,
        contact_name: user.name,
        contact_phone: '13800138000',
        total_price: @deep_travel_product.price,
        insurance_price: 0,
        status: 'paid',
        notes: '骑行向导+路线规划+后勤支持',
        data_version: @data_version
      )
      
      # 2. 创建租车订单（自行车租赁）
      pickup_datetime = @tour_date.to_time + 9.hours
      return_datetime = @tour_date.to_time + 18.hours
      
      CarOrder.create!(
        user: user,
        car: @car,
        pickup_datetime: pickup_datetime,
        return_datetime: return_datetime,
        total_price: @car.price_per_day,
        pickup_location: '骑行起点',
        driver_name: user.name,
        driver_id_number: '310101198001011234',
        contact_phone: '13800138000',
        status: 'paid',
        data_version: @data_version
      )
    end
    
    private
    
    def execution_state_data
      {
        tour_date: @tour_date.to_s,
        participant_count: @participant_count,
        location: @location,
        deep_travel_product_id: @deep_travel_product&.id,
        guide_id: @guide&.id,
        car_id: @car&.id
      }
    end
    
    def restore_from_state(data)
      @tour_date = Date.parse(data['tour_date'])
      @participant_count = data['participant_count']
      @location = data['location']
      
      @deep_travel_product = DeepTravelProduct.find(data['deep_travel_product_id']) if data['deep_travel_product_id']
      @guide = DeepTravelGuide.find(data['guide_id']) if data['guide_id']
      @car = Car.find(data['car_id']) if data['car_id']
    end
  end
end
