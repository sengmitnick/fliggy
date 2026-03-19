class ChangeInsuranceProductPriceToInteger < ActiveRecord::Migration[7.2]
  def up
    # First, round all existing prices to integers
    execute <<-SQL
      UPDATE insurance_products 
      SET price_per_day = ROUND(price_per_day)
    SQL
    
    # Change column type to integer
    change_column :insurance_products, :price_per_day, :integer, null: false, default: 0
  end

  def down
    # Revert to decimal type
    change_column :insurance_products, :price_per_day, :decimal, precision: 10, scale: 2, null: false, default: 0.0
  end
end
