class AddTypeAndRegionToHotels < ActiveRecord::Migration[7.2]
  def change
    add_column :hotels, :hotel_type, :string, default: 'hotel' # hotel, homestay, hourly
    add_column :hotels, :region, :string # 深圳南山区, 香港, etc.
    add_column :hotels, :is_domestic, :boolean, default: true # true=国内, false=国际(含港澳)
    
    add_index :hotels, :hotel_type
    add_index :hotels, :is_domestic
    add_index :hotels, :region
  end
end
