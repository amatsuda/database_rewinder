# DatabaseRewinder

[![Build Status](https://github.com/amatsuda/database_rewinder/actions/workflows/main.yml/badge.svg)](https://github.com/amatsuda/database_rewinder/actions)

database\_rewinder is a minimalist's tiny and ultra-fast database cleaner.

## Features

* Cleans up tables via DELETE SQL. No other strategies are implemented ATM
* Supports multiple databases
* Runs extremely fast :dash:

## Why is it fast?

database\_rewinder memorizes every table name into which `INSERT` SQL was performed during each test case.
Then it executes `DELETE` SQL only against these tables when cleaning.
So, the more number of tables you have in your database, the more benefit you will get.
Also, database\_rewinder joins all `DELETE` SQL statements and casts it in one DB server call.

### Credit

This strategy was originally devised and implemented by Shingo Morita (@eudoxa) at COOKPAD Inc.

## Supported versions

* ActiveRecord 4.2, 5.0, 5.1, 5.2, 6.0, 6.1, 7.0 (edge)

* Ruby 2.4, 2.5, 2.6, 2.7, 3.0, 3.1 (trunk)

## Installation

Add this line to your Gemfile's `:test` group:

    gem 'database_rewinder'

And then execute:

    $ bundle

## Usage

### Basic configuration

Do `clean` in `after(:each)`. And do `clean_all` or `clean_with` in `before(:suite)` if you'd like to.

```ruby
RSpec.configure do |config|
  config.before(:suite) do
    DatabaseRewinder.clean_all
    # or
    # DatabaseRewinder.clean_with :any_arg_that_would_be_actually_ignored_anyway
  end

  config.after(:each) do
    DatabaseRewinder.clean
  end
end
```

### Dealing with multiple DBs

You can configure multiple DB connections to tell DatabaseRewinder to cleanup all of them after each test.
In order to add another connection, use `DatabaseRewinder[]` method.

```ruby
RSpec.configure do |config|
  config.before(:suite) do
    # simply give the DB connection names that are written in config/database.yml
    DatabaseRewinder['test']
    DatabaseRewinder['another_test_db']

    # you could give the DB name with connection: key if you like
    DatabaseRewinder[connection: 'yet_another_test_db']

    # or with a meaningless something first, then {connection: DB_NAME} as the second argument (DatabaseCleaner compatible)
    DatabaseRewinder[:active_record, connection: 'an_active_record_db']

    DatabaseRewinder.clean_all
  end

  config.after(:each) do
    DatabaseRewinder.clean
  end
end
```

### MySQL + use\_transactional\_tests Specific Problems

database\_rewinder tries to create a new DB connection for deletion when you're running tests on MySQL.
You would occasionally hit some weird errors (e.g. query execution timeout) because of this, especially when your tests are run with the `use_transactional_tests` option enabled (which is Rails' default).

#### 1. Properly understand what `use_transactional_tests` means, and consider turning it off

`use_transactional_tests` is the option that surrounds each of your test case with a DB transaction to roll back all your test data after each test run.
So far as this works properly, you won't really need to use database\_rewinder.
However, this simple mechanism doesn't work well when you're running integration tests with capybara + js mode.
In cases of this situation, bundle database\_rewinder and add the following configuration.

```ruby
RSpec.configure do |config|
  config.use_transactional_tests = false

  ...
end
```

#### 2. Cleaning with `multiple: false` option
If you're really sure you need to keep using transactional tests + database\_rewinder for some reason, then explicitly pass in `multiple: false` option to `DatabaseRewinder.clean_all` and `DatabaseRewinder.clean` invocations as follows. Note that you won't be able to get full performance merit that database\_rewinder provides though.

```ruby
RSpec.configure do |config|
  config.before :suite do
    DatabaseRewinder.clean_all multiple: false
  end

  config.after :each do
    DatabaseRewinder.clean multiple: false
  end
end
```

### Pro Tip

database\_rewinder is designed to be almost compatible with database\_cleaner.
So the following code will probably let your existing app work under database\_rewinder without making any change on your configuration.

```ruby
DatabaseCleaner = DatabaseRewinder
```

## Contributing

Send me your pull requests.
