# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例281: 预订亲子套餐
#
# 任务描述:
#   用户预订2大1小全程服务套餐，包含亲子活动和儿童设施
#
# 评分标准:
#   - 创建跟团游订单 (30%)
#   - 人数配置正确 (2大1小) (25%)
#   - 包含亲子元素 (25%)
#   - 订单状态正确 (20%)
module V251V300
  class V281BookFamilyPackageValidator < BaseValidator
    self.validator_id = 'v281_book_family_package_validator'
    self.task_id = '97f3e67d-07f1-4e31-b1bc-0f6b87f0d09f'
    self.title = '预订亲子套餐'
    self.description = '用户预订2大1小全程服务套餐，包含亲子活动和儿童设施'
    self.timeout_seconds = 300
    
    def prepare
      @adult_count = 2
      @child_count = 1
      @keyword = '亲子'
      
      # 查找包含亲子元素的跟团游产品
      @product = TourGroupProduct.where('tags LIKE ?', "%#{@keyword}%")
                                 .where(data_version: 0)
                                 .first
      
      # 如果没有找到，使用任意一个产品
      @product ||= TourGroupProduct.where(data_version: 0).first!
      
      # 确保用户有足够余额
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      total_price = @product.price * @adult_count + (@product.price * 0.7 * @child_count)
      if user.balance < total_price
        user.update!(balance: total_price + 1000)
      end
      
      {
        task: "请预订适合#{@adult_count}大#{@child_count}小的亲子旅游套餐，包含适合儿童的活动和设施",
        adult_count: @adult_count,
        child_count: @child_count,
        product_title: @product.title,
        hint: "选择适合家庭出游的跟团游产品"
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
      
      add_assertion "人数配置正确（#{@adult_count}大#{@child_count}小）", weight: 25 do
        expect(@booking.adult_count).to eq(@adult_count),
          "成人数量错误。期望: #{@adult_count}, 实际: #{@booking.adult_count}"
        expect(@booking.child_count).to eq(@child_count),
          "儿童数量错误。期望: #{@child_count}, 实际: #{@booking.child_count}"
      end
      
      add_assertion "总人数正确（#{@adult_count + @child_count}人）", weight: 25 do
        total = @booking.adult_count + @booking.child_count
        expect(total).to eq(@adult_count + @child_count),
          "总人数错误。期望: #{@adult_count + @child_count}, 实际: #{total}"
      end
      
      add_assertion "订单状态正确", weight: 20 do
        expect(@booking.status).to eq('pending').or(eq('confirmed')),
          "订单状态错误。期望: pending/confirmed, 实际: #{@booking.status}"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      product = TourGroupProduct.where('tags LIKE ?', "%#{@keyword}%")
                                .where(data_version: 0)
                                .first
      product ||= TourGroupProduct.where(data_version: 0).first!
      
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
        adult_count: @adult_count,
        child_count: @child_count,
        contact_name: user.name || '张三',
        contact_phone: user.phone || '13800138000',
        travel_date: Date.today + 7.days,
        total_price: package.price * @adult_count + package.child_price * @child_count,
        status: 'confirmed',
        data_version: @data_version
      )
    end
    
    private
    
    def execution_state_data
      {
        adult_count: @adult_count,
        child_count: @child_count,
        keyword: @keyword,
        product_id: @product&.id
      }
    end
    
    def restore_from_state(data)
      @adult_count = data['adult_count']
      @child_count = data['child_count']
      @keyword = data['keyword']
      @product = TourGroupProduct.find(data['product_id']) if data['product_id']
    end
  end
end
