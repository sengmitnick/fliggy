# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例280: 预订包车套餐
#
# 任务描述:
#   用户预订3天包车套餐，包含司导服务和油费
#
# 评分标准:
#   - 创建包车订单 (30%)
#   - 租赁天数正确 (25%)
#   - 价格合理 (25%)
#   - 订单状态正确 (20%)
module V251V300
  class V280BookCarRentalPackageValidator < BaseValidator
    self.validator_id = 'v280_book_car_rental_package_validator'
    self.task_id = 'f6d6a9af-de20-4b9c-85f2-f63ef9397045'
    self.title = '预订包车套餐'
    self.description = '用户预订3天包车套餐，包含司导服务和油费'
    self.timeout_seconds = 300
    
    def prepare
      @rental_days = 3
      @pickup_city = '深圳'
      @pickup_datetime = Date.today + 2.days
      @return_datetime = @pickup_datetime + @rental_days.days
      
      # 确保用户有足够余额
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      if user.account_balance < 2000
        user.update!(account_balance: 3000)
      end
      
      {
        task: "请预订#{@pickup_city}的包车服务，租期#{@rental_days}天，从#{@pickup_datetime.strftime('%Y年%-m月%-d日')}开始",
        pickup_city: @pickup_city,
        rental_days: @rental_days,
        pickup_date: @pickup_datetime.to_s,
        return_date: @return_datetime.to_s,
        hint: "选择适合多天使用的车型，包含司机服务"
      }
    end
    
    def verify
      add_assertion "创建了包车订单", weight: 30 do
        @order = CarOrder
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        expect(@order).not_to be_nil, "未找到包车订单"
      end
      
      return unless @order
      
      add_assertion "租赁天数正确（#{@rental_days}天）", weight: 25 do
        actual_days = (@order.return_datetime.to_date - @order.pickup_datetime.to_date).to_i
        expect(actual_days).to eq(@rental_days),
          "租赁天数错误。期望: #{@rental_days}天, 实际: #{actual_days}天"
      end
      
      add_assertion "取车地点正确（#{@pickup_city}）", weight: 25 do
        expect(@order.pickup_location).to include(@pickup_city),
          "取车地点错误。期望包含: #{@pickup_city}, 实际: #{@order.pickup_location}"
      end
      
      add_assertion "订单状态正确", weight: 20 do
        expect(@order.status).to eq('pending').or(eq('confirmed')),
          "订单状态错误。期望: pending/confirmed, 实际: #{@order.status}"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 找一辆车
      car = Car.where(data_version: 0).where('price_per_day < ?', 500).first!
      
      CarOrder.create!(
        user_id: user.id,
        car_id: car.id,
        driver_name: user.name || '张三',
        driver_id_number: '440300199001011234',
        contact_phone: user.phone || '13800138000',
        pickup_datetime: @pickup_datetime,
        return_datetime: @return_datetime,
        pickup_location: "#{@pickup_city}市中心",
        status: 'confirmed',
        total_price: car.price_per_day * @rental_days,
        data_version: @data_version
      )
    end
    
    private
    
    def execution_state_data
      {
        rental_days: @rental_days,
        pickup_city: @pickup_city,
        pickup_datetime: @pickup_datetime&.to_s,
        return_datetime: @return_datetime&.to_s
      }
    end
    
    def restore_from_state(data)
      @rental_days = data['rental_days']
      @pickup_city = data['pickup_city']
      @pickup_datetime = Date.parse(data['pickup_datetime']) if data['pickup_datetime']
      @return_datetime = Date.parse(data['return_datetime']) if data['return_datetime']
    end
  end
end
