class HomeController < ApplicationController
  include HomeDemoConcern

  def index
    # 获取用户上次选择的城市，如果没有则默认为深圳
    if session[:last_destination_slug].present?
      @current_destination = Destination.friendly.find(session[:last_destination_slug])
    else
      @current_destination = Destination.friendly.find('shen-zhen')
    end
  end
end
