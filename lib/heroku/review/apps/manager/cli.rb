# frozen_string_literal: true

require "heroku/review/apps/manager"
require "thor"
require "platform-api"
require "octokit"
require "cgi"
require "faraday"
require "whirly"

# rubocop:disable Style/Documentation, Metrics/ClassLength, Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
module Heroku
  module Review
    module Apps
      module Manager
        class Cli < Thor
          class << self
            def exit_on_failure?
              true
            end
          end

          desc "list-app", "List all review apps"
          option :json, type: :boolean, default: false
          def list_app(pipeline_name = nil)
            pipeline_name ||= ENV["HEROKU_REVIEW_APPS_MANAGER_PIPELINE_NAME"]
            platform_api = PlatformAPI.connect_oauth(ENV["HEROKU_REVIEW_APPS_MANAGER_HEROKU_API_KEY"])

            begin
              pipeline = platform_api.pipeline.info(pipeline_name)
            rescue Excon::Error::NotFound
              say_error "Pipleline does not exists.", Thor::Shell::Color::RED and return
            end

            result = platform_api.review_app.list(pipeline["id"])

            if options[:json]
              output_as_json(result)
            else
              headers = %w[ID PR Branch Status]
              body = result.map do |app|
                [app["id"], "##{app["pr_number"]}", app["branch"], app["status"]]
              end
              print_table([
                            headers,
                            *body
                          ])
            end
          end

          desc "delete-app", "Delete review app"
          option :json, type: :boolean, default: false
          def delete_app(branch, pipeline_name = nil)
            pipeline_name ||= ENV["HEROKU_REVIEW_APPS_MANAGER_PIPELINE_NAME"]
            platform_api = PlatformAPI.connect_oauth(ENV["HEROKU_REVIEW_APPS_MANAGER_HEROKU_API_KEY"])

            begin
              pipeline = platform_api.pipeline.info(pipeline_name)
            rescue Excon::Error::NotFound
              say_error "Pipleline does not exists.", Thor::Shell::Color::RED and return
            end

            begin
              apps = platform_api.review_app.list(pipeline["id"])
            rescue Excon::Error::NotFound
              say_error "Review app not exists.", Thor::Shell::Color::RED and return
            end

            app = apps.filter { |app| app["branch"] == branch }.first

            say_error "Review app not exists.", Thor::Shell::Color::RED and return if app.nil?

            result = platform_api.review_app.delete(app["id"])

            if options[:json]
              output_as_json(result)
            else
              headers = %w[ID PR Branch]
              body = [result["id"], "##{result["pr_number"]}", result["branch"]]
              print_table([
                            headers,
                            body
                          ])
            end
          end

          desc "create-app", "Create review app"
          option :json, type: :boolean, default: false
          def create_app(branch, pipeline_name = nil, repository = nil)
            Whirly.configure(spinner: "dots", stream: $stderr)

            platform_api = PlatformAPI.connect_oauth(ENV["HEROKU_REVIEW_APPS_MANAGER_HEROKU_API_KEY"])
            octokit = Octokit::Client.new(access_token: ENV["HEROKU_REVIEW_APPS_MANAGER_GITHUB_TOKEN"])
            pipeline_name ||= ENV["HEROKU_REVIEW_APPS_MANAGER_PIPELINE_NAME"]
            repository ||= ENV["HEROKU_REVIEW_APPS_MANAGER_TARGET_GITHUB_REPOSITORY"]
            org = repository.split("/").first

            pipeline = platform_api.pipeline.info(pipeline_name)
            pipeline_id = pipeline["id"]

            github_archive_link = octokit.archive_link(repository, ref: branch)

            pull_requests = octokit.pull_requests(
              repository,
              state: "all",
              head: "#{org}:#{branch}"
            )
            pull_request = pull_requests.first

            apps = platform_api.review_app.list(pipeline_id)
            app = apps.filter { |app| app["branch"] == branch }.first

            say_error "Review app already exists.", Thor::Shell::Color::YELLOW and return unless app.nil?

            begin
              review_app = platform_api.review_app.create(
                branch: branch,
                pipeline: pipeline_id,
                source_blob: { url: github_archive_link, version: "v1.0.0" },
                pr_number: pull_request[:number]
              )
            rescue Excon::Error::Conflict
              say_error "Review app already exists.", Thor::Shell::Color::YELLOW and return
            end

            last_status = nil
            Whirly.start
            begin
              loop do
                review_app = platform_api.review_app.get_review_app(review_app["id"])

                if %w[created errored].include?(review_app["status"])
                  last_status = review_app["status"]
                  Whirly.status = "Status: #{review_app["status"]}"
                  break
                else
                  Whirly.status = "Status: #{review_app["status"]}"
                end

                sleep 30
              end
            ensure
              Whirly.stop
            end

            if last_status == "errored"
              say_error "Review app was changed to errored status.",
                        Thor::Shell::Color::RED and return
            end

            app_id = review_app["app"]["id"]
            app_info = platform_api.app.info(app_id)

            config_vars = platform_api.config_var.info_for_app(app_id)
            database_url = config_vars["DATABASE_URL"]
            uri = URI.parse(database_url)

            if options[:json]
              result = {
                url: app_info["web_url"],
                name: app_info["name"],
                db: {
                  host: uri.host,
                  port: uri.port,
                  name: uri.path[1..],
                  user: uri.user,
                  password: uri.password
                }
              }
              output_as_json(result)
            else
              print_table([
                            ["URL", "Name", "DB Host", "DB Port", "DB Name", "DB User",
                             "DB Password", "DB Scheme"],
                            [
                              app_info["web_url"], app_info["name"], uri.host, uri.port, uri.path[1..], uri.user,
                              uri.password, uri.scheme
                            ]
                          ])

            end
          end

          private

          def output_as_json(result)
            $stdout.puts result.to_json
          end
        end
      end
    end
  end
end
# rubocop:enable Style/Documentation, Metrics/ClassLength, Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
