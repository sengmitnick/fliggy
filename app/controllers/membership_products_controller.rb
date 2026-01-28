class MembershipProductsController < ApplicationController
  before_action :authenticate_user!

  def index
    @products = MembershipProduct.available
    
    # Filter by category
    if params[:category].present?
      @products = @products.by_category(params[:category])
    end
    
    # Filter by region
    if params[:region].present? && params[:region] != 'all'
      @products = @products.by_region(params[:region])
    end
    
    # Sort products
    @products = @products.sorted_by(params[:sort_by])
    
    # Paginate
    @products = @products.page(params[:page]).per(20)
    
    # Get available categories
    @categories = MembershipProduct::CATEGORIES
    @regions = MembershipProduct::REGIONS
  end

  def show
    @product = MembershipProduct.friendly.find(params[:id])
    @user_mileage = current_user.available_mileage
  end

  private
  # Write your private methods here
end
