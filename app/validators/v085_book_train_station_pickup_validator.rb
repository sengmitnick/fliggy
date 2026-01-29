# frozen_string_literal: true

require_relative 'base_validator'

# 验证用例85: 预订虹桥火车站接站服务（经济7座，家庭出行）
class V085BookTrainStationPickupValidator < BaseValidator
  self.validator_id = 'v085_book_train_station_pickup_validator'
  self.title = '预订虹桥火车站接站服务（家庭出行，经济7座）'
  self.description = '后天从虹桥火车站接站送到酒店，一家5口人，选择经济7座车型'
  self.timeout_seconds = 240
  
  def prepare
    @service_type = 'from_station'  # 火车站接站服务
    @transfer_type = 'train_pickup'
    @pickup_location = '上海虹桥站西广场接送中心'
    @dropoff_location = '浦东新区张江酒店'
    @pickup_datetime = Date.current + 2.days + 14.hours
    @vehicle_category = 'economy_7'  # 经济7座（家庭出行，5人）
    
    @available_packages = TransferPackage.where(
      vehicle_category: @vehicle_category,
      is_active: true,
      data_version: 0
    )
    
    {
      task: "请预订后天下午2点从#{@pickup_location}接站送到#{@dropoff_location}，一家5口人，选择经济7座车型且价格最低的套餐",
      service_type: "火车站接站（from_train_station）",
      pickup_location: @pickup_location,
      dropoff_location: @dropoff_location,
      pickup_datetime: @pickup_datetime.strftime('%Y-%m-%d %H:%M'),
      passenger_count: 5,
      vehicle_category: '经济7座',
      hint: "家庭出行5人需要7座车，选择economy_7车型最便宜的套餐",
      available_packages_count: @available_packages.count
    }
  end
  
  def verify
    add_assertion "订单已创建", weight: 20 do
      @transfer = Transfer.order(created_at: :desc).first
      expect(@transfer).not_to be_nil, "未找到任何接送机订单"
    end
    
    return unless @transfer
    
    add_assertion "服务类型正确（train_pickup + from_station）", weight: 20 do
      expect(@transfer.transfer_type).to eq(@transfer_type),
        "服务类型错误。期望: #{@transfer_type}（火车站接站）, 实际: #{@transfer.transfer_type}"
      expect(@transfer.service_type).to eq(@service_type),
        "具体服务类型错误。期望: #{@service_type}（从车站接），实际: #{@transfer.service_type}"
    end
    
    add_assertion "车辆类型正确（economy_7 经济7座）", weight: 30 do
      expect(@transfer.transfer_package.vehicle_category).to eq(@vehicle_category),
        "车辆类型错误。期望: #{@vehicle_category}（经济7座，适合5人家庭）, 实际: #{@transfer.transfer_package.vehicle_category}"
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
      passenger_name: '王五',
      passenger_phone: '13900139001',
      total_price: cheapest.price,
      discount_amount: 0,
      status: 'pending',
      driver_status: 'pending'
    )
  end
end
