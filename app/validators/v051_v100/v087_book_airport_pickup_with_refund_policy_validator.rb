# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例87: 给张三预订上海浦东国际机场接机服务（北京→上海航班，浦东国际机场T2航站楼→徐家汇商圈接送服务点，舒适5座，3天后上午11点，要求随时退）
#
# 任务描述:
#   用户3天后从北京坐飞机到上海浦东机场，需要接机送到徐家汇商圈。
#   Agent 需要通过搜索航班确定到达机场位置（浦东T2），选择舒适5座车型且支持随时退政策的套餐中价格最低的
#
# 业务流程（8个关键步骤）：
#   1. 用户选择"接我"服务（from_airport = 从机场接到目的地）
#   2. 根据航班的起终城市搜索（北京→上海），确定到达机场（如：上海浦东国际机场T2）
#   3. 上车点：到达机场（location_from = 浦东国际机场T2航站楼，通过航班搜索确定）
#   4. 下车点：目的地地址（location_to = 徐家汇商圈接送服务点）
#   5. 用车时间：3天后上午11点（pickup_datetime）
#   6. 根据单人出行需求，筛选舒适5座车型
#   7. 筛选支持"随时退"退款政策的套餐
#   8. 在符合条件的套餐中选择价格最低的
#
# 复杂度分析（8个关键点）：
#   1. 需要理解"接机"含义：from_airport = 从机场出发，送到目的地
#   2. 需要根据航班起终城市（北京→上海）搜索航班，确定到达机场位置（location_from = 浦东T2）
#   3. 需要选择下车地点（徐家汇商圈接送服务点）
#   4. 需要设置用车时间（3天后上午11点）
#   5. 需要筛选舒适5座车型
#   6. 需要筛选支持"随时退"退款政策的套餐
#   7. 需要对比符合条件的套餐价格
#   8. 需要选择价格最低的套餐
#   ❌ 不能一次性提供：需要先搜索航班→确定机场→选地址→设置时间→筛选车型→筛选退款政策→对比价格→预订
#
# 评分标准（8项，总计100分）：
#   - 创建了接机订单（15分）
#   - 服务类型正确（airport_pickup + from_airport）（10分）
#   - 上车点和下车点正确（浦东国际机场T2航站楼→徐家汇商圈接送服务点）（10分）
#   - 车辆类型正确（comfort_5 舒适5座）（15分）
#   - 退款政策包含'随时退'（20分）
#   - 选择了符合条件中价格最低的套餐（15分）
#   - 订单价格正确（10分）
#   - 联系人信息正确（张三）（5分）

