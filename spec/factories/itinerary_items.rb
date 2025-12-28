FactoryBot.define do
  factory :itinerary_item do

    association :itinerary
    item_type { "flight" }
    bookable_type { "Booking" }
    bookable_id { 1 }
    item_date { Date.today }
    sequence(:sequence) { |n| n }

  end
end
