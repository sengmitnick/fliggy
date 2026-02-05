# frozen_string_literal: true

module V301V350
  class V321BookLaborDayShortTripValidator < BaseValidator
    self.validator_id = 321
    self.task_id = "e5f6g7h8-9i0j-1k2l-3m4n-5o6p7q8r9s0t"
    self.title = "五一小长假短途游快速预订"
    self.description = "用户需要快速预订五一假期（5月1-3日）从上海到杭州的短途游，包含高铁+西湖景区"
    self.timeout_seconds = 180

    def prepare
      # 五一假期：5月1-3日
      current_year = Date.today.year
      @departure_date = Date.new(current_year, 5, 1)
      if @departure_date < Date.today
        @departure_date = Date.new(current_year + 1, 5, 1)
      end
      @return_date = @departure_date + 2.days
      @visit_date = @departure_date + 1.day
      @departure_city = "上海"
      @arrival_city = "杭州"
      @attraction_name = "西湖风景区"
      
      # 创建去程高铁
      @outbound_train = Train.find_by!(
        train_number: "G7503",
        departure_city: @departure_city,
        arrival_city: @arrival_city,
        data_version: 0
      )

      # 创建返程高铁
      @return_train = Train.find_by!(
        train_number: "G7512",
        departure_city: @arrival_city,
        arrival_city: @departure_city,
        data_version: 0
      )

      # 创建杭州城市和西湖景区
      city = City.find_by!(name: @arrival_city, data_version: 0)
      
      @attraction = Attraction.find_by!(
        name: @attraction_name,
        city: city,
        data_version: 0
      )

      @ticket = Ticket.find_by!(
        attraction: @attraction,
        ticket_type: "free",
        data_version: 0
      )

      {
        departure_date: @departure_date.to_s,
        return_date: @return_date.to_s,
        visit_date: @visit_date.to_s,
        departure_city: @departure_city,
        arrival_city: @arrival_city,
        attraction_name: @attraction_name,
        task_info: "用户预订五一小长假短途游"
      }
    end

    def simulate
      # 1. 查找测试用户
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      passenger = Passenger.find_by!(user: user, name: '张三', data_version: 0)
      
      # 2. 创建去程高铁订单
      outbound_booking = TrainBooking.create!(
        train_id: @outbound_train.id,
        user_id: user.id,
        passenger_name: passenger.name,
        passenger_id_number: passenger.id_number,
        contact_phone: passenger.phone,
        seat_type: 'second_class',
        accept_terms: true,
        total_price: @outbound_train.price_second_class,
        status: 'pending',
        data_version: @data_version
      )
      
      # 3. 创建返程高铁订单
      return_booking = TrainBooking.create!(
        train_id: @return_train.id,
        user_id: user.id,
        passenger_name: passenger.name,
        passenger_id_number: passenger.id_number,
        contact_phone: passenger.phone,
        seat_type: 'second_class',
        accept_terms: true,
        total_price: @return_train.price_second_class,
        status: 'pending',
        data_version: @data_version
      )
      
      {
        action: 'create_round_trip_trains',
        outbound_booking_id: outbound_booking.id,
        return_booking_id: return_booking.id
      }
    end

    def verify
      add_assertion "创建了去程高铁订单", weight: 25 do
        all_bookings = TrainBooking
          .joins(:train)
          .includes(:train)
          .where(trains: { 
            departure_city: @departure_city,
            arrival_city: @arrival_city
          })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        expect(all_bookings).not_to be_empty, "未找到去程高铁订单"
        
        @outbound_bookings = all_bookings.select { |b| 
          b.train.departure_time.to_date == @departure_date
        }
        
        expect(@outbound_bookings.size).to be >= 1, "未找到#{@departure_date}的去程高铁"
      end

      add_assertion "创建了返程高铁订单", weight: 25 do
        all_return_bookings = TrainBooking
          .joins(:train)
          .includes(:train)
          .where(trains: { 
            departure_city: @arrival_city,
            arrival_city: @departure_city
          })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        expect(all_return_bookings).not_to be_empty, "未找到返程高铁订单"
        
        @return_bookings = all_return_bookings.select { |b| 
          b.train.departure_time.to_date == @return_date
        }
        
        expect(@return_bookings.size).to be >= 1, "未找到#{@return_date}的返程高铁"
      end

      return if (@outbound_bookings.nil? || @outbound_bookings.empty?) && 
                (@return_bookings.nil? || @return_bookings.empty?)

      add_assertion "出发地和目的地正确（#{@departure_city}→#{@arrival_city}）", weight: 15 do
        @outbound_bookings&.each do |booking|
          expect(booking.train.departure_city).to eq(@departure_city),
            "去程出发地错误"
          expect(booking.train.arrival_city).to eq(@arrival_city),
            "去程目的地错误"
        end
        
        @return_bookings&.each do |booking|
          expect(booking.train.departure_city).to eq(@arrival_city),
            "返程出发地错误"
          expect(booking.train.arrival_city).to eq(@departure_city),
            "返程目的地错误"
        end
      end

      add_assertion "去程日期正确（五一假期：#{@departure_date}）", weight: 15 do
        @outbound_bookings&.each do |booking|
          actual_date = booking.train.departure_time.to_date
          expect(actual_date).to eq(@departure_date),
            "去程日期错误。期望: #{@departure_date}（五一假期首日），实际: #{actual_date}"
        end
      end

      add_assertion "返程日期正确（#{@return_date}）", weight: 20 do
        @return_bookings&.each do |booking|
          actual_date = booking.train.departure_time.to_date
          expect(actual_date).to eq(@return_date),
            "返程日期错误。期望: #{@return_date}（五一假期末），实际: #{actual_date}"
        end
      end
    end

    def execution_state_data
      {
        departure_date: @departure_date&.to_s,
        return_date: @return_date&.to_s,
        visit_date: @visit_date&.to_s,
        departure_city: @departure_city,
        arrival_city: @arrival_city,
        attraction_name: @attraction_name,
        outbound_train_id: @outbound_train&.id,
        return_train_id: @return_train&.id
      }
    end

    def restore_from_state(state)
      @departure_date = Date.parse(state['departure_date']) if state['departure_date']
      @return_date = Date.parse(state['return_date']) if state['return_date']
      @visit_date = Date.parse(state['visit_date']) if state['visit_date']
      @departure_city = state['departure_city']
      @arrival_city = state['arrival_city']
      @attraction_name = state['attraction_name']
      @outbound_train = Train.find_by(id: state['outbound_train_id']) if state['outbound_train_id']
      @return_train = Train.find_by(id: state['return_train_id']) if state['return_train_id']
    end
  end
end
