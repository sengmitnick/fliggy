class HomeController < ApplicationController
  include HomeDemoConcern

  def index
    @full_render = true
  end
end
