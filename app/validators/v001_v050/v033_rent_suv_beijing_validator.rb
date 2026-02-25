# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例33: 给张三租赁后天北京SUV（租车2天）
# 
# 任务描述:
#   Agent 需要在系统中搜索北京的租车服务，
#   找到SUV车型并成功创建租赁2天的订单
# 
# 复杂度分析:
#   1. 需要搜索北京的租车服务
#   2. 需要选择"后天"取车日期
#   3. 需要筛选SUV车型
#   4. 需要计算2天的租期
#   ❌ 车型筛选，无价格限制
# 
# 评分标准:
#   - 订单已创建 (20分)
#   - 城市正确（北京） (20分)
#   - 车型正确（SUV） (30分)
#   - 租赁天数正确（2天） (30分)
#
module V001V050
  class V033RentSuvBeijingValidator < BaseValidator
    self.validator_id = 'v033_rent_suv_beijing_validator'
    self.task_id = '6eb27ac0-25d9-4fd8-bb9b-3834d06e4ffa'
    self.title = '给张三租赁后天北京SUV（租车2天）'
    self.description = '租赁后天北京SUV（租车2天）'
    self.timeout_seconds = 240
  
    def prepare
      @location = '北京'
      @category = 'SUV'
      @rental_days = 2
      @pickup_date = Date.current + 2.days
    
      suitable_cars = Car.where(
        location: @location,
        category: @category,
        data_version: 0
      )
    
      {
        task: "帮张三租一辆后天在#{@location}取车的#{@category}（租期2天）",
        location: @location,
        category: @category,
        rental_days: @rental_days,
        pickup_date: @pickup_date.to_s,
        pickup_date_description: "后天（#{@pickup_date.strftime('%Y年%m月%d日')}）",
        hint: "系统中有多辆SUV可选，选择车型正确即可",
        suitable_cars_count: suitable_cars.count
      }
    end
  
    def verify
      add_assertion "订单已创建", weight: 15 do
        all_orders = CarOrder
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        expect(all_orders).not_to be_empty, "未找到任何租车订单记录"
        @order = all_orders.first
      end
    
      return unless @order
    
      add_assertion "城市正确（北京）", weight: 15 do
        expect(@order.car.location).to eq(@location)
      end
    
      add_assertion "取车日期正确（后天 #{@pickup_date.strftime('%Y-%m-%d')}）", weight: 15 do
        pickup_date = @order.pickup_datetime.to_date
        expect(pickup_date).to eq(@pickup_date),
          "取车日期不正确。期望: #{@pickup_date}（后天）, 实际: #{pickup_date}"
      end
    
      add_assertion "车型正确（SUV）", weight: 25 do
        expect(@order.car.category).to eq(@category),
          "车型不正确。期望: #{@category}, 实际: #{@order.car.category}"
      end
    
      add_assertion "租赁天数正确（2天）", weight: 20 do
        return_date = @order.return_datetime.to_date
        pickup_date = @order.pickup_datetime.to_date
        actual_days = (return_date - pickup_date).to_i
      
        expect(actual_days).to eq(@rental_days),
          "租赁天数不正确。期望: #{@rental_days}天, 实际: #{actual_days}天"
      end
    
      add_assertion "驾驶人信息正确（张三 13800138000）", weight: 10 do
        expect(@order.driver_name).to eq('张三'),
          "驾驶人姓名错误。期望: 张三（demo_user数据）, 实际: #{@order.driver_name}"
        expect(@order.contact_phone).to eq('13800138000'),
          "联系电话错误。期望: 13800138000（demo_user数据）, 实际: #{@order.contact_phone}"
        expect(@order.driver_id_number).to eq('110101199001011234'),
          "身份证号错误。期望: 110101199001011234（demo_user数据）, 实际: #{@order.driver_id_number}"
      end
    end
  
    private
  
    def execution_state_data
      { location: @location, category: @category, rental_days: @rental_days, pickup_date: @pickup_date.to_s }
    end
  
    def restore_from_state(data)
      @location = data['location']
      @category = data['category']
      @rental_days = data['rental_days']
      @pickup_date = Date.parse(data['pickup_date'])
    end
  
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      passenger = user.passengers.find_by!(name: '张三', data_version: 0)
    
      target_car = Car.where(
        location: @location,
        category: @category,
        data_version: 0
      ).sample
    
      total_price = target_car.price_per_day * @rental_days
      pickup_datetime = @pickup_date.to_time.in_time_zone.change(hour: 9, min: 0)
      return_datetime = (@pickup_date + @rental_days.days).to_time.in_time_zone.change(hour: 9, min: 0)
    
      CarOrder.create!(
        car_id: target_car.id,
        user_id: user.id,
        driver_name: passenger.name,
        driver_id_number: passenger.id_number,
        contact_phone: passenger.phone,
        pickup_datetime: pickup_datetime,
        return_datetime: return_datetime,
        pickup_location: target_car.pickup_location,
        status: 'pending',
        total_price: total_price,
        data_version: @data_version
      )
    
      { action: 'create_car_order', car_model: "#{target_car.brand} #{target_car.car_model}" }
    end
    end
end