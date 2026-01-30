# frozen_string_literal: true

require_relative 'base_validator'

# 验证用例099: 预订热门民宿（北京王府井地区）
#
# 任务描述:
#   在北京王府井地区预订评分最高的民宿，入住2晚
#
# 评分标准:
#   - 订单已创建 (25分)
#   - 城市/地区正确（北京王府井）(15分)
#   - 住宿类型正确（民宿）(20分)
#   - 入住天数正确（2晚）(15分)
#   - 选择了评分最高的民宿（优化项）(25分)
#
# 使用方法:
#   # 准备阶段
#   POST /api/tasks/v099_homestay_booking_validator/start
#   
#   # Agent 通过界面操作完成任务...
#   
#   # 验证结果
#   POST /api/verify/:execution_id/result
class V099HomestayBookingValidator < BaseValidator
  self.validator_id = 'v099_homestay_booking_validator'
  self.task_id = '7874748d-a0b8-4725-a536-ff9141c0fed1'
  self.title = '预订热门民宿（上海CBD核心区）'
  self.description = '在上海CBD核心区预订评分最高的民宿，入住2晚'
  self.timeout_seconds = 300
  
  def prepare
    @city = '上海'
    @area = 'CBD核心区'
    @check_in_date = Date.current + 3.days  # 大后天入住
    @nights = 2
    @check_out_date = @check_in_date + @nights.days
    
    # 查找北京王府井地区的民宿（type='homestay'）
    @qualified_homestays = Hotel.where(
      hotel_type: 'homestay',
      data_version: 0
    ).where("city = ? OR city LIKE ?", @city, "#{@city}%")
     .where("address LIKE ?", "%#{@area}%")
    
    # 找到评分最高的民宿
    @best_homestay = @qualified_homestays.order(rating: :desc).first
    
    {
      task: "请在#{@city}#{@area}地区预订评分最高的民宿，入住#{@nights}晚（大后天入住，#{@check_in_date.strftime('%Y年%m月%d日')}到#{@check_out_date.strftime('%Y年%m月%d日')}）",
      requirements: {
        city: @city,
        area: @area,
        accommodation_type: 'homestay',
        accommodation_type_description: '民宿（非酒店）',
        check_in_date: @check_in_date.to_s,
        check_out_date: @check_out_date.to_s,
        nights: @nights,
        optimization: 'highest_rating',
        optimization_description: '评分最高'
      },
      hint: "#{@city}#{@area}地区有多家民宿可选，请选择评分最高的",
      statistics: {
        total_homestays: @qualified_homestays.count,
        best_homestay_rating: @best_homestay&.rating
      }
    }
  end
  
  def verify
    add_assertion "订单已创建", weight: 25 do
      all_bookings = HotelBooking.joins(:hotel)
                                  .where(hotels: { hotel_type: 'homestay' })
                                  .where(data_version: @data_version)
                                  .order(created_at: :desc)
                                  .to_a
      
      @bookings = all_bookings.select do |b|
        (b.hotel.city == @city || b.hotel.city.start_with?(@city)) &&
        b.hotel.address&.include?(@area)
      end
      
      expect(@bookings).not_to be_empty, "未找到任何#{@city}#{@area}地区的民宿订单"
      @booking = @bookings.first
    end
    
    return if @bookings.nil? || @bookings.empty?
    
    add_assertion "城市/地区正确（#{@city}#{@area}）", weight: 15 do
      expect(@booking.hotel.city == @city || @booking.hotel.city.start_with?(@city)).to be_truthy,
        "城市错误。期望: #{@city}，实际: #{@booking.hotel.city}"
      expect(@booking.hotel.address).to include(@area),
        "地区错误。期望地址包含: #{@area}，实际地址: #{@booking.hotel.address}"
    end
    
    add_assertion "住宿类型正确（民宿）", weight: 20 do
      expect(@booking.hotel.hotel_type).to eq('homestay'),
        "住宿类型错误。期望: homestay（民宿），实际: #{@booking.hotel.hotel_type}（#{@booking.hotel.hotel_type == 'hotel' ? '酒店' : @booking.hotel.hotel_type}）"
    end
    
    add_assertion "入住天数正确（#{@nights}晚）", weight: 15 do
      actual_nights = (@booking.check_out_date - @booking.check_in_date).to_i
      expect(actual_nights).to eq(@nights),
        "入住天数错误。期望: #{@nights}晚，实际: #{actual_nights}晚（入住#{@booking.check_in_date}，离店#{@booking.check_out_date}）"
    end
    
    add_assertion "选择了评分最高的民宿", weight: 25 do
      # 获取所有符合条件的民宿
      qualified_homestays = Hotel.where(
        hotel_type: 'homestay',
        data_version: 0
      ).where("city = ? OR city LIKE ?", @city, "#{@city}%")
       .where("address LIKE ?", "%#{@area}%")
      
      best_homestay = qualified_homestays.order(rating: :desc).first
      
      expect(@booking.hotel_id).to eq(best_homestay.id),
        "未选择评分最高的民宿。" \
        "应选: #{best_homestay.name}（评分#{best_homestay.rating}分），" \
        "实际选择: #{@booking.hotel.name}（评分#{@booking.hotel.rating}分）"
    end
  end
  
  def simulate
    user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
    
    # 查找北京王府井地区评分最高的民宿
    target_homestay = Hotel.where(
      hotel_type: 'homestay',
      data_version: 0
    ).where("city = ? OR city LIKE ?", @city, "#{@city}%")
     .where("address LIKE ?", "%#{@area}%")
     .order(rating: :desc)
     .first
    
    raise "未找到符合条件的民宿" unless target_homestay
    
    # 查找房型（选择整晚房型中价格最低的）
    target_room = HotelRoom.where(hotel_id: target_homestay.id, room_category: 'overnight')
                           .order(:price)
                           .first
    
    raise "民宿没有可用房型" unless target_room
    
    # 创建订单
    HotelBooking.create!(
      hotel_id: target_homestay.id,
      hotel_room_id: target_room.id,
      user_id: user.id,
      check_in_date: @check_in_date,
      check_out_date: @check_out_date,
      rooms_count: 1,
      adults_count: 2,
      children_count: 0,
      total_price: target_room.price * @nights,
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
      data_version: 0
    ).where("city = ? OR city LIKE ?", @city, "#{@city}%")
     .where("address LIKE ?", "%#{@area}%")
  end
end
