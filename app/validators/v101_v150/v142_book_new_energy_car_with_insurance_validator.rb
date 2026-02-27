# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例142: 帮张三预订明天成都的新能源车，租3天，包含全险和免费取消
# 
# 任务描述:
#   Agent 需要在系统中搜索成都的新能源车，
#   找到符合条件的车辆并创建3天租期的订单，要求包含全险和支持免费取消
# 
# 复杂度分析:
#   1. 需要搜索成都的租车产品
#   2. 需要筛选车型类别为"新能源"（电动或混动）
#   3. 需要选择"明天"取车日期
#   4. 需要设置租期为3天
#   5. 需要确保订单状态支持取消
#   ✅ 地点+车型类别+时间+租期+保险+取消政策多维筛选
# 
# 评分标准:
#   - 创建了新能源车租车订单 (20分)
#   - 车型类别=新能源 (20分)
#   - 租车地点=成都 (10分)
#   - 取车时间=明天 (10分)
#   - 租期=3天 (10分)
#   - 订单状态支持取消 (10分)
#   - 车辆为新能源类型 (10分)
#   - 司机信息正确（张三） (10分)
#
module V101V150
  class V142BookNewEnergyCarWithInsuranceValidator < BaseValidator
    self.validator_id = 'v142_book_new_energy_car_with_insurance_validator'
    self.task_id = 'c2d3e4f5-6a7b-8c9d-0e1f-2a3b4c5d6e7f'
    self.title = '帮张三预订明天成都的新能源车，租3天，包含全险和免费取消'
    self.description = '帮张三预订明天成都的新能源车，租3天，包含全险和免费取消'
    self.timeout_seconds = 300

    def task_description
      "预订明天成都新能源车3天，包含全险和免费取消"
    end

    def prepare
      @location = "成都"
      @category = "新能源"
      @pickup_date = Date.current + 1.day
      @rental_days = 3
      @return_date = @pickup_date + @rental_days.days

      # 预查询乘客信息（用于 simulate 和 verify）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @zhangsan = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_driver_name = @zhangsan.name
      @expected_driver_id = @zhangsan.id_number
      @expected_contact_phone = @zhangsan.phone

      @available_cars = Car.where(
        location: @location,
        category: @category,
        data_version: 0
      ).order(price_per_day: :asc)

      raise "未找到符合条件的新能源车" if @available_cars.empty?
    end

    def verify
      # 断言1: 创建了新能源车租车订单 (20分) - 核心评分项
      add_assertion "创建了新能源车租车订单", weight: 20 do
        all_car_orders = CarOrder
          .joins(:car)
          .includes(:car)
          .where(cars: { location: @location, category: @category })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a

        @car_order = all_car_orders.first
        expect(@car_order).not_to be_nil, "未找到新能源车租车订单"
      end

      return if @car_order.nil?

      # 断言2: 车型类别=新能源 (20分) - 核心评分项
      add_assertion "车型类别=新能源", weight: 20 do
        expect(@car_order.car.category).to eq(@category)
      end

      # 断言3: 租车地点=成都 (10分)
      add_assertion "租车地点=成都", weight: 10 do
        expect(@car_order.car.location).to eq(@location)
      end

      # 断言4: 取车时间=明天 (10分)
      add_assertion "取车时间=明天", weight: 10 do
        expect(@car_order.pickup_datetime.to_date).to eq(@pickup_date)
      end

      # 断言5: 租期=3天 (10分)
      add_assertion "租期=3天", weight: 10 do
        actual_days = (@car_order.return_datetime.to_date - @car_order.pickup_datetime.to_date).to_i
        expect(actual_days).to eq(@rental_days),
          "租期错误。期望: #{@rental_days}天, 实际: #{actual_days}天"
      end

      # 断言6: 订单状态支持取消 (10分)
      add_assertion "订单状态支持取消", weight: 10 do
        # Verify order status is 'confirmed' which can be cancelled
        status = @car_order.status.to_s
        can_cancel = ['confirmed', 'pending'].include?(status)
        expect(can_cancel).to be(true),
          "订单状态不支持取消。当前状态: #{status}"
      end

      # 断言7: 车辆为新能源类型 (10分)
      add_assertion "车辆为新能源类型", weight: 10 do
        fuel_type = @car_order.car.fuel_type.to_s
        is_new_energy = fuel_type.include?("电") || fuel_type.include?("混动") || 
                       fuel_type.downcase.include?("electric") || fuel_type.downcase.include?("hybrid")
        expect(is_new_energy).to be(true),
          "车辆不是新能源类型。实际燃料类型: #{fuel_type}"
      end

      # 断言8: 司机信息正确（张三） (10分)
      add_assertion "司机信息正确（张三）", weight: 10 do
        expect(@car_order.driver_name).to eq(@expected_driver_name),
          "司机姓名错误。期望: #{@expected_driver_name}, 实际: #{@car_order.driver_name}"
        expect(@car_order.driver_id_number).to eq(@expected_driver_id),
          "司机身份证号错误。期望: #{@expected_driver_id}, 实际: #{@car_order.driver_id_number}"
        expect(@car_order.contact_phone).to eq(@expected_contact_phone),
          "联系电话错误。期望: #{@expected_contact_phone}, 实际: #{@car_order.contact_phone}"
      end
    end

    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      passenger = user.passengers.find_by!(name: '张三', data_version: 0)

      car = @available_cars.first
      CarOrder.create!(
        user: user,
        car: car,
        driver_name: passenger.name,
        driver_id_number: passenger.id_number,
        contact_phone: passenger.phone,
        pickup_datetime: @pickup_date.in_time_zone + 10.hours,
        return_datetime: (@pickup_date + @rental_days.days).in_time_zone + 18.hours,
        pickup_location: "成都双流国际机场",
        status: 'confirmed',
        total_price: car.price_per_day * @rental_days + 150,  # +150 for full insurance
        data_version: @data_version
      )
    end

    private

    def execution_state_data
      {
        location: @location,
        category: @category,
        pickup_date: @pickup_date.to_s,
        rental_days: @rental_days,
        return_date: @return_date.to_s,
        expected_driver_name: @expected_driver_name,
        expected_driver_id: @expected_driver_id,
        expected_contact_phone: @expected_contact_phone
      }
    end

    def restore_from_state(data)
      @location = data['location']
      @category = data['category']
      @pickup_date = Date.parse(data['pickup_date'])
      @rental_days = data['rental_days']
      @return_date = Date.parse(data['return_date'])
      @expected_driver_name = data['expected_driver_name']
      @expected_driver_id = data['expected_driver_id']
      @expected_contact_phone = data['expected_contact_phone']

      @available_cars = Car.where(
        location: @location,
        category: @category,
        data_version: 0
      ).order(price_per_day: :asc)
    end
  end
end
