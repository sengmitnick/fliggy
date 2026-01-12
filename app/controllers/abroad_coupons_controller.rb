class AbroadCouponsController < ApplicationController
  before_action :authenticate_user!

  # 卡券详情页
  def show
    @user_coupon = current_user.user_coupons.find(params[:id])
    @coupon = @user_coupon.abroad_coupon
    @brand = @coupon.abroad_brand
    @shops = @coupon.abroad_shop_id ? [@coupon.abroad_shop] : @brand.abroad_shops
  end

  # 卡券包页面 - 显示可使用和已失效的卡券
  def wallet
    @usable_coupons = current_user.user_coupons.usable.includes(:abroad_coupon)
    @expired_coupons = current_user.user_coupons.expired.includes(:abroad_coupon)
  end

  # 领取卡券
  def claim
    @coupon = AbroadCoupon.find(params[:id])
    
    # 检查是否已经领取过
    existing = current_user.user_coupons.find_by(abroad_coupon_id: @coupon.id)
    
    if existing
      redirect_to wallet_abroad_coupons_path, alert: "您已领取过该卡券"
    else
      user_coupon = current_user.user_coupons.create!(
        abroad_coupon: @coupon,
        status: 'claimed',
        claimed_at: Time.current,
        expires_at: @coupon.valid_until
      )
      redirect_to wallet_abroad_coupons_path, notice: "卡券领取成功"
    end
  rescue StandardError => e
    redirect_to request.referer || root_path, alert: "领取失败：#{e.message}"
  end

  private
  # Write your private methods here
end
