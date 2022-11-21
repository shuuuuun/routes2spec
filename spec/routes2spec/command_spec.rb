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

    describe "controller option" do
      # subject { run_routes_command(options) }
      # let(:options) { nil }
      # before { subject }

      it do
        # binding.irb
        run_routes_command(["-c", "PostController"])
        expect(File.exist?(app_path("spec/requests/posts_spec.rb"))).to be true
        expect(File.exist?(app_path("spec/requests/user_permissions_spec.rb"))).to be false
      end

      it do
        run_routes_command(["-c", "UserPermissionController"])
        expect(File.exist?(app_path("spec/requests/posts_spec.rb"))).to be false
        expect(File.exist?(app_path("spec/requests/user_permissions_spec.rb"))).to be true
      end
    end

    describe "grep option" do
      it do
        run_routes_command(["-g", "Post"])
        expect(File.exist?(app_path("spec/requests/posts_spec.rb"))).to be true
        expect(File.exist?(app_path("spec/requests/user_permissions_spec.rb"))).to be false
      end

      it do
        run_routes_command(["-g", "UserPermission"])
        expect(File.exist?(app_path("spec/requests/posts_spec.rb"))).to be false
        expect(File.exist?(app_path("spec/requests/user_permissions_spec.rb"))).to be true
      end
    end

    describe "symbol_status option" do
      before do
        run_routes_command("--symbol-status")
      end
      it do
        # TODO: symbolになってるかどうか
      end
    end

    describe "overwrite option" do
      before do
        # 事前にファイルを作る
        FileUtils.mkdir_p(app_path("spec/requests"))
        FileUtils.touch(app_path("spec/requests/posts_spec.rb"))
      end

      context "yes" do
        before do
          allow($stdin).to receive(:gets).and_return("y\n")
          # $stdin = StringIO.new("y\n")
          binding.irb
          run_routes_command("--overwrite")
          # run_routes_command("--overwrite", stderr: true)
          # y 入力
          # $stdin.gets.chomp
          # $stdin = STDIN
        end
        it do
          # 事前にあったファイルが上書きされてること
          expect(File.exist?(app_path("spec/requests/posts_spec.rb"))).to be true
          expect(File.read(app_path("spec/requests/posts_spec.rb"))).not_to be_empty
        end
        it do
          # 事前になかったファイルは普通に作成されてること
          expect(File.exist?(app_path("spec/requests/user_permissions_spec.rb"))).to be true
        end
      end

      context "no" do
        before do
          allow($stdin).to receive(:gets).and_return("n\n")
          run_routes_command("--overwrite")
          # n 入力
        end
        it do
          # 事前にあったファイルが上書きされてないこと
          expect(File.exist?(app_path("spec/requests/posts_spec.rb"))).to be true
          expect(File.read(app_path("spec/requests/posts_spec.rb"))).not_to be_empty
        end
        it do
          # 事前になかったファイルは普通に作成されてること
          expect(File.exist?(app_path("spec/requests/user_permissions_spec.rb"))).to be true
        end
      end

      context "quit" do
        before do
          allow($stdin).to receive(:gets).and_return("q\n")
          run_routes_command("--overwrite")
        end
        it do
          expect(File.exist?(app_path("spec/requests/posts_spec.rb"))).to be true
          expect(File.read(app_path("spec/requests/posts_spec.rb"))).not_to be_empty
        end
        it do
          expect(File.exist?(app_path("spec/requests/user_permissions_spec.rb"))).to be true
        end
      end
    end

    describe "force_overwrite option" do
      before do
        # 事前にファイルを作る
        FileUtils.mkdir_p(app_path("spec/requests"))
        FileUtils.touch(app_path("spec/requests/posts_spec.rb"))
        # File.write(app_path("spec/requests/posts_spec.rb"), "hoge")

        run_routes_command("--force-overwrite")
      end
      it do
        # 事前にあったファイルが上書きされてること
        expect(File.exist?(app_path("spec/requests/posts_spec.rb"))).to be true
        # expect(File.read(app_path("spec/requests/posts_spec.rb"))).not_to eq("hoge")
        expect(File.read(app_path("spec/requests/posts_spec.rb"))).not_to be_empty
      end
      it do
        # 事前になかったファイルは普通に作成されてること
        expect(File.exist?(app_path("spec/requests/user_permissions_spec.rb"))).to be true
      end
    end
  end

  private

  def run_routes_command(args = [])
    run_command "bin/routes2spec", args
  end

  def run_command(*args, allow_failure: false, stderr: false)
    args = args.flatten
    command = "#{Shellwords.join args}#{' 2>&1' unless stderr}"
    output = `cd #{app_path}; #{command}`

    raise "command failed (#{$?.exitstatus}): #{command}\n#{output}" unless allow_failure || $?.success?

    output
  end
end
