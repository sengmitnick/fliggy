class Room < ApplicationRecord
  include DataVersionable
  belongs_to :hotel

  serialize :amenities, coder: JSON
end
