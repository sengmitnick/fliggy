class FlightsController < ApplicationController

  def index
    # Flight search page with city selector
    @hot_cities = City.hot_cities.order(:pinyin)
    @all_cities = City.all.order(:pinyin)
  end

  def search
    @departure_city = params[:departure_city] || '北京'
    @destination_city = params[:destination_city] || '杭州'
    @date = params[:date].present? ? Date.parse(params[:date]) : Date.today
    @trip_type = params[:trip_type] || 'one_way'
    @return_date = params[:return_date].present? ? Date.parse(params[:return_date]) : nil

    # Get or generate flights for the outbound route and date
    @flights = Flight.search(@departure_city, @destination_city, @date)

    # Get prices for nearby dates (5 days)
    @date_prices = get_date_prices(@departure_city, @destination_city, @date)

    # For round trip, also get return flights
    if @trip_type == 'round_trip' && @return_date
      @return_flights = Flight.search(@destination_city, @departure_city, @return_date)
      @return_date_prices = get_date_prices(@destination_city, @departure_city, @return_date)
    end
  end

  # 多程航班搜索 - 第一步：显示第一程航班选择
  def multi_city_search
    @segments = JSON.parse(params[:segments] || '[]')
    @cabin_class = params[:cabin_class] || 'all'
    @current_segment_index = 0
    @selected_flights = [] # 已选择的航班

    if @segments.empty?
      redirect_to flights_path, alert: '请添加至少2个行程段'
      return
    end

    # 验证所有航段日期顺序
    @segments.each_with_index do |segment, index|
      next if index == 0 # 跳过第一程
      
      current_date = Date.parse(segment['date'])
      previous_date = Date.parse(@segments[index - 1]['date'])
      
      if current_date < previous_date
        @error_message = "第#{index + 1}程日期不能早于第#{index}程，请返回航班首页修改"
        respond_to do |format|
          format.turbo_stream { 
            render turbo_stream: render_to_string(partial: 'shared/show_toast', formats: [:turbo_stream], locals: { message: @error_message })
          }
          format.html { redirect_to flights_path, alert: @error_message }
        end
        return
      end
    end

    # 获取当前程的航班
    current_segment = @segments[@current_segment_index]
    @departure_city = current_segment['departureCity']
    @destination_city = current_segment['destinationCity']
    @date = Date.parse(current_segment['date'])

    # 搜索当前程的航班
    @flights = Flight.search(@departure_city, @destination_city, @date)
    @date_prices = get_date_prices(@departure_city, @destination_city, @date)

    render :multi_city_results
  end

  # 多程航班结果 - 逐步选择每一程
  def multi_city_results
    @segments = JSON.parse(params[:segments] || '[]')
    @cabin_class = params[:cabin_class] || 'all'
    @current_segment_index = (params[:current_segment]&.to_i || 0)
    @selected_flights = JSON.parse(params[:selected_flights] || '[]')

    # 验证日期顺序：检查是否有已选择的航班，且新航段日期早于之前的航段
    if @selected_flights.any? && @current_segment_index > 0 && @current_segment_index < @segments.length
      # 获取最后一个已选航班的日期
      last_selected = @selected_flights.last
      last_flight = Flight.find_by(id: last_selected['flight_id'])
      
      if last_flight
        # 获取当前段的日期
        current_segment = @segments[@current_segment_index]
        current_date = params[:date_override].present? ? Date.parse(params[:date_override]) : Date.parse(current_segment['date'])
        
        # 如果当前段日期早于上一段，显示错误并返回首页
        if current_date < last_flight.flight_date
          @error_message = "第#{@current_segment_index + 1}程日期不能早于第#{@current_segment_index}程，请返回航班首页修改"
          respond_to do |format|
            format.turbo_stream { 
              render turbo_stream: render_to_string(partial: 'shared/show_toast', formats: [:turbo_stream], locals: { message: @error_message })
            }
            format.html { redirect_to flights_path, alert: @error_message }
          end
          return
        end
      end
    end

    # 验证当前段日期不能晚于后续航段的日期
    if @current_segment_index < @segments.length
      current_segment = @segments[@current_segment_index]
      current_date = params[:date_override].present? ? Date.parse(params[:date_override]) : Date.parse(current_segment['date'])
      
      # 检查后续所有航段
      ((@current_segment_index + 1)...@segments.length).each do |next_index|
        next_segment = @segments[next_index]
        next_date = Date.parse(next_segment['date'])
        
        if current_date > next_date
          @error_message = "第#{@current_segment_index + 1}程日期不能晚于第#{next_index + 1}程，请返回航班首页修改"
          respond_to do |format|
            format.turbo_stream { 
              render turbo_stream: render_to_string(partial: 'shared/show_toast', formats: [:turbo_stream], locals: { message: @error_message })
            }
            format.html { redirect_to flights_path, alert: @error_message }
          end
          return
        end
      end
    end

    if @current_segment_index >= @segments.length
      # 所有程都已选择，跳转到订单确认页
      redirect_to new_booking_path(
        trip_type: 'multi_city',
        selected_flights: @selected_flights.to_json
      )
      return
    end

    # 获取当前程的航班
    current_segment = @segments[@current_segment_index]
    @departure_city = current_segment['departureCity']
    @destination_city = current_segment['destinationCity']
    
    # 如果有日期覆盖参数，使用它；否则使用段默认日期
    @date = params[:date_override].present? ? Date.parse(params[:date_override]) : Date.parse(current_segment['date'])

    # 搜索当前程的航班
    @flights = Flight.search(@departure_city, @destination_city, @date)
    @date_prices = get_date_prices(@departure_city, @destination_city, @date)
    
    render :multi_city_results
  end

  def show
    @flight = Flight.includes(:flight_offers).find(params[:id])
    @offers = @flight.sorted_offers
  end

  private

  def get_date_prices(departure_city, destination_city, center_date)
    prices = []
    (-2..2).each do |offset|
      date = center_date + offset.days
      flights = Flight.search(departure_city, destination_city, date)
      min_price = flights.minimum(:price) || 0
      
      prices << {
        date: date,
        weekday: I18n.l(date, format: '%A'),
        day: date.day,
        price: min_price.to_i,
        is_today: date == center_date
      }
    end
    prices
  end
end
