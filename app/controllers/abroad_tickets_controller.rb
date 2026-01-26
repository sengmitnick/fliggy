class AbroadTicketsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :search, :show]

  def index
    @region = params[:region] || 'japan'
    @ticket_type = params[:ticket_type] || 'train'
    @origin = params[:origin]
    @destination = params[:destination]
    @date = params[:date] ? Date.parse(params[:date]) : Date.today

    # Get popular routes based on region
    @popular_routes = get_popular_routes(@region)
  end

  def search
    @region = params[:region] || 'japan'
    @origin = params[:origin]
    @destination = params[:destination]
    @date = params[:date] ? Date.parse(params[:date]) : Date.today
    
    # Get available tickets
    @tickets = AbroadTicket.available
                           .by_region(@region)
                           .by_route(@origin, @destination)
                           .by_date(@date)
                           .order(time_slot_start: :asc)

    # Get date range for date picker
    # Show yesterday (disabled) + today onwards, so today appears in second position
    start_date = @date - 1.day
    @date_range = (start_date..(start_date + 13.days)).to_a
  end

  def find_by_time_slot
    @region = params[:region] || 'japan'
    @origin = params[:origin]
    @destination = params[:destination]
    @date = params[:date] ? Date.parse(params[:date]) : Date.today
    @time_slot_start = params[:time_slot_start]
    @time_slot_end = params[:time_slot_end]
    
    # Find ticket matching the criteria
    @ticket = AbroadTicket.available
                          .by_region(@region)
                          .by_route(@origin, @destination)
                          .by_date(@date)
                          .where(time_slot_start: @time_slot_start, time_slot_end: @time_slot_end)
                          .first
    
    if @ticket
      # Redirect to the ticket's show page
      redirect_to abroad_ticket_path(@ticket, origin: @origin, destination: @destination, date: @date.strftime('%Y-%m-%d'))
    else
      # No ticket found for this time slot, redirect to search page
      redirect_to search_abroad_tickets_path(region: @region, origin: @origin, destination: @destination, date: @date.strftime('%Y-%m-%d')), alert: "该时间段暂无可用班次"
    end
  end

  def show
    @ticket = AbroadTicket.find(params[:id])
    @origin = params[:origin] || @ticket.origin
    @destination = params[:destination] || @ticket.destination
    @date = params[:date] ? Date.parse(params[:date]) : @ticket.departure_date
    
    # If date parameter is different from ticket's departure_date, find ticket for new date
    if @date != @ticket.departure_date
      # Find a ticket with same route and time slot but different date
      new_ticket = AbroadTicket.available
                               .by_region(@ticket.region)
                               .by_route(@ticket.origin, @ticket.destination)
                               .by_date(@date)
                               .where(time_slot_start: @ticket.time_slot_start)
                               .first
      
      if new_ticket
        # Redirect to the new ticket's show page
        redirect_to abroad_ticket_path(new_ticket, origin: @origin, destination: @destination, date: @date.strftime('%Y-%m-%d'))
        return
      else
        # If no ticket found for new date, show warning and keep current ticket
        flash.now[:warning] = "该日期暂无相同路线的班次，显示原日期信息"
      end
    end
    
    # Get same route tickets for the day (different seat categories)
    @available_tickets = AbroadTicket.available
                                     .by_region(@ticket.region)
                                     .by_route(@ticket.origin, @ticket.destination)
                                     .by_date(@ticket.departure_date)
                                     .where(time_slot_start: @ticket.time_slot_start)
                                     .order(price: :asc)
  end

  private

  def get_popular_routes(region)
    if region == 'japan'
      [
        { name: '关西', name_en: 'Kansai', cities: '大阪/广岛/京都/神户/冈山...' },
        { name: '北海道', name_en: 'Hokkaido', cities: '函馆/札幌/小樽/富良野...' },
        { name: '关东', name_en: 'Kanto', cities: '东京/横滨/千叶/日光/仙台...' },
        { name: '九州', name_en: 'Kyushu', cities: '福冈/熊本/鹿儿岛...' }
      ]
    else
      [
        { name: '法国', name_en: 'France', cities: '巴黎/里昂/马赛...' },
        { name: '德国', name_en: 'Germany', cities: '慕尼黑/柏林/法兰克福...' },
        { name: '意大利', name_en: 'Italy', cities: '罗马/米兰/佛罗伦萨...' },
        { name: '西班牙', name_en: 'Spain', cities: '巴塞罗那/马德里/塞维利亚...' }
      ]
    end
  end
end
