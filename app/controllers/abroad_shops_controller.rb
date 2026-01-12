class AbroadShopsController < ApplicationController

  # 首页 - 全球购福利、三个分类卡片、商品流、底部Tab
  def index
    @featured_brands = AbroadBrand.featured.limit(4)
    @all_brands = AbroadBrand.all
  end

  # 品牌详情页 - 显示品牌下的门店和优惠券
  def brand
    @brand = AbroadBrand.friendly.find(params[:id])
    @shops = @brand.abroad_shops
    @coupons = @brand.abroad_coupons.active
  end

  # 门店搜索页 - 按城市搜索门店
  def search
    @city = params[:city]
    @shops = AbroadShop.all
    @shops = @shops.by_city(@city) if @city.present?
  end

  # 门店详情页 - 显示门店信息和优惠券
  def shop
    @shop = AbroadShop.find(params[:id])
    @brand = @shop.abroad_brand
    @coupons = @shop.abroad_coupons.active
  end

  # 药妆专享页面
  def cosmeceuticals
    @brands = AbroadBrand.cosmeceuticals
  end

  # 免税店页面
  def duty_free
    @brands = AbroadBrand.duty_free
  end

  private
  # Write your private methods here
end
