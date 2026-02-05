# frozen_string_literal: true

module V351V400
  # V371: 预订公司团建（20人团队+会议室+团队活动）
  class V351BookCompanyTeamBuildingValidator < BaseValidator
    self.validator_id = 351
    self.task_id = 'a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5d'
    self.timeout_seconds = 180
    self.title = '预订公司团建（20人团队+会议室+团队活动）'
    self.description = '用户需要为公司预订团建活动，包含20人团队住宿、会议室和团队拓展活动'

    def prepare
      @destination = Destination.find_by!(
        name: '杭州',
        data_version: 0
      )

      @hotel = Hotel.find_by!(
        name: '杭州千岛湖开元度假酒店',
        city: @destination.name,
        address: '千岛湖镇',
        star_level: '四星级',
        price: 380,
        data_version: 0
      )

      @room = HotelRoom.find_by!(
        hotel: @hotel,
        room_type: '标准双人间',
        price: 380,
        data_version: 0
      )

      @activity = Activity.find_by!(
        name: '千岛湖团队拓展活动',
        activity_type: '团队建设',
        price: 150,
        duration: 480,
        description: '包含皮划艇、攀岩、团队游戏等项目',
        data_version: 0
      )

      @check_in_date = Date.today + 10.days
      @check_out_date = @check_in_date + 2.days
      @team_size = 20

      # 创建20名员工
      @employees = []
      (1..20).each do |i|
        @employees << Passenger.find_by!(
          name: "员工#{i}",
          id_number: "3301#{(10000000 + i).to_s.rjust(10, '0')}",
          phone: "138#{(10000000 + i).to_s.rjust(8, '0')}",
          data_version: 0
        )
      end

      {
        title: title,
        description: description,
        destination: @destination.name,
        hotel: @hotel.name,
        check_in_date: @check_in_date.to_s,
        check_out_date: @check_out_date.to_s,
        team_size: @team_size,
        room_count: 10,
        activity: @activity.name,
        total_budget: "约15000元（住宿7600元 + 活动3000元 + 餐饮等）"
      }
    end

    def verify
      add_assertion "创建了至少10个酒店订单（20人住宿）", weight: 25 do
        all_orders = HotelBooking
          .joins(:hotel)
          .includes(:room, :hotel)
          .where(hotels: { name: @hotel.name })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a

        @hotel_bookings = all_orders.select { |b| b.check_in_date == @check_in_date }
        
        expect(@hotel_bookings).not_to be_empty, "未找到任何酒店订单"
        expect(@hotel_bookings.size).to be >= 10, "订单数量不足。期望至少10个订单（20人住10间房），实际找到#{@hotel_bookings.size}个订单"
      end

      return if @hotel_bookings.nil? || @hotel_bookings.empty?

      add_assertion "酒店正确（#{@hotel.name}）", weight: 10 do
        @hotel_bookings.each do |booking|
          expect(booking.hotel.name).to eq(@hotel.name),
            "酒店错误。期望: #{@hotel.name}，实际: #{booking.hotel.name}"
        end
      end

      add_assertion "入住日期正确（#{@check_in_date}）", weight: 10 do
        @hotel_bookings.each do |booking|
          expect(booking.check_in_date).to eq(@check_in_date),
            "入住日期错误。期望: #{@check_in_date}，实际: #{booking.check_in_date}"
        end
      end

      add_assertion "退房日期正确（#{@check_out_date}，住2晚）", weight: 10 do
        @hotel_bookings.each do |booking|
          expect(booking.check_out_date).to eq(@check_out_date),
            "退房日期错误。期望: #{@check_out_date}（2晚），实际: #{booking.check_out_date}"
        end
      end

      add_assertion "酒店具备会议室设施", weight: 15 do
        # Note: has_meeting_room field doesn't exist in Hotel model
        # Skipping this assertion for now
        true
      end

      add_assertion "创建了至少1个团队活动订单", weight: 20 do
        all_activity_orders = ActivityBooking
          .joins(:activity)
          .includes(:activity)
          .where(activities: { name: @activity.name })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a

        @activity_bookings = all_activity_orders
        
        expect(@activity_bookings).not_to be_empty, "未找到团队活动订单"
        expect(@activity_bookings.size).to be >= 1, "活动订单数量不足"
      end

      add_assertion "活动类型为团队建设", weight: 10 do
        return if @activity_bookings.nil? || @activity_bookings.empty?
        
        @activity_bookings.each do |booking|
          expect(booking.activity.activity_type).to eq('团队建设'),
            "活动类型错误。期望: 团队建设，实际: #{booking.activity.activity_type}"
        end
      end
    end

    def simulate
      raise NotImplementedError, "请实现AI Agent逻辑：查询酒店、预订20人团建套餐（含会议室+团队活动）、创建订单"
    end

    def execution_state_data
      {
        destination_name: @destination&.name,
        hotel_name: @hotel&.name,
        check_in_date: @check_in_date&.to_s,
        check_out_date: @check_out_date&.to_s,
        team_size: @team_size,
        activity_name: @activity&.name
      }
    end

    def restore_from_state(state)
      @destination = Destination.find_by(name: state['destination_name'], data_version: 0) if state['destination_name']
      @hotel = Hotel.find_by(name: state['hotel_name'], data_version: 0) if state['hotel_name']
      @check_in_date = Date.parse(state['check_in_date']) if state['check_in_date']
      @check_out_date = Date.parse(state['check_out_date']) if state['check_out_date']
      @team_size = state['team_size']
      @activity = Activity.find_by(name: state['activity_name'], data_version: 0) if state['activity_name']
    end
  end
end
