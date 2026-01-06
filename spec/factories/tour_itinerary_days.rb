FactoryBot.define do
  factory :tour_itinerary_day do

    association :tour_group_product
    day_number { 1 }
    title { "MyString" }
    attractions { "MyText" }
    assembly_point { "MyText" }
    assembly_details { "MyText" }
    disassembly_point { "MyText" }
    disassembly_details { "MyText" }
    transportation { "MyString" }
    service_info { "MyText" }
    duration_minutes { 1 }

  end
end
