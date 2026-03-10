# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例140: 帮张三订明天北京豪华车1天（上午9:00在国贸CBD租车服务站取车、晚上20:00还车），并预订同天下午2点送机服务（从国贸CBD到首都国际机场T3航站楼）
#
# 任务描述:
#   张三明天需要在北京租豪华车1天（上午9:00在国贸CBD租车服务站取车，晚上20:00还车），并需要预订同天下午2点的送机服务（从国贸CBD到首都国际机场T3航站楼）。
#   Agent 需要创建2个订单（租车订单+送机服务），确保租车车型为豪华车，租期1天，驾驶员信息为张三，送机起点为国贸CBD，目的地为首都国际机场。
#
# 业务流程（8个关键步骤）：
#   1. 明确受益人信息（张三，使用其姓名、身份证号、电话作为驾驶员和送机联系人信息）
#   2. 搜索北京的租车服务，筛选车型类别=豪华车
#   3. 按车辆价格升序排序，选择最低价格车辆
#   4. 创建租车订单（pickup_datetime=明天上午9:00，return_datetime=明天晚上20:00，租期1天）
#   5. 设置驾驶员信息为张三（driver_name, driver_id_number, contact_phone）
#   6. 创建送机服务订单（transfer_type='airport_dropoff', service_type='to_airport'）
#   7. 设置送机起点为国贸CBD，目的地为首都国际机场T3航站楼
#   8. 设置送机时间为明天下午2点（pickup_datetime = 明天 14:00）
#
# 复杂度分析（8个关键点）：
#   1. 需要理解租车+送机的两模块组合预订场景
#   2. 需要理解送机服务类型（transfer_type='airport_dropoff' 送机，service_type='to_airport' 到机场）
#   3. 需要选择豪华车车型（category = '豪华车'）
#   4. 需要计算租期1天（return_datetime = pickup_datetime + 1天）
#   5. 需要使用受益人信息作为驾驶员和送机联系人信息
#   6. 需要协调送机时间：在租车期间内（下午2点，在上午9:00取车后、晚上8点还车前）
#   7. 需要查询TransferLocation获取具体位置（国贸CBD → 首都国际机场T3航站楼）
#   8. 需要区分送机服务和接机服务（transfer_type='airport_dropoff' vs 'airport_pickup'）
#   ❌ 不能一次性提供所有信息：需要分别查询租车数据、送机服务，协调时间逻辑，分步骤创建2个订单。
#
# 评分标准（10项，总计100分）：
#   1. 创建了租车订单（15分）
#   2. 车型类别=豪华车（15分）
#   3. 租车地点=北京（5分）
#   4. 租期=1天（8分）
#   5. 取车地点明确（包含租车相关关键词）（7分）
#   6. 驾驶员信息正确（张三的姓名、身份证号）（5分）
#   7. 创建了送机订单（20分）
#   8. 送机起点=国贸CBD（10分）
#   9. 送机目的地=首都国际机场T3航站楼（5分）
#   10. 送机时间正确（下午2点±2小时范围）（10分）
#
# 使用方法:
#   rake validator:simulate_single[v140_book_luxury_car_and_airport_dropoff_validator]
#   或访问 http://localhost:<PORT>/api/tasks 获取任务列表
#
module V101V150
  class V140BookLuxuryCarAndAirportDropoffValidator < BaseValidator
    self.validator_id = 'v140_book_luxury_car_and_airport_dropoff_validator'
    self.task_id = 'a0b1c2d3-4e5f-6a7b-8c9d-0e1f2a3b4c5d'
    self.title = '帮张三订明天北京豪华车1天（上午9:00在国贸CBD租车服务站取车、晚上20:00还车），并预订同天下午2点送机服务（从国贸CBD到首都国际机场T3航站楼）'
    self.description = '帮张三订明天北京豪华车1天（上午9:00在国贸CBD租车服务站取车、晚上20:00还车），并预订同天下午2点送机服务（从国贸CBD到首都国际机场T3航站楼）'
    self.timeout_seconds = 300
    

    def task_description
      "帮张三订明天北京豪华车1天（上午9:00在国贸CBD租车服务站取车、晚上20:00还车），并预订同天下午2点的送机服务（从国贸CBD到首都国际机场T3航站楼）"
    end

    def prepare
      @location = "北京"
      @category = "豪华车"
      @pickup_date = Date.current + 1.day
      @rental_days = 1
      @return_date = @pickup_date + @rental_days.days
      @expected_rental_location = "国贸CBD租车服务站"

      # 预查询驾驶员信息（张三）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_driver_name = @passenger.name
      @expected_driver_id = @passenger.id_number
      @expected_phone = @passenger.phone

      @available_cars = Car.where(
        location: @location,
        category: @category,
        data_version: 0
      ).order(price_per_day: :asc)

      raise "未找到符合条件的豪华车" if @available_cars.empty?
      
      # 查找送机起点位置（国贸CBD）
      @transfer_from_loc = TransferLocation.find_by(
        city: @location,
        name: '国贸CBD',
        data_version: 0
      )
      raise "未找到国贸CBD送机起点" unless @transfer_from_loc
      @expected_transfer_from = @transfer_from_loc.name
      
      # 查找送机目的地位置（首都国际机场T3航站楼）
      @transfer_to_loc = TransferLocation.find_by(
        city: @location,
        name: '首都国际机场T3航站楼',
        location_type: 'airport',
        data_version: 0
      )
      raise "未找到首都国际机场T3航站楼" unless @transfer_to_loc
      @expected_transfer_to = @transfer_to_loc.name
      
      {
        task: "请为张三预订#{@pickup_date.strftime('%Y年%m月%d日')}在北京的豪华车（租期1天），" \
              "并预订同天下午2点的送机服务（从国贸CBD到首都国际机场T3航站楼）",
        requirements: {
          driver: @expected_driver_name,
          city: @location,
          car_category: @category,
          rental_days: @rental_days,
          rental_location: @expected_rental_location,
          pickup_time: '明天上午9:00',
          return_time: '明天晚上20:00',
          dropoff_service: '送机服务（到机场）',
          dropoff_time: '明天下午2点',
          dropoff_from: @expected_transfer_from,
          dropoff_to: @expected_transfer_to
        },
        hint: "先选择豪华车（最低价格），在国贸CBD租车服务站取车，然后预订送机服务（从国贸CBD到首都国际机场T3航站楼）。送机时间应在租车期间内（上午9:00-晚上20:00）",
        statistics: {
          available_cars: @available_cars.count,
          price_range: {
            min: @available_cars.minimum(:price_per_day),
            max: @available_cars.maximum(:price_per_day)
          }
        }
      }
    end

    def verify
      # 断言1: 创建了租车订单 (15分) - 核心评分项
      add_assertion "创建了租车订单", weight: 15 do
        all_car_orders = CarOrder
          .joins(:car)
          .includes(:car)
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a

        @car_order = all_car_orders.first
        expect(@car_order).not_to be_nil, "未找到租车订单"
      end

      return if @car_order.nil?

      # 断言2: 车型类别=豪华车 (15分)
      add_assertion "车型类别=豪华车", weight: 15 do
        expect(@car_order.car.category).to eq(@category),
          "车型类别错误。期望: #{@category}，实际: #{@car_order.car.category}"
      end

      # 断言3: 租车地点=北京 (5分)
      add_assertion "租车地点=北京", weight: 5 do
        expect(@car_order.car.location).to eq(@location),
          "租车地点错误。期望: #{@location}，实际: #{@car_order.car.location}"
      end

      # 断言4: 租期=1天 (8分)
      add_assertion "租期=1天", weight: 8 do
        # Use same rental_days calculation as CarOrder model (rounds up)
        # Formula: ceil((return_datetime - pickup_datetime) / 24 hours)
        diff_hours = (@car_order.return_datetime - @car_order.pickup_datetime) / 3600.0
        actual_days = (diff_hours / 24.0).ceil
        
        expect(actual_days).to eq(@rental_days),
          "租期错误。期望: #{@rental_days}天 (取车: #{@car_order.pickup_datetime.strftime('%Y-%m-%d %H:%M')}, 还车: #{@car_order.return_datetime.strftime('%Y-%m-%d %H:%M')}, 共#{diff_hours.round(1)}小时), 实际: #{actual_days}天"
      end

      # 断言5: 取车地点明确（包含租车相关关键词） (7分)
      add_assertion "取车地点明确（包含租车相关关键词）", weight: 7 do
        pickup_location = @car_order.pickup_location.to_s
        has_rental_keyword = pickup_location.include?("租车") || pickup_location.include?("CBD") || pickup_location.include?("服务")
        expect(has_rental_keyword).to be(true),
          "取车地点必须包含租车相关关键词。实际: #{pickup_location}"
      end

      # 断言6: 驾驶员信息正确（张三的姓名、身份证号） (5分)
      add_assertion "驾驶员信息正确（张三）", weight: 5 do
        expect(@car_order.driver_name).to eq(@expected_driver_name),
          "驾驶员姓名错误。期望: #{@expected_driver_name}, 实际: #{@car_order.driver_name}"
        expect(@car_order.driver_id_number).to eq(@expected_driver_id),
          "驾驶员身份证号错误。期望: #{@expected_driver_id}, 实际: #{@car_order.driver_id_number}"
      end

      # 断言7: 创建了送机订单 (20分)
      add_assertion "创建了送机订单", weight: 20 do
        all_transfers = Transfer
          .where(transfer_type: 'airport_dropoff', data_version: @data_version)
          .order(created_at: :desc)
          .to_a

        @transfer = all_transfers.first
        expect(@transfer).not_to be_nil, "未找到送机订单"
      end

      return if @transfer.nil?

      # 断言8: 送机起点=国贸CBD (10分)
      add_assertion "送机起点=国贸CBD", weight: 10 do
        location_from = @transfer.location_from
        is_correct = location_from.include?("国贸CBD")
        expect(is_correct).to be(true),
          "送机起点应该是'国贸CBD'。实际: #{location_from}"
      end

      # 断言9: 送机目的地=首都国际机场T3航站楼 (5分)
      add_assertion "送机目的地=首都国际机场T3航站楼", weight: 5 do
        location_to = @transfer.location_to
        is_correct = location_to.include?("首都国际机场T3航站楼")
        expect(is_correct).to be(true),
          "送机目的地应该是'首都国际机场T3航站楼'。实际: #{location_to}"
      end

      # 断言10: 送机时间正确（下午2点±2小时范围） (10分)
      add_assertion "送机时间正确（下午2点±2小时范围）", weight: 10 do
        pickup_hour = @transfer.pickup_datetime.hour
        # 验证送机时间在12:00-16:00之间（下午2点±2小时）
        expect(pickup_hour).to be >= 12, "送机时间过早。期望: 12:00之后（下午2点±2小时），实际: #{@transfer.pickup_datetime.strftime('%H:%M')}"
        expect(pickup_hour).to be <= 16, "送机时间过晚。期望: 16:00之前（下午2点±2小时），实际: #{@transfer.pickup_datetime.strftime('%H:%M')}"
      end
    end

    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      passenger = user.passengers.find_by!(name: '张三', data_version: 0)

      # 步骤1: 选择最低价格豪华车
      car = @available_cars.first
      
      # 步骤2: 创建租车订单（明天9:00在国贸CBD租车服务站取车，晚上20:00还车）
      # 注意：租期1天指的是同一天内租用（9:00-20:00，共11小时），按1天计费
      CarOrder.create!(
        user: user,
        car: car,
        driver_name: passenger.name,
        driver_id_number: passenger.id_number,
        contact_phone: passenger.phone,
        pickup_datetime: @pickup_date.in_time_zone + 9.hours,  # 上午9:00取车
        return_datetime: @pickup_date.in_time_zone + 20.hours,  # 同一天晚上20:00还车（租期1天）
        pickup_location: car.pickup_location,  # 使用车辆数据包中的pickup_location（具体租车点）
        status: 'confirmed',
        total_price: car.price_per_day * @rental_days,
        data_version: @data_version
      )

      # 步骤3: 创建送机服务（明天下午2点，从国贸CBD到首都国际机场T3航站楼）
      Transfer.create!(
        user: user,
        transfer_type: 'airport_dropoff',
        service_type: 'to_airport',
        location_from: @expected_transfer_from,  # 国贸CBD
        location_to: @expected_transfer_to,  # 首都国际机场T3航站楼
        pickup_datetime: @pickup_date.in_time_zone + 14.hours,  # 下午2点送机
        vehicle_type: 'luxury_5',
        passenger_name: passenger.name,
        passenger_phone: passenger.phone,
        total_price: 120.0,
        status: 'pending',
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
        expected_rental_location: @expected_rental_location,
        expected_transfer_from: @expected_transfer_from,
        expected_transfer_to: @expected_transfer_to,
        expected_driver_name: @expected_driver_name,
        expected_driver_id: @expected_driver_id,
        expected_phone: @expected_phone
      }
    end

    def restore_from_state(data)
      @location = data['location']
      @category = data['category']
      @pickup_date = Date.parse(data['pickup_date'])
      @rental_days = data['rental_days']
      @return_date = Date.parse(data['return_date'])
      @expected_rental_location = data['expected_rental_location']
      @expected_transfer_from = data['expected_transfer_from']
      @expected_transfer_to = data['expected_transfer_to']
      @expected_driver_name = data['expected_driver_name']
      @expected_driver_id = data['expected_driver_id']
      @expected_phone = data['expected_phone']

      @available_cars = Car.where(
        location: @location,
        category: @category,
        data_version: 0
      ).order(price_per_day: :asc)
      
      @transfer_from_loc = TransferLocation.find_by(
        city: @location,
        name: @expected_transfer_from,
        data_version: 0
      ) if @expected_transfer_from
      
      @transfer_to_loc = TransferLocation.find_by(
        city: @location,
        name: @expected_transfer_to,
        data_version: 0
      ) if @expected_transfer_to
    end
  end
end
