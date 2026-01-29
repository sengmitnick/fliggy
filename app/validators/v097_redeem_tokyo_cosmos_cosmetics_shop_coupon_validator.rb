# frozen_string_literal: true

require_relative 'base_validator'

# 验证用例97: 兑换东京科摩思药妆店优惠券（满额立减7%）
class V097RedeemTokyoCosmosCosmeticsShopCouponValidator < BaseValidator
  self.validator_id = 'v097_redeem_tokyo_cosmos_cosmetics_shop_coupon_validator'
  self.title = '兑换东京科摩思药妆店优惠券（满额立减7%）'
  self.description = '兑换东京歌舞伎町科摩思药妆店的优惠券，选择折扣最高的'
  self.timeout_seconds = 180
  
  def prepare
    @brand_keyword = '科摩思'
    @city = '东京'
    @shop_keyword = '歌舞伎町'
    
    @available_brands = AbroadBrand.where(data_version: 0)
                                   .where('name LIKE ?', "%#{@brand_keyword}%")
    
    {
      task: "请兑换#{@city}#{@shop_keyword}#{@brand_keyword}药妆店的优惠券，选择折扣最高的券",
      brand_keyword: @brand_keyword,
      city: @city,
      shop_keyword: @shop_keyword,
      hint: "筛选品牌名包含'科摩思'、门店城市='东京'且门店名包含'歌舞伎町'的优惠券，选择折扣值(discount_value)最高的",
      available_brands_count: @available_brands.count
    }
  end
  
  def verify
    add_assertion "优惠券已兑换", weight: 20 do
      @user_coupon = UserCoupon.order(created_at: :desc).first
      expect(@user_coupon).not_to be_nil, "未找到任何优惠券兑换记录"
    end
    
    return unless @user_coupon
    
    add_assertion "品牌正确（科摩思）", weight: 25 do
      brand = @user_coupon.abroad_coupon.abroad_brand
      expect(brand.name).to include(@brand_keyword),
        "品牌不符合要求。期望包含: #{@brand_keyword}, 实际: #{brand.name}"
    end
    
    add_assertion "门店城市正确（东京）", weight: 20 do
      shop = @user_coupon.abroad_coupon.abroad_shop
      expect(shop.city).to eq(@city),
        "门店城市不符合要求。期望: #{@city}, 实际: #{shop.city}"
    end
    
    add_assertion "门店名称包含关键词（歌舞伎町）", weight: 20 do
      shop = @user_coupon.abroad_coupon.abroad_shop
      expect(shop.name).to include(@shop_keyword),
        "门店名称不符合要求。期望包含: #{@shop_keyword}, 实际: #{shop.name}"
    end
    
    add_assertion "选择了折扣最高的优惠券", weight: 15 do
      brand = AbroadBrand.where(data_version: 0).where('name LIKE ?', "%#{@brand_keyword}%").first
      available_coupons = AbroadCoupon.where(data_version: 0, abroad_brand_id: brand.id)
                                      .joins(:abroad_shop)
                                      .where('abroad_shops.city = ?', @city)
                                      .where('abroad_shops.name LIKE ?', "%#{@shop_keyword}%")
      
      highest_discount = available_coupons.max_by { |c| c.discount_value.to_f }
      expect(@user_coupon.abroad_coupon_id).to eq(highest_discount.id),
        "未选择折扣最高的优惠券。应选: #{highest_discount.title}（折扣#{highest_discount.discount_value}%），实际: #{@user_coupon.abroad_coupon.title}（折扣#{@user_coupon.abroad_coupon.discount_value}%）"
    end
  end
  
  def execution_state_data
    { brand_keyword: @brand_keyword, city: @city, shop_keyword: @shop_keyword }
  end
  
  def restore_from_state(data)
    @brand_keyword = data['brand_keyword']
    @city = data['city']
    @shop_keyword = data['shop_keyword']
    @available_brands = AbroadBrand.where(data_version: 0).where('name LIKE ?', "%#{@brand_keyword}%")
  end
  
  def simulate
    user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
    
    brand = AbroadBrand.where(data_version: 0).where('name LIKE ?', "%#{@brand_keyword}%").first
    raise "未找到符合条件的品牌" unless brand
    
    available_coupons = AbroadCoupon.where(data_version: 0, abroad_brand_id: brand.id)
                                    .joins(:abroad_shop)
                                    .where('abroad_shops.city = ?', @city)
                                    .where('abroad_shops.name LIKE ?', "%#{@shop_keyword}%")
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
