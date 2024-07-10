class CreateFlightSales < ActiveRecord::Migration[7.1]
  def change
    create_table :flight_sales do |t|
      t.datetime :purchase_datetime
      t.decimal :base_price
      t.decimal :fees
      t.integer :client_id
      t.datetime :departure_datetime
      t.timestamps
    end
  end
end
