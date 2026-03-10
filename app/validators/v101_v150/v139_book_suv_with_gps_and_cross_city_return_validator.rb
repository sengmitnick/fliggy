# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例139: 帮张三后天从上海虹桥站南广场租车中心租SUV自驾游5天（含GPS导航），异地还车到杭州钱江新城CBD租车点
#
# 任务描述:
#   张三计划后天从上海虹桥站南广场租车中心出发自驾游，需要租一辆SUV，租期5天，要求配备GPS导航功能，并且需要异地还车到杭州钱江新城CBD租车点。
#   Agent 需要创建1个租车订单，确保车型为SUV，取车地点为上海虹桥站南广场租车中心，租期5天，包含GPS导航功能，并支持异地还车到杭州钱江新城CBD租车点（通常需要额外支付异地还车费）。
#
# 业务流程（7个关键步骤）：
#   1. 明确受益人信息（张三，使用其姓名、身份证号、电话作为驾驶员信息）
#   2. 搜索上海的租车服务，筛选车型类别=SUV
#   3. 筛选包含GPS导航功能的车辆（通过car.features字段判断）
#   4. 筛选虹桥站南广场租车中心的车辆
#   5. 设置取车时间为后天（Date.current + 2.days）
#   6. 设置租期5天，还车时间为取车后5天
#   7. 创建租车订单（pickup_location为上海虹桥站南广场租车中心，目的地为杭州，支持异地还车，total_price需包含异地还车费约200元）
#
# 复杂度分析（9个关键点）：
#   1. 需要理解车型分类（category = 'SUV'，不是经济轿车或商务车）
#   2. 需要筛选GPS导航功能（通过car.features字段查找包含'GPS'或'导航'关键词的车辆）
#   3. 需要理解异地还车概念（从上海虹桥站南广场租车中心取车，到杭州钱江新城CBD租车点还车，需支付异地还车费）
#   4. 需要计算异地还车费用（通常为固定费用200元，叠加到总价中）
#   5. 需要正确计算租期5天（return_datetime = pickup_datetime + 5天）
#   6. 需要设置取车时间为后天（Date.current + 2.days）
#   7. 需要使用受益人信息作为驾驶员信息（driver_name、driver_id_number、contact_phone）
#   8. 需要明确取车地点：上海虹桥站南广场租车中心（不是浦东机场）
#   9. 需要明确还车地点：杭州钱江新城CBD租车点
#   ❌ 不能忽略GPS功能：必须选择包含GPS导航的车辆，如果没有则选择普通SUV（但会被扣分）。
#
# 评分标准（8项，总计100分）：
#   1. 创建了SUV租车订单（25分）
#   2. 车型类别=SUV（15分）
#   3. 取车地点=上海虹桥站南广场租车中心（10分）
#   4. 取车时间=后天（10分）
#   5. 租期=5天（10分）
#   6. 驾驶员信息正确（张三的姓名、身份证号）（10分）
#   7. 支付异地还车费用（+200元）（10分）
#   8. 包含GPS导航功能（10分）
#
# 使用方法:
#   rake validator:simulate_single[v139_book_suv_with_gps_and_cross_city_return_validator]
#   或访问 http://localhost:<PORT>/api/tasks 获取任务列表
#
module V101V150
  class V139BookSuvWithGpsAndCrossCityReturnValidator < BaseValidator
    self.validator_id = 'v139_book_suv_with_gps_and_cross_city_return_validator'
    self.task_id = 'f9a0b1c2-3d4e-5f6a-7b8c-9d0e1f2a3b4c'
    self.title = '帮张三后天从上海虹桥站南广场租车中心租SUV自驾游5天（含GPS导航），异地还车到杭州钱江新城CBD租车点'
    self.description = '帮张三后天从上海虹桥站南广场租车中心租SUV自驾游5天，需要GPS导航功能，异地还车到杭州钱江新城CBD租车点'
    self.timeout_seconds = 300

    def task_description
      "帮张三后天从上海虹桥站南广场租车中心租SUV自驾游5天（含GPS导航），异地还车到杭州钱江新城CBD租车点"
    end

    def prepare
      @pickup_location = "上海"
      @pickup_location_detail = "上海虹桥站南广场租车中心"
      @return_location = "杭州"
      @return_location_detail = "杭州钱江新城CBD租车点"
      @category = "SUV"
      @pickup_date = Date.current + 2.days
      @rental_days = 5
      @return_date = @pickup_date + @rental_days.days
      @required_feature = "GPS导航"

      # 预查询驾驶员信息（张三）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_driver_name = @passenger.name
      @expected_driver_id = @passenger.id_number
      @expected_phone = @passenger.phone

      @available_cars = Car.where(
        location: @pickup_location,
        category: @category,
        data_version: 0
      ).order(price_per_day: :asc)

      raise "未找到符合条件的SUV" if @available_cars.empty?
    end

    def verify
      # 断言1: 创建了SUV租车订单 (25分) - 核心评分项
      add_assertion "创建了SUV租车订单", weight: 25 do
        all_car_orders = CarOrder
          .joins(:car)
          .includes(:car)
          .where(cars: { location: @pickup_location, category: @category })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a

        @car_order = all_car_orders.first
        expect(@car_order).not_to be_nil, "未找到SUV租车订单"
      end

      return if @car_order.nil?

      # 断言2: 车型类别=SUV (15分)
      add_assertion "车型类别=SUV", weight: 15 do
        expect(@car_order.car.category).to eq(@category)
      end

      # 断言3: 取车地点=上海虹桥站南广场租车中心 (10分)
      add_assertion "取车地点=上海虹桥站南广场租车中心", weight: 10 do
        expect(@car_order.car.location).to eq(@pickup_location)
        # 验证pickup_location必须是虹桥站南广场租车中心（不能是浦东机场）
        pickup_loc = @car_order.pickup_location.to_s
        expect(pickup_loc).to include("虹桥"),
          "取车地点必须是虹桥站南广场租车中心。实际: #{pickup_loc}"
        expect(pickup_loc).to include("租车中心"),
          "取车地点必须包含'租车中心'。实际: #{pickup_loc}"
      end

      # 断言4: 取车时间=后天 (10分)
      add_assertion "取车时间=后天", weight: 10 do
        expect(@car_order.pickup_datetime.to_date).to eq(@pickup_date)
      end

      # 断言5: 租期=5天 (10分)
      add_assertion "租期=5天", weight: 10 do
        actual_days = (@car_order.return_datetime.to_date - @car_order.pickup_datetime.to_date).to_i
        expect(actual_days).to eq(@rental_days),
          "租期错误。期望: #{@rental_days}天, 实际: #{actual_days}天"
      end

      # 断言6: 驾驶员信息正确（张三的姓名、身份证号） (10分)
      add_assertion "驾驶员信息正确（张三）", weight: 10 do
        expect(@car_order.driver_name).to eq(@expected_driver_name),
          "驾驶员姓名错误。期望: #{@expected_driver_name}, 实际: #{@car_order.driver_name}"
        expect(@car_order.driver_id_number).to eq(@expected_driver_id),
          "驾驶员身份证号错误。期望: #{@expected_driver_id}, 实际: #{@car_order.driver_id_number}"
      end

      # 断言7: 支付异地还车费用（+200元） (10分)
      add_assertion "支付异地还车费用（+200元）", weight: 10 do
        # 验证订单总价包含异地还车费（基础租金 + 200元异地还车费）
        base_price = @car_order.car.price_per_day * @rental_days
        expected_total = base_price + 200  # 异地还车费约200元
        price_diff = (@car_order.total_price - expected_total).abs
        
        # 允许50元浮动范围（不同车型异地还车费可能略有差异）
        expect(price_diff).to be <= 50,
          "异地还车费用错误。期望总价: #{expected_total}元（租金#{base_price}元 + 异地还车费200元），实际: #{@car_order.total_price}元"
      end

      # 断言8: 包含GPS导航功能 (10分)
      add_assertion "包含GPS导航功能", weight: 10 do
        features = @car_order.car.features.to_s
        has_gps = features.include?("GPS") || features.include?("导航")
        
        expect(has_gps).to be(true),
          "车辆缺少GPS导航功能。期望: 包含GPS或导航, 实际车辆功能: #{features}"
      end
    end

    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      passenger = user.passengers.find_by!(name: '张三', data_version: 0)

      # Select a car with GPS feature from 虹桥站南广场租车中心
      car = @available_cars.find { |c| 
        (c.features.to_s.include?("GPS") || c.features.to_s.include?("导航")) &&
        c.pickup_location.to_s.include?("虹桥")
      }
      car ||= @available_cars.find { |c| c.pickup_location.to_s.include?("虹桥") }
      car ||= @available_cars.first

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
        total_price: car.price_per_day * @rental_days + 200,  # +200 for cross-city return fee
        data_version: @data_version
      )
    end

    private

    def execution_state_data
      {
        pickup_location: @pickup_location,
        pickup_location_detail: @pickup_location_detail,
        return_location: @return_location,
        return_location_detail: @return_location_detail,
        category: @category,
        pickup_date: @pickup_date.to_s,
        rental_days: @rental_days,
        return_date: @return_date.to_s,
        expected_driver_name: @expected_driver_name,
        expected_driver_id: @expected_driver_id,
        expected_phone: @expected_phone
      }
    end

    def restore_from_state(data)
      @pickup_location = data['pickup_location']
      @pickup_location_detail = data['pickup_location_detail']
      @return_location = data['return_location']
      @return_location_detail = data['return_location_detail']
      @category = data['category']
      @pickup_date = Date.parse(data['pickup_date'])
      @rental_days = data['rental_days']
      @return_date = Date.parse(data['return_date'])
      @expected_driver_name = data['expected_driver_name']
      @expected_driver_id = data['expected_driver_id']
      @expected_phone = data['expected_phone']

      @available_cars = Car.where(
        location: @pickup_location,
        category: @category,
        data_version: 0
      ).order(price_per_day: :asc)
    end
  end
end
