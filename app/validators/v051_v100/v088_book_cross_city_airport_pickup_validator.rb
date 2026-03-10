# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例88: 给张三预订首都国际机场接机服务（上海→北京航班，首都国际机场T3航站楼→三里屯太古里接送服务站，经济5座价格最低套餐，3天后下午1点）
#
# 任务描述:
#   用户3天后从上海飞往北京，需要在首都机场接机送到三里屯太古里。
#   Agent 需要通过搜索航班确定到达机场位置（首都T3），选择经济5座车型中价格最低的套餐
#
# 业务流程（7个关键步骤）：
#   1. 用户选择"接我"服务（from_airport = 从机场接到目的地）
#   2. 根据航班的起终城市搜索（上海→北京），确定到达机场（如：首都国际机场T3）
#   3. 上车点：到达机场（location_from = 首都国际机场T3航站楼，通过航班搜索确定）
#   4. 下车点：目的地地址（location_to = 三里屯太古里接送服务站）
#   5. 用车时间：3天后下午1点（pickup_datetime）
#   6. 根据单人出行需求，筛选经济5座车型
#   7. 在符合条件的套餐中选择价格最低的
#
# 复杂度分析（7个关键点）：
#   1. 需要理解"接机"含义：from_airport = 从机场出发，送到目的地
#   2. 需要根据航班起终城市（上海→北京）搜索航班，确定到达机场位置（location_from = 首都T3）
#   3. 需要选择下车地点（三里屯太古里接送服务站）
#   4. 需要设置用车时间（3天后下午1点）
#   5. 需要筛选经济5座车型
#   6. 需要对比符合条件的套餐价格
#   7. 需要选择价格最低的套餐
#   ❌ 不能一次性提供：需要先搜索航班→确定机场→选地址→设置时间→筛选车型→对比价格→预订
#
# 评分标准（7项，总计100分）：
#   - 创建了接机订单（15分）
#   - 服务类型正确（airport_pickup + from_airport）（10分）
#   - 上车点和下车点正确（首都国际机场T3航站楼→三里屯太古里接送服务站）（15分）
#   - 车辆类型正确（economy_5 经济5座）（15分）
#   - 选择了符合条件中价格最低的套餐（25分）
#   - 订单价格正确（10分）
#   - 联系人信息正确（张三）（10分）
module V051V100
  class V088BookCrossCityAirportPickupValidator < BaseValidator
    self.validator_id = 'v088_book_cross_city_airport_pickup_validator'
    self.task_id = '2f2c38ea-6cf0-4c4c-9f44-53f6444baece'
    self.title = '给张三预订首都国际机场接机服务（上海→北京航班，首都国际机场T3航站楼→三里屯太古里接送服务站，经济5座价格最低套餐，3天后下午1点）'
    self.description = '预订首都国际机场接机服务（首都T3→三里屯太古里，经济5座价格最低套餐，3天后下午1点）'
    self.timeout_seconds = 240
  
    def prepare
      # Demo user data
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @zhangsan = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_passenger_name = @zhangsan.name
      @expected_passenger_phone = @zhangsan.phone
      
      @service_type = 'from_airport'  # 接机服务
      @transfer_type = 'airport_pickup'
      @departure_city = '上海'  # 航班出发城市
      @arrival_city = '北京'  # 航班降落城市
      @arrival_airport = '首都国际机场T3航站楼'  # 到达机场（上车点，通过航班搜索确定）
      @dropoff_location = '三里屯太古里接送服务站'  # 下车点（市区地址）
      @flight_date = (Date.current + 3.days).strftime('%Y-%m-%d')  # 3天后
      @pickup_datetime = Date.current + 3.days + 13.hours  # 3天后下午1点
      @vehicle_category = 'economy_5'  # 经济5座
    
      @location_from = @arrival_airport  # 上车点 = 到达机场（通过航班搜索确定）
      @location_to = @dropoff_location  # 下车点 = 市区地址
    
      @available_packages = TransferPackage.where(
        vehicle_category: @vehicle_category,
        is_active: true,
        data_version: 0
      )
    
      {
        task: "请预订机场接机服务，从机场送到三里屯太古里，选择经济5座车型中价格最低的套餐",
        scenario: "3天后从上海飞往北京，需要在机场接机送到三里屯太古里",
        flight_info: {
          departure_city: @departure_city,
          arrival_city: @arrival_city,
          flight_date: @flight_date,
          flight_number: "HU7604",
          arrival_airport: "首都T3",
          arrival_time: "12:30"
        },
        service_type: "机场接机（from_airport）",
        pickup_location: "首都国际机场T3航站楼（上车点，通过#{@departure_city}→#{@arrival_city}航班搜索确定）",
        dropoff_location: "三里屯太古里接送服务站（下车点，目的地）",
        pickup_datetime: @pickup_datetime.strftime('%Y-%m-%d %H:%M'),
        vehicle_category: '经济5座（economy_5）',
        flow_hint: "1. 搜索#{@departure_city}→#{@arrival_city}航班（如HU7604，3天后中午12:30到达首都T3） → 2. 确认到达机场（首都T3） → 3. 选择接机服务 → 4. 上车点自动=首都T3 → 5. 下车点输入目的地地址 → 6. 设置用车时间（3天后下午1点） → 7. 筛选经济5座车型 → 8. 对比符合条件套餐价格 → 9. 选择该车型中价格最低的套餐",
        hint: "单人出行选择经济5座即可，搜索#{@departure_city}→#{@arrival_city}航班确定到达首都T3，选择economy_5车型中价格最低的套餐",
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
    
      add_assertion "上车点和下车点正确（首都国际机场T3航站楼→三里屯太古里接送服务站）", weight: 15 do
        # 验证上车点为北京首都T3（支持简化名称"首都T3"和完整名称"首都国际机场T3航站楼"）
        location_from = @transfer.location_from
        is_valid_pickup = location_from.include?('首都') && location_from.include?('T3')
        
        expect(is_valid_pickup).to be_truthy,
          "上车点错误。期望: 首都国际机场T3航站楼（或首都T3），实际: #{location_from}"
        
        # 验证下车点包含三里屯
        location_to = @transfer.location_to
        is_valid_dropoff = location_to.include?('三里屯')
        
        expect(is_valid_dropoff).to be_truthy,
          "下车点错误。期望: 三里屯太古里接送服务站（或包含三里屯），实际: #{location_to}"
      end
    
      add_assertion "车辆类型正确（economy_5 经济5座）", weight: 15 do
        expect(@transfer.transfer_package).not_to be_nil, "未选择车辆套餐"
        expect(@transfer.transfer_package.vehicle_category).to eq(@vehicle_category),
          "车辆类型错误。期望: #{@vehicle_category}（经济5座）, 实际: #{@transfer.transfer_package.vehicle_category}"
      end
    
      add_assertion "选择了符合条件中价格最低的套餐", weight: 25 do
        packages = TransferPackage.where(vehicle_category: @vehicle_category, is_active: true, data_version: 0)
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
    
      add_assertion "联系人信息正确（张三）", weight: 10 do
        expect(@transfer.passenger_name).to eq(@expected_passenger_name),
          "联系人姓名错误。期望: #{@expected_passenger_name}，实际: #{@transfer.passenger_name}"
        expect(@transfer.passenger_phone).to eq(@expected_passenger_phone),
          "联系人电话错误。期望: #{@expected_passenger_phone}，实际: #{@transfer.passenger_phone}"
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
        departure_city: @departure_city,
        arrival_city: @arrival_city,
        arrival_airport: @arrival_airport,
        dropoff_location: @dropoff_location,
        flight_date: @flight_date,
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
      @departure_city = data['departure_city']
      @arrival_city = data['arrival_city']
      @arrival_airport = data['arrival_airport']
      @dropoff_location = data['dropoff_location']
      @flight_date = data['flight_date']
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