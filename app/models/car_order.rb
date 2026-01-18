class CarOrder < ApplicationRecord
  include DataVersionable
  belongs_to :user
  belongs_to :car
end
