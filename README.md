# DatabaseRewinder

[![Build Status](https://travis-ci.org/amatsuda/database_rewinder.svg)](http://travis-ci.org/amatsuda/database\_rewinder)

database\_rewinder is a minimalist's tiny and ultra-fast database cleaner.

## Features

* Cleans up tables via DELETE SQL. No other strategies are implemented ATM
* Supports multiple databases
* Runs extremely fast :dash:

## Why is it fast?

database\_rewinder memorizes every table name into which `INSERT` SQL was performed during each test case.
Then it executes `DELETE` SQL only against these tables when cleaning.
So, the more number of tables you have in your database, the more benefit you will get.

### Credit

This strategy was originally devised and implemented by Shingo Morita (@eudoxa) at COOKPAD Inc.

## Supported versions

* ActiveRecord 3.2, 4.0, 4.1, 4.2

* Ruby 2.0, 2.1, 2.2

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
  config.before :suite do
    DatabaseRewinder.clean_all
    # or
    # DatabaseRewinder.clean_with :any_arg_that_would_be_actually_ignored_anyway
  end

  config.after :each do
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

    # also with a meaning less something first, then {connection: DB_NAME} as the second argument (DatabaseCleaner compatible)
    DatabaseRewinder[:active_record, connection: 'an_active_record_db']

    DatabaseRewinder.clean_all
  end

  config.after(:each) do
    DatabaseRewinder.clean
  end
```

### Pro Tip

database\_rewinder is designed to be almost compatible with database\_cleaner.
So the following code will probably let your existing app work under database\_rewinder without making any change on your configuration.

```ruby
DatabaseCleaner = DatabaseRewinder
```

## TODO

Write documentation and specs about multiple databases.


## Contributing

Send me your pull requests.
