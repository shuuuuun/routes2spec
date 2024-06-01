# Routes2spec

[![Gem Version](https://badge.fury.io/rb/routes2spec.svg)](https://badge.fury.io/rb/routes2spec)
[![Ruby](https://github.com/shuuuuun/routes2spec/actions/workflows/main.yml/badge.svg)](https://github.com/shuuuuun/routes2spec/actions/workflows/main.yml)

Generate Request specs and Routing specs of RSpec, from your Rails routes config.
It is useful as a test scaffolding.

**Currently does not work with Rails 7.**

## Installation

Add this line to your application's Gemfile:

```ruby
gem "routes2spec", group: :test
```

And then execute:

    $ bundle install

## Usage

This gem depends on the Rails application, so it generates binstubs first.
```sh
$ bundle exec routes2spec --binstubs
# => `bin/routes2spec` will be generated.
```

Then, simply execute the following command to generate the spec files.
```sh
$ bin/routes2spec
```

See help for other options.
```sh
$ bin/routes2spec --help
Usage:
  routes2spec [options]

Options:
  -h, [--help]                   # Show this message.
  -V, [--version]                # Show version.
      [--binstubs]               # Generate binstubs.
  -c, [--controller=CONTROLLER]  # Filter by a specific controller, e.g. PostsController or Admin::PostsController.
  -g, [--grep=GREP]              # Grep routes by a specific pattern.
      [--symbol-status]          # Use symbols for http status.
      [--overwrite]              # Overwrite files even if they exist.
      [--force-overwrite]        # Force overwrite files even if they exist.
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/shuuuuun/routes2spec. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/shuuuuun/routes2spec/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
