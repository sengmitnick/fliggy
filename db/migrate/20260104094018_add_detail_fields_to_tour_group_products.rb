class AddDetailFieldsToTourGroupProducts < ActiveRecord::Migration[7.2]
  def change
    add_column :tour_group_products, :reward_points, :integer, default: 0
    add_column :tour_group_products, :requires_merchant_confirm, :boolean, default: false
    add_column :tour_group_products, :merchant_confirm_hours, :integer, default: 48
    add_column :tour_group_products, :success_rate_high, :boolean, default: false
    add_column :tour_group_products, :description, :text
    add_column :tour_group_products, :cost_includes, :text
    add_column :tour_group_products, :cost_excludes, :text
    add_column :tour_group_products, :safety_notice, :text
    add_column :tour_group_products, :booking_notice, :text
    add_column :tour_group_products, :insurance_notice, :text
    add_column :tour_group_products, :cancellation_policy, :text
    add_column :tour_group_products, :price_explanation, :text
    add_column :tour_group_products, :group_tour_notice, :text
    add_column :tour_group_products, :custom_tour_available, :boolean, default: false

  end
end
