class InternetServicesController < ApplicationController
  def index
    @region = params[:region] || '中国香港'
    @current_tab = params[:tab] || 'sim_card'
    
    @sim_cards = InternetSimCard.by_region(@region).popular
    @data_plans = InternetDataPlan.by_region(@region)
    @wifis = InternetWifi.by_region(@region).popular
  end

  def sim_cards
    @region = params[:region] || '中国香港'
    @sim_cards = InternetSimCard.by_region(@region).popular
    render :index
  end

  def data_plans
    @region = params[:region] || '中国香港'
    @data_plans = InternetDataPlan.by_region(@region)
    @current_user_phone = current_user&.phone || '180 2712 8600'
    render :index
  end

  def wifis
    @region = params[:region] || '中国香港'
    @wifis = InternetWifi.by_region(@region).popular
    render :index
  end
end
