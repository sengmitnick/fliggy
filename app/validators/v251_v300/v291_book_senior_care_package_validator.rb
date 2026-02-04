# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例291: 预订老年人关怀套餐
#
# 任务描述:
#   用户预订老年人关怀套餐（适老化服务+医疗保障）
#
# 评分标准:
#   - 创建跟团游预订 (30%)
#   - 创建老年人专用保险 (30%)
#   - 出行日期正确 (25%)
#   - 订单状态正确 (15%)
module V251V300
  class V291BookSeniorCarePackageValidator < BaseValidator
    self.validator_id = 'v291_book_senior_care_package_validator'
    self.task_id = '09a76fc5-3c70-446f-a35e-e52d8ed218f9'
    self.title = '预订老年人关怀套餐'
    self.description = '用户预订老年人关怀套餐（适老化服务+医疗保障）'
    self.timeout_seconds = 300
    
    def prepare
      @destination = '九寨沟'
      @travel_date = Date.today + 10.days
      
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      if user.balance < 5000
        user.update!(balance: 8000)
      end
      
      {
        task: "请为70岁老年人预订#{@destination}跟团游，#{@travel_date.strftime('%Y年%-m月%-d日')}出发，需要适老化服务和医疗保障",
        destination: @destination,
        travel_date: @travel_date.to_s,
        hint: "选择适合老年人的跟团游产品，并购买高龄旅游保险"
      }
    end
    
    def verify
      add_assertion "创建了跟团游预订", weight: 30 do
        @tour_booking = TourGroupBooking
          .joins(:tour_group_product)
          .where(tour_group_products: { destination: @destination })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        expect(@tour_booking).not_to be_nil, "未找到#{@destination}的跟团游预订"
      end
      
      add_assertion "创建了老年人专用保险", weight: 30 do
        @insurance = InsuranceOrder
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        expect(@insurance).not_to be_nil, "未找到老年人旅游保险"
      end
      
      return unless @tour_booking
      
      add_assertion "出行日期正确", weight: 25 do
        expect(@tour_booking.travel_date).to eq(@travel_date),
          "出行日期错误。期望: #{@travel_date}, 实际: #{@tour_booking.travel_date}"
      end
      
      add_assertion "订单状态正确", weight: 15 do
        valid_statuses = ['pending', 'confirmed', 'paid']
        expect(valid_statuses).to include(@tour_booking.status),
          "跟团游订单状态错误: #{@tour_booking.status}"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 1. 预订跟团游
      tour_product = TourGroupProduct.where(destination: @destination, data_version: 0).first!
      tour_package = tour_product.tour_packages.first!
      
      TourGroupBooking.create!(
        user_id: user.id,
        tour_group_product_id: tour_product.id,
        tour_package_id: tour_package.id,
        travel_date: @travel_date,
        adult_count: 1,
        child_count: 0,
        contact_name: user.name || '王老伯',
        contact_phone: user.phone || '13800138000',
        insurance_type: 'none',
        total_price: tour_package.price,
        status: 'confirmed',
        data_version: @data_version
      )
      
      # 2. 购买老年人保险
      insurance_product = InsuranceProduct.where(data_version: 0).order(price_per_day: :desc).first!
      InsuranceOrder.create!(
        user_id: user.id,
        insurance_product_id: insurance_product.id,
        start_date: @travel_date,
        end_date: @travel_date + 5.days,
        days: 5,
        insured_persons: [{ name: '王老伯', id_number: '440300195001011234' }],
        unit_price: insurance_product.price_per_day,
        quantity: 1,
        total_price: insurance_product.price_per_day * 5,
        status: 'paid',
        source: 'standalone',
        data_version: @data_version
      )
    end
    
    private
    
    def execution_state_data
      {
        destination: @destination,
        travel_date: @travel_date&.to_s
      }
    end
    
    def restore_from_state(data)
      @destination = data['destination']
      @travel_date = Date.parse(data['travel_date']) if data['travel_date']
    end
  end
end
