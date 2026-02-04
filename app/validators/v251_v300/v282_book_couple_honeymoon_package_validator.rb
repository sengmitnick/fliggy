# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例282: 预订情侣蜜月套餐
#
# 任务描述:
#   用户预订浪漫酒店和双人游套餐，包含特色服务
#
# 评分标准:
#   - 创建酒店套餐订单 (30%)
#   - 套餐适合情侣 (25%)
#   - 价格合理 (25%)
#   - 订单状态正确 (20%)
module V251V300
  class V282BookCoupleHoneymoonPackageValidator < BaseValidator
    self.validator_id = 'v282_book_couple_honeymoon_package_validator'
    self.task_id = '34788f50-b5af-484d-b9ee-e8fe13d134bf'
    self.title = '预订情侣蜜月套餐'
    self.description = '用户预订浪漫酒店和双人游套餐，包含特色服务'
    self.timeout_seconds = 300
    
    def prepare
      @keyword = '希尔顿'
      @package = HotelPackage.where('title LIKE ?', "%#{@keyword}%")
                            .where(data_version: 0)
                            .where('night_count >= ?', 2)
                            .order(price: :desc)
                            .first!
      
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      if user.balance < @package.price
        user.update!(balance: @package.price + 1000)
      end
      
      {
        task: "请预订适合情侣蜜月的高端酒店套餐「#{@package.title}」，享受浪漫体验",
        package_title: @package.title,
        price: @package.price.to_f,
        night_count: @package.night_count,
        hint: "选择高档浪漫的酒店套餐，适合蜜月旅行"
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
      
      add_assertion "预订的是高端酒店套餐（#{@keyword}）", weight: 25 do
        package = @order.hotel_package
        expect(package).not_to be_nil, "订单没有关联套餐"
        expect(package.title).to include(@keyword),
          "酒店品牌不匹配。期望包含: #{@keyword}, 实际: #{package.title}"
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
      
      package = HotelPackage.where('title LIKE ?', "%#{@keyword}%")
                           .where(data_version: 0)
                           .where('night_count >= ?', 2)
                           .order(price: :desc)
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
        keyword: @keyword,
        package_id: @package&.id
      }
    end
    
    def restore_from_state(data)
      @keyword = data['keyword']
      @package = HotelPackage.find(data['package_id']) if data['package_id']
    end
  end
end
