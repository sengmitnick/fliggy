# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例109: 预订网红民宿（成都宽窄巷子，高评分）
#
# 核心验证点:
# 1. 订单创建: 民宿订单创建成功
# 2. 城市/地区: 成都宽窄巷子
# 3. 住宿类型: 民宿（homestay）
# 4. 入住天数: 3晚
# 5. 评分要求: 评分>=4.5分
# 6. 评分优化: 选择评分最高的网红民宿
module V101V150
  class V109PopularHomestayValidator < BaseValidator
    self.validator_id = 'v109_popular_homestay_validator'
    self.task_id = 'c7f2e8d9-3a1b-4c6e-9d8f-7a2e5b4c1d93'
    self.title = '预订网红民宿（成都宽窄巷子，高评分）'
    self.description = '在成都宽窄巷子地区预订评分最高且>=4.5的网红民宿，入住3晚'
    self.timeout_seconds = 300
  
    def prepare
      @city = '成都'
      @area = '宽窄巷子'
      @check_in_date = Date.current + 5.days  # 5天后入住
      @nights = 3
      @check_out_date = @check_in_date + @nights.days
      @min_rating = 4.5
    
      # 查找成都宽窄巷子的民宿（type='homestay'）
      @qualified_homestays = Hotel.where(
        hotel_type: 'homestay',
        data_version: 0
      ).where("city = ? OR city LIKE ?", @city, "#{@city}%")
       .where("address LIKE ?", "%#{@area}%")
       .where("rating >= ?", @min_rating)
    
      # 找到销量最高的民宿（网红民宿）
      @hottest_homestay = @qualified_homestays.order(rating: :desc).first
    
      {
        task: "请在#{@city}#{@area}地区预订网红民宿（评分最高且>=#{@min_rating}分），入住#{@nights}晚（5天后入住，#{@check_in_date.strftime('%Y年%m月%d日')}到#{@check_out_date.strftime('%Y年%m月%d日')}）",
        requirements: {
          city: @city,
          area: @area,
          accommodation_type: 'homestay',
          accommodation_type_description: '民宿（非酒店）',
          check_in_date: @check_in_date.to_s,
          check_out_date: @check_out_date.to_s,
          nights: @nights,
          min_rating: @min_rating,
          optimization: 'highest_rating',
          optimization_description: '评分最高且>=4.5分（网红民宿）'
        },
        hint: "#{@city}#{@area}地区有多家评分>=#{@min_rating}分的民宿可选，请选择评分最高的（网红民宿）",
        statistics: {
          total_qualified_homestays: @qualified_homestays.count,
          hottest_homestay_rating: @hottest_homestay&.rating
        }
      }
    end
  
    def verify
      # 断言1: 订单已创建（权重25%）
      add_assertion "订单已创建", weight: 25 do
        all_bookings = HotelBooking
          .joins(:hotel)
          .where(hotels: { hotel_type: 'homestay' })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
      
        @bookings = all_bookings.select do |b|
          (b.hotel.city == @city || b.hotel.city.start_with?(@city)) &&
          b.hotel.address&.include?(@area) &&
          b.hotel.rating >= @min_rating
        end
      
        expect(@bookings).not_to be_empty, "未找到任何#{@city}#{@area}地区评分>=#{@min_rating}的民宿订单"
        @booking = @bookings.first
      end
    
      return if @bookings.nil? || @bookings.empty?
    
      # 断言2: 城市/地区正确（权重10%）
      add_assertion "城市/地区正确（#{@city}#{@area}）", weight: 10 do
        expect(@booking.hotel.city == @city || @booking.hotel.city.start_with?(@city)).to be_truthy,
          "城市错误。期望: #{@city}，实际: #{@booking.hotel.city}"
        expect(@booking.hotel.address).to include(@area),
          "地区错误。期望地址包含: #{@area}，实际地址: #{@booking.hotel.address}"
      end
    
      # 断言3: 住宿类型正确（权重15%）
      add_assertion "住宿类型正确（民宿）", weight: 15 do
        expect(@booking.hotel.hotel_type).to eq('homestay'),
          "住宿类型错误。期望: homestay（民宿），实际: #{@booking.hotel.hotel_type}"
      end
    
      # 断言4: 入住天数正确（权重10%）
      add_assertion "入住天数正确（#{@nights}晚）", weight: 10 do
        actual_nights = (@booking.check_out_date - @booking.check_in_date).to_i
        expect(actual_nights).to eq(@nights),
          "入住天数错误。期望: #{@nights}晚，实际: #{actual_nights}晚（入住#{@booking.check_in_date}，离店#{@booking.check_out_date}）"
      end
    
      # 断言5: 评分符合要求（权重10%）
      add_assertion "评分符合要求（>=#{@min_rating}分）", weight: 10 do
        expect(@booking.hotel.rating).to be >= @min_rating,
          "评分不符合要求。期望>=#{@min_rating}分，实际: #{@booking.hotel.rating}分"
      end
    
      # 断言6: 选择了评分最高的网红民宿（权重30%）
      add_assertion "选择了评分最高的网红民宿", weight: 30 do
        # 获取所有符合条件的民宿（评分>=4.5）
        qualified_homestays = Hotel.where(
          hotel_type: 'homestay',
          data_version: 0
        ).where("city = ? OR city LIKE ?", @city, "#{@city}%")
         .where("address LIKE ?", "%#{@area}%")
         .where("rating >= ?", @min_rating)
      
        hottest_homestay = qualified_homestays.order(rating: :desc).first
      
        expect(@booking.hotel_id).to eq(hottest_homestay.id),
          "未选择评分最高的网红民宿。" \
          "应选: #{hottest_homestay.name}（评分#{hottest_homestay.rating}分），" \
          "实际选择: #{@booking.hotel.name}（评分#{@booking.hotel.rating}分）"
      end
    end
  
    def simulate
      # 查找演示用户（使用基线 data_version=0）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
    
      # 查找成都宽窄巷子地区评分最高且>=4.5的民宿（从基线数据中查找）
      target_homestay = Hotel.where(
        hotel_type: 'homestay',
        data_version: 0
      ).where("city = ? OR city LIKE ?", @city, "#{@city}%")
       .where("address LIKE ?", "%#{@area}%")
       .where("rating >= ?", @min_rating)
       .order(rating: :desc)
       .first
    
      raise "未找到符合条件的网红民宿" unless target_homestay
    
      # 查找房型（选择整晚房型中价格适中的）
      target_room = HotelRoom.where(hotel_id: target_homestay.id, room_category: 'overnight')
                             .order(:price)
                             .offset(HotelRoom.where(hotel_id: target_homestay.id, room_category: 'overnight').count / 2)
                             .first
    
      raise "民宿没有可用房型" unless target_room
    
      # 创建网红民宿订单
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
        guest_name: '王芳',
        guest_phone: '13800138013',
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
        min_rating: @min_rating
      }
    end
  
    def restore_from_state(data)
      @city = data['city']
      @area = data['area']
      @check_in_date = Date.parse(data['check_in_date'])
      @check_out_date = Date.parse(data['check_out_date'])
      @nights = data['nights']
      @min_rating = data['min_rating']
    
      @qualified_homestays = Hotel.where(
        hotel_type: 'homestay',
        data_version: 0
      ).where("city = ? OR city LIKE ?", @city, "#{@city}%")
       .where("address LIKE ?", "%#{@area}%")
       .where("rating >= ?", @min_rating)
    
      @hottest_homestay = @qualified_homestays.order(rating: :desc).first
    end
  end
end
