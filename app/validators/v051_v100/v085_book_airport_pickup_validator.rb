# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例85: 给张三预订上海接机服务（北京→上海航班，虹桥机场→张江酒店，经济7座，后天下午2点）
# 
# 任务描述:
#   用户后天从北京坐飞机到上海，一家5口人需要在虹桥机场接机送到张江酒店。
#   Agent 需要通过搜索航班确定到达机场位置，选择经济7座车型中价格最低的套餐
# 
# 业务流程:
#   1. 用户选择"接我"服务（from_airport = 从机场接到目的地）
#   2. 根据航班的起终城市搜索（北京→上海），确定到达机场（如：上海虹桥机场T2）
#   3. 上车点：到达机场（location_from = 虹桥T2接机处，通过航班搜索确定）
#   4. 下车点：酒店地址（location_to = 浦东新区张江酒店）
#   5. 用车时间：后天下午2点（pickup_datetime）
#   6. 根据5人家庭需求，筛选经济7座车型
#   7. 浏览经济7座车型套餐，选择价格最低的
# 
# 复杂度分析:
#   1. 需要理解"接机"含义：from_airport = 从机场出发，送到目的地
#   2. 需要根据航班起终城市（北京→上海）搜索航班，确定到达机场位置（location_from = 虹桥T2）
#   3. 需要理解5人家庭需要7座车（座位需求匹配）
#   4. 需要选择下车地点（张江酒店）
#   5. 需要设置用车时间（后天下午2点）
#   6. 需要筛选经济7座车型
#   7. 需要对比同类车型不同供应商的价格
#   8. 需要选择最低价格的套餐
#   ❌ 不能一次性提供：需要先搜索航班→确定机场→选地址→设置时间→筛选车型→对比价格→预订
# 
# 评分标准:
#   - 创建了接机订单 (15分)
#   - 服务类型正确（airport_pickup + from_airport）(10分)
#   - 上车点和下车点正确（虹桥机场→张江酒店）(10分)
#   - 车辆类型正确（economy_7 经济7座）(15分)
#   - 联系人信息正确（4个成人中任选1人）(5分)
#   - 选择了该车型中价格最低的套餐 (30分)
#   - 订单价格正确 (5分)
#   - 用车时间正确（后天下午2点）(10分)
module V051V100
  class V085BookAirportPickupValidator < BaseValidator
    self.validator_id = 'v085_book_airport_pickup_validator'
    self.task_id = '74f8237a-b1b5-4670-b135-2867748d0721'
    self.title = '给张三预订上海接机服务（北京→上海航班，虹桥机场→张江酒店，经济7座，后天下午2点）'
    self.description = '预订上海虹桥机场接机服务（虹桥T2→浦东新区张江酒店，经济7座，后天下午2点）'
    self.timeout_seconds = 240
  
    def prepare
      # Demo user data - 5人中4个成人可选作为联系人（排除小明-儿童）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @zhangjianguo = user.passengers.find_by!(name: '张建国', data_version: 0)
      @zhangsan = user.passengers.find_by!(name: '张三', data_version: 0)
      @wangfang = user.passengers.find_by!(name: '王芳', data_version: 0)
      @lisi = user.passengers.find_by!(name: '李四', data_version: 0)
      # 小明（儿童）不应作为联系人
      
      @valid_passenger_names = [@zhangjianguo.name, @zhangsan.name, @wangfang.name, @lisi.name]
      @valid_passenger_phones = [@zhangjianguo.phone, @zhangsan.phone, @wangfang.phone, @lisi.phone]
      
      @service_type = 'from_airport'  # 机场接机服务
      @transfer_type = 'airport_pickup'
      @departure_city = '北京'  # 航班出发城市
      @arrival_city = '上海'  # 航班到达城市
      @arrival_airport = '虹桥T2接机处'  # 到达机场（上车点，上海，通过航班搜索确定）
      @dropoff_location = '浦东新区张江酒店'  # 下车点（目的地）
      @flight_date = (Date.current + 2.days).strftime('%Y-%m-%d')  # 后天
      @pickup_datetime = Date.current + 2.days + 14.hours  # 后天下午2点（预计到达时间）
      @vehicle_category = 'economy_7'  # 经济7座（家庭出行，5人）
      @passenger_count = 5  # 乘客人数
    
      @location_from = @arrival_airport  # 上车点 = 到达机场（通过航班搜索确定）
      @location_to = @dropoff_location  # 下车点 = 目的地
    
      @available_packages = TransferPackage.where(
        vehicle_category: @vehicle_category,
        is_active: true,
        data_version: 0
      )
    
      {
        task: "请预订机场接机服务，从机场送到酒店，选择经济7座车型中价格最低的套餐",
        scenario: "后天从北京坐飞机到上海，一家5口人，需要在机场接机送到浦东新区酒店",
        flight_info: {
          departure_city: @departure_city,
          arrival_city: @arrival_city,
          flight_date: @flight_date,
          flight_number: "CA1903",
          arrival_airport: "虹桥T2",
          arrival_time: "14:00"
        },
        service_type: "机场接机（from_airport）",
        pickup_location: "虹桥T2接机处（上车点，通过CA1903航班搜索确定）",
        dropoff_location: "#{@dropoff_location}（下车点，目的地酒店）",
        pickup_datetime: @pickup_datetime.strftime('%Y-%m-%d %H:%M'),
        passenger_count: @passenger_count,
        vehicle_category: '经济7座（economy_7）',
        flow_hint: "1. 搜索#{@departure_city}→#{@arrival_city}航班（CA1903，后天下午14:00到达虹桥T2） → 2. 确认到达机场（虹桥T2） → 3. 选择接机服务 → 4. 上车点自动=虹桥T2 → 5. 下车点输入目的地酒店地址 → 6. 根据5人家庭需求筛选经济7座车型 → 7. 对比同类车型不同供应商价格 → 8. 选择该车型中价格最低的套餐",
        hint: "家庭出行5人需要7座车（经济7座可容纳6人），搜索CA1903航班确定到达虹桥T2，选择economy_7车型中价格最低的套餐",
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
    
      add_assertion "上车点和下车点正确（虹桥机场→张江酒店）", weight: 10 do
        # 验证上车点包含虹桥
        expect(@transfer.location_from).to include('虹桥'),
          "上车点错误（缺少虹桥）。期望包含: 虹桥T2接机处, 实际: #{@transfer.location_from}"
        
        # 验证下车点包含张江
        expect(@transfer.location_to).to include('张江'),
          "下车点错误（缺少张江）。期望包含: 浦东新区张江酒店, 实际: #{@transfer.location_to}"
      end
    
      add_assertion "车辆类型正确（economy_7 经济7座）", weight: 15 do
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
    
      add_assertion "联系人信息正确（4个成人中任选1人）", weight: 5 do
        expect(@valid_passenger_names).to include(@transfer.passenger_name),
          "联系人姓名错误。应从4个成人中选择：#{@valid_passenger_names.join('、')}（小明是儿童不应作为联系人），实际: #{@transfer.passenger_name}"
        expect(@valid_passenger_phones).to include(@transfer.passenger_phone),
          "联系人电话错误。应从4个成人电话中选择，实际: #{@transfer.passenger_phone}"
      end
      
      add_assertion "订单价格正确", weight: 5 do
        expected_price = @transfer.transfer_package.price
        actual_price = @transfer.total_price
      
        expect(actual_price).to eq(expected_price),
          "订单价格错误。期望: #{expected_price}元，实际: #{actual_price}元"
      end
    
      add_assertion "用车时间正确（后天下午2点）", weight: 10 do
        actual_datetime = @transfer.pickup_datetime
        expect(actual_datetime).not_to be_nil, "未设置用车时间"
      
        # 验证日期是后天
        expect(actual_datetime.to_date).to eq(@pickup_datetime.to_date),
          "用车日期错误。期望: #{@pickup_datetime.to_date}（后天）, 实际: #{actual_datetime.to_date}"
      
        # 验证时间是下午2点（允许一些误差，比如12:00-16:00之间）
        actual_hour = actual_datetime.hour
        expect(actual_hour).to be_between(12, 16).inclusive,
          "用车时间错误。期望: 后天下午14:00左右，实际: #{actual_datetime.strftime('%Y-%m-%d %H:%M')}"
      end
    end
  
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      packages = TransferPackage.where(vehicle_category: @vehicle_category, is_active: true, data_version: 0)
      raise "未找到#{@vehicle_category}车型" if packages.empty?
    
      cheapest = packages.min_by(&:price)
      
      # 从4个成人中随机选择一个作为联系人（排除小明-儿童）
      selected_passenger = [@zhangjianguo, @zhangsan, @wangfang, @lisi].sample
    
      Transfer.create!(
        user_id: user.id,
        transfer_package_id: cheapest.id,
        transfer_type: @transfer_type,
        service_type: @service_type,
        location_from: @location_from,
        location_to: @location_to,
        pickup_datetime: @pickup_datetime,
        passenger_name: selected_passenger.name,
        passenger_phone: selected_passenger.phone,
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
        passenger_count: @passenger_count,
        valid_passenger_names: @valid_passenger_names,
        valid_passenger_phones: @valid_passenger_phones
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
      @passenger_count = data['passenger_count']
      @valid_passenger_names = data['valid_passenger_names']
      @valid_passenger_phones = data['valid_passenger_phones']
      @pickup_datetime = DateTime.parse(data['pickup_datetime']) if data['pickup_datetime']
      @available_packages = TransferPackage.where(vehicle_category: @vehicle_category, is_active: true, data_version: 0)
    end
    end
end