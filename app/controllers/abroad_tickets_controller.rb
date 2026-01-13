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

    # Get date range for date picker (7 days before and after)
    @date_range = ((@date - 3.days)..(@date + 10.days)).to_a
  end

  def show
    @ticket = AbroadTicket.find(params[:id])
    @origin = params[:origin] || @ticket.origin
    @destination = params[:destination] || @ticket.destination
    @date = params[:date] ? Date.parse(params[:date]) : @ticket.departure_date
    
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
