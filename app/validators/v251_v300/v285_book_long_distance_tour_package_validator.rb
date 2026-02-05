# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例285: 预订长线游套餐
#
# 任务描述:
#   用户预订7天6晚多城市旅游套餐
#
# 评分标准:
#   - 创建跟团游订单 (30%)
#   - 行程时长正确 (7天) (25%)
#   - 价格合理 (25%)
#   - 订单状态正确 (20%)
module V251V300
  class V285BookLongDistanceTourPackageValidator < BaseValidator
    self.validator_id = 'v285_book_long_distance_tour_package_validator'
    self.task_id = '017fa810-5e0d-4b89-9eef-1ac127ff20fe'
    self.title = '预订长线游套餐'
    self.description = '用户预订7天6晚多城市旅游套餐'
    self.timeout_seconds = 300
    
    def prepare
      @duration = 7
      @product = TourGroupProduct.where('duration >= ?', @duration)
                                 .where(data_version: 0)
                                 .order(price: :desc)
                                 .first
      
      # 如果没有7天的，找最长的
      @product ||= TourGroupProduct.where(data_version: 0).order(duration: :desc).first!
      
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      if user.balance < @product.price * 2
        user.update!(balance: @product.price * 2 + 1000)
      end
      
      {
        task: "请预订#{@product.duration}天的长线游套餐「#{@product.title}」，游览多个城市",
        product_title: @product.title,
        duration: @product.duration,
        price: @product.price.to_f,
        hint: "选择天数较长的跟团游产品，适合深度旅游"
      }
    end
    
    def verify
      add_assertion "创建了跟团游预订", weight: 30 do
        @booking = TourGroupBooking
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        expect(@booking).not_to be_nil, "未找到跟团游预订"
      end
      
      return unless @booking
      
      add_assertion "行程时长正确（≥7天）", weight: 25 do
        product = @booking.tour_group_product
        expect(product).not_to be_nil, "订单没有关联产品"
        expect(product.duration).to be >= 7,
          "行程时长不足。期望: ≥7天, 实际: #{product.duration}天"
      end
      
      add_assertion "价格合理（长线游产品）", weight: 25 do
        expect(@booking.total_price).to be > 1000,
          "长线游价格过低，不合理。实际: #{@booking.total_price}元"
      end
      
      add_assertion "订单状态正确", weight: 20 do
        expect(@booking.status).to eq('pending').or(eq('confirmed')),
          "订单状态错误。期望: pending/confirmed, 实际: #{@booking.status}"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      product = TourGroupProduct.where('duration >= ?', @duration)
                                .where(data_version: 0)
                                .order(price: :desc)
                                .first
      product ||= TourGroupProduct.where(data_version: 0).order(duration: :desc).first!
      
      # 创建或获取套餐
      package = product.tour_packages.where(data_version: 0).first
      package ||= TourPackage.create!(
        tour_group_product_id: product.id,
        name: '标准套餐',
        price: product.price,
        child_price: (product.price * 0.7).round(2),
        description: '包含基础服务',
        data_version: 0
      )
      
      TourGroupBooking.create!(
        user_id: user.id,
        tour_group_product_id: product.id,
        tour_package_id: package.id,
        adult_count: 2,
        child_count: 0,
        contact_name: user.name || '张三',
        contact_phone: user.phone || '13800138000',
        travel_date: Date.current + 14.days,
        total_price: package.price * 2,
        status: 'confirmed',
        data_version: @data_version
      )
    end
    
    private
    
    def execution_state_data
      {
        duration: @duration,
        product_id: @product&.id
      }
    end
    
    def restore_from_state(data)
      @duration = data['duration']
      @product = TourGroupProduct.find(data['product_id']) if data['product_id']
    end
  end
end
