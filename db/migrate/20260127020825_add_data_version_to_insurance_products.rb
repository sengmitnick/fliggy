class AddDataVersionToInsuranceProducts < ActiveRecord::Migration[7.2]
  def change
    add_column :insurance_products, :data_version, :integer, default: 0, null: false
    add_index :insurance_products, :data_version

    # Enable RLS policy for InsuranceProduct
    reversible do |dir|
      dir.up do
        execute <<-SQL
          ALTER TABLE insurance_products ENABLE ROW LEVEL SECURITY;
          
          DROP POLICY IF EXISTS insurance_products_isolation_policy ON insurance_products;
          CREATE POLICY insurance_products_isolation_policy ON insurance_products
            USING (data_version = COALESCE(current_setting('app.data_version', TRUE)::integer, 0));
        SQL
      end
      
      dir.down do
        execute <<-SQL
          DROP POLICY IF EXISTS insurance_products_isolation_policy ON insurance_products;
          ALTER TABLE insurance_products DISABLE ROW LEVEL SECURITY;
        SQL
      end
    end
  end
end
