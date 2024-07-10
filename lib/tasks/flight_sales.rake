# lib/tasks/flight_sales.rake
namespace :flight_sales do
  desc "Calculate the total sales amount per year, categorized by user levels"
  task yearly_sales_by_level: :environment do
    sql_time = Benchmark.realtime do
      # Fetch all flight sales sorted by purchase date
      # FlightSale structure: <id: 1, client_id: 1, purchase_datetime: "2022-01-01", base_price: 100, fees: 20>
      sales = FlightSale.order(:purchase_datetime)

      # Initialize data structures
      user_purchases = Hash.new { |hash, key| hash[key] = [] }
      # {153 => [<FlightSale id: 1, ...>], 225 => [<FlightSale id: 2, ...>], ...}
      user_levels = Hash.new(0)
      # {153 => 0, 225 => 2, ...}
      yearly_sales_amount_by_level = Hash.new { |hash, key| hash[key] = Hash.new(0) }
      # {2022 => {0 => 2452.25, 1 => 1131.40, 2 => 259.25}...}

      # Populate user purchases
      # {1 => [<FlightSale id: 1, client_id: 1, ...>], 2 => [<FlightSale id: 2, client_id: 2, ...>]}
      sales.each do |sale|
        user_purchases[sale.client_id] << sale
      end

      # Calculate user levels and track sales by level at the time of purchase
      user_purchases.each do |client_id, purchases|
        current_level = 0

        # Iterate over each user purchase to accumulate yearly sales by level
        purchases.each_with_index do |purchase, index|
          year = purchase.purchase_datetime.year
          amount = purchase.base_price + purchase.fees

          # Add the sale amount to the yearly sales for the current level
          # yearly_sales_amount_by_level[2022][0] += 120 for purchase with base_price 100 and fees 20
          yearly_sales_amount_by_level[year][current_level] += amount

          # Consider purchases in the last 2 years
          # We take the actual and previous purchases but reject those that are older than 2 years to see
          # how many purchases the user has made in the last 2 years
          window_purchases = purchases[0..index].reject { |p| p.purchase_datetime < purchase.purchase_datetime - 2.years }

          # Update user level based on window purchases
          # If with this purchase, the user has made 5 or more purchases in the last 2 years, he can pass to level 2
          # If with this purchase, the user has made 2 or more purchases in the last 2 years, he can pass to level 1
          # Once he reaches a level, he can't go back to a lower level, so we take the maximum between the current level and the new level
          if window_purchases.size >= 5
            current_level = 2
          elsif window_purchases.size >= 2
            current_level [user_levels[client_id], 1].max
          end

          # Update the highest level achieved by the user
          user_levels[client_id] = current_level
        end
      end

      # Output the results sorted by year and level
      yearly_sales_amount_by_level.sort.each do |year, sales_by_level|
        sales_by_level.sort.each do |level, amount|
          puts "Year: #{year}, Level: #{level}, Total Sales: $#{amount.round(2)}"
        end
      end
    end
    puts "in-memory processing execution time: #{sql_time.round(2)} seconds"
  end

  desc "Calculate the total sales amount per year, categorized by user levels using a single SQL query"
  task yearly_sales_by_level_single_query: :environment do
    sql_time = Benchmark.realtime do
      result = ActiveRecord::Base.connection.execute(<<~SQL
        -- We first create a temporary table to store the sales data with an additional column to track the sale number for each user
        WITH sales_table AS (
          SELECT
            purchase_datetime,
            base_price + fees as amount,
            client_id,
            ROW_NUMBER() OVER (
                PARTITION BY client_id
                ORDER BY purchase_datetime
              ) AS sale_number
          FROM flight_sales
        ),
        -- We then detect if the difference in years between the current purchase and the previous 5th and 2nd purchases
        -- is less than 2 years. If so, we assign a value of 2 or 1 to know that from that row the user achieved a new level
        intervals_detection AS (
          SELECT
            *,
            CASE
              WHEN purchase_datetime - interval '2 years' < LAG(purchase_datetime, 4) OVER (PARTITION BY client_id ORDER BY sale_number)
              THEN 2
              WHEN purchase_datetime - interval '2 years' < LAG(purchase_datetime, 1) OVER (PARTITION BY client_id ORDER BY sale_number)
              THEN 1
              ELSE 0
              END AS level_achieved
          FROM sales_table
        ),
        -- At this point, we use the level_achieved column to calculate the level for each purchase
        -- We use the MAX window function to keep the highest level achieved by the user
        -- At this point we have the level the user was at the time of each purchase
        -- The coalesce function is used to set the level to 0 for the first purchase of each user since there is no previous records
        -- so the MAX window function would return NULL
        levels_detection AS (
          SELECT
            DATE_PART('year', purchase_datetime) as year,
            amount,
            client_id,
            COALESCE(
              MAX(level_achieved) OVER (PARTITION BY client_id ORDER BY sale_number ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING)
              ,0) as level
          FROM intervals_detection
        )
        -- Finally, we group the data by year and level to calculate the total sales amount for each year and level
        SELECT
          year,
          level,
          SUM(amount) as total_amount
        FROM levels_detection
        GROUP BY year, level
        ORDER BY year, level;
      SQL
      )
      result.each do |row|
        puts "Year: #{row['year'].to_i}, Level: #{row['level']}, Total Sales: $#{row['total_amount'].to_f.round(2)}"
      end
    end
    puts "sql processing execution time: #{sql_time.round(2)} seconds"
  end
end
