## 1.1.0 (2025-01-20)

* Rails 8.0, Ruby 3.4 support.

* Fixed gemspec to include minimum files in packed gem. (#91 by @ybiquitous)

* Added support for trilogy adapter. (#90 by @hirocaster)

* Fixed NoMethodError `ConnectionPool#connection` on Rails 8.0. (#93 by kucho)

* Fixed a bug recording table names to a wrong cleaner when using the same database name on different hosts. (#68 by sinsoku)


## 1.0.1 (2024-02-27)

* Fixed a warning on AR < 7.1 && mysql. Also, fixed an unnecessary reference to `Rails` constant for non-Rails apps. (#88 by @onk)