module V051V100
  class V087BookAirportPickupWithRefundPolicyValidator < BaseValidator
    self.validator_id = 'v087_book_airport_pickup_with_refund_policy_validator'
    self.task_id = '309c926d-835e-4915-83b2-69118b74f6bc'
    self.title = '给张三预订上海浦东国际机场接机服务（北京→上海航班，浦东国际机场T2航站楼→徐家汇商圈接送服务点，舒适5座，3天后上午11点，要求随时退）'
    self.description = '预订上海浦东国际机场接机服务（浦东T2→徐家汇商圈，舒适5座，3天后上午11点，要求随时退）'
    self.timeout_seconds = 240

    def prepare
      # Demo user data
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @zhangsan = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_passenger_name = @zhangsan.name
      @expected_passenger_phone = @zhangsan.phone

      @service_type = 'from_airport'  # 机场接机服务
      @transfer_type = 'airport_pickup'
      @departure_city = '北京'  # 航班出发城市
      @arrival_city = '上海'  # 航班到达城市
      @arrival_airport = '浦东国际机场T2航站楼'  # 到达机场（上车点，通过航班搜索确定）
      @dropoff_location = '徐家汇商圈接送服务点'  # 下车点（目的地）
      @flight_date = (Date.current + 3.days).strftime('%Y-%m-%d')  # 3天后
      @pickup_datetime = Date.current + 3.days + 11.hours  # 3天后上午11点
      @vehicle_category = 'comfort_5'  # 舒适5座
      @required_refund_policy = '随时退'  # 退款政策要求

      @location_from = @arrival_airport  # 上车点 = 到达机场（通过航班搜索确定）
      @location_to = @dropoff_location  # 下车点 = 目的地

      @available_packages = TransferPackage.where(
        vehicle_category: @vehicle_category,
        is_active: true,
        data_version: 0
      ).select { |p| p.refund_policy.include?(@required_refund_policy) }

      {
        task: "请预订机场接机服务，从机场送到徐家汇商圈，选择舒适5座车型且支持随时退政策的套餐中价格最低的",
        scenario: "3天后从北京坐飞机到上海浦东机场，需要在机场接机送到徐家汇商圈，要求随时退",
        flight_info: {
          departure_city: @departure_city,
          arrival_city: @arrival_city,
          flight_date: @flight_date,
          flight_number: "MU5204",
          arrival_airport: "浦东T2",
          arrival_time: "11:30"
        },
        service_type: "机场接机（from_airport）",
        pickup_location: "浦东国际机场T2航站楼（上车点，通过#{@departure_city}→#{@arrival_city}航班搜索确定）",
        dropoff_location: "#{@dropoff_location}（下车点，目的地）",
        pickup_datetime: @pickup_datetime.strftime('%Y-%m-%d %H:%M'),
        vehicle_category: '舒适5座（comfort_5）',
        refund_policy: '随时退（出发前任何时间可免费取消）',
        flow_hint: "1. 搜索#{@departure_city}→#{@arrival_city}航班（如MU5204，3天后上午11:30到达浦东T2） → 2. 确认到达机场（浦东T2） → 3. 选择接机服务 → 4. 上车点自动=浦东T2 → 5. 下车点输入目的地地址 → 6. 设置用车时间（3天后上午11点） → 7. 筛选舒适5座车型 → 8. 筛选支持随时退的套餐 → 9. 对比符合条件套餐价格 → 10. 选择该车型中价格最低的套餐",
        hint: "单人出行选择舒适5座即可，搜索#{@departure_city}→#{@arrival_city}航班确定到达浦东T2，选择comfort_5车型且支持随时退政策的套餐中价格最低的",
        available_packages_count: @available_packages.count
      }
    end

    def verify
      add_assertion "创建了接机订单", weight: 15 do
        all_transfers = Transfer
          .where(data_version: @data_version)
          .where(transfer_type: @transfer_type)
          .where(service_type: @service_type)
          .order(created_at: :desc)
          .to_a

        expect(all_transfers).not_to be_empty, "未找到任何机场接机订单记录"
        @transfer = all_transfers.first
      end

      return if @transfer.nil?

      add_assertion "服务类型正确（airport_pickup + from_airport）", weight: 10 do
        expect(@transfer.transfer_type).to eq(@transfer_type),
          "服务类型错误。期望: #{@transfer_type}（机场接送）, 实际: #{@transfer.transfer_type}"
        expect(@transfer.service_type).to eq(@service_type),
          "具体服务类型错误。期望: #{@service_type}（从机场接），实际: #{@transfer.service_type}"
      end

      add_assertion "上车点和下车点正确（浦东国际机场T2航站楼→徐家汇商圈接送服务点）", weight: 10 do
        # 验证上车点包含浦东
        expect(@transfer.location_from).to include('浦东'),
          "上车点错误（缺少浦东）。期望包含: 浦东国际机场T2航站楼, 实际: #{@transfer.location_from}"

        # 验证下车点包含徐家汇
        expect(@transfer.location_to).to include('徐家汇'),
          "下车点错误（缺少徐家汇）。期望包含: 徐家汇商圈接送服务点, 实际: #{@transfer.location_to}"
      end

      add_assertion "车辆类型正确（comfort_5 舒适5座）", weight: 15 do
        expect(@transfer.transfer_package).not_to be_nil, "未选择车辆套餐"
        expect(@transfer.transfer_package.vehicle_category).to eq(@vehicle_category),
          "车辆类型错误。期望: #{@vehicle_category}（舒适5座）, 实际: #{@transfer.transfer_package.vehicle_category}"
      end

      add_assertion "退款政策包含'随时退'", weight: 20 do
        actual_policy = @transfer.transfer_package.refund_policy
        expect(actual_policy).to include(@required_refund_policy),
          "退款政策不符合要求。期望包含: '#{@required_refund_policy}'（出发前任何时间可免费取消）, 实际: #{actual_policy}"
      end

      add_assertion "选择了符合条件中价格最低的套餐", weight: 15 do
        packages = TransferPackage.where(vehicle_category: @vehicle_category, is_active: true, data_version: 0)
                                  .select { |p| p.refund_policy.include?(@required_refund_policy) }
        cheapest = packages.min_by(&:price)
        actual_price = @transfer.transfer_package.price
        cheapest_price = cheapest.price

        expect(@transfer.transfer_package_id).to eq(cheapest.id),
          "未选择符合条件最便宜套餐。" \
          "应选: #{cheapest.name} #{cheapest.category_name}（#{cheapest_price}元），" \
          "实际: #{@transfer.transfer_package.name} #{@transfer.transfer_package.category_name}（#{actual_price}元）"
      end

      add_assertion "订单价格正确", weight: 10 do
        expected_price = @transfer.transfer_package.price
        actual_price = @transfer.total_price

        expect(actual_price).to eq(expected_price),
          "订单价格错误。期望: #{expected_price}元，实际: #{actual_price}元"
      end

      add_assertion "联系人信息正确（张三）", weight: 5 do
        expect(@transfer.passenger_name).to eq(@expected_passenger_name),
          "联系人姓名错误。期望: #{@expected_passenger_name}，实际: #{@transfer.passenger_name}"
        expect(@transfer.passenger_phone).to eq(@expected_passenger_phone),
          "联系人电话错误。期望: #{@expected_passenger_phone}，实际: #{@transfer.passenger_phone}"
      end
    end

    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)

      # 查找符合条件的套餐（舒适5座 + 随时退）
      packages = TransferPackage.where(vehicle_category: @vehicle_category, is_active: true, data_version: 0)
                                .select { |p| p.refund_policy.include?(@required_refund_policy) }

      raise "未找到符合条件的机场接送套餐（#{@vehicle_category} + #{@required_refund_policy}）" if packages.empty?

      # 选择价格最低的套餐
      cheapest_package = packages.min_by(&:price)

      # 创建机场接送订单
      Transfer.create!(
        user_id: user.id,
        transfer_type: @transfer_type,
        service_type: @service_type,
        transfer_package_id: cheapest_package.id,
        location_from: @location_from,
        location_to: @location_to,
        pickup_datetime: @pickup_datetime,
        passenger_name: @expected_passenger_name,
        passenger_phone: @expected_passenger_phone,
        total_price: cheapest_package.price,
        discount_amount: 0,
        status: 'pending',
        driver_status: 'pending',
        data_version: @data_version
      )
    end

    private

    def execution_state_data
      {
        service_type: @service_type,
        transfer_type: @transfer_type,
        departure_city: @departure_city,
        arrival_city: @arrival_city,
        arrival_airport: @arrival_airport,
        dropoff_location: @dropoff_location,
        flight_date: @flight_date,
        location_from: @location_from,
        location_to: @location_to,
        pickup_datetime: @pickup_datetime.to_s,
        vehicle_category: @vehicle_category,
        required_refund_policy: @required_refund_policy,
        expected_passenger_name: @expected_passenger_name,
        expected_passenger_phone: @expected_passenger_phone
      }
    end

    def restore_from_state(data)
      @service_type = data['service_type']
      @transfer_type = data['transfer_type']
      @departure_city = data['departure_city']
      @arrival_city = data['arrival_city']
      @arrival_airport = data['arrival_airport']
      @dropoff_location = data['dropoff_location']
      @flight_date = data['flight_date']
      @location_from = data['location_from']
      @location_to = data['location_to']
      @vehicle_category = data['vehicle_category']
      @required_refund_policy = data['required_refund_policy']
      @expected_passenger_name = data['expected_passenger_name']
      @expected_passenger_phone = data['expected_passenger_phone']
      @pickup_datetime = DateTime.parse(data['pickup_datetime']) if data['pickup_datetime']
      @available_packages = TransferPackage.where(vehicle_category: @vehicle_category, is_active: true, data_version: 0)
                                           .select { |p| p.refund_policy.include?(@required_refund_policy) }
    end
  end
end
