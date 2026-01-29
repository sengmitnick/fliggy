class DeepTravelsController < ApplicationController

  def index
    @full_render = true  # Disable navbar for this page
    @location = params[:location] || '境内精选'
    
    # Get featured guides
    @guides = DeepTravelGuide.includes(:avatar_attachment, :video_attachment)
                            .featured
                            .by_rank
                            .limit(10)
    
    # Get products based on location filter
    @products = if @location == '境内精选'
                  DeepTravelProduct.includes(:deep_travel_guide, :images_attachments)
                                  .where(location: ['北京', '华东', '华中', '陕西'])
                                  .recent
                                  .limit(20)
                elsif @location == '境外精选'
                  DeepTravelProduct.includes(:deep_travel_guide, :images_attachments)
                                  .where.not(location: ['北京', '华东', '华中', '陕西'])
                                  .recent
                                  .limit(20)
                else
                  DeepTravelProduct.includes(:deep_travel_guide, :images_attachments)
                                  .by_location(@location)
                                  .recent
                                  .limit(20)
                end
    
    # Group products by venue (景点)
    @venues = {}
    @products.each do |product|
      guide = product.deep_travel_guide
      next unless guide && guide.venue.present?
      
      @venues[guide.venue] ||= {
        location: product.location,
        title: product.subtitle&.split(' ')&.first || product.title.split(/[【\[]/)[0],
        guides: [],
        products: []
      }
      
      # Add guide if not already in the list
      unless @venues[guide.venue][:guides].any? { |g| g.id == guide.id }
        @venues[guide.venue][:guides] << guide
      end
      
      # Add product
      @venues[guide.venue][:products] << product
    end
  end
  
  # GET /deep_travels/:id/available_dates
  def available_dates
    @guide = DeepTravelGuide.find(params[:id])
    start_date = params[:start_date]&.to_date || Time.zone.today
    end_date = params[:end_date]&.to_date || (Time.zone.today + 90.days)

    available_dates = @guide.availabilities
                           .where(is_available: true)
                           .where(available_date: start_date..end_date)
                           .pluck(:available_date)
                           .map(&:to_s)

    # 禁用缓存
    response.headers['Cache-Control'] = 'no-cache, no-store, must-revalidate'
    response.headers['Pragma'] = 'no-cache'
    response.headers['Expires'] = '0'
    
    render json: { available_dates: available_dates }
  end

  def show
    @full_render = true
    @guide = DeepTravelGuide.includes(:deep_travel_products, :deep_travel_reviews, :avatar_attachment, :video_attachment)
                           .find(params[:id])
    @products = @guide.deep_travel_products.order(sales_count: :desc)
    @selected_product = @products.first
    
    # Load reviews
    @reviews = @guide.deep_travel_reviews.includes(:user).recent.limit(10)
    @review_count = @guide.deep_travel_reviews.count
    @avg_rating = @guide.rating || 5.0  # Use guide's rating as average
  end

  private
  # Write your private methods here
end
