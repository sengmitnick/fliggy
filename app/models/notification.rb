class Notification < ApplicationRecord
  belongs_to :user
  
  CATEGORIES = {
    'interactive' => '互动消息',
    'member' => '会员消息',
    'itinerary' => '行程服务',
    'account' => '账户通知',
    'hotel' => '国际酒店消息',
    'subscription' => '订阅消息',
    'folded' => '折叠的消息',
    'group' => '群聊广场'
  }.freeze
  
  validates :category, inclusion: { in: CATEGORIES.keys }
  validates :title, presence: true
  
  scope :unread, -> { where(read: false) }
  scope :by_category, ->(category) { where(category: category) }
  scope :recent, -> { order(created_at: :desc) }
  
  def mark_as_read!
    update(read: true)
  end
  
  def category_display_name
    CATEGORIES[category]
  end
end
