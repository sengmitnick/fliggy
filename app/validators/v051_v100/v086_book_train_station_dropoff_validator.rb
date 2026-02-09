# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例86: 预订虹桥火车站送站服务（经济5座，赶高铁）
module V051V100
  class V086BookTrainStationDropoffValidator < BaseValidator
    self.validator_id = 'v086_book_train_station_dropoff_validator'
    self.task_id = '65b5c1be-7cd5-40d9-86b1-5b716ba64420'
    self.title = '给张三预订明天早上上海火车站送站服务（选最便宜的经济5座）'
    self.description = '帮张三订明天一早从酒店送到虹桥火车站赶高铁，要最便宜的经济5座'
    self.timeout_seconds = 240
  
    def prepare
      # Demo user data
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @zhangsan = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_passenger_name = @zhangsan.name
      @expected_passenger_phone = @zhangsan.phone
      
      @service_type = 'to_station'  # 送站服务
      @transfer_type = 'train_pickup'
      @pickup_location = '静安区商务酒店'
      @dropoff_location = '上海虹桥站南广场接送中心'
      @pickup_datetime = Date.current + 1.days + 7.hours
      @vehicle_category = 'economy_5'  # 经济5座
    
      @available_packages = TransferPackage.where(
        vehicle_category: @vehicle_category,
        is_active: true,
        data_version: 0
      )
    
      {
        task: "请预订明天早上7点从#{@pickup_location}送到#{@dropoff_location}赶高铁，选择经济5座车型且价格最低的套餐",
        service_type: "火车站送站（to_train_station）",
        pickup_location: @pickup_location,
        dropoff_location: @dropoff_location,
        pickup_datetime: @pickup_datetime.strftime('%Y-%m-%d %H:%M'),
        vehicle_category: '经济5座',
        hint: "送站服务从酒店送到火车站，选择economy_5车型最便宜的套餐",
        available_packages_count: @available_packages.count
      }
    end
  
    def verify
      add_assertion "创建了送站订单", weight: 20 do
        all_transfers = Transfer
          .where(data_version: @data_version)
          .where(transfer_type: @transfer_type)
          .where(service_type: @service_type)
          .order(created_at: :desc)
          .to_a
        
        expect(all_transfers).not_to be_empty, "未找到任何火车站送站订单"
        @transfer = all_transfers.first
      end
    
      return if @transfer.nil?
    
      add_assertion "服务类型正确（train_pickup + to_station）", weight: 15 do
        expect(@transfer.transfer_type).to eq(@transfer_type),
          "服务类型错误。期望: #{@transfer_type}（火车站送站）, 实际: #{@transfer.transfer_type}"
        expect(@transfer.service_type).to eq(@service_type),
          "具体服务类型错误。期望: #{@service_type}（送到车站），实际: #{@transfer.service_type}"
      end
    
      add_assertion "车辆类型正确（economy_5 经济5座）", weight: 20 do
        expect(@transfer.transfer_package.vehicle_category).to eq(@vehicle_category),
          "车辆类型错误。期望: #{@vehicle_category}（经济5座）, 实际: #{@transfer.transfer_package.vehicle_category}"
      end
    
      add_assertion "选择了该车型中最便宜的套餐", weight: 25 do
        packages = TransferPackage.where(vehicle_category: @vehicle_category, is_active: true, data_version: 0)
        cheapest = packages.min_by(&:price)
        expect(@transfer.transfer_package_id).to eq(cheapest.id),
          "未选择该车型最便宜套餐。应选: #{cheapest.name}（#{cheapest.price}元），实际: #{@transfer.transfer_package.name}（#{@transfer.transfer_package.price}元）"
      end
      
      add_assertion "乘客信息正确（张三）", weight: 10 do
        expect(@transfer.passenger_name).to eq(@expected_passenger_name),
          "乘客姓名错误。期望: #{@expected_passenger_name}，实际: #{@transfer.passenger_name}"
        expect(@transfer.passenger_phone).to eq(@expected_passenger_phone),
          "乘客电话错误。期望: #{@expected_passenger_phone}，实际: #{@transfer.passenger_phone}"
      end
      
      add_assertion "订单价格正确", weight: 10 do
        expected_price = @transfer.transfer_package.price
        actual_price = @transfer.total_price
        
        expect(actual_price).to eq(expected_price),
          "订单价格错误。期望: #{expected_price}元，实际: #{actual_price}元"
      end
    end
  
    def execution_state_data
      { 
        service_type: @service_type, 
        transfer_type: @transfer_type, 
        pickup_location: @pickup_location,
        dropoff_location: @dropoff_location, 
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
      @vehicle_category = data['vehicle_category']
      @expected_passenger_name = data['expected_passenger_name']
      @expected_passenger_phone = data['expected_passenger_phone']
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
        passenger_name: @expected_passenger_name,
        passenger_phone: @expected_passenger_phone,
        total_price: cheapest.price,
        discount_amount: 0,
        status: 'pending',
        driver_status: 'pending',
        data_version: @data_version
      )
    end
    end
end
