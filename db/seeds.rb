# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
require 'faker'

# Set up a batch size to insert records in batches
batch_size = 10_000
total_records = 3_000_000

def generate_flight_sale
  purchase_datetime = Faker::Time.between(from: 5.years.ago, to: Time.now)
  {
    purchase_datetime: purchase_datetime,
    base_price: Faker::Commerce.price(range: 100.0..1000.0),
    fees: Faker::Commerce.price(range: 10.0..100.0),
    client_id: Faker::Number.number(digits: 6),
    departure_datetime: Faker::Time.between(from: purchase_datetime, to: purchase_datetime + 1.year)
  }
end

  # Generate records in batches
(total_records / batch_size).times do |batch|
  flight_sales = []
  batch_size.times do
    flight_sales << generate_flight_sale
  end

  # Insert the batch into the database
  FlightSale.insert_all(flight_sales)
  puts "Inserted batch #{batch + 1} of #{total_records / batch_size}"
end