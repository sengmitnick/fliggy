class HotelPolicy < ApplicationRecord
  include DataVersionable
  belongs_to :hotel

  serialize :payment_methods, coder: JSON
end
