# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例142: 帮张三预订明天成都东站东广场租车中心的新能源车，租3天，包含全险和免费取消
#
# 任务描述:
#   张三计划明天从成都东站东广场租车中心租一辆新能源车，租期3天，要求包含全险和支持免费取消。
#   Agent 需要创建1个租车订单，确保车型为新能源，租车地点为成都，取车点为成都东站东广场租车中心，租期3天，订单状态支持取消。
#
# 业务流程（5个关键步骤）：
#   1. 明确受益人信息（张三，使用其姓名、身份证号、电话作为驾驶员信息）
#   2. 搜索成都的租车服务，筛选车型类别=新能源
#   3. 筛选燃料类型为电动或混动的车辆（通过car.fuel_type字段判断）
#   4. 设置取车时间为明天（Date.current + 1.day）
#   5. 创建租车订单（pickup_location=成都东站东广场租车中心，租期3天，订单状态为confirmed支持取消）
#
# 复杂度分析（6个关键点）：
#   1. 需要理解车型分类（category = '新能源'，不是SUV或商务车）
#   2. 需要筛选新能源车辆（通过car.fuel_type字段查找包含'电'或'混动'关键词的车辆）
#   3. 需要正确计算租期3天（return_datetime = pickup_datetime + 3天）
#   4. 需要设置取车时间为明天（Date.current + 1.day）
#   5. 需要使用受益人信息作为驾驶员信息（driver_name、driver_id_number、contact_phone）
#   6. 需要确保订单状态支持取消（status为confirmed或pending）
#
# 评分标准（8项，总计100分）：
#   1. 创建了新能源车租车订单（20分）
#   2. 车型类别=新能源（20分）
#   3. 租车地点=成都（10分）
#   4. 取车地点=成都东站东广场租车中心（10分）
#   5. 取车时间=明天（10分）
#   6. 租期=3天（10分）
#   7. 车辆为新能源类型（电动或混动）（10分）
#   8. 司机信息正确（张三的姓名、身份证号、电话）（10分）
#
# 使用方法:
#   rake validator:simulate_single[v142_book_new_energy_car_with_insurance_validator]
#   或访问 http://localhost:<PORT>/api/tasks 获取任务列表
#
module V101V150
  class V142BookNewEnergyCarWithInsuranceValidator < BaseValidator
    self.validator_id = 'v142_book_new_energy_car_with_insurance_validator'
    self.task_id = 'c2d3e4f5-6a7b-8c9d-0e1f-2a3b4c5d6e7f'
    self.title = '帮张三预订明天成都东站东广场租车中心的新能源车，租3天，包含全险和免费取消'
    self.description = '帮张三预订明天成都东站东广场租车中心的新能源车，租3天，包含全险和免费取消'
    self.timeout_seconds = 300

    def task_description
      "帮张三预订明天成都东站东广场租车中心的新能源车，租3天，包含全险和免费取消"
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

      # 断言4: 取车地点=成都东站东广场租车中心 (10分)
      add_assertion "取车地点=成都东站东广场租车中心", weight: 10 do
        pickup_loc = @car_order.pickup_location.to_s
        expect(pickup_loc).to include("成都东站")
        expect(pickup_loc).to include("租车")
      end

      # 断言5: 取车时间=明天 (10分)
      add_assertion "取车时间=明天", weight: 10 do
        expect(@car_order.pickup_datetime.to_date).to eq(@pickup_date)
      end

      # 断言6: 租期=3天 (10分)
      add_assertion "租期=3天", weight: 10 do
        actual_days = (@car_order.return_datetime.to_date - @car_order.pickup_datetime.to_date).to_i
        expect(actual_days).to eq(@rental_days),
          "租期错误。期望: #{@rental_days}天, 实际: #{actual_days}天"
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
        pickup_location: car.pickup_location,  # 使用车辆数据包中的pickup_location（具体租车点）
        status: 'confirmed',
        total_price: car.price_per_day * @rental_days,  # 基础价格，不额外收取保险费
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
