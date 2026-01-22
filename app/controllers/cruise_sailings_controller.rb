class CruiseSailingsController < ApplicationController
  before_action :authenticate_user!

  def show
    # 查找班次
    @sailing = CruiseSailing.find(params[:id])
    @cruise_ship = @sailing.cruise_ship
    
    # 获取选中的舱房类型
    cabin_type_id = params[:cabin_type_id]
    @cabin_type = @cruise_ship.cabin_types.find(cabin_type_id) if cabin_type_id.present?
    
    # 获取该班次 + 舱房类型的所有商家产品，按价格排序
    @products = if @cabin_type
                  @sailing.cruise_products
                          .where(cabin_type: @cabin_type, status: 'on_sale')
                          .order(:price_per_person)
                else
                  @sailing.cruise_products
                          .where(status: 'on_sale')
                          .order(:price_per_person)
                end
  end

  private
  # Write your private methods here
end
