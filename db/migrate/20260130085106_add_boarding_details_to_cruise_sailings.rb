class AddBoardingDetailsToCruiseSailings < ActiveRecord::Migration[7.2]
  def change
    add_column :cruise_sailings, :boarding_address, :string
    add_column :cruise_sailings, :boarding_deadline, :string

  end
end
