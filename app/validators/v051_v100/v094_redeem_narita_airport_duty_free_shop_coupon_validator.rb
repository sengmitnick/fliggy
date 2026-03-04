# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例94: 给张三兑换成田机场免税店优惠券（全日空免税，最高折扣）
#
# 任务描述:
#   用户想为张三兑换成田机场全日空免税店的优惠券。
#   Agent 需要在符合条件的优惠券中，选择discount_value（折扣值）最高的优惠券。
#
# 业务流程（4个关键步骤）：
#   1. 搜索成田机场相关的免税店优惠券
#   2. 筛选品牌名包含“全日空”且门店城市包含“成田”的优惠券
#   3. 对比多个符合条件优惠券的discount_value（折扣值）
#   4. 选择discount_value最高的优惠券并兑换
#
# 复杂度分析（4个关键点）：
#   1. 需要理解“免税店优惠券”这一特殊服务类型
#   2. 需要同时满足两个筛选条件（品牌包含“全日空” AND 城市包含“成田”）
#   3. 需要理解“最高折扣”条件：对比多个优惠券的discount_value字段
#   4. 需要选择discount_value最大值的优惠券
#   ❌ 不能随机选择：必须精确对比discount_value并选择最高的
#
# 评分标准（4项，总计100分）：
#   - 优惠券已兑换（20分）
#   - 品牌正确（全日空免税店）（30分）
#   - 门店城市正确（成田）（20分）
#   - 选择了折扣最高的优惠券（30分）
module V051V100
  class V094RedeemNaritaAirportDutyFreeShopCouponValidator < BaseValidator
    self.validator_id = 'v094_redeem_narita_airport_duty_free_shop_coupon_validator'
    self.task_id = 'ecf457a8-face-4e6a-9380-668b730c5fc2'
    self.title = '给张三兑换成田机场免税店优惠券（全日空免税，最高折扣）'
    self.description = '兑换成田机场免税店优惠券（全日空免税，最高折扣）'
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
        @user_coupon = UserCoupon.where(data_version: @data_version).order(created_at: :desc).first
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
        expires_at: Time.current + 1.year,
        data_version: @data_version
      )
    end
    end
end