class LiveProduct < ApplicationRecord
  include DataVersionable
  
  belongs_to :productable, polymorphic: true
end
