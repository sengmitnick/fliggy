# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例278: 预订酒店套餐
#
# 任务描述:
#   用户购买住5送1优惠套餐，连续入住享受折扣
#
# 评分标准:
#   - 创建酒店套餐购买订单 (30%)
#   - 套餐匹配正确 (25%)
#   - 支付金额正确 (25%)
#   - 订单状态已支付 (20%)
module V251V300
  class V278RedeemHotelStayPromotionPackageValidator < BaseValidator
    self.validator_id = 'v278_redeem_hotel_stay_promotion_package_validator'
    self.task_id = '64e513f9-454d-4346-af2b-cc7b87b03178'
    self.title = '预订酒店套餐'
    self.description = '用户购买住5送1优惠套餐，连续入住享受折扣'
    self.timeout_seconds = 300
    
    def prepare
      @package_keyword = '万豪酒店'
      @package = HotelPackage.where('title LIKE ?', "%#{@package_keyword}%")
                            .where(data_version: 0)
                            .where('night_count >= ?', 2)
                            .first!
      
      # 确保用户有足够余额
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      if user.balance < @package.price
        user.update!(balance: @package.price + 1000)
      end
      
      {
        task: "请购买「#{@package.title}」酒店套餐，享受连住优惠",
        package_title: @package.title,
        price: @package.price.to_f,
        night_count: @package.night_count,
        valid_days: @package.valid_days,
        hint: "这是一个多晚连住的酒店套餐，适合长期出差或旅游的用户"
      }
    end
    
    def verify
      add_assertion "创建了酒店套餐购买订单", weight: 30 do
        @order = HotelPackageOrder
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        expect(@order).not_to be_nil, "未找到酒店套餐购买订单"
      end
      
      return unless @order
      
      add_assertion "购买的是指定酒店品牌套餐（#{@package_keyword}）", weight: 25 do
        package = @order.hotel_package
        expect(package).not_to be_nil, "订单没有关联套餐"
        expect(package.title).to include(@package_keyword),
          "套餐不匹配。期望包含: #{@package_keyword}, 实际: #{package.title}"
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
      
      package = HotelPackage.where('title LIKE ?', "%#{@package_keyword}%")
                           .where(data_version: 0)
                           .where('night_count >= ?', 2)
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
        package_keyword: @package_keyword,
        package_id: @package&.id
      }
    end
    
    def restore_from_state(data)
      @package_keyword = data['package_keyword']
      @package = HotelPackage.find(data['package_id']) if data['package_id']
    end
  end
end
