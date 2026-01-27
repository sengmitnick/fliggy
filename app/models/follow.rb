class Follow < ApplicationRecord
  belongs_to :user
  # Note: followable_type and followable_id are stored but not validated as polymorphic
  # This allows following non-ActiveRecord objects like LiveRoom
  
  validates :user_id, uniqueness: { scope: [:followable_type, :followable_id] }
  validates :followable_type, :followable_id, presence: true
end
