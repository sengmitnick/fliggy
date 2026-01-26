class TripsController < ApplicationController

  def index
    @full_render = true
    if current_user
      # 已登录用户：加载真实订单数据（首次5个）
      # Fetch flight bookings
      flight_bookings = current_user.bookings.includes(:flight).where('flights.flight_date >= ?', Date.today).references(:flights)
      
      # Fetch hotel bookings (upcoming check-ins)
      hotel_bookings = current_user.hotel_bookings.includes(:hotel, :hotel_room)
                                   .where('hotel_bookings.check_in_date >= ?', Date.today)
                                   .where(status: ['paid', 'confirmed'])
      
      # Fetch train bookings (upcoming trips)
      train_bookings = current_user.train_bookings.includes(:train)
                                   .joins(:train)
                                   .where('trains.departure_time >= ?', Date.today.beginning_of_day)
                                   .where(status: ['paid', 'completed'])
      
      # Combine all three types sorted by date
      # For flights, use flight_date; for hotels, use check_in_date; for trains, use train.departure_time
      combined = (flight_bookings.to_a + hotel_bookings.to_a + train_bookings.to_a).sort_by do |item|
        if item.is_a?(Booking)
          [item.flight.flight_date, item.flight.departure_time]
        elsif item.is_a?(HotelBooking)
          [item.check_in_date, Time.parse('00:00')]
        else # TrainBooking
          [item.train.departure_time.to_date, item.train.departure_time]
        end
      end
      
      @bookings = combined.first(5)
      @has_upcoming_trips = @bookings.any?
      
      # 获取总数，用于判断是否还有更多
      @total_bookings_count = combined.length
      @has_more = @total_bookings_count > 5
    else
      # 未登录用户：显示演示数据
      @has_upcoming_trips = true
      @bookings = [OpenStruct.new(
        id: 999999,
        flight: OpenStruct.new(
          departure_city: '深圳',
          destination_city: '武汉',
          departure_time: (Date.today + 10.days).to_time.change(hour: 10, min: 55),
          arrival_time: (Date.today + 10.days).to_time.change(hour: 12, min: 55),
          departure_airport: '宝安T3',
          arrival_airport: '天河T3',
          airline: '东方航空',
          flight_number: 'MU2478',
          aircraft_type: '中型机737',
          flight_date: Date.today + 10.days
        ),
        passenger_name: '张润胜',
        status: 'paid'
      )]
      @has_more = false
    end
  end

  def load_more
    page = params[:page].to_i
    offset = page * 5
    
    # Fetch flight bookings
    flight_bookings = current_user.bookings.includes(:flight).where('flights.flight_date >= ?', Date.today).references(:flights)
    
    # Fetch hotel bookings
    hotel_bookings = current_user.hotel_bookings.includes(:hotel, :hotel_room)
                                 .where('hotel_bookings.check_in_date >= ?', Date.today)
                                 .where(status: ['paid', 'confirmed'])
    
    # Fetch train bookings
    train_bookings = current_user.train_bookings.includes(:train)
                                 .joins(:train)
                                 .where('trains.departure_time >= ?', Date.today.beginning_of_day)
                                 .where(status: ['paid', 'completed'])
    
    # Combine and sort
    combined = (flight_bookings.to_a + hotel_bookings.to_a + train_bookings.to_a).sort_by do |item|
      if item.is_a?(Booking)
        [item.flight.flight_date, item.flight.departure_time]
      elsif item.is_a?(HotelBooking)
        [item.check_in_date, Time.parse('00:00')]
      else # TrainBooking
        [item.train.departure_time.to_date, item.train.departure_time]
      end
    end
    
    @bookings = combined[offset, 5] || []
    
    # 判断是否还有更多
    @total_bookings_count = combined.length
    @has_more = @total_bookings_count > (offset + 5)
  end

  private
  # Write your private methods here
end
