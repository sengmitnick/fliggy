# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例108: 预订长租民宿
class V108LongTermHomestayValidator < BaseValidator
  self.validator_id = 'v108_long_term_homestay_validator'
  self.task_id = 'a8f4e3b7-9c2d-4e1f-b6a9-5d7c3e8f2a61'
  self.title = '预订长租民宿（杭州西湖区，月租，性价比优先）'
  self.description = '在杭州西湖区预订适合长租的民宿（30天以上），选择价格最低的月租房'
  self.timeout_seconds = 300
  
  def prepare
    @city = '杭州'
    @area = '西湖区'
    @check_in_date = Date.current + 7.days  # 下周入住
    @nights = 30  # 月租（30天）
    @check_out_date = @check_in_date + @nights.days
    
    # 查找杭州西湖区的民宿（type='homestay'）
    @qualified_homestays = Hotel.where(
      hotel_type: 'homestay',
      data_version: 0
    ).where("city = ? OR city LIKE ?", @city, "#{@city}%")
     .where("address LIKE ?", "%#{@area}%")
    
    # 找到有月租房型的民宿（room_category='monthly'）
    @available_monthly_rooms = HotelRoom
      .joins(:hotel)
      .where(
        hotels: { hotel_type: 'homestay', data_version: 0 },
        room_category: 'monthly'
      )
      .where("hotels.city = ? OR hotels.city LIKE ?", @city, "#{@city}%")
      .where("hotels.address LIKE ?", "%#{@area}%")
    
    # 找到价格最低的月租房
    @cheapest_room = @available_monthly_rooms.order(:price).first
    
    {
      task: "请在#{@city}#{@area}地区预订适合长租的民宿，租期#{@nights}天（月租），下周入住（#{@check_in_date.strftime('%Y年%m月%d日')}到#{@check_out_date.strftime('%Y年%m月%d日')}），选择价格最低的月租房（性价比优先）",
      requirements: {
        city: @city,
        area: @area,
        accommodation_type: 'homestay',
        accommodation_type_description: '民宿（非酒店）',
        check_in_date: @check_in_date.to_s,
        check_out_date: @check_out_date.to_s,
        nights: @nights,
        rental_type: 'monthly',
        rental_type_description: '月租房（room_category=monthly）',
        optimization: 'lowest_price',
        optimization_description: '价格最低（性价比优先）'
      },
      hint: "#{@city}#{@area}地区有多家民宿提供月租服务（room_category='monthly'），请选择价格最低的月租房",
      statistics: {
        total_homestays: @qualified_homestays.count,
        available_monthly_rooms: @available_monthly_rooms.count,
        cheapest_monthly_price: @cheapest_room&.price
      }
    }
  end
  
  def verify
    add_assertion "订单已创建", weight: 25 do
      all_bookings = HotelBooking
        .joins(:hotel, :hotel_room)
        .where(hotels: { hotel_type: 'homestay' })
        .where(data_version: @data_version)
        .order(created_at: :desc)
        .to_a
      
      @bookings = all_bookings.select do |b|
        (b.hotel.city == @city || b.hotel.city.start_with?(@city)) &&
        b.hotel.address&.include?(@area) &&
        b.hotel_room.room_category == 'monthly'
      end
      
      expect(@bookings).not_to be_empty, "未找到任何#{@city}#{@area}地区的月租民宿订单"
      @booking = @bookings.first
    end
    
    return if @bookings.nil? || @bookings.empty?
    
    add_assertion "城市/地区正确（#{@city}#{@area}）", weight: 15 do
      expect(@booking.hotel.city == @city || @booking.hotel.city.start_with?(@city)).to be_truthy,
        "城市错误。期望: #{@city}，实际: #{@booking.hotel.city}"
      expect(@booking.hotel.address).to include(@area),
        "地区错误。期望地址包含: #{@area}，实际地址: #{@booking.hotel.address}"
    end
    
    add_assertion "住宿类型正确（民宿）", weight: 15 do
      expect(@booking.hotel.hotel_type).to eq('homestay'),
        "住宿类型错误。期望: homestay（民宿），实际: #{@booking.hotel.hotel_type}"
    end
    
    add_assertion "租期类型正确（月租房）", weight: 15 do
      expect(@booking.hotel_room.room_category).to eq('monthly'),
        "房型类别错误。期望: monthly（月租房），实际: #{@booking.hotel_room.room_category}（#{@booking.hotel_room.room_category == 'overnight' ? '整晚' : @booking.hotel_room.room_category}）"
    end
    
    add_assertion "租期天数正确（30天）", weight: 10 do
      actual_nights = (@booking.check_out_date - @booking.check_in_date).to_i
      expect(actual_nights).to eq(@nights),
        "租期天数错误。期望: #{@nights}天，实际: #{actual_nights}天（入住#{@booking.check_in_date}，离店#{@booking.check_out_date}）"
    end
    
    add_assertion "选择了价格最低的月租房", weight: 20 do
      # 获取所有符合条件的月租房
      available_rooms = HotelRoom
        .joins(:hotel)
        .where(
          hotels: { hotel_type: 'homestay', data_version: 0 },
          room_category: 'monthly'
        )
        .where("hotels.city = ? OR hotels.city LIKE ?", @city, "#{@city}%")
        .where("hotels.address LIKE ?", "%#{@area}%")
      
      cheapest_room = available_rooms.order(:price).first
      
      expect(@booking.hotel_room_id).to eq(cheapest_room.id),
        "未选择价格最低的月租房。" \
        "应选: #{cheapest_room.hotel.name} - #{cheapest_room.room_type}（#{cheapest_room.price}元/月），" \
        "实际选择: #{@booking.hotel.name} - #{@booking.hotel_room.room_type}（#{@booking.hotel_room.price}元/月）"
    end
  end
  
  def simulate
    user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
    
    # 查找杭州西湖区价格最低的月租房
    target_room = HotelRoom
      .joins(:hotel)
      .where(
        hotels: { hotel_type: 'homestay', data_version: 0 },
        room_category: 'monthly'
      )
      .where("hotels.city = ? OR hotels.city LIKE ?", @city, "#{@city}%")
      .where("hotels.address LIKE ?", "%#{@area}%")
      .order(:price)
      .first
    
    raise "未找到符合条件的月租民宿" unless target_room
    
    target_homestay = target_room.hotel
    
    # 创建订单
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
      guest_name: '李明',
      guest_phone: '13800138012',
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
      nights: @nights
    }
  end
  
  def restore_from_state(data)
    @city = data['city']
    @area = data['area']
    @check_in_date = Date.parse(data['check_in_date'])
    @check_out_date = Date.parse(data['check_out_date'])
    @nights = data['nights']
    
    @qualified_homestays = Hotel.where(
      hotel_type: 'homestay',
      data_version: @data_version
    ).where("city = ? OR city LIKE ?", @city, "#{@city}%")
     .where("address LIKE ?", "%#{@area}%")
    
    @available_monthly_rooms = HotelRoom
      .joins(:hotel)
      .where(
        hotels: { hotel_type: 'homestay', data_version: @data_version },
        room_category: 'monthly'
      )
      .where("hotels.city = ? OR hotels.city LIKE ?", @city, "#{@city}%")
      .where("hotels.address LIKE ?", "%#{@area}%")
    
    @cheapest_room = @available_monthly_rooms.order(:price).first
  end
end
