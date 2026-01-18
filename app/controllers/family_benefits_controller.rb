class FamilyBenefitsController < ApplicationController

  def index
    @family_benefit = FamilyBenefit.recent.first || FamilyBenefit.new
    @available_coupons = FamilyCoupon.available
  end


  def verify
    @family_benefit = FamilyBenefit.recent.first || FamilyBenefit.new
  end
  
  def create
    @family_benefit = FamilyBenefit.recent.first || FamilyBenefit.new
    
    if @family_benefit.update(family_benefit_params)
      redirect_to family_benefits_path, notice: '家庭认证成功！'
    else
      render :verify
    end
  end

  private
  
  def family_benefit_params
    params.require(:family_benefit).permit(:verification_status, :adult_count, :child_count)
  end
end
