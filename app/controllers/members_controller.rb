class MembersController < ApplicationController
  def index
    @full_render = true
    # 如果用户未登录，显示默认数据
    if current_user
      @membership = current_user.membership || current_user.create_membership!(level: 'F1', points: 0, experience: 0)
      @brand_memberships = current_user.brand_memberships.where(status: 'active')
    else
      # 未登录用户显示示例数据
      @membership = Membership.new(level: 'F1', points: 2, experience: 0)
      @brand_memberships = []
    end
    
    @all_benefits = MembershipBenefit.order(:level_required)
    @available_benefits = @all_benefits.where("level_required <= ?", @membership.level)
    @locked_benefits = @all_benefits.where("level_required > ?", @membership.level)
  end

  private
  # Write your private methods here
end
