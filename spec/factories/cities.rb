FactoryBot.define do
  factory :city do
    name { '武汉' }
    pinyin { 'wuhan' }
    airport_code { 'WUH' }
    region { 'central' }
    is_hot { true }
  end
end
