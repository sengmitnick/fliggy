# frozen_string_literal: true

require_relative '../base_validator'

# V264: 预订自驾游+人身险+车险+道路救援
#
# 任务描述:
#   用户需要预订自驾游并购买人身险、车险和道路救援组合保险
#
# 评分标准:
#   - 创建了租车订单 (30%)
#   - 创建了保险订单 (30%)
#   - 保险类型适合自驾游 (20%)
#   - 保险保障天数正确 (10%)
#   - 订单状态有效 (10%)
module V251V300
  class V264BookSelfDriveWithComprehensiveInsuranceValidator < BaseValidator
    self.validator_id = 'v264_book_self_drive_with_comprehensive_insurance_validator'
    self.task_id = 'f257a001-0001-4001-8001-000000000264'
    self.title = '预订自驾游+人身险+车险+道路救援'
    self.description = '用户需要预订自驾游并购买人身险、车险和道路救援组合保险'
    self.timeout_seconds = 300
    
    def prepare
      @city = '杭州'
      @pickup_date = Date.today + 1.day
      @return_date = @pickup_date + 5.days
      @rental_days = (@return_date - @pickup_date).to_i
      
      # 查找租车产品
      @car = Car
        .where(location: @city, is_available: true, data_version: 0)
        .first
      
      raise "未找到#{@city}的可用租车" unless @car
      
      # 查找适合自驾游的保险产品
      @available_insurances = InsuranceProduct
        .where(product_type: 'domestic', data_version: 0)
        .where('min_days <= ? AND max_days >= ?', @rental_days, @rental_days)
        .select { |p| p.scenes&.include?('自驾游') }
      
      # 如果没有自驾游保险，使用交通意外险
      if @available_insurances.empty?
        @available_insurances = InsuranceProduct
          .where(product_type: 'transport', data_version: 0)
          .where('min_days <= ? AND max_days >= ?', @rental_days, @rental_days)
          .to_a
      end
      
      raise "未找到适合#{@rental_days}天的保险产品" if @available_insurances.empty?
      
      {
        task: "请预订#{@city}自驾游（#{@pickup_date.strftime('%Y年%m月%d日')}取车，#{@return_date.strftime('%Y年%m月%d日')}还车，共#{@rental_days}天），并购买人身险+车险+道路救援组合保险。",
        requirements: {
          city: @city,
          pickup_date: @pickup_date,
          return_date: @return_date,
          rental_days: @rental_days,
          insurance_type: '自驾游保险',
          insurance_coverage: '人身+车辆+道路救援'
        },
        hint: "自驾游建议购买包含人身意外、车辆损失和道路救援的综合保险。"
      }
    end
    
    def verify
      add_assertion "创建了租车订单", weight: 30 do
        all_orders = CarOrder
          .joins(:car)
          .includes(:car)
          .where(cars: { location: @city })
          .where(data_version: @data_version)
          .to_a
        
        @car_order = all_orders.first
        expect(@car_order).not_to be_nil, "未找到#{@city}的租车订单"
      end
      
      return if @car_order.nil?
      
      add_assertion "创建了保险订单", weight: 30 do
        @insurance_order = InsuranceOrder
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@insurance_order).not_to be_nil, "未找到保险订单"
      end
      
      return if @insurance_order.nil?
      
      add_assertion "保险类型适合自驾游", weight: 20 do
        product_type = @insurance_order.insurance_product.product_type
        scenes = @insurance_order.insurance_product.scenes || []
        
        is_suitable = product_type == 'domestic' && scenes.include?('自驾游') ||
                      product_type == 'transport'
        
        expect(is_suitable).to be_truthy,
          "保险类型不适合自驾游。产品类型: #{product_type}，场景: #{scenes.inspect}"
      end
      
      add_assertion "保险保障天数正确", weight: 10 do
        insurance_days = @insurance_order.days
        pickup = @car_order.pickup_datetime.to_date
        return_dt = @car_order.return_datetime.to_date
        rental_days = (return_dt - pickup).to_i
        
        expect(insurance_days).to be >= rental_days,
          "保险天数不足。租车天数: #{rental_days}天，保险天数: #{insurance_days}天"
      end
      
      add_assertion "订单状态有效", weight: 10 do
        expect(@car_order.status).to be_in(['pending', 'paid', 'confirmed'])
        expect(@insurance_order.status).to be_in(['pending', 'paid'])
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 1. 创建租车订单
      pickup_datetime = @pickup_date.to_time + 9.hours
      return_datetime = @return_date.to_time + 18.hours
      
      car_order = CarOrder.create!(
        user: user,
        car: @car,
        driver_name: user.name,
        driver_id_number: '110101199001011234',
        contact_phone: '13800138000',
        pickup_datetime: pickup_datetime,
        return_datetime: return_datetime,
        pickup_location: @car.pickup_location,
        total_price: @car.price_per_day * @rental_days,
        status: 'paid',
        data_version: @data_version
      )
      
      # 2. 创建保险订单
      insurance_product = @available_insurances.first
      start_date = @pickup_date
      end_date = @return_date
      unit_price = insurance_product.price_per_day * @rental_days
      
      InsuranceOrder.create!(
        user: user,
        insurance_product: insurance_product,
        source: 'standalone',
        related_booking_type: 'CarOrder',
        related_booking_id: car_order.id,
        start_date: start_date,
        end_date: end_date,
        days: @rental_days,
        destination: @city,
        destination_type: 'domestic',
        insured_persons: [user.name],
        unit_price: unit_price,
        quantity: 1,
        total_price: unit_price,
        status: 'paid',
        data_version: @data_version
      )
    end
    
    private
    
    def execution_state_data
      {
        city: @city,
        pickup_date: @pickup_date.to_s,
        return_date: @return_date.to_s,
        rental_days: @rental_days,
        car_id: @car&.id
      }
    end
    
    def restore_from_state(data)
      @city = data['city']
      @pickup_date = Date.parse(data['pickup_date'])
      @return_date = Date.parse(data['return_date'])
      @rental_days = data['rental_days']
      
      @car = Car.find(data['car_id']) if data['car_id']
      
      @available_insurances = InsuranceProduct
        .where(product_type: 'domestic', data_version: 0)
        .where('min_days <= ? AND max_days >= ?', @rental_days, @rental_days)
        .select { |p| p.scenes&.include?('自驾游') }
      
      if @available_insurances.empty?
        @available_insurances = InsuranceProduct
          .where(product_type: 'transport', data_version: 0)
          .where('min_days <= ? AND max_days >= ?', @rental_days, @rental_days)
          .to_a
      end
    end
  end
end
