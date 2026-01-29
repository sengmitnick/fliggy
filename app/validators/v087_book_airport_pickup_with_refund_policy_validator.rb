# frozen_string_literal: true

require_relative 'base_validator'

# 验证用例87: 预订浦东机场接机服务（舒适5座，要求随时退）
class V087BookAirportPickupWithRefundPolicyValidator < BaseValidator
  self.validator_id = 'v087_book_airport_pickup_with_refund_policy_validator'
  self.task_id = '309c926d-835e-4915-83b2-69118b74f6bc'
  self.title = '预订浦东机场接机服务（舒适5座，要求可随时取消）'
  self.description = '3天后从北京飞往上海，在浦东T2接机，需要舒适5座车型，并且要求出发前任何时间都可以免费取消订单（需先按起降城市搜索航班，系统会自动识别机场）'
  self.timeout_seconds = 240
  
  def prepare
    @service_type = 'from_airport'  # 接机服务
    @transfer_type = 'airport_pickup'
    @pickup_location = '浦东国际机场T2航站楼'
    @dropoff_location = '徐家汇商圈接送服务点'
    @pickup_datetime = Date.current + 3.days + 11.hours
    @vehicle_category = 'comfort_5'  # 舒适5座
    @required_refund_policy = '随时退'  # 要求随时退政策
    
    @available_packages = TransferPackage.where(
      vehicle_category: @vehicle_category,
      is_active: true,
      data_version: 0
    ).select { |p| p.refund_policy.include?(@required_refund_policy) }
    
    {
      task: "请预订3天后从#{@pickup_location}接机送到#{@dropoff_location}，要求舒适5座车型且支持随时取消（出发前任何时间都可免费取消），选择价格最低的套餐",
      service_type: "接机（from_airport）",
      pickup_location: @pickup_location,
      dropoff_location: @dropoff_location,
      pickup_datetime: @pickup_datetime.strftime('%Y-%m-%d %H:%M'),
      vehicle_category: '舒适5座',
      cancellation_policy: '随时退（出发前任何时间可免费取消）',
      hint: "接机服务需先按起降城市（北京→上海）搜索航班，系统会自动识别浦东T2机场。然后筛选舒适5座车型且取消政策显示'随时退'的套餐，选择其中价格最低的",
      available_packages_count: @available_packages.count
    }
  end
  
  def verify
    add_assertion "订单已创建", weight: 15 do
      @transfer = Transfer.order(created_at: :desc).first
      expect(@transfer).not_to be_nil, "未找到任何接送机订单"
    end
    
    return unless @transfer
    
    add_assertion "服务类型正确（airport_pickup）", weight: 15 do
      expect(@transfer.transfer_type).to eq(@transfer_type),
        "服务类型错误。期望: #{@transfer_type}（接机）, 实际: #{@transfer.transfer_type}"
    end
    
    add_assertion "车辆类型正确（comfort_5 舒适5座）", weight: 25 do
      expect(@transfer.transfer_package.vehicle_category).to eq(@vehicle_category),
        "车辆类型错误。期望: #{@vehicle_category}（舒适5座）, 实际: #{@transfer.transfer_package.vehicle_category}"
    end
    
    add_assertion "退款政策包含'随时退'", weight: 25 do
      actual_policy = @transfer.transfer_package.refund_policy
      expect(actual_policy).to include(@required_refund_policy),
        "退款政策不符合要求。期望包含: '#{@required_refund_policy}', 实际: #{actual_policy}"
    end
    
    add_assertion "选择了符合条件中最便宜的套餐", weight: 20 do
      packages = TransferPackage.where(vehicle_category: @vehicle_category, is_active: true, data_version: 0)
                                .select { |p| p.refund_policy.include?(@required_refund_policy) }
      cheapest = packages.min_by(&:price)
      expect(@transfer.transfer_package_id).to eq(cheapest.id),
        "未选择符合条件最便宜套餐。应选: #{cheapest.name}（#{cheapest.price}元），实际: #{@transfer.transfer_package.name}（#{@transfer.transfer_package.price}元）"
    end
  end
  
  def execution_state_data
    { service_type: @service_type, transfer_type: @transfer_type, pickup_location: @pickup_location,
      dropoff_location: @dropoff_location, pickup_datetime: @pickup_datetime.to_s, vehicle_category: @vehicle_category,
      required_refund_policy: @required_refund_policy }
  end
  
  def restore_from_state(data)
    @service_type = data['service_type']
    @transfer_type = data['transfer_type']
    @pickup_location = data['pickup_location']
    @dropoff_location = data['dropoff_location']
    @vehicle_category = data['vehicle_category']
    @required_refund_policy = data['required_refund_policy']
    @pickup_datetime = DateTime.parse(data['pickup_datetime']) if data['pickup_datetime']
    @available_packages = TransferPackage.where(vehicle_category: @vehicle_category, is_active: true, data_version: 0)
                                        .select { |p| p.refund_policy.include?(@required_refund_policy) }
  end
  
  def simulate
    user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
    packages = TransferPackage.where(vehicle_category: @vehicle_category, is_active: true, data_version: 0)
                              .select { |p| p.refund_policy.include?(@required_refund_policy) }
    raise "未找到符合条件的#{@vehicle_category}车型" if packages.empty?
    
    cheapest = packages.min_by(&:price)
    
    Transfer.create!(
      user_id: user.id,
      transfer_package_id: cheapest.id,
      transfer_type: @transfer_type,
      service_type: @service_type,
      location_from: @pickup_location,
      location_to: @dropoff_location,
      pickup_datetime: @pickup_datetime,
      passenger_name: '孙七',
      passenger_phone: '13900139003',
      total_price: cheapest.price,
      discount_amount: 0,
      status: 'pending',
      driver_status: 'pending'
    )
  end
end