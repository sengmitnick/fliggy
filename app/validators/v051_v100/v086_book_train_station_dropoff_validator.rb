# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例86: 给张三预订上海火车站送站服务（人民广场→上海虹桥站南广场接送中心，经济5座，明天早上7点）
# 
# 任务描述:
#   用户明天需要从人民广场去虹桥火车站赶高铁，需要预订送站服务。
#   Agent 需要选择火车站送站服务，选择经济5座车型中价格最低的套餐
# 
# 业务流程:
#   1. 用户选择"送我"服务（to_station = 从出发地送到车站）
#   2. 上车点：出发地（location_from = 人民广场接送服务站）
#   3. 下车点：目的地火车站（location_to = 上海虹桥站南广场接送中心）
#   4. 用车时间：明天早上7点（pickup_datetime）
#   5. 根据单人出行需求，筛选经济5座车型
#   6. 浏览经济5座车型套餐，选择价格最低的
# 
# 复杂度分析:
#   1. 需要理解"送站"含义：to_station = 从出发地送到火车站
#   2. 需要选择上车地点（人民广场接送服务站）
#   3. 需要选择下车地点（虹桥火车站）
#   4. 需要设置用车时间（明天早上7点）
#   5. 需要筛选经济5座车型
#   6. 需要对比同类车型不同供应商的价格
#   7. 需要选择最低价格的套餐
#   ❌ 不能一次性提供：需要选地址→设置时间→筛选车型→对比价格→预订
# 
# 评分标准:
#   - 创建了送站订单 (15分)
#   - 服务类型正确（train_pickup + to_station）(10分)
#   - 上车点和下车点正确（人民广场→上海虹桥站南广场接送中心）(10分)
#   - 车辆类型正确（economy_5 经济5座）(15分)
#   - 选择了该车型中价格最低的套餐 (30分)
#   - 联系人信息正确（张三）(5分)
#   - 订单价格正确 (5分)
#   - 用车时间正确（明天早上7点）(10分)
module V051V100
  class V086BookTrainStationDropoffValidator < BaseValidator
    self.validator_id = 'v086_book_train_station_dropoff_validator'
    self.task_id = '65b5c1be-7cd5-40d9-86b1-5b716ba64420'
    self.title = '给张三预订上海火车站送站服务（人民广场→上海虹桥站南广场接送中心，经济5座，明天早上7点）'
    self.description = '预订虹桥火车站送站服务（人民广场接送服务站→上海虹桥站南广场，经济5座，明天早上7点）'
    self.timeout_seconds = 240
  
    def prepare
      # Demo user data
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @zhangsan = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_passenger_name = @zhangsan.name
      @expected_passenger_phone = @zhangsan.phone
      
      @service_type = 'to_station'  # 送站服务
      @transfer_type = 'train_dropoff'
      @pickup_location = '人民广场接送服务站'  # 上车点（出发地）
      @dropoff_location = '上海虹桥站南广场接送中心'  # 下车点（目的地火车站）
      @pickup_datetime = Date.current + 1.days + 7.hours  # 明天早上7点
      @vehicle_category = 'economy_5'  # 经济5座（单人出行）
    
      @location_from = @pickup_location  # 上车点 = 出发地
      @location_to = @dropoff_location  # 下车点 = 目的地火车站
    
      @available_packages = TransferPackage.where(
        vehicle_category: @vehicle_category,
        is_active: true,
        data_version: 0
      )
    
      {
        task: "请预订火车站送站服务，从人民广场送到虹桥火车站，选择经济5座车型中价格最低的套餐",
        scenario: "明天早上需要从人民广场去虹桥火车站赶高铁",
        service_type: "火车站送站（to_station）",
        pickup_location: "#{@pickup_location}（上车点，出发地）",
        dropoff_location: "#{@dropoff_location}（下车点，目的地火车站）",
        pickup_datetime: @pickup_datetime.strftime('%Y-%m-%d %H:%M'),
        vehicle_category: '经济5座（economy_5）',
        flow_hint: "1. 选择送站服务 → 2. 上车点选择人民广场接送服务站 → 3. 下车点选择虹桥火车站 → 4. 设置用车时间（明天早上7点） → 5. 筛选经济5座车型 → 6. 对比同类车型不同供应商价格 → 7. 选择该车型中价格最低的套餐",
        hint: "单人赶高铁选择经济5座即可，选择economy_5车型中价格最低的套餐",
        available_packages_count: @available_packages.count
      }
    end
  
    def verify
      add_assertion "创建了送站订单", weight: 15 do
        all_transfers = Transfer
          .where(data_version: @data_version)
          .where(transfer_type: @transfer_type)
          .where(service_type: @service_type)
          .order(created_at: :desc)
          .to_a
        
        expect(all_transfers).not_to be_empty, "未找到任何火车站送站订单记录"
        @transfer = all_transfers.first
      end
    
      return if @transfer.nil?
    
      add_assertion "服务类型正确（train_dropoff + to_station）", weight: 10 do
        expect(@transfer.transfer_type).to eq(@transfer_type),
          "服务类型错误。期望: #{@transfer_type}（火车站送站）, 实际: #{@transfer.transfer_type}"
        expect(@transfer.service_type).to eq(@service_type),
          "具体服务类型错误。期望: #{@service_type}（送到车站），实际: #{@transfer.service_type}"
      end
    
      add_assertion "上车点和下车点正确（人民广场→上海虹桥站南广场接送中心）", weight: 10 do
        # 验证上车点包含人民广场
        expect(@transfer.location_from).to include('人民广场'),
          "上车点错误（缺少人民广场）。期望包含: 人民广场接送服务站, 实际: #{@transfer.location_from}"
        
        # 验证下车点包含虹桥
        expect(@transfer.location_to).to include('虹桥'),
          "下车点错误（缺少虹桥）。期望包含: 上海虹桥站南广场接送中心, 实际: #{@transfer.location_to}"
      end
    
      add_assertion "车辆类型正确（economy_5 经济5座）", weight: 15 do
        expect(@transfer.transfer_package).not_to be_nil, "未选择车辆套餐"
        expect(@transfer.transfer_package.vehicle_category).to eq(@vehicle_category),
          "车辆类型错误。期望: #{@vehicle_category}（经济5座，适合单人出行）, 实际: #{@transfer.transfer_package.vehicle_category}"
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
      
      add_assertion "联系人信息正确（张三）", weight: 5 do
        expect(@transfer.passenger_name).to eq(@expected_passenger_name),
          "联系人姓名错误。期望: #{@expected_passenger_name}，实际: #{@transfer.passenger_name}"
        expect(@transfer.passenger_phone).to eq(@expected_passenger_phone),
          "联系人电话错误。期望: #{@expected_passenger_phone}，实际: #{@transfer.passenger_phone}"
      end
      
      add_assertion "订单价格正确", weight: 5 do
        expected_price = @transfer.transfer_package.price
        actual_price = @transfer.total_price
      
        expect(actual_price).to eq(expected_price),
          "订单价格正确。期望: #{expected_price}元，实际: #{actual_price}元"
      end
    
      add_assertion "用车时间正确（明天早上7点）", weight: 10 do
        actual_datetime = @transfer.pickup_datetime
        expect(actual_datetime).not_to be_nil, "未设置用车时间"
      
        # 验证日期是明天
        expect(actual_datetime.to_date).to eq(@pickup_datetime.to_date),
          "用车日期错误。期望: #{@pickup_datetime.to_date}（明天）, 实际: #{actual_datetime.to_date}"
      
        # 验证时间是早上7点（允许一些误差，比如6:00-9:00之间）
        actual_hour = actual_datetime.hour
        expect(actual_hour).to be_between(6, 9).inclusive,
          "用车时间错误。期望: 明天早上07:00左右，实际: #{actual_datetime.strftime('%Y-%m-%d %H:%M')}"
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
        location_from: @pickup_location,
        location_to: @dropoff_location,
        pickup_datetime: @pickup_datetime,
        passenger_name: @expected_passenger_name,
        passenger_phone: @expected_passenger_phone,
        total_price: cheapest.price,
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
        pickup_location: @pickup_location,
        dropoff_location: @dropoff_location,
        location_from: @location_from,
        location_to: @location_to,
        pickup_datetime: @pickup_datetime.to_s, 
        vehicle_category: @vehicle_category,
        expected_passenger_name: @expected_passenger_name,
        expected_passenger_phone: @expected_passenger_phone
      }
    end
  
    def restore_from_state(data)
      @service_type = data['service_type']
      @transfer_type = data['transfer_type']
      @pickup_location = data['pickup_location']
      @dropoff_location = data['dropoff_location']
      @location_from = data['location_from']
      @location_to = data['location_to']
      @vehicle_category = data['vehicle_category']
      @expected_passenger_name = data['expected_passenger_name']
      @expected_passenger_phone = data['expected_passenger_phone']
      @pickup_datetime = DateTime.parse(data['pickup_datetime']) if data['pickup_datetime']
      @available_packages = TransferPackage.where(vehicle_category: @vehicle_category, is_active: true, data_version: 0)
    end
    end
end
