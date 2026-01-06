FactoryBot.define do
  factory :tour_review do

    association :tour_group_product
    association :user
    rating { 9.99 }
    guide_attitude { 9.99 }
    meal_quality { 9.99 }
    itinerary_arrangement { 9.99 }
    travel_transportation { 9.99 }
    comment { "MyText" }
    is_featured { true }
    helpful_count { 1 }

  end
end
