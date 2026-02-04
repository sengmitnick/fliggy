# frozen_string_literal: true

module V351V400
  # V374: 预订同学会（30人聚会+怀旧主题酒店）
  class V354BookClassReunionValidator < BaseValidator
    self.validator_id = 354
    self.task_id = 'd4e5f6a7-b8c9-4d0e-1f2a-3b4c5d6e7f8a'
    self.timeout_seconds = 180
    self.title = '预订同学会（30人聚会+怀旧主题酒店）'
    self.description = '用户需要为同学会预订聚会场地，30位同学参加，需要怀旧主题酒店和聚餐场地'

    def prepare
      @destination = Destination.find_by!(
        name: '成都',
        data_version: 0
      )

      @hotel = Hotel.find_by!(
        name: '成都锦里怀旧主题酒店',
        destination: @destination.name,
        address: '武侯区锦里',
        star_rating: '四星级',
        description: '80年代怀旧主题装修，适合同学聚会',
        has_meeting_room: true,
        price: 320,
        data_version: 0
      )

      @room = HotelRoom.find_by!(
        hotel: @hotel,
        room_type: '怀旧标准间',
        price: 320,
        data_version: 0
      )

      @activity = Activity.find_by!(
        name: '同学会聚餐套餐',
        activity_type: '聚餐',
        price: 120,
        duration: 180,
        description: '含30人桌餐、KTV包厢',
        data_version: 0
      )

      @reunion_date = Date.today + 20.days
      @group_size = 30

      # 创建30名同学
      @classmates = []
      (1..30).each do |i|
        @classmates << Passenger.find_by!(
          name: "同学#{i}",
          id_number: "5101#{(19850101 + i * 30).to_s.rjust(10, '0')}",
          phone: "136#{(10000000 + i).to_s.rjust(8, '0')}",
          data_version: 0
        )
      end

      {
        title: title,
        description: description,
        destination: @destination.name,
        hotel: @hotel.name,
        reunion_date: @reunion_date.to_s,
        duration: 2,
        group_size: @group_size,
        room_count: 15,
        activity: @activity.name,
        total_budget: "约13200元（住宿9600元 + 聚餐3600元）"
      }
    end

    def verify
      add_assertion "创建了至少15个酒店订单（30人住宿）", weight: 25 do
        all_orders = HotelBooking
          .joins(:hotel)
          .includes(:room, :hotel)
          .where(hotels: { name: @hotel.name })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a

        @hotel_bookings = all_orders.select { |b| b.check_in_date == @reunion_date }
        
        expect(@hotel_bookings).not_to be_empty, "未找到任何酒店订单"
        expect(@hotel_bookings.size).to be >= 15, "订单数量不足。期望至少15个订单（30人住15间房），实际找到#{@hotel_bookings.size}个订单"
      end

      return if @hotel_bookings.nil? || @hotel_bookings.empty?

      add_assertion "酒店正确（#{@hotel.name}）", weight: 10 do
        @hotel_bookings.each do |booking|
          expect(booking.hotel.name).to eq(@hotel.name),
            "酒店错误。期望: #{@hotel.name}，实际: #{booking.hotel.name}"
        end
      end

      add_assertion "入住日期正确（#{@reunion_date}）", weight: 10 do
        @hotel_bookings.each do |booking|
          expect(booking.check_in_date).to eq(@reunion_date),
            "入住日期错误。期望: #{@reunion_date}，实际: #{booking.check_in_date}"
        end
      end

      add_assertion "酒店为怀旧主题", weight: 15 do
        expect(@hotel.description).to include('怀旧'),
          "酒店主题错误。期望包含'怀旧'主题，实际: #{@hotel.description}"
      end

      add_assertion "酒店具备会议室（聚会场地）", weight: 15 do
        expect(@hotel.has_meeting_room).to be_truthy,
          "酒店不具备会议室。期望: 有会议室，实际: #{@hotel.has_meeting_room}"
      end

      add_assertion "创建了聚餐活动订单", weight: 20 do
        all_activity_orders = ActivityBooking
          .joins(:activity)
          .includes(:activity)
          .where(activities: { name: @activity.name })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a

        @activity_bookings = all_activity_orders
        
        expect(@activity_bookings).not_to be_empty, "未找到聚餐活动订单"
        expect(@activity_bookings.size).to be >= 1, "活动订单数量不足"
      end

      add_assertion "活动类型为聚餐", weight: 5 do
        return if @activity_bookings.nil? || @activity_bookings.empty?
        
        @activity_bookings.each do |booking|
          expect(booking.activity.activity_type).to eq('聚餐'),
            "活动类型错误。期望: 聚餐，实际: #{booking.activity.activity_type}"
        end
      end
    end

    def simulate
      raise NotImplementedError, "请实现AI Agent逻辑：查询成都怀旧主题酒店、预订30人同学会套餐、创建订单"
    end

    def execution_state_data
      {
        destination_name: @destination&.name,
        hotel_name: @hotel&.name,
        reunion_date: @reunion_date&.to_s,
        group_size: @group_size,
        activity_name: @activity&.name
      }
    end

    def restore_from_state(state)
      @destination = Destination.find_by(name: state['destination_name'], data_version: 0) if state['destination_name']
      @hotel = Hotel.find_by(name: state['hotel_name'], data_version: 0) if state['hotel_name']
      @reunion_date = Date.parse(state['reunion_date']) if state['reunion_date']
      @group_size = state['group_size']
      @activity = Activity.find_by(name: state['activity_name'], data_version: 0) if state['activity_name']
    end
  end
end
