FactoryBot.define do
  factory :tour_group_product do
    association :travel_agency

    title { "北京深度游" }
    subtitle { "精选酒店 贴心服务" }
    tour_category { "group_tour" }
    destination { "北京" }
    duration { 3 }
    departure_city { "上海" }
    price { 1999 }
    original_price { 2599 }
    rating { 4.8 }
    rating_desc { "168条评价" }
    highlights { ["故宫深度游", "长城全景", "特色美食"] }
    tags { ["历史文化", "美食"] }
    provider { "优质旅行社" }
    sales_count { 128 }
    badge { "跟团游" }
    departure_label { "03月15日" }
    image_url { "https://images.unsplash.com/photo-1508804185872-d7badad00f7d?w=800" }
    is_featured { false }
    display_order { 1 }
  end
end
