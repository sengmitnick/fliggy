# frozen_string_literal: true

require_relative '../base_validator'

# V258: 给张三预订成都租车3天（后天取车）并购买交通意外险
#
# 任务描述:
#   帮张三在成都预订租车3天（后天取车），并购买交通意外险，保险保障天数必须覆盖整个租车期间
#
# 评分标准:
#   - 创建了租车订单 (20%)
#   - 取车日期正确（后天）(10%)
#   - 创建了保险订单 (20%)
#   - 保险类型正确（交通意外险）(15%)
#   - 保险保障天数与租车天数匹配 (15%)
#   - 驾驶人信息正确（张三） (10%)
#   - 投保人信息正确（张三） (5%)
#   - 订单状态有效 (5%)
module V251V300
  class V258BookCarWithFullInsuranceValidator < BaseValidator
    self.validator_id = 'v258_book_car_with_full_insurance_validator'
    self.task_id = '7785f506-a374-4f39-b8f3-08cffdf278fb'
    self.title = '给张三预订成都租车3天（后天取车）并购买交通意外险'
    self.description = '帮张三在成都租车3天（后天取车），并购买交通意外险（保障天数覆盖整个租车期间）'
    self.timeout_seconds = 300
    
    def prepare
      @city = '成都'
      @pickup_date = Date.current + 2.days
      @return_date = @pickup_date + 3.days
      @rental_days = (@return_date - @pickup_date).to_i
      
      # 查询 demo_user 和驾驶人信息（基线数据）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @zhangsan = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_driver_name = @zhangsan.name
      @expected_driver_id = @zhangsan.id_number
      @expected_contact_phone = @zhangsan.phone
      @expected_insured_name = @zhangsan.name
      
      # 查找租车产品
      @car = Car
        .where(location: @city, is_available: true, data_version: 0)
        .first
      
      raise "未找到#{@city}的可用租车" unless @car
      
      # 查找交通意外险
      @available_insurances = InsuranceProduct
        .where(product_type: 'transport', data_version: 0)
        .where('min_days <= ? AND max_days >= ?', @rental_days, @rental_days)
        .to_a
      
      raise "未找到适合#{@rental_days}天的交通意外险" if @available_insurances.empty?
      
      {
        task: "请为张三预订#{@city}租车（#{@pickup_date.strftime('%Y年%m月%d日')}取车，#{@return_date.strftime('%Y年%m月%d日')}还车，共#{@rental_days}天），并购买交通意外险（保障天数需覆盖整个租车期间）。",
        requirements: {
          driver_name: '张三',
          city: @city,
          pickup_date: @pickup_date,
          return_date: @return_date,
          rental_days: @rental_days,
          insurance_type: '交通意外险',
          insurance_coverage: '驾驶期间人身安全'
        },
        hint: "租车建议购买交通意外险，保障天数应与租车天数一致。"
      }
    end
    
    def verify
      add_assertion "创建了租车订单", weight: 20 do
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
      
      add_assertion "取车日期正确（后天）", weight: 10 do
        actual_pickup_date = @car_order.pickup_datetime.to_date
        expect(actual_pickup_date).to eq(@pickup_date),
          "取车日期错误。期望: #{@pickup_date}（后天），实际: #{actual_pickup_date}"
      end
      
      add_assertion "创建了保险订单", weight: 20 do
        @insurance_order = InsuranceOrder
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@insurance_order).not_to be_nil, "未找到保险订单"
      end
      
      return if @insurance_order.nil?
      
      add_assertion "保险类型正确（交通意外险）", weight: 15 do
        product_type = @insurance_order.insurance_product.product_type
        expect(product_type).to eq('transport'),
          "保险类型错误。期望: transport（交通意外险），实际: #{product_type}"
      end
      
      add_assertion "保险保障天数与租车天数匹配", weight: 15 do
        insurance_days = @insurance_order.days
        pickup = @car_order.pickup_datetime.to_date
        return_dt = @car_order.return_datetime.to_date
        rental_days = (return_dt - pickup).to_i
        
        expect(insurance_days).to be >= rental_days,
          "保险天数不足。租车天数: #{rental_days}天，保险天数: #{insurance_days}天"
      end
      
      add_assertion "驾驶人信息正确（张三）", weight: 10 do
        expect(@car_order.driver_name).to eq(@expected_driver_name),
          "驾驶人姓名错误。期望: #{@expected_driver_name}，实际: #{@car_order.driver_name}"
        
        expect(@car_order.driver_id_number).to eq(@expected_driver_id),
          "驾驶人证件号错误。期望: #{@expected_driver_id}，实际: #{@car_order.driver_id_number}"
        
        expect(@car_order.contact_phone).to eq(@expected_contact_phone),
          "联系电话错误。期望: #{@expected_contact_phone}，实际: #{@car_order.contact_phone}"
      end
      
      add_assertion "投保人信息正确（张三）", weight: 5 do
        insured = @insurance_order.insured_persons || []
        expect(insured).to include(@expected_insured_name),
          "投保人列表中缺少#{@expected_insured_name}。期望: [#{@expected_insured_name}]，实际: #{insured.inspect}"
      end
      
      add_assertion "订单状态有效", weight: 5 do
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
        driver_name: @zhangsan.name,
        driver_id_number: @zhangsan.id_number,
        contact_phone: @zhangsan.phone,
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
        insured_persons: [@zhangsan.name],
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
        car_id: @car&.id,
        expected_driver_name: @expected_driver_name,
        expected_driver_id: @expected_driver_id,
        expected_contact_phone: @expected_contact_phone,
        expected_insured_name: @expected_insured_name
      }
    end
    
    def restore_from_state(data)
      @city = data['city']
      @pickup_date = Date.parse(data['pickup_date'])
      @return_date = Date.parse(data['return_date'])
      @rental_days = data['rental_days']
      @expected_driver_name = data['expected_driver_name']
      @expected_driver_id = data['expected_driver_id']
      @expected_contact_phone = data['expected_contact_phone']
      @expected_insured_name = data['expected_insured_name']
      
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @zhangsan = user.passengers.find_by!(name: '张三', data_version: 0)
      
      @car = Car.find(data['car_id']) if data['car_id']
      
      @available_insurances = InsuranceProduct
        .where(product_type: 'transport', data_version: 0)
        .where('min_days <= ? AND max_days >= ?', @rental_days, @rental_days)
        .to_a
    end
  end
end
