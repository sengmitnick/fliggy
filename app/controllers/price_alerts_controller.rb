class PriceAlertsController < ApplicationController

  def index
    @price_alerts = PriceAlert.active.recent
  end


  def new
    @price_alert = PriceAlert.new
  end


  def create
    @price_alert = PriceAlert.new(price_alert_params)
    
    if @price_alert.save
      redirect_to price_alerts_path, notice: '低价提醒添加成功！'
    else
      render :new
    end
  end


  def destroy
    @price_alert = PriceAlert.find(params[:id])
    @price_alert.destroy
    redirect_to price_alerts_path, notice: '低价提醒已删除'
  end

  private
  
  def price_alert_params
    params.require(:price_alert).permit(:departure, :destination, :expected_price, :departure_date)
  end
end
