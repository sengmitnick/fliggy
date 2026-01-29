# frozen_string_literal: true

require_relative 'base_validator'

# 验证用例84: 预订浦东机场送机服务（上海→北京，舒适5座）
class V084BookAirportDropoffServiceValidator < BaseValidator
  self.validator_id = 'v084_book_airport_dropoff_service_validator'
  self.title = '预订浦东机场送机服务（市区→机场，舒适5座）'
  self.description = '明天从市区送到浦东T1机场赶飞机，选择舒适5座车型'
  self.timeout_seconds = 240
  
  def prepare
    @service_type = 'to_airport'  # 送机服务
    @transfer_type = 'airport_pickup'
    @pickup_location = '上海人民广场'
    @dropoff_location = '浦东T1'
    @pickup_datetime = Date.current + 1.days + 6.hours
    @vehicle_category = 'comfort_5'  # 舒适5座
    
    @available_packages = TransferPackage.where(
      vehicle_category: @vehicle_category,
      is_active: true,
      data_version: 0
    )
    
    {
      task: "请预订明天早上6点从#{@pickup_location}送到#{@dropoff_location}机场的送机服务，选择舒适5座车型且价格最低的套餐",
      service_type: "送机（to_airport）",
      pickup_location: @pickup_location,
      dropoff_location: @dropoff_location,
      pickup_datetime: @pickup_datetime.strftime('%Y-%m-%d %H:%M'),
      vehicle_category: '舒适5座',
      hint: "送机服务是从市区送到机场，车型要求comfort_5（舒适5座）",
      available_packages_count: @available_packages.count
    }
  end
  
  def verify
    add_assertion "订单已创建", weight: 20 do
      @transfer = Transfer.order(created_at: :desc).first
      expect(@transfer).not_to be_nil, "未找到任何接送机订单"
    end
    
    return unless @transfer
    
    add_assertion "服务类型正确（airport_pickup + to_airport）", weight: 20 do
      expect(@transfer.transfer_type).to eq(@transfer_type),
        "服务类型错误。期望: #{@transfer_type}（送机）, 实际: #{@transfer.transfer_type}"
      expect(@transfer.service_type).to eq(@service_type),
        "具体服务类型错误。期望: #{@service_type}（送到机场）, 实际: #{@transfer.service_type}"
    end
    
    add_assertion "车辆类型正确（comfort_5 舒适5座）", weight: 30 do
      expect(@transfer.transfer_package.vehicle_category).to eq(@vehicle_category),
        "车辆类型错误。期望: #{@vehicle_category}（舒适5座）, 实际: #{@transfer.transfer_package.vehicle_category}"
    end
    
    add_assertion "选择了该车型中最便宜的套餐", weight: 30 do
      packages = TransferPackage.where(vehicle_category: @vehicle_category, is_active: true, data_version: 0)
      cheapest = packages.min_by(&:price)
      expect(@transfer.transfer_package_id).to eq(cheapest.id),
        "未选择该车型最便宜套餐。应选: #{cheapest.name}（#{cheapest.price}元），实际: #{@transfer.transfer_package.name}（#{@transfer.transfer_package.price}元）"
    end
  end
  
  def execution_state_data
    { service_type: @service_type, transfer_type: @transfer_type, pickup_location: @pickup_location,
      dropoff_location: @dropoff_location, pickup_datetime: @pickup_datetime.to_s, vehicle_category: @vehicle_category }
  end
  
  def restore_from_state(data)
    @service_type = data['service_type']
    @transfer_type = data['transfer_type']
    @pickup_location = data['pickup_location']
    @dropoff_location = data['dropoff_location']
    @vehicle_category = data['vehicle_category']
    @pickup_datetime = DateTime.parse(data['pickup_datetime']) if data['pickup_datetime']
    @available_packages = TransferPackage.where(vehicle_category: @vehicle_category, is_active: true, data_version: 0)
  end
  
  def simulate
    user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
    packages = TransferPackage.where(vehicle_category: @vehicle_category, is_active: true, data_version: 0)
    raise "未找到#{@vehicle_category}车型" if packages.empty?
    
    cheapest = packages.min_by(&:price)
    
    Transfer.create!(
      user_id: user.id,
      transfer_package_id: cheapest.id,
      transfer_type: @transfer_type,
      service_type: @service_type,
      location_from: @pickup_location,
      location_to: @dropoff_location,
      pickup_datetime: @pickup_datetime,
      passenger_name: '李四',
      passenger_phone: '13900139000',
      total_price: cheapest.price,
      discount_amount: 0,
      status: 'pending',
      driver_status: 'pending'
    )
  end
end
