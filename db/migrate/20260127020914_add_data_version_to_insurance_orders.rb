class AddDataVersionToInsuranceOrders < ActiveRecord::Migration[7.2]
  def change
    add_column :insurance_orders, :data_version, :integer, default: 0, null: false
    add_index :insurance_orders, :data_version

    # Enable RLS policy for InsuranceOrder
    reversible do |dir|
      dir.up do
        execute <<-SQL
          ALTER TABLE insurance_orders ENABLE ROW LEVEL SECURITY;
          
          DROP POLICY IF EXISTS insurance_orders_isolation_policy ON insurance_orders;
          CREATE POLICY insurance_orders_isolation_policy ON insurance_orders
            USING (data_version = COALESCE(current_setting('app.data_version', TRUE)::integer, 0));
        SQL
      end
      
      dir.down do
        execute <<-SQL
          DROP POLICY IF EXISTS insurance_orders_isolation_policy ON insurance_orders;
          ALTER TABLE insurance_orders DISABLE ROW LEVEL SECURITY;
        SQL
      end
    end
  end
end
