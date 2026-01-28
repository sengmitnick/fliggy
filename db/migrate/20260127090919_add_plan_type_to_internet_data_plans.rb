class AddPlanTypeToInternetDataPlans < ActiveRecord::Migration[7.2]
  def change
    add_column :internet_data_plans, :plan_type, :string, default: "daily"

  end
end
