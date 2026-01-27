class LiveProduct < ApplicationRecord
  belongs_to :productable, polymorphic: true
end
