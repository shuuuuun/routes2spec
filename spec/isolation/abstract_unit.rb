# frozen_string_literal: true

# Note:
# It is important to keep this file as light as possible
# the goal for tests that require this is to test booting up
# Rails from an empty state, so anything added here could
# hide potential failures
#
# It is also good to know what is the bare minimum to get
# Rails booted up.
require "fileutils"
require "shellwords"

require "bundler/setup" unless defined?(Bundler)
require "active_support"
require "active_support/testing/autorun"
require "active_support/testing/stream"
require "active_support/testing/method_call_assertions"
require "active_support/test_case"

# RAILS_FRAMEWORK_ROOT = File.expand_path("../../..", __dir__)
RAILS_FRAMEWORK_ROOT = File.expand_path("..", __dir__)

# These files do not require any others and are needed
# to run the tests
require "active_support/core_ext/object/blank"
require "active_support/testing/isolation"
require "active_support/core_ext/kernel/reporting"
require "tmpdir"
require "rails/secrets"

module TestHelpers
  module Paths
    def app_template_path
      File.join RAILS_FRAMEWORK_ROOT, "tmp/templates/app_template"
    end

    def bootsnap_cache_path
      File.join RAILS_FRAMEWORK_ROOT, "tmp/templates/bootsnap"
    end

    def tmp_path(*args)
      @tmp_path ||= File.realpath(Dir.mktmpdir(nil, File.join(RAILS_FRAMEWORK_ROOT, "tmp")))
      File.join(@tmp_path, *args)
    end

    def app_path(*args)
      path = tmp_path(*%w[app] + args)
      if block_given?
        yield path
      else
        path
      end
    end

    def framework_path
      RAILS_FRAMEWORK_ROOT
    end

    def rails_root
      app_path
    end
  end

  module Generation
    # Build an application by invoking the generator and going through the whole stack.
    def build_app(options = {})
      @prev_rails_env = ENV["RAILS_ENV"]
      ENV["RAILS_ENV"] = "development"

      FileUtils.rm_rf(app_path)
      FileUtils.cp_r(app_template_path, app_path)

      # Delete the initializers unless requested
      unless options[:initializers]
        Dir["#{app_path}/config/initializers/**/*.rb"].each do |initializer|
          File.delete(initializer)
        end
      end

      routes = File.read("#{app_path}/config/routes.rb")
      if routes =~ /(\n\s*end\s*)\z/
        File.open("#{app_path}/config/routes.rb", "w") do |f|
          f.puts $` + "\nActiveSupport::Deprecation.silence { match ':controller(/:action(/:id))(.:format)', via: :all }\n" + $1
        end
      end

      if options[:multi_db]
        File.open("#{app_path}/config/database.yml", "w") do |f|
          f.puts <<-YAML
          default: &default
            adapter: sqlite3
            pool: 5
            timeout: 5000
            variables:
              statement_timeout: 1000
          development:
            primary:
              <<: *default
              database: db/development.sqlite3
            primary_readonly:
              <<: *default
              database: db/development.sqlite3
              replica: true
            animals:
              <<: *default
              database: db/development_animals.sqlite3
              migrations_paths: db/animals_migrate
            animals_readonly:
              <<: *default
              database: db/development_animals.sqlite3
              migrations_paths: db/animals_migrate
              replica: true
          test:
            primary:
              <<: *default
              database: db/test.sqlite3
            primary_readonly:
              <<: *default
              database: db/test.sqlite3
              replica: true
            animals:
              <<: *default
              database: db/test_animals.sqlite3
              migrations_paths: db/animals_migrate
            animals_readonly:
              <<: *default
              database: db/test_animals.sqlite3
              migrations_paths: db/animals_migrate
              replica: true
          production:
            primary:
              <<: *default
              database: db/production.sqlite3
            primary_readonly:
              <<: *default
              database: db/production.sqlite3
              replica: true
            animals:
              <<: *default
              database: db/production_animals.sqlite3
              migrations_paths: db/animals_migrate
            animals_readonly:
              <<: *default
              database: db/production_animals.sqlite3
              migrations_paths: db/animals_migrate
              replica: true
          YAML
        end
      else
        File.open("#{app_path}/config/database.yml", "w") do |f|
          f.puts <<-YAML
          default: &default
            adapter: sqlite3
            pool: 5
            timeout: 5000
          development:
            <<: *default
            database: db/development.sqlite3
          test:
            <<: *default
            database: db/test.sqlite3
          production:
            <<: *default
            database: db/production.sqlite3
          YAML
        end
      end

      add_to_config <<-RUBY
        config.hosts << proc { true }
        config.eager_load = false
        config.session_store :cookie_store, key: "_myapp_session"
        config.cache_store = :mem_cache_store
        config.active_support.deprecation = :log
        config.action_controller.allow_forgery_protection = false
      RUBY
    end

    def teardown_app
      ENV["RAILS_ENV"] = @prev_rails_env if @prev_rails_env
      FileUtils.rm_rf(tmp_path)
    end

    # Make a very basic app, without creating the whole directory structure.
    # This is faster and simpler than the method above.
    def make_basic_app
      require "rails"
      require "action_controller/railtie"
      require "action_view/railtie"

      @app = Class.new(Rails::Application) do
        def self.name; "RailtiesTestApp"; end
      end
      @app.config.hosts << proc { true }
      @app.config.eager_load = false
      @app.config.session_store :cookie_store, key: "_myapp_session"
      @app.config.active_support.deprecation = :log
      @app.config.log_level = :info
      @app.secrets.secret_key_base = "b3c631c314c0bbca50c1b2843150fe33"

      yield @app if block_given?
      @app.initialize!

      @app.routes.draw do
        get "/" => "omg#index"
      end

      require "rack/test"
      extend ::Rack::Test::Methods
    end

    def simple_controller
      controller :foo, <<-RUBY
        class FooController < ApplicationController
          def index
            render plain: "foo"
          end
        end
      RUBY

      app_file "config/routes.rb", <<-RUBY
        Rails.application.routes.draw do
          get ':controller(/:action)'
        end
      RUBY
    end

    def add_to_config(str)
      environment = File.read("#{app_path}/config/application.rb")
      if environment =~ /(\n\s*end\s*end\s*)\z/
        File.open("#{app_path}/config/application.rb", "w") do |f|
          f.puts $` + "\n#{str}\n" + $1
        end
      end
    end

    def remove_from_config(str)
      remove_from_file("#{app_path}/config/application.rb", str)
    end

    def remove_from_file(file, str)
      contents = File.read(file)
      contents.sub!(/#{str}/, "")
      File.write(file, contents)
    end

    def app_file(path, contents, mode = "w")
      file_name = "#{app_path}/#{path}"
      FileUtils.mkdir_p File.dirname(file_name)
      File.open(file_name, mode) do |f|
        f.puts contents
      end
      file_name
    end

    def app_dir(path)
      FileUtils.mkdir_p("#{app_path}/#{path}")
    end

    def remove_file(path)
      FileUtils.rm_rf "#{app_path}/#{path}"
    end

    def controller(name, contents)
      app_file("app/controllers/#{name}_controller.rb", contents)
    end
  end
end

# Create a scope and build a fixture rails app
Module.new do
  extend TestHelpers::Paths

  def self.sh(cmd)
    output = `#{cmd}`
    raise "Command #{cmd.inspect} failed. Output:\n#{output}" unless $?.success?
  end

  # Build a rails app
  FileUtils.rm_rf(app_template_path)
  FileUtils.mkdir_p(app_template_path)

  # sh "#{Gem.ruby} #{RAILS_FRAMEWORK_ROOT}/railties/exe/rails new #{app_template_path} --skip-bundle --no-rc --quiet"
  # sh "#{Gem.ruby} bundle exec rails new #{app_template_path} --skip-bundle --no-rc --quiet"
  sh "#{Gem.ruby} bin/rails new #{app_template_path} --skip-bundle --no-rc --quiet \
      --skip-git \
      --skip-keeps \
      --skip-action-mailer \
      --skip-action-mailbox \
      --skip-action-text \
      --skip-active-record \
      --skip-active-job \
      --skip-active-storage \
      --skip-action-cable \
      --skip-asset-pipeline \
      --skip-javascript \
      --skip-hotwire \
      --skip-jbuilder \
      --skip-test \
      --skip-system-test \
      --skip-bootsnap"
      # --asset-pipeline=propshaft"
  File.open("#{app_template_path}/config/boot.rb", "w") do |f|
    f.puts 'require "bootsnap/setup" if ENV["BOOTSNAP_CACHE_DIR"]'
    f.puts 'require "rails/all"'
  end

  FileUtils.mkdir_p "#{app_template_path}/app/javascript"
  File.write("#{app_template_path}/app/javascript/application.js", "\n")

  # Fake 'Bundler.require' -- we run using the repo's Gemfile, not an
  # app-specific one: we don't want to require every gem that lists.
  # contents = File.read("#{app_template_path}/config/application.rb")
  # # contents.sub!(/^Bundler\.require.*/, "%w(sprockets/railtie importmap-rails).each { |r| require r }")
  # # contents.sub!(/^Bundler\.require.*/, "require 'propshaft'")
  # contents.sub!(/^Bundler\.require.*/, "")
  # File.write("#{app_template_path}/config/application.rb", contents)

  require "rails"

  require "action_dispatch/routing/route_set"
end unless defined?(RAILS_ISOLATED_ENGINE)
