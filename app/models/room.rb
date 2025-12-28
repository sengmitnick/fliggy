class Room < ApplicationRecord
  belongs_to :hotel

  serialize :amenities, coder: JSON
end
