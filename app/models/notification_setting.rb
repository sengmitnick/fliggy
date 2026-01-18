class NotificationSetting < ApplicationRecord
  include DataVersionable
  belongs_to :user
  
  CATEGORIES = Notification::CATEGORIES.keys
  
  validates :category, inclusion: { in: CATEGORIES }, uniqueness: { scope: :user_id }
end
