class AddDataVersionToCruiseTables < ActiveRecord::Migration[7.2]
  def up
    # Cruise-related tables that need data_version
    cruise_tables = %w[
      cruise_lines
      cruise_ships
      cruise_routes
      cruise_sailings
      cabin_types
      travel_agencies
      cruise_products
    ]
    
    cruise_tables.each do |table|
      # Skip if column already exists
      next if column_exists?(table.to_sym, :data_version)
      
      # 1. Add data_version column
      add_column table, :data_version, :bigint, default: 0, null: false
      add_index table, :data_version unless index_exists?(table.to_sym, :data_version)
      
      # 2. Enable RLS
      execute "ALTER TABLE #{table} ENABLE ROW LEVEL SECURITY"
      
      # 3. Create RLS policy
      policy_name = "#{table}_version_policy"
      execute "DROP POLICY IF EXISTS #{policy_name} ON #{table}"
      execute <<-SQL
        CREATE POLICY #{policy_name} ON #{table}
        FOR ALL
        USING (
          data_version = 0 
          OR data_version::text = current_setting('app.data_version', true)
        )
        WITH CHECK (
          data_version::text = current_setting('app.data_version', true)
        )
      SQL
    end
  end
  
  def down
    cruise_tables = %w[
      cruise_lines
      cruise_ships
      cruise_routes
      cruise_sailings
      cabin_types
      travel_agencies
      cruise_products
    ]
    
    cruise_tables.each do |table|
      # 1. Drop RLS policy
      policy_name = "#{table}_version_policy"
      execute "DROP POLICY IF EXISTS #{policy_name} ON #{table}"
      
      # 2. Disable RLS
      execute "ALTER TABLE #{table} DISABLE ROW LEVEL SECURITY"
      
      # 3. Remove data_version column
      remove_column table, :data_version if column_exists?(table.to_sym, :data_version)
    end
  end
end
