# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例88: 预订虹桥机场接机服务（广州→上海航班，经济5座）
# 
# 任务描述:
#   用户3天后从广州飞往上海，需要在虹桥机场接机送到市区酒店。
#   Agent 需要通过搜索航班确定到达机场位置，预订接机服务，选择经济5座车型中价格最低的套餐
# 
# 业务流程:
#   1. 用户选择"接我"服务（from_airport = 从机场接到目的地）
#   2. 根据航班的起降城市搜索（广州→上海），确定到达机场（如：虹桥T2）
#   3. 上车点：到达机场（location_from = 虹桥国际机场T2航站楼，通过航班搜索确定）
#   4. 下车点：市区地址（location_to = 徐家汇商圈接送服务点）
#   5. 浏览经济5座车型套餐，选择价格最低的
# 
# 复杂度分析:
#   1. 需要理解"接机"含义：from_airport = 从机场出发，送到市区
#   2. 需要根据航班起降城市（广州→上海）搜索航班，确定到达机场位置（location_from = 虹桥T2）
#   3. 需要选择下车地点（市区酒店）
#   4. 需要筛选经济5座车型
#   5. 需要对比同类车型不同供应商的价格
#   6. 需要选择最低价格的套餐
#   ❌ 不能一次性提供：需要先搜索航班→确定机场→选地址→筛选车型→对比价格→预订
module V051V100
  class V088BookCrossCityAirportPickupValidator < BaseValidator
    self.validator_id = 'v088_book_cross_city_airport_pickup_validator'
    self.task_id = '2f2c38ea-6cf0-4c4c-9f44-53f6444baece'
    self.title = '预订虹桥机场接机服务（广州→上海航班，经济5座）'
    self.description = '3天后从广州飞往上海，通过搜索航班确定到达机场，从虹桥机场接机送到市区酒店，选择经济5座车型中价格最低的套餐'
    self.timeout_seconds = 240
  
    def prepare
      @service_type = 'from_airport'  # 接机服务
      @transfer_type = 'airport_pickup'
      @departure_city = '广州'  # 航班出发城市
      @arrival_city = '上海'  # 航班降落城市
      @arrival_airport = '虹桥国际机场T2航站楼'  # 到达机场（上车点，通过航班搜索确定）
      @dropoff_location = '徐家汇商圈接送服务点'  # 下车点（市区地址）
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
        task: "请预订接机服务，从机场送到市区酒店，选择经济5座车型中价格最低的套餐",
        scenario: "3天后从广州飞往上海，需要从到达机场送到市区酒店",
        flight_info: {
          departure_city: @departure_city,
          arrival_city: @arrival_city,
          flight_date: @flight_date
        },
        service_type: "接机（from_airport）",
        pickup_location: "到达机场（上车点，通过#{@departure_city}→#{@arrival_city}航班搜索确定）",
        dropoff_location: "#{@dropoff_location}（下车点，市区地址）",
        pickup_datetime: @pickup_datetime.strftime('%Y-%m-%d %H:%M'),
        vehicle_category: '经济5座（economy_5）',
        flow_hint: "1. 搜索#{@departure_city}→#{@arrival_city}航班 → 2. 确认到达机场（如虹桥T2） → 3. 选择接机服务 → 4. 上车点自动=到达机场 → 5. 下车点选择市区地址 → 6. 筛选经济5座车型 → 7. 选择该车型中价格最低的套餐",
        available_packages_count: @available_packages.count
      }
    end
  
    def verify
      add_assertion "订单已创建", weight: 20 do
        @transfer = Transfer.order(created_at: :desc).first
        expect(@transfer).not_to be_nil, "未找到任何接送机订单记录"
      end
    
      return unless @transfer
    
      add_assertion "服务类型正确（airport_pickup + from_airport）", weight: 15 do
        expect(@transfer.transfer_type).to eq(@transfer_type),
          "服务类型错误。期望: #{@transfer_type}（机场接送）, 实际: #{@transfer.transfer_type}"
        expect(@transfer.service_type).to eq(@service_type),
          "具体服务类型错误。期望: #{@service_type}（从机场接），实际: #{@transfer.service_type}"
      end
    
      add_assertion "车辆类型正确（economy_5 经济5座）", weight: 25 do
        expect(@transfer.transfer_package).not_to be_nil, "未选择车辆套餐"
        expect(@transfer.transfer_package.vehicle_category).to eq(@vehicle_category),
          "车辆类型错误。期望: #{@vehicle_category}（经济5座）, 实际: #{@transfer.transfer_package.vehicle_category}"
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
        passenger_name: '周八',
        passenger_phone: '13900139004',
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
        arrival_airport: @arrival_airport,
        dropoff_location: @dropoff_location,
        flight_date: @flight_date,
        location_from: @location_from,
        location_to: @location_to,
        pickup_datetime: @pickup_datetime.to_s,
        vehicle_category: @vehicle_category
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
      @pickup_datetime = DateTime.parse(data['pickup_datetime']) if data['pickup_datetime']
      @available_packages = TransferPackage.where(vehicle_category: @vehicle_category, is_active: true, data_version: 0)
    end
  end
end
