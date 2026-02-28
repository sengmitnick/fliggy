# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例122: 预订送站服务
#
# 任务描述:
#   用户预订了从上海外滩到上海虹桥火车站的送站服务（后天下午14:00出发）。
#   需要创建1个订单：
#   - 1个送站订单（外滩 → 上海虹桥站，出发时间14:00）
#
# 复杂度分析:
#   1. 需要明确上车地点（外滩）
#   2. 需要明确目的地火车站（上海虹桥站）
#   3. 需要明确出发时间（14:00）
#   4. 选择经济5座并选择最优价格
#
# 评分标准:
#   - 创建了送站订单 (25分)
#   - 乘客信息正确（李四）(10分)
#   - 上车地点正确（外滩）(15分)
#   - 目的地正确（上海虹桥站）(15分)
#   - 出发时间正确（14:00）(10分)
#   - 价格选择合理（25分)
#
# 使用方法:
#   # 准备阶段
#   POST /api/tasks/v122_book_station_dropoff_validator/start
#   
#   # Agent 通过界面操作完成任务...
#   
#   # 验证结果
#   POST /api/verify/:execution_id/result
module V101V150
  class V122BookStationDropoffValidator < BaseValidator
    self.validator_id = 'v122_book_station_dropoff_validator'
    self.task_id = 'b7afcc22-6dff-4fb6-a389-a675def90300'
    self.title = '给李四预订后天送站服务（上海外滩→上海虹桥站，14:00出发）'
    self.description = '帮李四预订后天下午14:00从外滩到上海虹桥火车站的送站服务'
    self.timeout_seconds = 300
  
    def prepare
      @city = '上海'
      @departure_location = '外滩'
      @destination_station = '上海虹桥站'
      @departure_date = Date.current + 2.days
      @departure_time = Time.zone.parse("#{@departure_date} 14:00")
      @vehicle_category = 'economy_5'
      @transfer_type = 'train_dropoff'
      @service_type = 'to_station'

      # 获取受益人信息
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '李四', data_version: 0)
      @expected_passenger_name = @passenger.name
      @expected_passenger_phone = @passenger.phone
    
      @departure_loc = TransferLocation.find_by(
        city: @city,
        name: @departure_location,
        location_type: 'other',
        data_version: 0
      )
    
      raise "未找到出发地点: #{@departure_location}" unless @departure_loc
    
      @station_location = TransferLocation.find_by(
        city: @city,
        name: @destination_station,
        location_type: 'train_station',
        data_version: 0
      )
    
      raise "未找到车站位置: #{@destination_station}" unless @station_location
    
      @available_packages = TransferPackage.where(
        vehicle_category: @vehicle_category,
        data_version: 0
      ).order(:price)
    
      raise "未找到经济5座套餐" if @available_packages.empty?
    
      @best_package = @available_packages.first
    
      {
        task: "请给李四预订#{@departure_date.strftime('%Y年%m月%d日')}下午14:00从#{@departure_location}到#{@destination_station}的送站服务（选择经济5座车型）",
        requirements: {
          beneficiary: '李四',
          city: @city,
          departure_location: @departure_location,
          destination_station: @destination_station,
          departure_date: @departure_date.to_s,
          departure_time: '14:00',
          vehicle_category: '经济5座',
          service_description: '送站服务（到火车站）'
        },
        hint: "送站服务需要明确上车地点和目的地火车站。出发时间为14:00",
        statistics: {
          available_packages: @available_packages.count,
          price_range: {
            min: @available_packages.minimum(:price),
            max: @available_packages.maximum(:price)
          }
        }
      }
    end
  
    def verify
      add_assertion "创建了送站订单", weight: 25 do
        @transfers = Transfer
          .where(transfer_type: @transfer_type, service_type: @service_type)
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
      
        expect(@transfers).not_to be_empty, "未找到送站订单"
        @transfer = @transfers.first
      end
    
      return if @transfer.nil?

      add_assertion "乘客信息正确（李四）", weight: 10 do
        expect(@transfer.passenger_name).to eq(@expected_passenger_name),
          "乘客姓名错误。期望: #{@expected_passenger_name}, 实际: #{@transfer.passenger_name}"
        expect(@transfer.passenger_phone).to eq(@expected_passenger_phone),
          "乘客电话错误。期望: #{@expected_passenger_phone}, 实际: #{@transfer.passenger_phone}"
      end
    
      add_assertion "上车地点正确（#{@departure_location}）", weight: 15 do
        expect(@transfer.location_from).to eq(@departure_location),
          "上车地点错误。期望: #{@departure_location}, 实际: #{@transfer.location_from}"
      end
    
      add_assertion "目的地正确（#{@destination_station}）", weight: 15 do
        expect(@transfer.location_to).to eq(@destination_station),
          "目的地错误。期望: #{@destination_station}, 实际: #{@transfer.location_to}"
      end
    
      add_assertion "出发时间正确（14:00）", weight: 10 do
        pickup_hour = @transfer.pickup_datetime.hour
        pickup_minute = @transfer.pickup_datetime.min
      
        expect(pickup_hour).to eq(14), "出发时间错误。期望: 14:00, 实际: #{@transfer.pickup_datetime.strftime('%H:%M')}"
        expect(pickup_minute).to eq(0), "出发时间错误。期望: 14:00, 实际: #{@transfer.pickup_datetime.strftime('%H:%M')}"
      end
    
      add_assertion "价格选择合理（最便宜）", weight: 25 do
        cheapest_price = TransferPackage
          .where(vehicle_category: @vehicle_category, data_version: @data_version)
          .minimum(:price)
      
        if cheapest_price.present?
          expect(@transfer.total_price).to be <= (cheapest_price * 1.05),
            "未选择最优价格。最低价: ¥#{cheapest_price}, 实际: ¥#{@transfer.total_price}"
        end
      end
    end
  
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      passenger = user.passengers.find_by!(name: '李四', data_version: 0)
    
      transfer = Transfer.create!(
        user_id: user.id,
        transfer_package_id: @best_package.id,
        transfer_type: @transfer_type,
        service_type: @service_type,
        location_from: @departure_loc.name,
        location_to: @station_location.name,
        pickup_datetime: @departure_time,
        passenger_name: passenger.name,
        passenger_phone: passenger.phone,
        passenger_count: 1,
        luggage_count: 1,
        total_price: @best_package.price,
        discount_amount: 0,
        status: 'paid',
        driver_status: 'pending',
        data_version: @data_version
      )
    
      { transfer: transfer }
    end
  
    private
  
    def execution_state_data
      {
        city: @city,
        departure_location: @departure_location,
        destination_station: @destination_station,
        departure_date: @departure_date.to_s,
        departure_time: @departure_time.to_s,
        vehicle_category: @vehicle_category,
        transfer_type: @transfer_type,
        service_type: @service_type,
        expected_passenger_name: @expected_passenger_name,
        expected_passenger_phone: @expected_passenger_phone
      }
    end
  
    def restore_from_state(data)
      @city = data['city']
      @departure_location = data['departure_location']
      @destination_station = data['destination_station']
      @departure_date = Date.parse(data['departure_date'])
      @departure_time = Time.zone.parse(data['departure_time'])
      @vehicle_category = data['vehicle_category']
      @transfer_type = data['transfer_type']
      @service_type = data['service_type']
      @expected_passenger_name = data['expected_passenger_name']
      @expected_passenger_phone = data['expected_passenger_phone']
    
      @departure_loc = TransferLocation.find_by(
        city: @city,
        name: @departure_location,
        data_version: 0
      )
    
      @station_location = TransferLocation.find_by(
        city: @city,
        name: @destination_station,
        data_version: 0
      )
    
      @available_packages = TransferPackage.where(
        vehicle_category: @vehicle_category,
        data_version: 0
      ).order(:price)
    
      @best_package = @available_packages.first if @available_packages.any?
    end
  end
end
