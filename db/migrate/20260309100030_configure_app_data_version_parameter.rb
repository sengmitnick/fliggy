# frozen_string_literal: true

class ConfigureAppDataVersionParameter < ActiveRecord::Migration[7.2]
  def up
    # Configure PostgreSQL custom parameter app.data_version at database level
    # This allows SET SESSION app.data_version = 'xxx' and current_setting('app.data_version', true) to work
    execute "ALTER DATABASE #{connection.current_database} SET app.data_version = '0'"
    
    puts "\n" + "=" * 80
    puts "✓ Configured app.data_version parameter at database level"
    puts "  Default value: '0'"
    puts "=" * 80
  end
  
  def down
    # Reset the parameter to default (which effectively removes the custom setting)
    execute "ALTER DATABASE #{connection.current_database} RESET app.data_version"
    
    puts "\n" + "=" * 80
    puts "✓ Reset app.data_version parameter"
    puts "=" * 80
  end
end
