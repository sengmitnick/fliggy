class AddValidatorFieldsToHotels < ActiveRecord::Migration[7.2]
  def change
    add_column :hotels, :facilities, :text
    add_column :hotels, :cancellation_policy, :string
    add_column :hotels, :price_per_night, :decimal

  end
end
