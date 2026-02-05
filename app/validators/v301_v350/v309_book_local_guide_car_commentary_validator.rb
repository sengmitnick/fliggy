# frozen_string_literal: true

require_relative '../base_validator'

# V309: 预订当地司导+包车+景点讲解
#
# 任务描述:
#   用户需要预订深度旅行服务，包含专业导游、包车和景点讲解
#
# 评分标准:
#   - 创建了深度旅行订单（导游讲解）(40%)
#   - 创建了包车订单 (30%)
#   - 服务日期正确 (20%)
#   - 订单状态和价格有效 (10%)
module V301V350
  class V309BookLocalGuideCarCommentaryValidator < BaseValidator
    self.validator_id = 'v309_book_local_guide_car_commentary_validator'
    self.task_id = 'f309a001-0001-4001-8001-000000000309'
    self.title = '预订当地司导+包车+景点讲解'
    self.description = '用户需要预订深度旅行服务，包含专业导游、包车和景点讲解'
    self.timeout_seconds = 300
    
    def prepare
      @travel_date = Date.current + 5.days
      @participant_count = 4
      @location = '北京'
      
      # 查找北京地区的深度旅行产品
      @deep_travel_product = DeepTravelProduct
        .joins(:deep_travel_guide)
        .where(location: @location, data_version: 0)
        .where('deep_travel_products.title LIKE ?', '%讲解%')
        .first
      
      @deep_travel_product ||= DeepTravelProduct
        .joins(:deep_travel_guide)
        .where(location: @location, data_version: 0)
        .first
      
      raise "未找到#{@location}的深度旅行产品" unless @deep_travel_product
      
      @guide = @deep_travel_product.deep_travel_guide
      
      # 查找包车服务
      @car = Car.where(data_version: 0, category: 'mpv').first
      @car ||= Car.where(data_version: 0).first
      raise "未找到可用车辆" unless @car
      
      {
        task: "请预订#{@location}的深度旅行服务（#{@travel_date.strftime('%Y年%m月%d日')}，#{@participant_count}人），包含当地司导、包车和景点讲解服务。",
        requirements: {
          location: @location,
          travel_date: @travel_date,
          participant_count: @participant_count,
          services: ['专业导游', '包车服务', '景点讲解']
        },
        hint: "需要预订深度旅行产品（导游讲解）和包车服务。"
      }
    end
    
    def verify
      add_assertion "创建了深度旅行订单（导游讲解）", weight: 40 do
        @deep_travel_booking = DeepTravelBooking
          .joins(:deep_travel_product)
          .where(deep_travel_products: { location: @location })
          .where(data_version: @data_version)
          .first
        
        expect(@deep_travel_booking).not_to be_nil, "未找到#{@location}的深度旅行订单"
      end
      
      return if @deep_travel_booking.nil?
      
      add_assertion "创建了包车订单", weight: 30 do
        @car_order = CarOrder
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@car_order).not_to be_nil, "未找到包车订单"
      end
      
      add_assertion "服务日期正确", weight: 20 do
        expect(@deep_travel_booking.travel_date).to eq(@travel_date),
          "深度旅行日期错误。期望: #{@travel_date}，实际: #{@deep_travel_booking.travel_date}"
        
        if @car_order
          expect(@car_order.pickup_datetime.to_date).to eq(@travel_date),
            "包车取车日期错误。期望: #{@travel_date}，实际: #{@car_order.pickup_datetime.to_date}"
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
      
      # 1. 创建深度旅行订单
      DeepTravelBooking.create!(
        user: user,
        deep_travel_guide: @guide,
        deep_travel_product: @deep_travel_product,
        travel_date: @travel_date,
        adult_count: @participant_count,
        child_count: 0,
        contact_name: user.name,
        contact_phone: '13800138000',
        total_price: @deep_travel_product.price,
        insurance_price: 0,
        status: 'paid',
        data_version: @data_version
      )
      
      # 2. 创建包车订单
      pickup_datetime = @travel_date.to_time + 9.hours
      return_datetime = @travel_date.to_time + 18.hours
      
      CarOrder.create!(
        user: user,
        car: @car,
        pickup_datetime: pickup_datetime,
        return_datetime: return_datetime,
        total_price: @car.price_per_day,
        pickup_location: @location,
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
        travel_date: @travel_date.to_s,
        participant_count: @participant_count,
        location: @location,
        deep_travel_product_id: @deep_travel_product&.id,
        guide_id: @guide&.id,
        car_id: @car&.id
      }
    end
    
    def restore_from_state(data)
      @travel_date = Date.parse(data['travel_date'])
      @participant_count = data['participant_count']
      @location = data['location']
      
      @deep_travel_product = DeepTravelProduct.find(data['deep_travel_product_id']) if data['deep_travel_product_id']
      @guide = DeepTravelGuide.find(data['guide_id']) if data['guide_id']
      @car = Car.find(data['car_id']) if data['car_id']
    end
  end
end
