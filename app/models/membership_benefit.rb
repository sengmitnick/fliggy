class MembershipBenefit < ApplicationRecord
  include DataVersionable
  LEVELS = %w[F1 F2 F3 F4 F5].freeze
  
  validates :name, presence: true
  validates :level_required, inclusion: { in: LEVELS }
end
