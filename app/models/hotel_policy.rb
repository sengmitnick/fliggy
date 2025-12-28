class HotelPolicy < ApplicationRecord
  belongs_to :hotel

  serialize :payment_methods, coder: JSON
end
