class Admin::BusTicketsController < Admin::BaseController
  before_action :set_bus_ticket, only: [:show, :edit, :update, :destroy]

  def index
    @bus_tickets = BusTicket.page(params[:page]).per(10)
  end

  def show
  end

  def new
    @bus_ticket = BusTicket.new
  end

  def create
    @bus_ticket = BusTicket.new(bus_ticket_params)

    if @bus_ticket.save
      redirect_to admin_bus_ticket_path(@bus_ticket), notice: '汽车票创建成功。'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @bus_ticket.update(bus_ticket_params)
      redirect_to admin_bus_ticket_path(@bus_ticket), notice: '汽车票更新成功。'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @bus_ticket.destroy
    redirect_to admin_bus_tickets_path, notice: '汽车票删除成功。'
  end

  private

  def set_bus_ticket
    @bus_ticket = BusTicket.find(params[:id])
  end

  def bus_ticket_params
    params.require(:bus_ticket).permit(:origin, :destination, :departure_date, :departure_time, :arrival_time, :price, :status, :seat_type, :departure_station, :arrival_station, :route_description)
  end
end
