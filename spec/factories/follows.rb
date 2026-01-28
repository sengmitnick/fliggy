FactoryBot.define do
  factory :follow do

    association :user
    association :followable

  end
end
