# frozen_string_literal: true

require_relative 'base_validator'

# 验证用例94: 预订成田机场免税店优惠券（全日空免税，最高折扣）
class V094RedeemNaritaAirportDutyFreeShopCouponValidator < BaseValidator
  self.validator_id = 'v094_redeem_narita_airport_duty_free_shop_coupon_validator'
  self.title = '兑换成田机场免税店优惠券（全日空免税，最高折扣）'
  self.description = '兑换成田机场全日空免税店优惠券，选择折扣最高的券'
  self.timeout_seconds = 180
  
  def prepare
    @brand_keyword = '全日空'
    @city_keyword = '成田'
    
    @available_brands = AbroadBrand.where(data_version: 0)
                                   .where('name LIKE ?', "%#{@brand_keyword}%")
    
    {
      task: "请兑换成田机场#{@brand_keyword}免税店优惠券，选择折扣最高的券",
      brand_keyword: @brand_keyword,
      city_keyword: @city_keyword,
      hint: "筛选品牌名包含'全日空'、门店城市包含'成田'的优惠券，选择折扣值(discount_value)最高的",
      available_brands_count: @available_brands.count
    }
  end
  
  def verify
    add_assertion "优惠券已兑换", weight: 20 do
      @user_coupon = UserCoupon.order(created_at: :desc).first
      expect(@user_coupon).not_to be_nil, "未找到任何优惠券兑换记录"
    end
    
    return unless @user_coupon
    
    add_assertion "品牌正确（全日空免税店）", weight: 30 do
      brand = @user_coupon.abroad_coupon.abroad_brand
      expect(brand.name).to include(@brand_keyword),
        "品牌不符合要求。期望包含: #{@brand_keyword}, 实际: #{brand.name}"
    end
    
    add_assertion "门店城市正确（成田）", weight: 20 do
      shop = @user_coupon.abroad_coupon.abroad_shop
      expect(shop.city).to include(@city_keyword),
        "门店城市不符合要求。期望包含: #{@city_keyword}, 实际: #{shop.city}"
    end
    
    add_assertion "选择了折扣最高的优惠券", weight: 30 do
      # 查找所有符合条件的优惠券
      brand = AbroadBrand.where(data_version: 0).where('name LIKE ?', "%#{@brand_keyword}%").first
      available_coupons = AbroadCoupon.where(data_version: 0, abroad_brand_id: brand.id)
                                      .joins(:abroad_shop)
                                      .where('abroad_shops.city LIKE ?', "%#{@city_keyword}%")
      
      highest_discount = available_coupons.max_by { |c| c.discount_value.to_f }
      expect(@user_coupon.abroad_coupon_id).to eq(highest_discount.id),
        "未选择折扣最高的优惠券。应选: #{highest_discount.title}（折扣#{highest_discount.discount_value}%），实际: #{@user_coupon.abroad_coupon.title}（折扣#{@user_coupon.abroad_coupon.discount_value}%）"
    end
  end
  
  def execution_state_data
    { brand_keyword: @brand_keyword, city_keyword: @city_keyword }
  end
  
  def restore_from_state(data)
    @brand_keyword = data['brand_keyword']
    @city_keyword = data['city_keyword']
    @available_brands = AbroadBrand.where(data_version: 0).where('name LIKE ?', "%#{@brand_keyword}%")
  end
  
  def simulate
    user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
    
    brand = AbroadBrand.where(data_version: 0).where('name LIKE ?', "%#{@brand_keyword}%").first
    raise "未找到符合条件的品牌" unless brand
    
    available_coupons = AbroadCoupon.where(data_version: 0, abroad_brand_id: brand.id)
                                    .joins(:abroad_shop)
                                    .where('abroad_shops.city LIKE ?', "%#{@city_keyword}%")
    raise "未找到符合条件的优惠券" if available_coupons.empty?
    
    highest_discount = available_coupons.max_by { |c| c.discount_value.to_f }
    
    UserCoupon.create!(
      user_id: user.id,
      abroad_coupon_id: highest_discount.id,
      status: 'claimed',
      claimed_at: Time.current,
      expires_at: Time.current + 1.year
    )
  end
end
