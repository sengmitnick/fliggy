# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例108: 帮张三在杭州西湖区订民宿（7天后入住，30天，选价格最低的房间）
#
# 任务描述:
#   用户张三想在杭州西湖区租一间民宿，租期30天，7天后入住。
#   优先选择价格最低的房源（性价比优先）。
#   Agent 需要在杭州西湖区的民宿中，选择价格最低的房间完成预订。
#
# 业务流程（4个关键步骤）：
#   1. 搜索杭州西湖区的民宿（hotel_type='homestay'）
#   2. 按房间价格排序，选择价格最低的房间（性价比优先）
#   3. 设置入住日期（7天后）、离店日期（30天后）
#   4. 填写租客信息（张三）并提交订单
#
# 复杂度分析（4个关键点）：
#   1. 需要理解住宿类型：hotel_type='homestay'（民宿，非酒店 'hotel'）
#   2. 需要理解租期计算：30天（长期租期）
#   3. 需要理解价格优化：选择同条件下价格最低的房间（性价比优先）
#   4. 需要理解地区筛选：杭州西湖区
#   ❌ 不能随机选择：必须精确匹配住宿类型（homestay）、地区（西湖区）并选择最低价
#
# 评分标准（6项，总计100分）：
#   - 订单已创建（25分）
#   - 城市/地区正确（杭州西湖区）（20分）
#   - 住宿类型正确（民宿 hotel_type='homestay'）（20分）
#   - 租期天数正确（30天）（10分）
#   - 房间数和人数正确（1间房，1成人，0儿童）（10分）
#   - 选择价格最低的房间（15分）
module V101V150
  class V108LongTermHomestayValidator < BaseValidator
    self.validator_id = 'v108_long_term_homestay_validator'
    self.task_id = 'a8f4e3b7-9c2d-4e1f-b6a9-5d7c3e8f2a61'
    self.title = '帮张三在杭州西湖区订民宿（7天后入住，30天，选价格最低的房间）'
    self.description = '在杭州西湖区预订民宿（30天，选价格最低的房间）'
    self.timeout_seconds = 300
  
    def prepare
      @city = '杭州'
      @area = '西湖区'
      @check_in_date = Date.current + 7.days  # 7天后入住
      @nights = 30  # 月租（30天）
      @check_out_date = @check_in_date + @nights.days
      @guest_name = '张三'
      @guest_phone = '13800138000'
    
      # 查找杭州西湖区的民宿（type='homestay'）
      @qualified_homestays = Hotel.where(
        hotel_type: 'homestay',
        data_version: 0
      ).where("city = ? OR city LIKE ?", @city, "#{@city}%")
       .where("address LIKE ?", "%#{@area}%")
    
      # 找到所有可用房间
      @available_rooms = HotelRoom
        .joins(:hotel)
        .where(
          hotels: { hotel_type: 'homestay', data_version: 0 }
        )
        .where("hotels.city = ? OR hotels.city LIKE ?", @city, "#{@city}%")
        .where("hotels.address LIKE ?", "%#{@area}%")
    
      # 找到价格最低的房间
      @cheapest_room = @available_rooms.order(:price).first
    
      {
        task: "请在#{@city}#{@area}地区预订民宿，租期#{@nights}天，7天后入住（#{@check_in_date.strftime('%Y年%m月%d日')}到#{@check_out_date.strftime('%Y年%m月%d日')}），选择价格最低的房间（性价比优先）",
        city: @city,
        area: @area,
        accommodation_type: 'homestay',
        accommodation_type_description: '民宿（非酒店，hotel_type=homestay）',
        check_in_date: @check_in_date.strftime('%Y-%m-%d'),
        check_out_date: @check_out_date.strftime('%Y-%m-%d'),
        nights: @nights,
        optimization: 'lowest_price',
        optimization_description: '价格最低（性价比优先）',
        guest_name: @guest_name,
        hint: "1. 在民宿搜索页选择杭州城市和西湖区地区。筛选住宿类型为'民宿'（hotel_type='homestay'）。在符合条件的房间中，选择价格最低的（性价比优先）。填写入住日期（7天后）、离店日期（30天后）。填写租客信息（张三）并提交订单。\n\n重要提示：\n- 必须选择西湖区的民宿（地址包含'西湖区'）\n- 推荐选择：杭州西湖雅居（西湖区灵隐寺附近，价格最低）",
        available_homestays_count: @qualified_homestays.count,
        available_rooms_count: @available_rooms.count,
        cheapest_room_price: @cheapest_room&.price
      }
    end
  
    def verify
      # 断言1: 订单已创建（权重25%）
      add_assertion "创建了民宿订单", weight: 25 do
        all_bookings = HotelBooking
          .joins(:hotel, :hotel_room)
          .includes(:hotel, :hotel_room)
          .where(hotels: { hotel_type: 'homestay' })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        expect(all_bookings).not_to be_empty, "未找到任何民宿订单"
        
        # 筛选符合城市和地区条件的订单
        @bookings = all_bookings.select do |b|
          (b.hotel.city == @city || b.hotel.city.start_with?(@city)) &&
          b.hotel.address&.include?(@area)
        end
        
        expect(@bookings).not_to be_empty, "未找到任何#{@city}#{@area}地区的民宿订单"
        @booking = @bookings.first
      end
    
      return if @bookings.nil? || @bookings.empty?
    
      # 断言2: 城市/地区正确（权重20%）
      add_assertion "城市/地区正确（#{@city}#{@area}）", weight: 20 do
        expect(@booking.hotel.city == @city || @booking.hotel.city.start_with?(@city)).to be_truthy,
          "城市错误。期望: #{@city}，实际: #{@booking.hotel.city}"
        expect(@booking.hotel.address).to include(@area),
          "地区错误。期望地址包含: #{@area}，实际地址: #{@booking.hotel.address}"
      end
    
      # 断言3: 住宿类型正确（权重20%）
      add_assertion "住宿类型正确（民宿 hotel_type='homestay'）", weight: 20 do
        expect(@booking.hotel.hotel_type).to eq('homestay'),
          "住宿类型错误。期望: homestay（民宿），实际: #{@booking.hotel.hotel_type}（#{@booking.hotel.hotel_type == 'hotel' ? '酒店' : @booking.hotel.hotel_type}）"
      end
    
      # 断言4: 租期天数正确（权重10%）
      add_assertion "租期天数正确（30天）", weight: 10 do
        actual_nights = (@booking.check_out_date - @booking.check_in_date).to_i
        expect(actual_nights).to eq(@nights),
          "租期天数错误。期望: #{@nights}天，实际: #{actual_nights}天（入住#{@booking.check_in_date}，离店#{@booking.check_out_date}）"
      end
    
      # 断言6: 房间数和人数正确
      add_assertion "房间数和人数正确（1间房，1成人，0儿童）", weight: 10 do
        expect(@booking.rooms_count).to eq(1),
          "房间数错误。期望: 1间, 实际: #{@booking.rooms_count}间"
        expect(@booking.adults_count).to eq(1),
          "成人数错误。期望: 1人, 实际: #{@booking.adults_count}人"
        expect(@booking.children_count).to eq(0),
          "儿童数错误。期望: 0人, 实际: #{@booking.children_count}人"
      end
    
      # 断言6: 选择了价格最低的房间（权重15%）
      add_assertion "选择了价格最低的房间（性价比优先）", weight: 15 do
        # 获取所有符合条件的房间
        available_rooms = HotelRoom
          .joins(:hotel)
          .where(
            hotels: { hotel_type: 'homestay', data_version: 0 }
          )
          .where("hotels.city = ? OR hotels.city LIKE ?", @city, "#{@city}%")
          .where("hotels.address LIKE ?", "%#{@area}%")
      
        cheapest_room = available_rooms.order(:price).first
      
        expect(@booking.hotel_room_id).to eq(cheapest_room.id),
          "未选择价格最低的房间。" \
          "应选: #{cheapest_room.hotel.name} - #{cheapest_room.room_type}（#{cheapest_room.price}元），" \
          "实际选择: #{@booking.hotel.name} - #{@booking.hotel_room.room_type}（#{@booking.hotel_room.price}元）"
      end
    end
  
    def simulate
      # 查找演示用户（使用基线 data_version=0）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
    
      # 查找杭州西湖区价格最低的房间（从基线数据中查找）
      target_room = HotelRoom
        .joins(:hotel)
        .where(
          hotels: { hotel_type: 'homestay', data_version: 0 }
        )
        .where("hotels.city = ? OR hotels.city LIKE ?", @city, "#{@city}%")
        .where("hotels.address LIKE ?", "%#{@area}%")
        .order(:price)
        .first
    
      raise "未找到符合条件的民宿房间" unless target_room
    
      target_homestay = target_room.hotel
    
      # 创建月租民宿订单
      HotelBooking.create!(
        hotel_id: target_homestay.id,
        hotel_room_id: target_room.id,
        user_id: user.id,
        check_in_date: @check_in_date,
        check_out_date: @check_out_date,
        rooms_count: 1,
        adults_count: 1,
        children_count: 0,
        total_price: target_room.price,  # 月租按月计费
        payment_method: '花呗',
        status: 'pending',
        guest_name: '张三',
        guest_phone: '13800138000',
        data_version: @data_version
      )
    end
  
    private
  
    def execution_state_data
      {
        city: @city,
        area: @area,
        check_in_date: @check_in_date.to_s,
        check_out_date: @check_out_date.to_s,
        nights: @nights,
        guest_name: @guest_name,
        guest_phone: @guest_phone
      }
    end
  
    def restore_from_state(data)
      @city = data['city']
      @area = data['area']
      @check_in_date = Date.parse(data['check_in_date'])
      @check_out_date = Date.parse(data['check_out_date'])
      @nights = data['nights']
      @guest_name = data['guest_name'] || '张三'
      @guest_phone = data['guest_phone'] || '13800138000'
    
      @qualified_homestays = Hotel.where(
        hotel_type: 'homestay',
        data_version: 0  # ✅ 查询基线数据
      ).where("city = ? OR city LIKE ?", @city, "#{@city}%")
       .where("address LIKE ?", "%#{@area}%")
    
      @available_rooms = HotelRoom
        .joins(:hotel)
        .where(
          hotels: { hotel_type: 'homestay', data_version: 0 }  # ✅ 查询基线数据
        )
        .where("hotels.city = ? OR hotels.city LIKE ?", @city, "#{@city}%")
        .where("hotels.address LIKE ?", "%#{@area}%")
    
      @cheapest_room = @available_rooms.order(:price).first
    end
  end
end
