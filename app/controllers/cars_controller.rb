class CarsController < ApplicationController

  def index
    @cars = Car.where(is_available: true).order(:sales_rank)
    
    # 按分类统计
    @categories = Car.where(is_available: true).group(:category).count
    
    # 如果有分类筛选
    if params[:category].present?
      @cars = @cars.where(category: params[:category])
    end
    
    # 如果有排序
    if params[:sort] == 'price_asc'
      @cars = @cars.order(:price_per_day)
    elsif params[:sort] == 'price_desc'
      @cars = @cars.order(price_per_day: :desc)
    end
  end
  
  def search
    @cars = Car.where(is_available: true).order(:sales_rank)
    
    # 按分类统计
    @categories = Car.where(is_available: true).group(:category).count
    
    # 如果有分类筛选
    if params[:category].present?
      @cars = @cars.where(category: params[:category])
    end
    
    # 如果有排序
    if params[:sort] == 'price_asc'
      @cars = @cars.order(:price_per_day)
    elsif params[:sort] == 'price_desc'
      @cars = @cars.order(price_per_day: :desc)
    end
  end

  private
  # Write your private methods here
end
