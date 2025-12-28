FactoryBot.define do
  factory :itinerary do

    association :user
    title { "MyString" }
    start_date { Date.today }
    end_date { Date.today }
    destination { "MyString" }
    status { "MyString" }

  end
end
