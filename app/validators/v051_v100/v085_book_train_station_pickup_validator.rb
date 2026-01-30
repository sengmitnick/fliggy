# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例85: 预订虹桥火车站接站服务（经济7座，家庭出行）
# 
# 任务描述:
#   用户后天从北京坐火车到上海，一家5口人需要在虹桥火车站接站送到酒店。
#   Agent 需要通过搜索火车班次确定到达车站位置，选择经济7座车型中价格最低的套餐
# 
# 业务流程:
#   1. 用户选择"接我"服务（from_station = 从车站接到目的地）
#   2. 根据火车班次的起终城市搜索（北京→上海），确定到达车站（如：上海虹桥站）
#   3. 上车点：到达车站（location_from = 上海虹桥站西广场接送中心，通过火车班次搜索确定）
#   4. 下车点：酒店地址（location_to = 浦东新区张江酒店）
#   5. 根据5人家庭需求，筛选经济7座车型
#   6. 浏览经济7座车型套餐，选择价格最低的
# 
# 复杂度分析:
#   1. 需要理解"接站"含义：from_station = 从车站出发，送到目的地
#   2. 需要根据火车班次起终城市（北京→上海）搜索火车，确定到达车站位置（location_from = 上海虹桥站）
#   3. 需要理解5人家庭需要7座车（座位需求匹配）
#   4. 需要选择下车地点（酒店）
#   5. 需要筛选经济7座车型
#   6. 需要对比同类车型不同供应商的价格
#   7. 需要选择最低价格的套餐
#   ❌ 不能一次性提供：需要先搜索火车班次→确定车站→选地址→筛选车型→对比价格→预订
class V085BookTrainStationPickupValidator < BaseValidator
  self.validator_id = 'v085_book_train_station_pickup_validator'
  self.task_id = '74f8237a-b1b5-4670-b135-2867748d0721'
  self.title = '预订虹桥火车站接站服务（北京→上海火车，家庭出行，经济7座）'
  self.description = '后天从北京坐火车到上海，通过搜索火车班次确定到达车站，接站送到酒店，一家5口人，选择经济7座车型中价格最低的套餐'
  self.timeout_seconds = 240
  
  def prepare
    @service_type = 'from_station'  # 火车站接站服务
    @transfer_type = 'train_pickup'
    @departure_city = '北京'  # 火车出发城市
    @arrival_city = '上海'  # 火车到达城市
    @arrival_station = '上海虹桥站西广场接送中心'  # 到达车站（上车点，通过火车班次搜索确定）
    @dropoff_location = '浦东新区张江酒店'  # 下车点（目的地）
    @train_date = (Date.current + 2.days).strftime('%Y-%m-%d')  # 后天
    @pickup_datetime = Date.current + 2.days + 14.hours  # 后天下午2点（预计到达时间）
    @vehicle_category = 'economy_7'  # 经济7座（家庭出行，5人）
    @passenger_count = 5  # 乘客人数
    
    @location_from = @arrival_station  # 上车点 = 到达车站（通过火车班次搜索确定）
    @location_to = @dropoff_location  # 下车点 = 目的地
    
    @available_packages = TransferPackage.where(
      vehicle_category: @vehicle_category,
      is_active: true,
      data_version: 0
    )
    
    {
      task: "请预订火车站接站服务，从车站送到酒店，选择经济7座车型中价格最低的套餐",
      scenario: "后天从北京坐火车到上海，一家5口人，需要在车站接站送到浦东新区酒店",
      train_info: {
        departure_city: @departure_city,
        arrival_city: @arrival_city,
        train_date: @train_date
      },
      service_type: "火车站接站（from_station）",
      pickup_location: "到达车站（上车点，通过#{@departure_city}→#{@arrival_city}火车班次搜索确定）",
      dropoff_location: "#{@dropoff_location}（下车点，目的地酒店）",
      pickup_datetime: @pickup_datetime.strftime('%Y-%m-%d %H:%M'),
      passenger_count: @passenger_count,
      vehicle_category: '经济7座（economy_7）',
      flow_hint: "1. 搜索#{@departure_city}→#{@arrival_city}火车班次 → 2. 确认到达车站（如上海虹桥站） → 3. 选择接站服务 → 4. 上车点自动=到达车站 → 5. 下车点输入目的地酒店地址 → 6. 根据5人家庭需求筛选经济7座车型 → 7. 对比同类车型不同供应商价格 → 8. 选择该车型中价格最低的套餐",
      hint: "家庭出行5人需要7座车（经济7座可容纳6人），选择economy_7车型中价格最低的套餐",
      available_packages_count: @available_packages.count
    }
  end
  
  def verify
    add_assertion "订单已创建", weight: 20 do
      @transfer = Transfer.order(created_at: :desc).first
      expect(@transfer).not_to be_nil, "未找到任何接送机订单记录"
    end
    
    return unless @transfer
    
    add_assertion "服务类型正确（train_pickup + from_station）", weight: 15 do
      expect(@transfer.transfer_type).to eq(@transfer_type),
        "服务类型错误。期望: #{@transfer_type}（火车站接送）, 实际: #{@transfer.transfer_type}"
      expect(@transfer.service_type).to eq(@service_type),
        "具体服务类型错误。期望: #{@service_type}（从车站接），实际: #{@transfer.service_type}"
    end
    
    add_assertion "车辆类型正确（economy_7 经济7座）", weight: 25 do
      expect(@transfer.transfer_package).not_to be_nil, "未选择车辆套餐"
      expect(@transfer.transfer_package.vehicle_category).to eq(@vehicle_category),
        "车辆类型错误。期望: #{@vehicle_category}（经济7座，适合#{@passenger_count}人家庭）, 实际: #{@transfer.transfer_package.vehicle_category}"
    end
    
    add_assertion "选择了该车型中价格最低的套餐", weight: 30 do
      packages = TransferPackage.where(vehicle_category: @vehicle_category, is_active: true, data_version: 0)
      cheapest = packages.min_by(&:price)
      actual_price = @transfer.transfer_package.price
      cheapest_price = cheapest.price
      
      expect(@transfer.transfer_package_id).to eq(cheapest.id),
        "未选择该车型最便宜套餐。" \
        "应选: #{cheapest.name} #{cheapest.category_name}（#{cheapest_price}元），" \
        "实际: #{@transfer.transfer_package.name} #{@transfer.transfer_package.category_name}（#{actual_price}元）"
    end
    
    add_assertion "订单价格正确", weight: 10 do
      expected_price = @transfer.transfer_package.price
      actual_price = @transfer.total_price
      
      expect(actual_price).to eq(expected_price),
        "订单价格错误。期望: #{expected_price}元，实际: #{actual_price}元"
    end
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
      location_from: @location_from,
      location_to: @location_to,
      pickup_datetime: @pickup_datetime,
      passenger_name: '王五',
      passenger_phone: '13900139001',
      total_price: cheapest.price,
      discount_amount: 0,
      status: 'pending',
      driver_status: 'pending'
    )
  end
  
  private
  
  def execution_state_data
    {
      service_type: @service_type,
      transfer_type: @transfer_type,
      departure_city: @departure_city,
      arrival_city: @arrival_city,
      arrival_station: @arrival_station,
      dropoff_location: @dropoff_location,
      train_date: @train_date,
      location_from: @location_from,
      location_to: @location_to,
      pickup_datetime: @pickup_datetime.to_s,
      vehicle_category: @vehicle_category,
      passenger_count: @passenger_count
    }
  end
  
  def restore_from_state(data)
    @service_type = data['service_type']
    @transfer_type = data['transfer_type']
    @departure_city = data['departure_city']
    @arrival_city = data['arrival_city']
    @arrival_station = data['arrival_station']
    @dropoff_location = data['dropoff_location']
    @train_date = data['train_date']
    @location_from = data['location_from']
    @location_to = data['location_to']
    @vehicle_category = data['vehicle_category']
    @passenger_count = data['passenger_count']
    @pickup_datetime = DateTime.parse(data['pickup_datetime']) if data['pickup_datetime']
    @available_packages = TransferPackage.where(vehicle_category: @vehicle_category, is_active: true, data_version: 0)
  end
end