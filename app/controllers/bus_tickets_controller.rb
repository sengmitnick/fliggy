class BusTicketsController < ApplicationController

  def index
    # Homepage with search form
  end

  def show
    @bus_ticket = BusTicket.find(params[:id])
  end

  def search
    @origin = params[:origin] || '深圳'
    @destination = params[:destination] || '广州市'
    @date = params[:date].present? ? Date.parse(params[:date]) : Date.today
    
    # Search bus tickets with base criteria
    @bus_tickets = BusTicket.where(
      origin: @origin,
      destination: @destination,
      departure_date: @date,
      status: 'available'
    )
    
    # Apply filters if present
    apply_filters
    
    @bus_tickets = @bus_tickets.order(:departure_time)
    
    # Get unique stations for filter options
    @departure_stations = BusTicket.where(
      origin: @origin,
      destination: @destination,
      status: 'available'
    ).distinct.pluck(:departure_station).compact.sort
    
    @arrival_stations = BusTicket.where(
      origin: @origin,
      destination: @destination,
      status: 'available'
    ).distinct.pluck(:arrival_station).compact.sort
    
    # Get nearby dates (3 days before and after)
    @nearby_dates = []
    (-1..5).each do |offset|
      date = @date + offset.days
      next if date < Date.today
      
      count = BusTicket.where(
        origin: @origin,
        destination: @destination,
        departure_date: date,
        status: 'available'
      ).count
      
      @nearby_dates << {
        date: date,
        has_tickets: count > 0
      }
    end
  end

  private
  
  def apply_filters
    # Filter by time slots
    if params[:time_slots].present?
      time_slots = params[:time_slots].split(',')
      time_conditions = time_slots.map do |slot|
        case slot
        when 'early'
          "departure_time >= '00:00' AND departure_time < '06:00'"
        when 'morning'
          "departure_time >= '06:00' AND departure_time < '12:00'"
        when 'afternoon'
          "departure_time >= '12:00' AND departure_time < '18:00'"
        when 'evening'
          "departure_time >= '18:00' AND departure_time < '24:00'"
        end
      end.compact
      
      @bus_tickets = @bus_tickets.where(time_conditions.join(' OR ')) if time_conditions.any?
    end
    
    # Filter by seat types
    if params[:seat_types].present?
      seat_types = params[:seat_types].split(',')
      @bus_tickets = @bus_tickets.where(seat_type: seat_types)
    end
    
    # Filter by departure stations
    if params[:departure_stations].present?
      departure_stations = params[:departure_stations].split(',')
      @bus_tickets = @bus_tickets.where(departure_station: departure_stations)
    end
    
    # Filter by arrival stations
    if params[:arrival_stations].present?
      arrival_stations = params[:arrival_stations].split(',')
      @bus_tickets = @bus_tickets.where(arrival_station: arrival_stations)
    end
  end
end
