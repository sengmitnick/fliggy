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
#   - 联系人信息正确（张三/李四/王芳任一） (10%)
#   - 保险人数正确（3人） (10%)
#   - 被保险人信息正确（张三、李四、王芳） (5%)
#   - 保险时间覆盖租车时间 (10%)
module V251V300
  class V264BookSelfDriveWithComprehensiveInsuranceValidator < BaseValidator
    self.validator_id = 'v264_book_self_drive_with_comprehensive_insurance_validator'
    self.task_id = '7c2e2d2c-6733-4917-9166-69ac075dd6ce'
    self.title = '帮张三、李四、王芳3人在杭州预订明天开始的5天自驾游（明天取车，5天后还车），并购买适合自驾游场景的旅游保险，保险需为3人投保，保险时间需与租车时间一致，保障天数覆盖整个租车期间（5天）'
    self.description = '帮张三、李四、王芳3人在杭州预订明天开始的5天自驾游（明天取车，5天后还车），并购买适合自驾游场景的旅游保险，保险需为3人投保，保险时间需与租车时间一致，保障天数覆盖整个租车期间（5天）'
    self.timeout_seconds = 300
    
    def prepare
      @city = '杭州'
      @pickup_date = Date.current + 1.day
      @return_date = @pickup_date + 5.days
      @rental_days = (@return_date - @pickup_date).to_i
      @travelers_count = 3
      
      # 查询用户和乘客信息
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @zhangsan = user.passengers.find_by!(name: '张三', data_version: 0)
      @lisi = user.passengers.find_by!(name: '李四', data_version: 0)
      @wangfang = user.passengers.find_by!(name: '王芳', data_version: 0)
      @expected_contact_names = [@zhangsan.name, @lisi.name, @wangfang.name]
      @expected_insured_names = [@zhangsan.name, @lisi.name, @wangfang.name]
      
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
        task: "请帮张三、李四、王芳3人预订#{@city}自驾游（#{@pickup_date.strftime('%Y年%m月%d日')}取车，明天取车，#{@return_date.strftime('%Y年%m月%d日')}还车，共#{@rental_days}天），并购买适合自驾游场景的旅游保险。3人都需要投保。",
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
      
      add_assertion "联系人信息正确（张三/李四/王芳任一）", weight: 10 do
        driver_name = @car_order.driver_name
        expect(@expected_contact_names).to include(driver_name),
          "驾驶员/联系人姓名错误。期望: #{@expected_contact_names.join('/')}中任一人，实际: #{driver_name}"
      end
      
      add_assertion "保险人数正确（#{@travelers_count}人）", weight: 10 do
        insured_count = @insurance_order.insured_persons&.size || 0
        
        expect(insured_count).to eq(@travelers_count),
          "保险人数错误。期望: #{@travelers_count}人，实际: #{insured_count}人"
      end
      
      add_assertion "被保险人信息正确（张三、李四、王芳）", weight: 5 do
        insured_persons = @insurance_order.insured_persons || []
        actual_names = insured_persons.map { |p| p.is_a?(Hash) ? p['name'] : p }.compact
        expect(actual_names).to match_array(@expected_insured_names),
          "被保险人姓名错误。期望: #{@expected_insured_names.join('、')}，实际: #{actual_names.join('、')}"
      end
      
      add_assertion "保险时间覆盖租车时间", weight: 10 do
        # 租车起止日期
        rental_start = @car_order.pickup_datetime.to_date
        rental_end = @car_order.return_datetime.to_date
        rental_days = (rental_end - rental_start).to_i
        
        # 保险起止日期
        insurance_start = @insurance_order.start_date
        insurance_end = @insurance_order.end_date
        insurance_days = @insurance_order.days
        
        # 验证保险天数覆盖租车天数
        expect(insurance_days).to be >= rental_days,
          "保险天数不足。租车天数: #{rental_days}天，保险天数: #{insurance_days}天"
        
        # 验证保险起始日期不晚于取车日期
        expect(insurance_start).to be <= rental_start,
          "保险起始日期晚于取车日期。取车日期: #{rental_start}，保险起始日期: #{insurance_start}"
        
        # 验证保险结束日期不早于还车日期
        expect(insurance_end).to be >= rental_end,
          "保险结束日期早于还车日期。还车日期: #{rental_end}，保险结束日期: #{insurance_end}"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 1. 创建租车订单（使用预查询的乘客信息）
      pickup_datetime = @pickup_date.beginning_of_day + 9.hours
      return_datetime = @return_date.beginning_of_day + 18.hours
      
      # 使用张三作为驾驶员/联系人（实际也可以是李四或王芳）
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
      
      # 2. 创建保险订单（3人，使用预查询的乘客信息）
      insurance_product = @available_insurances.first
      start_date = @pickup_date
      end_date = @return_date  # 保险结束日期 = 还车日期
      insurance_days = (@return_date - @pickup_date).to_i + 1  # 包含首尾两天，例如2月9日到2月14日 = 6天
      unit_price = insurance_product.price_per_day * insurance_days
      
      # 3人投保人名单（使用预查询的乘客信息）
      insured_persons_data = [
        { name: @zhangsan.name, id_number: @zhangsan.id_number },
        { name: @lisi.name, id_number: @lisi.id_number },
        { name: @wangfang.name, id_number: @wangfang.id_number }
      ]
      
      InsuranceOrder.create!(
        user: user,
        insurance_product: insurance_product,
        source: 'standalone',
        related_booking_type: 'CarOrder',
        related_booking_id: car_order.id,
        start_date: start_date,
        end_date: end_date,
        days: insurance_days,  # 使用正确的保险天数（包含首尾）
        destination: @city,
        destination_type: 'domestic',
        insured_persons: insured_persons_data,
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
        car_id: @car&.id,
        zhangsan_id: @zhangsan&.id,
        lisi_id: @lisi&.id,
        wangfang_id: @wangfang&.id,
        expected_contact_names: @expected_contact_names
      }
    end
    
    def restore_from_state(data)
      @city = data['city']
      @pickup_date = Date.parse(data['pickup_date'])
      @return_date = Date.parse(data['return_date'])
      @rental_days = data['rental_days']
      @travelers_count = data['travelers_count'] || 3
      
      @car = Car.find(data['car_id']) if data['car_id']
      
      # 恢复乘客信息
      if data['zhangsan_id'] && data['lisi_id'] && data['wangfang_id']
        @zhangsan = Passenger.find(data['zhangsan_id'])
        @lisi = Passenger.find(data['lisi_id'])
        @wangfang = Passenger.find(data['wangfang_id'])
        @expected_contact_names = data['expected_contact_names'] || [@zhangsan.name, @lisi.name, @wangfang.name]
        @expected_insured_names = [@zhangsan.name, @lisi.name, @wangfang.name]
      end
      
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
