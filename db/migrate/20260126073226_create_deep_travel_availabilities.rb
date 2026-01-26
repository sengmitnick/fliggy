class CreateDeepTravelAvailabilities < ActiveRecord::Migration[7.2]
  def change
    create_table :deep_travel_availabilities do |t|
      t.references :deep_travel_guide, null: false, foreign_key: true
      t.date :available_date, null: false
      t.boolean :is_available, default: true, null: false
      t.bigint :data_version, default: 0, null: false

      t.timestamps
    end

    add_index :deep_travel_availabilities, [:deep_travel_guide_id, :available_date], unique: true, name: 'index_deep_travel_avail_on_guide_and_date'
    add_index :deep_travel_availabilities, :data_version
  end
end
