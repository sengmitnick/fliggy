class AddBrandToHotels < ActiveRecord::Migration[7.2]
  def change
    add_column :hotels, :brand, :string

  end
end
