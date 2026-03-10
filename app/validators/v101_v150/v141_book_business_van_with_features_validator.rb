# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例141: 帮张三预订后天广州珠江新城CBD租车服务站的商务车，租2天，要求自动挡
#
# 任务描述:
#   张三计划后天从广州珠江新城CBD租车服务站租一辆商务车，租期2天，要求自动挡变速箱。
#   Agent 需要创建1个租车订单，确保车型为商务车，取车地点为广州珠江新城CBD租车服务站，租期2天，变速箱为自动挡。
#
# 业务流程（6个关键步骤）：
#   1. 明确受益人信息（张三，使用其姓名、身份证号、电话作为驾驶员信息）
#   2. 搜索广州的租车服务，筛选车型类别=商务车
#   3. 筛选自动挡变速箱的车辆（通过car.transmission字段判断）
#   4. 筛选珠江新城CBD租车服务站的车辆
#   5. 设置取车时间为后天（Date.current + 2.days）
#   6. 创建租车订单（pickup_location为广州珠江新城CBD租车服务站，租期2天）
#
# 复杂度分析（6个关键点）：
#   1. 需要理解车型分类（category = '商务车'，不是SUV或经济轿车）
#   2. 需要筛选自动挡变速箱（通过car.transmission字段查找包含'自动'或'automatic'关键词的车辆）
#   3. 需要正确计算租期2天（return_datetime = pickup_datetime + 2天）
#   4. 需要设置取车时间为后天（Date.current + 2.days）
#   5. 需要使用受益人信息作为驾驶员信息（driver_name、driver_id_number、contact_phone）
#   6. 需要明确取车地点：广州珠江新城CBD租车服务站
#
# 评分标准（8项，总计100分）：
#   1. 创建了商务车租车订单（25分）
#   2. 车型类别=商务车（15分）
#   3. 租车地点=广州（10分）
#   4. 取车地点=珠江新城CBD租车服务站（10分）
#   5. 取车时间=后天（10分）
#   6. 租期=2天（10分）
#   7. 变速箱=自动挡（15分）
#   8. 司机信息正确（张三的姓名、身份证号、电话）（5分）
#
# 使用方法:
#   rake validator:simulate_single[v141_book_business_van_with_features_validator]
#   或访问 http://localhost:<PORT>/api/tasks 获取任务列表
#
module V101V150
  class V141BookBusinessVanWithFeaturesValidator < BaseValidator
    self.validator_id = 'v141_book_business_van_with_features_validator'
    self.task_id = 'b1c2d3e4-5f6a-7b8c-9d0e-1f2a3b4c5d6e'
    self.title = '帮张三预订后天广州珠江新城CBD租车服务站的商务车，租2天，要求自动挡'
    self.description = '帮张三预订后天广州珠江新城CBD租车服务站的商务车，租2天，要求自动挡'
    self.timeout_seconds = 300

    def task_description
      "帮张三预订后天广州珠江新城CBD租车服务站的商务车，租2天，要求自动挡"
    end

    def prepare
      @location = "广州"
      @category = "商务车"
      @pickup_date = Date.current + 2.days
      @rental_days = 2
      @return_date = @pickup_date + @rental_days.days
      @required_transmission = "自动"

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

      raise "未找到符合条件的商务车" if @available_cars.empty?
    end

    def verify
      add_assertion "创建了商务车租车订单", weight: 25 do
        all_car_orders = CarOrder
          .joins(:car)
          .includes(:car)
          .where(cars: { location: @location, category: @category })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a

        @car_order = all_car_orders.first
        expect(@car_order).not_to be_nil, "未找到商务车租车订单"
      end

      return if @car_order.nil?

      add_assertion "车型类别=商务车", weight: 15 do
        expect(@car_order.car.category).to eq(@category)
      end

      add_assertion "租车地点=广州", weight: 10 do
        expect(@car_order.car.location).to eq(@location)
      end

      add_assertion "取车地点=珠江新城CBD租车服务站", weight: 10 do
        pickup_loc = @car_order.pickup_location.to_s
        expect(pickup_loc).to include("珠江新城"),
          "取车地点必须是珠江新城CBD租车服务站。实际: #{pickup_loc}"
        expect(pickup_loc).to include("租车"),
          "取车地点必须包含'租车'。实际: #{pickup_loc}"
      end

      add_assertion "取车时间=后天", weight: 10 do
        expect(@car_order.pickup_datetime.to_date).to eq(@pickup_date)
      end

      add_assertion "租期=2天", weight: 10 do
        actual_days = (@car_order.return_datetime.to_date - @car_order.pickup_datetime.to_date).to_i
        expect(actual_days).to eq(@rental_days),
          "租期错误。期望: #{@rental_days}天, 实际: #{actual_days}天"
      end

      add_assertion "变速箱=自动挡", weight: 15 do
        transmission = @car_order.car.transmission.to_s
        is_automatic = transmission.include?("自动") || transmission.downcase.include?("automatic")
        expect(is_automatic).to be(true),
          "变速箱不是自动挡。实际: #{transmission}"
      end

      add_assertion "司机信息正确（张三）", weight: 5 do
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

      # Find automatic transmission car
      car = @available_cars.find { |c| c.transmission.to_s.include?("自动") || c.transmission.to_s.downcase.include?("automatic") }
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
        total_price: car.price_per_day * @rental_days,  # No extra fees for same-city return
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
