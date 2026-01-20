class ChangePassengersDataVersionToBigint < ActiveRecord::Migration[7.2]
  def up
    # 1. 删除依赖 data_version 的 RLS 策略
    execute <<-SQL
      DROP POLICY IF EXISTS passengers_version_policy ON passengers;
    SQL

    # 2. 修改列类型
    change_column :passengers, :data_version, :bigint, default: 0, null: false

    # 3. 重新创建 RLS 策略
    execute <<-SQL
      CREATE POLICY passengers_version_policy ON passengers
        USING (data_version = current_setting('app.data_version', true)::bigint);
    SQL
  end

  def down
    # 回滚时：先删除策略，改回 integer，重新创建策略
    execute <<-SQL
      DROP POLICY IF EXISTS passengers_version_policy ON passengers;
    SQL

    change_column :passengers, :data_version, :integer, default: 0, null: false

    execute <<-SQL
      CREATE POLICY passengers_version_policy ON passengers
        USING (data_version = current_setting('app.data_version', true)::integer);
    SQL
  end
end
