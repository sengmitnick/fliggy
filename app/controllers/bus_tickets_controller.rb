class BusTicketsController < ApplicationController
  include CitySelectorDataConcern

  def index
    # Homepage with search form
  end

  def show
    @bus_ticket = BusTicket.find(params[:id])
  end

  # 实时计算筛选结果数量（AJAX接口）
  def count_filtered_results
    @origin = params[:origin]
    @destination = params[:destination]
    @date = params[:date].present? ? Date.parse(params[:date]) : Time.zone.today
    
    # 基础查询
    @bus_tickets = BusTicket.where(
      origin: @origin,
      destination: @destination,
      departure_date: @date,
      status: 'available'
    )
    
    # 应用筛选
    apply_filters
    
    # 返回数量
    render json: { count: @bus_tickets.count }
  end

  def search
    @origin = params[:departure_city] || params[:origin] || '深圳'
    @destination = params[:destination_city] || params[:destination] || '广州'
    @date = params[:date].present? ? Date.parse(params[:date]) : Time.zone.today
    
    # Search bus tickets with base criteria
    @bus_tickets = BusTicket.where(
      origin: @origin,
      destination: @destination,
      departure_date: @date,
      status: 'available'
    )
    
    # Apply filters if present
    apply_filters
    
    # Apply sorting if present
    apply_sorting
    
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
      next if date < Time.zone.today
      
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
      time_slots = params[:time_slots].is_a?(Array) ? params[:time_slots] : params[:time_slots].split(',')
      time_conditions = time_slots.map do |slot|
        case slot
        when 'morning'  # 凌晨
          "departure_time >= '00:00' AND departure_time < '06:00'"
        when 'morning2'  # 上午
          "departure_time >= '06:00' AND departure_time < '12:00'"
        when 'afternoon'  # 下午
          "departure_time >= '12:00' AND departure_time < '18:00'"
        when 'evening'  # 晚上
          "departure_time >= '18:00' AND departure_time < '24:00'"
        end
      end.compact
      
      @bus_tickets = @bus_tickets.where(time_conditions.join(' OR ')) if time_conditions.any?
    end
    
    # Filter by seat types
    if params[:seat_types].present?
      seat_types = params[:seat_types].is_a?(Array) ? params[:seat_types] : params[:seat_types].split(',')
      @bus_tickets = @bus_tickets.where(seat_type: seat_types)
    end
    
    # Filter by departure stations
    if params[:departure_stations].present?
      departure_stations = params[:departure_stations].is_a?(Array) ? params[:departure_stations] : params[:departure_stations].split(',')
      @bus_tickets = @bus_tickets.where(departure_station: departure_stations)
    end
    
    # Filter by arrival stations
    if params[:arrival_stations].present?
      arrival_stations = params[:arrival_stations].is_a?(Array) ? params[:arrival_stations] : params[:arrival_stations].split(',')
      @bus_tickets = @bus_tickets.where(arrival_station: arrival_stations)
    end
  end
  
  def apply_sorting
    sort_by = params[:sort_by]
    sort_direction = params[:sort_direction] || 'asc'
    
    case sort_by
    when 'time'
      # 按时间排序
      if sort_direction == 'asc'
        @bus_tickets = @bus_tickets.order(departure_time: :asc)
      else
        @bus_tickets = @bus_tickets.order(departure_time: :desc)
      end
    when 'price'
      # 按价格排序
      if sort_direction == 'asc'
        @bus_tickets = @bus_tickets.order(price: :asc)
      else
        @bus_tickets = @bus_tickets.order(price: :desc)
      end
    else
      # 默认排序：按时间升序
      @bus_tickets = @bus_tickets.order(departure_time: :asc)
    end
  end
end
