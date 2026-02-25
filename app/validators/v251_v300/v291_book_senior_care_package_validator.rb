# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例291: 给张建国（老人）预订九寨沟跟团游（含老年人保险）
#
# 任务描述:
#   给张建国预订10天后出发的九寨沟跟团游，需要适老化服务和老年人专用保险
#
# 评分标准:
#   - 创建跟团游预订 (25%)
#   - 创建老年人专用保险 (20%)
#   - 被保险人信息正确（张建国，65岁）(15%)
#   - 出行日期正确 (20%)
#   - 联系人信息正确 (10%)
#   - 订单状态正确 (10%)
module V251V300
  class V291BookSeniorCarePackageValidator < BaseValidator
    self.validator_id = 'v291_book_senior_care_package_validator'
    self.task_id = '09a76fc5-3c70-446f-a35e-e52d8ed218f9'
    self.title = '给张建国（老人）预订九寨沟跟团游（含老年人保险）'
    self.description = '给张建国（老人）预订九寨沟跟团游（含老年人保险）'
    self.timeout_seconds = 300
    
    def prepare
      @destination = '九寨沟'
      @travel_date = Date.current + 10.days
      
      # 预查询老年人乘客信息
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @zhangjianguo = user.passengers.find_by!(name: '张建国', data_version: 0)  # 65岁老人
      @expected_insured_name = @zhangjianguo.name
      @expected_insured_id_number = @zhangjianguo.id_number
      @expected_contact_phone = @zhangjianguo.phone
      
      if user.balance < 5000
        user.update!(balance: 8000)
      end
      
      {
        task: "请为张建国老人预订#{@destination}跟团游，#{@travel_date.strftime('%Y年%-m月%-d日')}出发，需要适老化服务和老年人专用医疗保障",
        destination: @destination,
        travel_date: @travel_date.to_s,
        hint: "选择适合老年人的跟团游产品，并购买老年人旅游保险"
      }
    end
    
    def verify
      add_assertion "创建了跟团游预订", weight: 25 do
        @tour_booking = TourGroupBooking
          .joins(:tour_group_product)
          .where(tour_group_products: { destination: @destination })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        expect(@tour_booking).not_to be_nil, "未找到#{@destination}的跟团游预订"
      end
      
      return unless @tour_booking
      
      add_assertion "创建了老年人专用保险", weight: 20 do
        @insurance = InsuranceOrder
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        expect(@insurance).not_to be_nil, "未找到老年人旅游保险订单"
      end
      
      add_assertion "被保险人信息正确（张建国，65岁）", weight: 15 do
        return unless @insurance
        
        insured_persons = @insurance.insured_persons || []
        zhangjianguo_record = insured_persons.find { |p| p['name'] == @expected_insured_name }
        
        expect(zhangjianguo_record).not_to be_nil,
          "被保险人信息中未找到张建国"
        expect(zhangjianguo_record['id_number']).to eq(@expected_insured_id_number),
          "被保险人身份证号错误。期望: #{@expected_insured_id_number}, 实际: #{zhangjianguo_record['id_number']}"
      end
      
      add_assertion "出行日期正确（#{@travel_date}）", weight: 20 do
        expect(@tour_booking.travel_date).to eq(@travel_date),
          "出行日期错误。期望: #{@travel_date}（10天后）, 实际: #{@tour_booking.travel_date}"
      end
      
      add_assertion "联系人信息正确（张建国）", weight: 10 do
        expect(@tour_booking.contact_name).to eq(@expected_insured_name),
          "联系人姓名错误。期望: #{@expected_insured_name}, 实际: #{@tour_booking.contact_name}"
        expect(@tour_booking.contact_phone).to eq(@expected_contact_phone),
          "联系人电话错误。期望: #{@expected_contact_phone}, 实际: #{@tour_booking.contact_phone}"
      end
      
      add_assertion "订单状态正确", weight: 10 do
        valid_statuses = ['pending', 'confirmed', 'paid']
        expect(valid_statuses).to include(@tour_booking.status),
          "跟团游订单状态错误: #{@tour_booking.status}"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      zhangjianguo = user.passengers.find_by!(name: '张建国', data_version: 0)
      
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
        contact_name: zhangjianguo.name,
        contact_phone: zhangjianguo.phone,
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
        insured_persons: [{ name: zhangjianguo.name, id_number: zhangjianguo.id_number }],
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
        travel_date: @travel_date&.to_s,
        expected_insured_name: @expected_insured_name,
        expected_insured_id_number: @expected_insured_id_number,
        expected_contact_phone: @expected_contact_phone
      }
    end
    
    def restore_from_state(data)
      @destination = data['destination']
      @travel_date = Date.parse(data['travel_date']) if data['travel_date']
      @expected_insured_name = data['expected_insured_name']
      @expected_insured_id_number = data['expected_insured_id_number']
      @expected_contact_phone = data['expected_contact_phone']
    end
  end
end
