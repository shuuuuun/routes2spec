# frozen_string_literal: true

require "isolation/abstract_unit"

RSpec.describe Routes2spec::Command do
  include TestHelpers::Paths
  include TestHelpers::Generation

  before { build_app }
  after { teardown_app }

  describe "binstubs" do
    subject { run_command(%w[bundle exec routes2spec --binstubs]) }
    before { subject }
    it { expect(File.exist?(app_path("bin/routes2spec"))).to be true }
    it { expect(File.executable?(app_path("bin/routes2spec"))).to be true }
    it { expect(File.read(app_path("bin/routes2spec"))).to eq(File.read("lib/routes2spec/binstubs/routes2spec")) }
  end

  describe "regular usage" do
    before do
      app_file "config/routes.rb", <<-RUBY
        Rails.application.routes.draw do
          resource :post
          resource :user_permission
        end
      RUBY

      run_command(%w[bundle exec routes2spec --binstubs])
    end

    it do
      run_routes_command
      expect(File.read(app_path("spec/requests/posts_spec.rb"))).to eq(<<~OUTPUT)
        require "rails_helper"

        RSpec.describe "Posts", type: :request do

          describe "GET /post/new" do
            it "works!" do
              get new_post_path
              expect(response).to have_http_status(200)
            end
          end

          describe "GET /post/edit" do
            it "works!" do
              get edit_post_path
              expect(response).to have_http_status(200)
            end
          end

          describe "GET /post" do
            it "works!" do
              get post_path
              expect(response).to have_http_status(200)
            end
          end

          describe "PATCH /post" do
            it "works!" do
              patch post_path
              expect(response).to have_http_status(200)
            end
          end

          describe "PUT /post" do
            it "works!" do
              put post_path
              expect(response).to have_http_status(200)
            end
          end

          describe "DELETE /post" do
            it "works!" do
              delete post_path
              expect(response).to have_http_status(204)
            end
          end

          describe "POST /post" do
            it "works!" do
              post post_path
              expect(response).to have_http_status(201)
            end
          end

        end
      OUTPUT
    end

    it do
      run_routes_command
      expect(File.read(app_path("spec/requests/user_permissions_spec.rb"))).to eq(<<~OUTPUT)
        require "rails_helper"

        RSpec.describe "UserPermissions", type: :request do

          describe "GET /user_permission/new" do
            it "works!" do
              get new_user_permission_path
              expect(response).to have_http_status(200)
            end
          end

          describe "GET /user_permission/edit" do
            it "works!" do
              get edit_user_permission_path
              expect(response).to have_http_status(200)
            end
          end

          describe "GET /user_permission" do
            it "works!" do
              get user_permission_path
              expect(response).to have_http_status(200)
            end
          end

          describe "PATCH /user_permission" do
            it "works!" do
              patch user_permission_path
              expect(response).to have_http_status(200)
            end
          end

          describe "PUT /user_permission" do
            it "works!" do
              put user_permission_path
              expect(response).to have_http_status(200)
            end
          end

          describe "DELETE /user_permission" do
            it "works!" do
              delete user_permission_path
              expect(response).to have_http_status(204)
            end
          end

          describe "POST /user_permission" do
            it "works!" do
              post user_permission_path
              expect(response).to have_http_status(201)
            end
          end

        end
      OUTPUT
    end
  end

  private

  def run_routes_command(args = [])
    run_command "bin/routes2spec", args
  end

  # def run_command(cmd, args = [])
  def run_command(*args, allow_failure: false, stderr: false)
    args = args.flatten
    # puts "args: #{args}"
    # command = "#{cmd} #{Shellwords.join args}#{' 2>&1' unless stderr}"
    command = "#{Shellwords.join args}#{' 2>&1' unless stderr}"
    output = `cd #{app_path}; #{command}`

    raise "command failed (#{$?.exitstatus}): #{command}\n#{output}" unless allow_failure || $?.success?

    output
  end
end
