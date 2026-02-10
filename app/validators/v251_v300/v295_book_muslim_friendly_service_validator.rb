# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例295: 给刘强和陈静预订西安自由行（2个一日游+酒店3晚）
#
# 任务描述:
#   给刘强和陈静预订6天后去西安玩3天的自由行，需要预订2个不同的一日游产品，以及有停车场的酒店住3晚
#
# 评分标准:
#   - 创建了2个自由行订单 (20%)
#   - 自由行目的地正确（西安）(10%)
#   - 游客信息正确（刘强和陈静，2成人）(15%)
#   - 创建了酒店预订 (20%)
#   - 酒店在西安且配备停车场 (15%)
#   - 入住人信息正确（刘强或陈静）(10%)
#   - 入住日期正确（6天后，住3晚）(5%)
#   - 订单状态正确 (5%)
module V251V300
  class V295BookMuslimFriendlyServiceValidator < BaseValidator
    self.validator_id = 'v295_book_muslim_friendly_service_validator'
    self.task_id = '16fd7e2d-f8e9-49c8-91fc-72958aa2ec90'
    self.title = '给刘强和陈静预订西安自由行（2个一日游+酒店3晚，需要停车场）'
    self.description = '帮刘强和陈静订6天后去西安玩3天的自由行，预订2个不同的一日游产品，以及有停车场的酒店住3晚'
    self.timeout_seconds = 300
    
    def prepare
      @destination = '西安'
      @travel_type = '自由出行'
      @duration = 1  # 一日游
      @check_in_date = Date.current + 6.days
      @check_out_date = @check_in_date + 3.days  # 住3晚
      @adult_count = 2
      @child_count = 0
      
      # 预查询乘客信息
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @liuqiang = user.passengers.find_by!(name: '刘强', data_version: 0)
      @chenjing = user.passengers.find_by!(name: '陈静', data_version: 0)
      
      # 有效入住人电话映射
      @valid_guest_phones = {
        '刘强' => @liuqiang.phone,
        '陈静' => @chenjing.phone
      }
      
      @expected_traveler_names = [@liuqiang.name, @chenjing.name].sort
      
      if user.balance < 5000
        user.update!(balance: 8000)
      end
      
      {
        task: "请为刘强和陈静预订#{@destination}自由行（#{@check_in_date.strftime('%Y年%-m月%-d日')}出发，玩3天），预订2个不同的#{@destination}一日游产品，以及有停车场的酒店住3晚",
        destination: @destination,
        travel_type: @travel_type,
        check_in_date: @check_in_date.to_s,
        travelers: '刘强和陈静（2成人）',
        hint: "预订2个#{@destination}自由行一日游产品（不同产品）+ 配备停车场的#{@destination}酒店3晚"
      }
    end
    
    def verify
      add_assertion "创建了2个自由行订单", weight: 20 do
        all_bookings = TourGroupBooking
          .joins(:tour_group_product)
          .where(tour_group_products: { travel_type: @travel_type })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        @free_travel_bookings = all_bookings.select do |b|
          b.tour_group_product.destination&.include?(@destination)
        end
        
        expect(@free_travel_bookings.size).to be >= 2,
          "自由行订单数量不足。期望至少2个#{@destination}自由行订单，实际找到#{@free_travel_bookings.size}个订单"
        
        # 检查是否为不同产品
        product_ids = @free_travel_bookings.map(&:tour_group_product_id).uniq
        expect(product_ids.size).to be >= 2,
          "需要预订2个不同的自由行产品。实际只预订了#{product_ids.size}个不同产品"
      end
      
      return if @free_travel_bookings.nil? || @free_travel_bookings.size < 2
      
      add_assertion "自由行目的地正确（#{@destination}）", weight: 10 do
        @free_travel_bookings.each do |booking|
          expect(booking.tour_group_product.destination).to include(@destination),
            "自由行目的地错误。期望包含: #{@destination}，实际: #{booking.tour_group_product.destination}"
        end
      end
      
      add_assertion "游客信息正确（刘强和陈静，2成人）", weight: 15 do
        # 验证每个自由行订单都有正确的游客信息
        @free_travel_bookings.each_with_index do |booking, index|
          travelers = booking.booking_travelers.where(data_version: @data_version).to_a
          
          expect(travelers.size).to eq(2),
            "第#{index + 1}个自由行订单游客数量不正确。期望: 2个游客（刘强和陈静）, 实际: #{travelers.size}个游客"
          
          traveler_names = travelers.map(&:traveler_name).sort
          expect(traveler_names).to eq(@expected_traveler_names),
            "第#{index + 1}个自由行订单游客名单不正确。期望: #{@expected_traveler_names.join('、')}, 实际: #{traveler_names.join('、')}"
          
          # 验证刘强的身份证号
          liuqiang_traveler = travelers.find { |t| t.traveler_name == '刘强' }
          expect(liuqiang_traveler).not_to be_nil, "第#{index + 1}个订单未找到游客刘强"
          expect(liuqiang_traveler.id_number).to eq(@liuqiang.id_number),
            "刘强身份证号错误。期望: #{@liuqiang.id_number}, 实际: #{liuqiang_traveler.id_number}"
          
          # 验证陈静的身份证号
          chenjing_traveler = travelers.find { |t| t.traveler_name == '陈静' }
          expect(chenjing_traveler).not_to be_nil, "第#{index + 1}个订单未找到游客陈静"
          expect(chenjing_traveler.id_number).to eq(@chenjing.id_number),
            "陈静身份证号错误。期望: #{@chenjing.id_number}, 实际: #{chenjing_traveler.id_number}"
        end
        
        # 验证人数
        @free_travel_bookings.each_with_index do |booking, index|
          expect(booking.adult_count).to eq(@adult_count),
            "第#{index + 1}个订单成人数量错误。期望: #{@adult_count}人，实际: #{booking.adult_count}人"
          expect(booking.child_count).to eq(@child_count),
            "第#{index + 1}个订单儿童数量错误。期望: #{@child_count}人，实际: #{booking.child_count}人"
        end
      end
      
      add_assertion "创建了酒店预订", weight: 20 do
        @hotel_booking = HotelBooking
          .joins(:hotel)
          .where(hotels: { city: @destination })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        expect(@hotel_booking).not_to be_nil, "未找到#{@destination}的酒店预订"
      end
      
      return unless @hotel_booking
      
      add_assertion "酒店在西安且配备停车场", weight: 15 do
        hotel = @hotel_booking.hotel
        expect(hotel.city).to eq(@destination),
          "酒店城市错误。期望: #{@destination}, 实际: #{hotel.city}"
        
        expect(hotel.facilities).to be_present, "酒店未配置设施信息"
        has_parking = hotel.facilities.to_s.match?(/停车|免费停车/i)
        expect(has_parking).to be(true), 
          "酒店未配备停车场。当前设施: #{hotel.facilities}"
      end
      
      add_assertion "入住人信息正确（刘强或陈静）", weight: 10 do
        valid_guests = ['刘强', '陈静']
        expect(valid_guests).to include(@hotel_booking.guest_name),
          "入住人姓名错误。期望: 刘强或陈静, 实际: #{@hotel_booking.guest_name}"
        
        expected_phone = @valid_guest_phones[@hotel_booking.guest_name]
        expect(@hotel_booking.guest_phone).to eq(expected_phone),
          "入住人电话与姓名不匹配。入住人: #{@hotel_booking.guest_name}, 期望电话: #{expected_phone}, 实际电话: #{@hotel_booking.guest_phone}"
      end
      
      add_assertion "入住日期正确（6天后，住3晚）", weight: 5 do
        expect(@hotel_booking.check_in_date).to eq(@check_in_date),
          "入住日期错误。期望: #{@check_in_date}（6天后），实际: #{@hotel_booking.check_in_date}"
        
        nights = (@hotel_booking.check_out_date - @hotel_booking.check_in_date).to_i
        expect(nights).to eq(3),
          "入住天数错误。期望住3晚，实际住#{nights}晚"
      end
      
      add_assertion "订单状态正确", weight: 5 do
        # 验证自由行订单状态
        valid_statuses = ['pending', 'confirmed', 'paid']
        @free_travel_bookings.each do |booking|
          expect(valid_statuses).to include(booking.status),
            "自由行订单状态错误: #{booking.status}"
        end
        
        # 验证酒店订单状态
        expect(valid_statuses).to include(@hotel_booking.status),
          "酒店订单状态错误: #{@hotel_booking.status}"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      liuqiang = user.passengers.find_by!(name: '刘强', data_version: 0)
      chenjing = user.passengers.find_by!(name: '陈静', data_version: 0)
      
      # 随机选择入住人/联系人
      guest_names = ['刘强', '陈静']
      selected_guest_name = guest_names.sample
      guest_passenger = selected_guest_name == '刘强' ? liuqiang : chenjing
      
      # 1. 预订2个不同的西安自由行一日游产品
      xian_free_travel_products = TourGroupProduct
        .where(travel_type: @travel_type, duration: @duration, data_version: 0)
        .where("destination LIKE ?", "%#{@destination}%")
        .order(:price)
        .limit(2)
        .to_a
      
      raise "未找到足够的#{@destination}自由行产品（至少需要2个）" if xian_free_travel_products.size < 2
      
      # 创建2个自由行订单
      xian_free_travel_products.each do |product|
        package = product.tour_packages.order(:price).first
        raise "产品#{product.id}没有可用套餐" unless package
        
        total_price = package.price * @adult_count + package.child_price * @child_count
        
        booking = TourGroupBooking.create!(
          tour_group_product_id: product.id,
          tour_package_id: package.id,
          user_id: user.id,
          travel_date: @check_in_date,
          adult_count: @adult_count,
          child_count: @child_count,
          contact_name: guest_passenger.name,
          contact_phone: guest_passenger.phone,
          insurance_type: 'none',
          total_price: total_price,
          status: 'pending',
          data_version: @data_version
        )
        
        # 为每个订单创建出行人记录（刘强和陈静）
        BookingTraveler.create!(
          tour_group_booking_id: booking.id,
          traveler_name: liuqiang.name,
          id_number: liuqiang.id_number,
          traveler_type: 'adult',
          data_version: @data_version
        )
        
        BookingTraveler.create!(
          tour_group_booking_id: booking.id,
          traveler_name: chenjing.name,
          id_number: chenjing.id_number,
          traveler_type: 'adult',
          data_version: @data_version
        )
      end
      
      # 2. 预订配备停车场的西安酒店（住3晚）
      hotels_with_parking = Hotel
        .where(city: @destination, data_version: 0)
        .select { |h| h.facilities.to_s.match?(/停车|免费停车/i) }
      
      hotel = hotels_with_parking.max_by(&:rating)
      raise "未找到#{@destination}配备停车场的酒店" if hotel.nil?
      
      HotelBooking.create!(
        hotel_room_id: hotel.hotel_rooms.first!.id,
        user_id: user.id,
        rooms_count: 1,
        adults_count: 2,
        children_count: 0,
        hotel_id: hotel.id,
        check_in_date: @check_in_date,
        check_out_date: @check_out_date,
        guest_name: guest_passenger.name,
        guest_phone: guest_passenger.phone,
        payment_method: '花呗',
        total_price: hotel.price * (@check_out_date - @check_in_date).to_i,
        status: 'pending',
        data_version: @data_version
      )
    end
    
    private
    
    def execution_state_data
      {
        destination: @destination,
        travel_type: @travel_type,
        duration: @duration,
        check_in_date: @check_in_date&.to_s,
        check_out_date: @check_out_date&.to_s,
        adult_count: @adult_count,
        child_count: @child_count,
        valid_guest_phones: @valid_guest_phones,
        expected_traveler_names: @expected_traveler_names
      }
    end
    
    def restore_from_state(data)
      @destination = data['destination']
      @travel_type = data['travel_type']
      @duration = data['duration']
      @check_in_date = Date.parse(data['check_in_date']) if data['check_in_date']
      @check_out_date = Date.parse(data['check_out_date']) if data['check_out_date']
      @adult_count = data['adult_count']
      @child_count = data['child_count']
      @valid_guest_phones = data['valid_guest_phones'] || {}
      @expected_traveler_names = data['expected_traveler_names'] || []
      
      # 重新查询乘客信息
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @liuqiang = user.passengers.find_by!(name: '刘强', data_version: 0)
      @chenjing = user.passengers.find_by!(name: '陈静', data_version: 0)
    end
  end
end
