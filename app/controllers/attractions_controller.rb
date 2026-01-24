class AttractionsController < ApplicationController
  before_action :set_attraction, only: [:show]

  def index
    @city = params[:city].presence || '深圳'
    @sort_by = params[:sort_by].presence || 'rating' # rating/review_count/name
    
    # 获取所有可用的城市列表
    @cities = Attraction.distinct.pluck(:city).compact.sort
    @cities = ['深圳', '上海', '北京', '广州', '杭州', '成都'] if @cities.empty?
    
    # 查询景点
    @attractions = Attraction.by_city(@city)
    
    # 排序
    @attractions = case @sort_by
    when 'review_count'
      @attractions.order(review_count: :desc)
    when 'name'
      @attractions.order(name: :asc)
    else # 'rating' or default
      @attractions.order(rating: :desc, review_count: :desc)
    end
    
    @attractions = @attractions.page(params[:page]).per(20)
  end

  def show
    @tickets = @attraction.tickets.available.order(current_price: :asc)
    @activities = @attraction.attraction_activities.by_type(params[:activity_type]).order(current_price: :asc)
    @tours = @attraction.related_tours(10)
    @nearby_hotels = @attraction.nearby_hotels(10)
    @reviews = @attraction.attraction_reviews.recent.page(params[:page]).per(10)
    
    # Tab 切换参数
    @active_tab = params[:tab].presence || 'tickets'
  end

  def search
    @query = params[:q].to_s.strip
    @city = params[:city].presence
    
    @attractions = Attraction.all
    @attractions = @attractions.where("name LIKE ?", "%#{@query}%") if @query.present?
    @attractions = @attractions.by_city(@city) if @city.present?
    @attractions = @attractions.order(rating: :desc, review_count: :desc).limit(50)
    
    render json: @attractions.as_json(only: [:id, :name, :city, :rating, :review_count, :slug])
  end

  private

  def set_attraction
    @attraction = Attraction.friendly.find(params[:id])
  end
end
