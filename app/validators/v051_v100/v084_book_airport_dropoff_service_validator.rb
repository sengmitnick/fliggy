# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例84: 给张三预订浦东机场送机服务（上海→北京航班，舒适5座）
# 
# 任务描述:
#   用户明天从上海飞往北京，需要从市区送到浦东机场。
#   Agent 需要通过搜索航班确定起飞机场位置，预订送机服务，选择舒适5座车型中价格最低的套餐
# 
# 业务流程:
#   1. 用户选择"送我"服务（to_airport = 送到机场）
#   2. 根据航班的起降城市搜索（上海→北京），确定起飞机场（如：浦东T1）
#   3. 下车点：起飞机场（location_to = 浦东国际机场T1航站楼，通过航班搜索确定）
#   4. 上车点：市区地址（location_from = 上海人民广场接送服务站）
#   5. 浏览舒适5座车型套餐，选择价格最低的
# 
# 复杂度分析:
#   1. 需要理解"送机"含义：to_airport = 从市区出发，送到机场
#   2. 需要根据航班起降城市（上海→北京）搜索航班，确定起飞机场位置（location_to = 浦东T1）
#   3. 需要选择上车地点（市区）
#   4. 需要筛选舒适5座车型
#   5. 需要对比同类车型不同供应商的价格
#   6. 需要选择最低价格的套餐
#   ❌ 不能一次性提供：需要先搜索航班→确定机场→选地址→筛选车型→对比价格→预订
module V051V100
  class V084BookAirportDropoffServiceValidator < BaseValidator
    self.validator_id = 'v084_book_airport_dropoff_service_validator'
    self.task_id = '31608ddd-05b6-48a6-8e8e-b9a0cf0759b4'
    self.title = '给张三预订浦东机场送机服务（上海→北京航班，舒适5座）'
    self.description = '预订浦东机场送机服务（上海→北京航班，舒适5座）'
    self.timeout_seconds = 240
  
    def prepare
      @service_type = 'to_airport'  # 送机服务
      @transfer_type = 'airport_pickup'
      @departure_city = '上海'  # 航班出发城市
      @arrival_city = '北京'  # 航班降落城市
      @departure_airport = '浦东T1'  # 起飞机场（下车点，通过航班搜索确定）
      @pickup_location = '上海人民广场接送服务站'  # 上车点（市区地址）
      @flight_date = (Date.current + 1.days).strftime('%Y-%m-%d')  # 明天
      @pickup_datetime = Date.current + 1.days + 6.hours  # 明天早上6点
      @vehicle_category = 'comfort_5'  # 舒适5座
    
      @location_from = @pickup_location  # 上车点 = 市区地址
      @location_to = @departure_airport  # 下车点 = 起飞机场（通过航班搜索确定）
    
      # 查询联系人信息（从 demo_user.passengers 获取）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @contact = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_contact_name = @contact.name
      @expected_contact_phone = @contact.phone
    
      @available_packages = TransferPackage.where(
        vehicle_category: @vehicle_category,
        is_active: true,
        data_version: 0
      )
    
      {
        task: "请预订送机服务，从市区送到机场，选择舒适5座车型中价格最低的套餐",
        scenario: "明天从上海飞往北京，需要从市区送到起飞机场",
        flight_info: {
          departure_city: @departure_city,
          arrival_city: @arrival_city,
          flight_date: @flight_date
        },
        service_type: "送机（to_airport）",
        pickup_location: "#{@pickup_location}（上车点，市区地址）",
        dropoff_location: "起飞机场（下车点，通过#{@departure_city}→#{@arrival_city}航班搜索确定）",
        pickup_datetime: @pickup_datetime.strftime('%Y-%m-%d %H:%M'),
        vehicle_category: '舒适5座（comfort_5）',
        flow_hint: "1. 搜索#{@departure_city}→#{@arrival_city}航班 → 2. 确认起飞机场（如浦东T1） → 3. 选择送机服务 → 4. 上车点选择市区地址 → 5. 下车点自动=起飞机场 → 6. 筛选舒适5座车型 → 7. 选择该车型中价格最低的套餐",
        available_packages_count: @available_packages.count
      }
    end
  
    def verify
      add_assertion "创建了送机订单", weight: 20 do
        @transfer = Transfer
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        expect(@transfer).not_to be_nil, "未找到任何接送机订单记录"
      end
    
      return unless @transfer
    
      add_assertion "服务类型正确（airport_pickup + to_airport）", weight: 15 do
        expect(@transfer.transfer_type).to eq(@transfer_type),
          "服务类型错误。期望: #{@transfer_type}（机场接送）, 实际: #{@transfer.transfer_type}"
        expect(@transfer.service_type).to eq(@service_type),
          "具体服务类型错误。期望: #{@service_type}（送到机场）, 实际: #{@transfer.service_type}"
      end
    
      add_assertion "车辆类型正确（comfort_5 舒适5座）", weight: 15 do
        expect(@transfer.transfer_package).not_to be_nil, "未选择车辆套餐"
        expect(@transfer.transfer_package.vehicle_category).to eq(@vehicle_category),
          "车辆类型错误。期望: #{@vehicle_category}（舒适5座）, 实际: #{@transfer.transfer_package.vehicle_category}"
      end
    
      add_assertion "联系人信息正确（张三）", weight: 10 do
        expect(@transfer.passenger_name).to eq(@expected_contact_name),
          "联系人姓名错误。期望: #{@expected_contact_name}, 实际: #{@transfer.passenger_name}"
        expect(@transfer.passenger_phone).to eq(@expected_contact_phone),
          "联系人电话错误。期望: #{@expected_contact_phone}, 实际: #{@transfer.passenger_phone}"
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
        passenger_name: @contact.name,
        passenger_phone: @contact.phone,
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
        departure_airport: @departure_airport,
        pickup_location: @pickup_location,
        flight_date: @flight_date,
        location_from: @location_from,
        location_to: @location_to,
        pickup_datetime: @pickup_datetime.to_s,
        vehicle_category: @vehicle_category,
        expected_contact_name: @expected_contact_name,
        expected_contact_phone: @expected_contact_phone
      }
    end
  
    def restore_from_state(data)
      @service_type = data['service_type']
      @transfer_type = data['transfer_type']
      @departure_city = data['departure_city']
      @arrival_city = data['arrival_city']
      @departure_airport = data['departure_airport']
      @pickup_location = data['pickup_location']
      @flight_date = data['flight_date']
      @location_from = data['location_from']
      @location_to = data['location_to']
      @vehicle_category = data['vehicle_category']
      @expected_contact_name = data['expected_contact_name']
      @expected_contact_phone = data['expected_contact_phone']
      @pickup_datetime = DateTime.parse(data['pickup_datetime']) if data['pickup_datetime']
      @available_packages = TransferPackage.where(vehicle_category: @vehicle_category, is_active: true, data_version: 0)
      
      # 恢复 contact 对象（用于 simulate）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @contact = user.passengers.find_by!(name: @expected_contact_name, data_version: 0)
    end
    end
end