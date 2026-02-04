# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例284: 预订周末度假套餐
#
# 任务描述:
#   用户预订2天1晚含餐的周末度假套餐
#
# 评分标准:
#   - 创建酒店套餐订单 (30%)
#   - 套餐时长正确 (25%)
#   - 价格合理 (25%)
#   - 订单状态正确 (20%)
module V251V300
  class V284BookWeekendGetawayPackageValidator < BaseValidator
    self.validator_id = 'v284_book_weekend_getaway_package_validator'
    self.task_id = '1c21acda-6325-4222-95e3-d62e336cf477'
    self.title = '预订周末度假套餐'
    self.description = '用户预订2天1晚含餐的周末度假套餐'
    self.timeout_seconds = 300
    
    def prepare
      @night_count = 1
      @package = HotelPackage.where(night_count: @night_count, data_version: 0)
                            .order(price: :asc)
                            .first!
      
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      if user.balance < @package.price
        user.update!(balance: @package.price + 500)
      end
      
      {
        task: "请预订适合周末度假的#{@night_count}晚酒店套餐「#{@package.title}」，享受短途休闲",
        package_title: @package.title,
        night_count: @night_count,
        price: @package.price.to_f,
        hint: "选择1晚的短途度假套餐，适合周末放松"
      }
    end
    
    def verify
      add_assertion "创建了酒店套餐订单", weight: 30 do
        @order = HotelPackageOrder
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        expect(@order).not_to be_nil, "未找到酒店套餐订单"
      end
      
      return unless @order
      
      add_assertion "套餐时长正确（#{@night_count}晚）", weight: 25 do
        package = @order.hotel_package
        expect(package).not_to be_nil, "订单没有关联套餐"
        expect(package.night_count).to eq(@night_count),
          "套餐时长错误。期望: #{@night_count}晚, 实际: #{package.night_count}晚"
      end
      
      add_assertion "支付金额正确", weight: 25 do
        expect(@order.total_price).to be > 0,
          "支付金额错误。实际: #{@order.total_price}元"
      end
      
      add_assertion "订单状态正确", weight: 20 do
        expect(@order.status).to eq('pending').or(eq('confirmed')).or(eq('paid')),
          "订单状态错误。期望: pending/confirmed/paid, 实际: #{@order.status}"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      package = HotelPackage.where(night_count: @night_count, data_version: 0)
                           .order(price: :asc)
                           .first!
      
      HotelPackageOrder.create!(
        user_id: user.id,
        hotel_package_id: package.id,
        hotel_id: package.hotel_id,
        package_option_id: 1,
        passenger_id: user.id,
        quantity: 1,
        total_price: package.price,
        booking_type: 'stockup',
        status: 'pending',
        contact_name: user.name || '张三',
        contact_phone: user.phone || '13800138000',
        data_version: @data_version
      )
    end
    
    private
    
    def execution_state_data
      {
        night_count: @night_count,
        package_id: @package&.id
      }
    end
    
    def restore_from_state(data)
      @night_count = data['night_count']
      @package = HotelPackage.find(data['package_id']) if data['package_id']
    end
  end
end
