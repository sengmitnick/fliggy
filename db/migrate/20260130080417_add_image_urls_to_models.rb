class AddImageUrlsToModels < ActiveRecord::Migration[7.2]
  def change
    # Attraction: cover_image + gallery_images -> cover_image_url + gallery_image_urls
    add_column :attractions, :cover_image_url, :string unless column_exists?(:attractions, :cover_image_url)
    add_column :attractions, :gallery_image_urls, :text unless column_exists?(:attractions, :gallery_image_urls)
    
    # Hotel: image -> image_url
    add_column :hotels, :image_url, :string unless column_exists?(:hotels, :image_url)
    
    # Ticket: image -> image_url
    add_column :tickets, :image_url, :string unless column_exists?(:tickets, :image_url)
    
    # AttractionActivity: image -> image_url
    add_column :attraction_activities, :image_url, :string unless column_exists?(:attraction_activities, :image_url)
    
    # TourGroupProduct: main_image + gallery_images -> main_image_url + gallery_image_urls
    add_column :tour_group_products, :main_image_url, :string unless column_exists?(:tour_group_products, :main_image_url)
    add_column :tour_group_products, :gallery_image_urls, :text unless column_exists?(:tour_group_products, :gallery_image_urls)
    
    # HotelPackage: brand_logo -> brand_logo_url
    add_column :hotel_packages, :brand_logo_url, :string unless column_exists?(:hotel_packages, :brand_logo_url)
    
    # DeepTravelGuide: avatar + video -> avatar_url + video_url
    add_column :deep_travel_guides, :avatar_url, :string unless column_exists?(:deep_travel_guides, :avatar_url)
    add_column :deep_travel_guides, :video_url, :string unless column_exists?(:deep_travel_guides, :video_url)
    
    # MembershipProduct: image -> image_url
    add_column :membership_products, :image_url, :string unless column_exists?(:membership_products, :image_url)
    
    # DeepTravelProduct: images -> image_urls
    add_column :deep_travel_products, :image_urls, :text unless column_exists?(:deep_travel_products, :image_urls)
    
    # TourReview: images -> image_urls
    add_column :tour_reviews, :image_urls, :text unless column_exists?(:tour_reviews, :image_urls)
  end
end
