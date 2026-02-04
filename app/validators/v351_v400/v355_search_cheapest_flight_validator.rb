# frozen_string_literal: true

module V351V400
  # V375: 最低价机票搜索（含中转+红眼航班）
  class V355SearchCheapestFlightValidator < BaseValidator
    self.validator_id = 355
    self.task_id = 'e5f6a7b8-c9d0-4e1f-2a3b-4c5d6e7f8a9b'
    self.timeout_seconds = 180
    self.title = '最低价机票搜索（含中转+红眼航班）'
    self.description = '用户需要搜索最低价机票，接受中转航班和红眼航班，追求极致性价比'

    def prepare
      @departure_city = City.find_by!(
        name: '深圳',
        data_version: 0
      )

      @arrival_city = City.find_by!(
        name: '哈尔滨',
        data_version: 0
      )

      # 创建直飞航班（价格较高）
      @direct_flight = Flight.find_by!(
        flight_number: 'ZH9001',
        departure_city: @departure_city.name,
        arrival_city: @arrival_city.name,
        departure_time: (Date.today + 7.days).to_time + 10.hours,
        arrival_time: (Date.today + 7.days).to_time + 16.hours,
        data_version: 0
      )

      @direct_offer = FlightOffer.find_by!(
        flight: @direct_flight,
        cabin_class: '经济舱',
        price: 1580,
        available_seats: 50,
        data_version: 0
      )

      # 创建中转航班（价格较低）
      @transit_flight1 = Flight.find_by!(
        flight_number: 'CZ3101',
        departure_city: @departure_city.name,
        arrival_city: '北京',
        departure_time: (Date.today + 7.days).to_time + 8.hours,
        arrival_time: (Date.today + 7.days).to_time + 12.hours,
        data_version: 0
      )

      @transit_offer1 = FlightOffer.find_by!(
        flight: @transit_flight1,
        cabin_class: '经济舱',
        price: 580,
        available_seats: 50,
        data_version: 0
      )

      @transit_flight2 = Flight.find_by!(
        flight_number: 'CA1301',
        departure_city: '北京',
        arrival_city: @arrival_city.name,
        departure_time: (Date.today + 7.days).to_time + 15.hours,
        arrival_time: (Date.today + 7.days).to_time + 19.hours,
        data_version: 0
      )

      @transit_offer2 = FlightOffer.find_by!(
        flight: @transit_flight2,
        cabin_class: '经济舱',
        price: 680,
        available_seats: 50,
        data_version: 0
      )

      # 创建红眼航班（价格最低）
      @redeye_flight = Flight.find_by!(
        flight_number: 'MU5201',
        departure_city: @departure_city.name,
        arrival_city: @arrival_city.name,
        departure_time: (Date.today + 7.days).to_time + 23.hours,
        arrival_time: (Date.today + 8.days).to_time + 5.hours,
        is_red_eye: true,
        data_version: 0
      )

      @redeye_offer = FlightOffer.find_by!(
        flight: @redeye_flight,
        cabin_class: '经济舱',
        price: 680,
        available_seats: 50,
        data_version: 0
      )

      @travel_date = Date.today + 7.days
      @max_price = 1300

      {
        title: title,
        description: description,
        departure_city: @departure_city.name,
        arrival_city: @arrival_city.name,
        travel_date: @travel_date.to_s,
        max_price: @max_price,
        direct_flight_price: 1580,
        transit_flight_total: 1260,
        redeye_flight_price: 680,
        cheapest_option: "红眼航班（680元）或中转联程（1260元）"
      }
    end

    def verify
      add_assertion "创建了机票订单", weight: 25 do
        all_orders = FlightBooking
          .joins(flight_offer: :flight)
          .includes(flight_offer: :flight)
          .where(flights: { departure_city: @departure_city.name, arrival_city: @arrival_city.name })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a

        # 也查找中转航班订单
        transit_orders = FlightBooking
          .joins(flight_offer: :flight)
          .includes(flight_offer: :flight)
          .where(flights: { departure_city: @departure_city.name })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a

        @flight_bookings = (all_orders + transit_orders).uniq
        
        expect(@flight_bookings).not_to be_empty, "未找到任何机票订单"
      end

      return if @flight_bookings.nil? || @flight_bookings.empty?

      add_assertion "出发城市正确（#{@departure_city.name}）", weight: 10 do
        @flight_bookings.each do |booking|
          expect(booking.flight_offer.flight.departure_city).to eq(@departure_city.name),
            "出发城市错误。期望: #{@departure_city.name}，实际: #{booking.flight_offer.flight.departure_city}"
        end
      end

      add_assertion "出发日期正确（#{@travel_date}）", weight: 10 do
        @flight_bookings.each do |booking|
          flight_date = booking.flight_offer.flight.departure_time.to_date
          expect(flight_date).to be >= @travel_date,
            "出发日期错误。期望: #{@travel_date}，实际: #{flight_date}"
        end
      end

      add_assertion "舱位为经济舱", weight: 10 do
        @flight_bookings.each do |booking|
          expect(booking.flight_offer.cabin_class).to eq('经济舱'),
            "舱位错误。期望: 经济舱，实际: #{booking.flight_offer.cabin_class}"
        end
      end

      add_assertion "选择了最低价方案（价格≤1300元）", weight: 35 do
        total_price = @flight_bookings.sum { |b| b.flight_offer.price }
        expect(total_price).to be <= @max_price,
          "价格过高。期望≤#{@max_price}元，实际: #{total_price}元。提示：直飞1580元，中转1260元，红眼680元"
      end

      add_assertion "选择了中转或红眼航班（性价比优选）", weight: 10 do
        has_transit_or_redeye = @flight_bookings.any? do |booking|
          flight = booking.flight_offer.flight
          flight.is_red_eye || flight.arrival_city != @arrival_city.name || @flight_bookings.size > 1
        end

        expect(has_transit_or_redeye).to be_truthy,
          "未选择中转或红眼航班。建议选择红眼航班（680元）或中转联程（1260元）获得最佳性价比"
      end
    end

    def simulate
      raise NotImplementedError, "请实现AI Agent逻辑：搜索最低价机票（含中转和红眼航班）、比较价格、创建订单"
    end

    def execution_state_data
      {
        departure_city_name: @departure_city&.name,
        arrival_city_name: @arrival_city&.name,
        travel_date: @travel_date&.to_s,
        max_price: @max_price
      }
    end

    def restore_from_state(state)
      @departure_city = City.find_by(name: state['departure_city_name'], data_version: 0) if state['departure_city_name']
      @arrival_city = City.find_by(name: state['arrival_city_name'], data_version: 0) if state['arrival_city_name']
      @travel_date = Date.parse(state['travel_date']) if state['travel_date']
      @max_price = state['max_price']
    end
  end
end
