class FlightPackagesController < ApplicationController

  def index
    @flight_packages = FlightPackage.active.by_price
    @hot_destinations = ['昆明', '三亚', '成都', '杭州', '上海', '广州']
  end

  def show
    @flight_package = FlightPackage.find(params[:id])
  end

  private
  # Write your private methods here
end
