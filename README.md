# Flight Sales Processing Performance Comparison

### Introduction

Welcome to the Flight Sales Processing Performance Comparison project! This repository aims to compare the execution times of processing a large number of flight sales records using in-memory processing versus direct SQL queries.

### Project Structure

The project contains the following main components:

- Rake Tasks: Located in lib/tasks/flight_sales.rake, these tasks calculate the total sales amount per year, categorized by user levels, using two different approaches: in-memory processing and a single SQL query.

### Rake Tasks

#### In-Memory Processing

This task fetches all flight sales and processes them in memory to calculate the total sales amount per year, categorized by user levels.

Task: `flight_sales:yearly_sales_by_level`

```ruby
rake flight_sales:yearly_sales_by_level
```

#### Description

- Fetches all flight sales sorted by purchase date.
- Populates user purchases and calculates user levels based on purchase history.
- Outputs the results sorted by year and level.
- Logs the execution time for in-memory processing.

### Single SQL Query

This task uses a single SQL query to calculate the total sales amount per year, categorized by user levels.

Task: `flight_sales:yearly_sales_by_level_single_query`

```ruby
rake flight_sales:yearly_sales_by_level_single_query
```

#### Description

- Utilizes SQL window functions and temporary tables to determine user levels.
- Groups the data by year and level to calculate the total sales amount.
- Outputs the results sorted by year and level.
- Logs the execution time for SQL processing.

### Setup and Usage

#### Prerequisites

Ensure you have the following installed:

- Ruby on Rails
- PostgreSQL
- Bundler

#### Installation

1. Clone the repository:

```bash
git clone git@github.com:jdelmazo9/db_performance_test.git
cd flight_sales_performance_comparison
```

2. Install dependencies:

```bash
bundle install
```

3. Setup the database:

```bash
rails db:create
rails db:migrate
```

4. Populate the database with sample data.

```bash
bin/rails db:seed
```

### Running the Tasks

To run the in-memory processing task:

```bash
rake flight_sales:yearly_sales_by_level
```

To run the SQL processing task:

```bash
rake flight_sales:yearly_sales_by_level_single_query
```

### Results

The results of each task will be displayed in the console, including the total sales amount per year and user level, as well as the execution time.

### Contributing

Feel free to contribute to this project by opening issues or submitting pull requests. Contributions are welcome and greatly appreciated!
