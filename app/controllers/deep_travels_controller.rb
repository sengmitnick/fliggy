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
  end

  private
  # Write your private methods here
end
