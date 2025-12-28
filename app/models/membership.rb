class Membership < ApplicationRecord
  belongs_to :user
  
  LEVELS = %w[F1 F2 F3 F4 F5].freeze
  
  validates :level, inclusion: { in: LEVELS }
  validates :points, numericality: { greater_than_or_equal_to: 0 }
  validates :experience, numericality: { greater_than_or_equal_to: 0 }
  
  # 会员等级所需经验值
  LEVEL_EXPERIENCE = {
    'F1' => 0,
    'F2' => 50,
    'F3' => 200,
    'F4' => 500,
    'F5' => 1000
  }.freeze
  
  # 检查是否可以升级
  def can_level_up?
    current_level_index = LEVELS.index(level)
    return false if current_level_index == LEVELS.length - 1 # 已是最高等级
    
    next_level = LEVELS[current_level_index + 1]
    experience >= LEVEL_EXPERIENCE[next_level]
  end
  
  # 获取下一等级所需经验值
  def experience_to_next_level
    current_level_index = LEVELS.index(level)
    return 0 if current_level_index == LEVELS.length - 1
    
    next_level = LEVELS[current_level_index + 1]
    LEVEL_EXPERIENCE[next_level] - experience
  end
  
  # 获取可用权益
  def available_benefits
    MembershipBenefit.where("level_required <= ?", level).order(:level_required)
  end
end
