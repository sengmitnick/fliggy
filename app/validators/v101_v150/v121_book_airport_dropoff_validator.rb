# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例121: 给张三预订送机服务
#
# 任务描述:
#   用户预订了从上海陆家嘴到浦东国际机场T2航站楼的送机服务（明天上午06:00出发）。
#   航班信息：MU5422 上海→成都 07:00起飞，从浦东T2航站楼登机。
#   需要创建1个订单：
#   - 1个送机订单（陆家嘴 → 浦东T2，出发时间06:00）
#
# 复杂度分析:
#   1. 需要明确上车地点（陆家嘴）
#   2. 需要明确目的地机场和航站楼（浦东T2）
#   3. 需要明确出发时间（06:00，航班07:00起飞，提前1小时）
#   4. 选择经济5座并选择最优价格
#
# 评分标准:
#   - 创建了送机订单 (25分)
#   - 乘客信息正确（张三）(10分)
#   - 上车地点正确（陆家嘴）(15分)
#   - 目的地正确（浦东T2）(15分)
#   - 出发时间正确（06:00）(10分)
#   - 价格选择合理（25分)
#
# 使用方法:
#   # 准备阶段
#   POST /api/tasks/v121_book_airport_dropoff_validator/start
#   
#   # Agent 通过界面操作完成任务...
#   
#   # 验证结果
#   POST /api/verify/:execution_id/result
module V101V150
  class V121BookAirportDropoffValidator < BaseValidator
    self.validator_id = 'v121_book_airport_dropoff_validator'
    self.task_id = 'a8feeb5f-ef73-4817-919f-ee843937f5d8'
    self.title = '给张三预订送机服务'
    self.description = '预订送机服务'
    self.timeout_seconds = 300
  
    def prepare
      @city = '上海'
      @departure_location = '陆家嘴金融区'
      @destination_airport = '浦东国际机场T2航站楼'
      @departure_date = Date.current + 1.day
      @departure_time = Time.zone.parse("#{@departure_date} 06:00")
      @vehicle_category = 'economy_5'
      @transfer_type = 'airport_dropoff'
      @service_type = 'to_airport'

      # 获取受益人信息
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_passenger_name = @passenger.name
      @expected_passenger_phone = @passenger.phone
    
      @departure_loc = TransferLocation.find_by(
        city: @city,
        name: @departure_location,
        location_type: 'other',
        data_version: 0
      )
    
      raise "未找到出发地点: #{@departure_location}" unless @departure_loc
    
      @airport_location = TransferLocation.find_by(
        city: @city,
        name: @destination_airport,
        location_type: 'airport',
        data_version: 0
      )
    
      raise "未找到机场位置: #{@destination_airport}" unless @airport_location
    
      @available_packages = TransferPackage.where(
        vehicle_category: @vehicle_category,
        data_version: 0
      ).order(:price)
    
      raise "未找到经济5座套餐" if @available_packages.empty?
    
      @best_package = @available_packages.first
    
      {
        task: "请给张三预订#{@departure_date.strftime('%Y年%m月%d日')}上午06:00从#{@departure_location}到#{@destination_airport}的送机服务（选择经济5座车型）。张三要搭乘07:00飞往成都的MU5422航班，从浦东T2航站楼登机",
        requirements: {
          beneficiary: '张三',
          city: @city,
          departure_location: @departure_location,
          destination_airport: @destination_airport,
          departure_date: @departure_date.to_s,
          departure_time: '06:00',
          vehicle_category: '经济5座',
          service_description: '送机服务（到机场）',
          flight_info: 'MU5422 上海→成都 07:00起飞（浦东T2）'
        },
        hint: "送机服务需要明确上车地点和目的地机场及航站楼。出发时间为06:00，航班07:00起飞，提前1小时到机场",
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
      add_assertion "创建了送机订单", weight: 25 do
        @transfers = Transfer
          .where(transfer_type: @transfer_type, service_type: @service_type)
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
      
        expect(@transfers).not_to be_empty, "未找到送机订单"
        @transfer = @transfers.first
      end
    
      return if @transfer.nil?

      add_assertion "乘客信息正确（张三）", weight: 10 do
        expect(@transfer.passenger_name).to eq(@expected_passenger_name),
          "乘客姓名错误。期望: #{@expected_passenger_name}, 实际: #{@transfer.passenger_name}"
        expect(@transfer.passenger_phone).to eq(@expected_passenger_phone),
          "乘客电话错误。期望: #{@expected_passenger_phone}, 实际: #{@transfer.passenger_phone}"
      end
    
      add_assertion "上车地点正确（#{@departure_location}）", weight: 15 do
        expect(@transfer.location_from).to eq(@departure_location),
          "上车地点错误。期望: #{@departure_location}, 实际: #{@transfer.location_from}"
      end
    
      add_assertion "目的地正确（#{@destination_airport}）", weight: 15 do
        location_matches = @transfer.location_to.include?('浦东') && @transfer.location_to.include?('T2')
        
        expect(location_matches).to be_truthy,
          "目的地错误。期望: #{@destination_airport}（浦东T2），实际: #{@transfer.location_to}"
      end
    
      add_assertion "出发时间正确（06:00）", weight: 10 do
        pickup_hour = @transfer.pickup_datetime.hour
        pickup_minute = @transfer.pickup_datetime.min
      
        expect(pickup_hour).to eq(6), "出发时间错误。期望: 06:00, 实际: #{@transfer.pickup_datetime.strftime('%H:%M')}"
        expect(pickup_minute).to eq(0), "出发时间错误。期望: 06:00, 实际: #{@transfer.pickup_datetime.strftime('%H:%M')}"
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
      passenger = user.passengers.find_by!(name: '张三', data_version: 0)
    
      transfer = Transfer.create!(
        user_id: user.id,
        transfer_package_id: @best_package.id,
        transfer_type: @transfer_type,
        service_type: @service_type,
        location_from: @departure_loc.name,
        location_to: @airport_location.name,
        pickup_datetime: @departure_time,
        passenger_name: passenger.name,
        passenger_phone: passenger.phone,
        passenger_count: 1,
        luggage_count: 2,
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
        destination_airport: @destination_airport,
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
      @destination_airport = data['destination_airport']
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
    
      @airport_location = TransferLocation.find_by(
        city: @city,
        name: @destination_airport,
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