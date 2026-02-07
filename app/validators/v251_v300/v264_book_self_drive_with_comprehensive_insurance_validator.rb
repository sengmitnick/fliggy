# frozen_string_literal: true

require_relative '../base_validator'

# V264: 预订自驾游+适合自驾场景的旅游保险
#
# 任务描述:
#   3人需要预订自驾游并购买适合自驾游场景的旅游保险（境内旅游险或交通意外险）
#
# 评分标准:
#   - 创建了租车订单 (25%)
#   - 创建了保险订单 (25%)
#   - 保险类型适合自驾游 (15%)
#   - 保险人数正确（3人） (15%)
#   - 保险保障天数正确 (10%)
#   - 保险时间与租车时间一致 (10%)
module V251V300
  class V264BookSelfDriveWithComprehensiveInsuranceValidator < BaseValidator
    self.validator_id = 'v264_book_self_drive_with_comprehensive_insurance_validator'
    self.task_id = '7c2e2d2c-6733-4917-9166-69ac075dd6ce'
    self.title = '3人在杭州预订5天自驾游并购买适合自驾场景的旅游保险'
    self.description = '3人需要在杭州预订明天开始的5天自驾游（明天取车，5天后还车），并购买适合自驾游场景的旅游保险，保险需为3人投保，保险时间需与租车时间一致，保障天数覆盖整个租车期间（5天）'
    self.timeout_seconds = 300
    
    def prepare
      @city = '杭州'
      @pickup_date = Date.current + 1.day
      @return_date = @pickup_date + 5.days
      @rental_days = (@return_date - @pickup_date).to_i
      @travelers_count = 3
      
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
        task: "请为#{@travelers_count}人预订#{@city}自驾游（#{@pickup_date.strftime('%Y年%m月%d日')}取车，#{@return_date.strftime('%Y年%m月%d日')}还车，共#{@rental_days}天），并购买适合自驾游场景的旅游保险。",
        requirements: {
          city: @city,
          pickup_date: @pickup_date,
          return_date: @return_date,
          rental_days: @rental_days,
          travelers_count: @travelers_count,
          insurance_type: '境内旅游险（自驾游场景）或交通意外险',
          insurance_coverage: '人身意外伤害保障',
          insured_persons: @travelers_count
        },
        hint: "自驾游建议购买适合自驾游场景的旅游保险，#{@travelers_count}人都需要投保，保障期间应覆盖整个租车期间。"
      }
    end
    
    def verify
      add_assertion "创建了租车订单", weight: 25 do
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
      
      add_assertion "创建了保险订单", weight: 25 do
        @insurance_order = InsuranceOrder
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@insurance_order).not_to be_nil, "未找到保险订单"
      end
      
      return if @insurance_order.nil?
      
      add_assertion "保险类型适合自驾游", weight: 15 do
        product_type = @insurance_order.insurance_product.product_type
        scenes = @insurance_order.insurance_product.scenes || []
        
        is_suitable = product_type == 'domestic' && scenes.include?('自驾游') ||
                      product_type == 'transport'
        
        expect(is_suitable).to be_truthy,
          "保险类型不适合自驾游。产品类型: #{product_type}，场景: #{scenes.inspect}"
      end
      
      add_assertion "保险人数正确（#{@travelers_count}人）", weight: 15 do
        insured_count = @insurance_order.insured_persons&.size || 0
        
        expect(insured_count).to eq(@travelers_count),
          "保险人数错误。期望: #{@travelers_count}人，实际: #{insured_count}人"
      end
      
      add_assertion "保险保障天数正确", weight: 10 do
        insurance_days = @insurance_order.days
        pickup = @car_order.pickup_datetime.to_date
        return_dt = @car_order.return_datetime.to_date
        rental_days = (return_dt - pickup).to_i
        
        expect(insurance_days).to be >= rental_days,
          "保险天数不足。租车天数: #{rental_days}天，保险天数: #{insurance_days}天"
      end
      
      add_assertion "保险时间与租车时间一致", weight: 10 do
        insurance_start = @insurance_order.start_date
        insurance_end = @insurance_order.end_date
        rental_start = @car_order.pickup_datetime.to_date
        rental_end = @car_order.return_datetime.to_date
        
        expect(insurance_start).to eq(rental_start),
          "保险开始日期不一致。租车: #{rental_start}，保险: #{insurance_start}"
        expect(insurance_end).to eq(rental_end),
          "保险结束日期不一致。租车: #{rental_end}，保险: #{insurance_end}"
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
      
      # 2. 创建保险订单（3人）
      insurance_product = @available_insurances.first
      start_date = @pickup_date
      end_date = @return_date
      unit_price = insurance_product.price_per_day * @rental_days
      
      # 3人投保人名单
      insured_persons = [user.name, "#{user.name}的同伴A", "#{user.name}的同伴B"]
      
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
        insured_persons: insured_persons,
        unit_price: unit_price,
        quantity: @travelers_count,
        total_price: unit_price * @travelers_count,
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
        travelers_count: @travelers_count,
        car_id: @car&.id
      }
    end
    
    def restore_from_state(data)
      @city = data['city']
      @pickup_date = Date.parse(data['pickup_date'])
      @return_date = Date.parse(data['return_date'])
      @rental_days = data['rental_days']
      @travelers_count = data['travelers_count'] || 3
      
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
