# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例121: 预订送机服务
#
# 任务描述:
#   用户预订了从北京国贸CBD到首都国际机场T3航站楼的送机服务（明天上午08:00出发）。
#   航班信息：CA1901 北京→上海 10:00起飞，从首都T3航站楼登机。
#   需要创建1个订单：
#   - 1个送机订单（国贸CBD → 首都T3，出发时间08:00）
#
# 复杂度分析:
#   1. 需要明确上车地点（国贸CBD）
#   2. 需要明确目的地机场和航站楼（首都T3）
#   3. 需要明确出发时间（08:00，航班10:00起飞，提前2小时）
#   4. 选择经济5座并选择最优价格
#
# 评分标准:
#   - 创建了送机订单 (25分)
#   - 上车地点正确（国贸CBD）(20分)
#   - 目的地正确（首都国际机场T3航站楼）(20分)
#   - 出发时间正确（08:00）(15分)
#   - 价格选择合理（20分)
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
    self.title = '预订送机服务（上海陆家嘴→浦东机场T2）'
    self.description = '从上海陆家嘴金融区送机到浦东国际机场T2航站楼（明天上午06:00出发），搭乘07:00飞往成都的MU5422航班'
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
        task: "请预订#{@departure_date.strftime('%Y年%m月%d日')}上午06:00从#{@departure_location}到#{@destination_airport}的送机服务（选择经济5座车型）。我要搭乘07:00飞往成都的MU5422航班，从浦东T2航站楼登机",
        requirements: {
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
    
      add_assertion "上车地点正确（#{@departure_location}）", weight: 20 do
        expect(@transfer.location_from).to eq(@departure_location),
          "上车地点错误。期望: #{@departure_location}, 实际: #{@transfer.location_from}"
      end
    
      add_assertion "目的地正确（#{@destination_airport}）", weight: 20 do
        location_matches = @transfer.location_to.include?('浦东') && @transfer.location_to.include?('T2')
        
        expect(location_matches).to be_truthy,
          "目的地错误。期望: #{@destination_airport}（浦东T2），实际: #{@transfer.location_to}"
      end
    
      add_assertion "出发时间正确（06:00）", weight: 15 do
        pickup_hour = @transfer.pickup_datetime.hour
        pickup_minute = @transfer.pickup_datetime.min
      
        expect(pickup_hour).to eq(6), "出发时间错误。期望: 06:00, 实际: #{@transfer.pickup_datetime.strftime('%H:%M')}"
        expect(pickup_minute).to eq(0), "出发时间错误。期望: 06:00, 实际: #{@transfer.pickup_datetime.strftime('%H:%M')}"
      end
    
      add_assertion "价格选择合理", weight: 20 do
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
    
      transfer = Transfer.create!(
        user_id: user.id,
        transfer_package_id: @best_package.id,
        transfer_type: @transfer_type,
        service_type: @service_type,
        location_from: @departure_loc.name,
        location_to: @airport_location.name,
        pickup_datetime: @departure_time,
        passenger_name: '郑十',
        passenger_phone: '13200132000',
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
        service_type: @service_type
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
