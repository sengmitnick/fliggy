class CreateTrainSeats < ActiveRecord::Migration[7.2]
  def change
    create_table :train_seats do |t|
      t.references :train
      t.string :seat_type, default: "second_class"
      t.decimal :price, default: 0
      t.integer :available_count, default: 0
      t.integer :total_count, default: 0


      t.timestamps
    end
  end
end
