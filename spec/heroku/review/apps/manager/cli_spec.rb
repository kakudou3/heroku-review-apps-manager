# frozen_string_literal: true

require "securerandom"
require "erb"

# rubocop:disable Metrics/BlockLength
RSpec.describe Heroku::Review::Apps::Manager::Cli do
  describe "#list_app" do
    let(:pipeline) { "sample-app" }
    let(:heroku_api_token) { SecureRandom.hex(20) }
    let(:app_id) { SecureRandom.uuid }

    before do
      ENV["HEROKU_REVIEW_APPS_MANAGER_HEROKU_API_KEY"] = heroku_api_token
    end

    context "when review app exists" do
      before do
        stub_request(:get, "https://api.heroku.com/pipelines/#{pipeline}").with(
          headers: {
            "Accept" => "application/vnd.heroku+json; version=3",
            "Authorization" => "Bearer #{heroku_api_token}"
          }
        ).to_return(status: 200, headers: {
                      "Content-Type" => "application/json"
                    }, body: {
                      "id" => app_id
                    }.to_json)

        stub_request(:get, "https://api.heroku.com/pipelines/#{app_id}/review-apps").with(
          headers: {
            "Accept" => "application/vnd.heroku+json; version=3",
            "Authorization" => "Bearer #{heroku_api_token}"
          }
        ).to_return(status: 200, headers: {
                      "Content-Type" => "application/json"
                    }, body: [{
                      "app" => {
                        "id" => app_id
                      }
                    }].to_json)
      end

      it "displays review apps" do
        expect do
          described_class.new.invoke(:list_app, [pipeline], { json: true })
        end.to output("#{[{ "app" => { "id" => app_id } }].to_json}\n").to_stdout
      end
    end

    context "when review app does not exists" do
      before do
        stub_request(:get, "https://api.heroku.com/pipelines/").with(
          headers: {
            "Accept" => "application/vnd.heroku+json; version=3",
            "Authorization" => "Bearer #{heroku_api_token}"
          }
        ).to_return(status: 404, headers: {
                      "Content-Type" => "application/json"
                    })
      end

      it "displays a error message" do
        expect do
          described_class.new.invoke(:list_app, [""], { json: true })
        end.to output("Pipleline does not exists.\n").to_stdout
      end
    end
  end

  describe "#delete_app" do
    let(:pipeline) { "sample-app" }
    let(:branch) { "feature/add-sample" }
    let(:heroku_api_token) { SecureRandom.hex(20) }
    let(:app_id) { SecureRandom.uuid }
    let(:pr_number) { 10 }

    before do
      ENV["HEROKU_REVIEW_APPS_MANAGER_HEROKU_API_KEY"] = heroku_api_token
    end

    context "when review app exists" do
      before do
        @request_pipeline_stub = stub_request(
          :get,
          "https://api.heroku.com/pipelines/#{pipeline}"
        ).with(
          headers: {
            "Accept" => "application/vnd.heroku+json; version=3",
            "Authorization" => "Bearer #{heroku_api_token}"
          }
        ).to_return(status: 200, headers: {
                      "Content-Type" => "application/json"
                    }, body: {
                      "id" => app_id
                    }.to_json)

        @request_pipeline_review_apps_stub = stub_request(
          :get,
          "https://api.heroku.com/pipelines/#{app_id}/review-apps"
        ).with(
          headers: {
            "Accept" => "application/vnd.heroku+json; version=3",
            "Authorization" => "Bearer #{heroku_api_token}"
          }
        ).to_return(status: 200, headers: {
                      "Content-Type" => "application/json"
                    }, body: [
                      {
                        "id" => app_id,
                        "branch" => branch
                      }
                    ].to_json)

        @request_pipeline_review_apps_stub = stub_request(
          :delete,
          "https://api.heroku.com/review-apps/#{app_id}"
        ).with(
          headers: {
            "Accept" => "application/vnd.heroku+json; version=3",
            "Authorization" => "Bearer #{heroku_api_token}"
          }
        ).to_return(status: 200, headers: {
                      "Content-Type" => "application/json"
                    }, body: {
                      "app" => {
                        "id": app_id,
                        "branch": branch,
                        "pr_number": pr_number
                      }
                    }.to_json)
      end

      it "displays a deleted review app" do
        expect { described_class.new.invoke(:delete_app, [branch, pipeline], { json: true }) }.to output("#{{
          "app" => {
            "id" => app_id,
            "branch" => branch,
            "pr_number" => pr_number
          }
        }.to_json}\n").to_stdout
      end
    end

    context "when pipeline does not exist" do
      before do
        stub_request(
          :get,
          "https://api.heroku.com/pipelines/"
        ).with(
          headers: {
            "Accept" => "application/vnd.heroku+json; version=3",
            "Authorization" => "Bearer #{heroku_api_token}"
          }
        ).to_return(status: 404, headers: {
                      "Content-Type" => "application/json"
                    })
      end

      it "displays a error message" do
        expect do
          described_class.new.invoke(:delete_app, [branch, ""], { json: true })
        end.to output("Pipleline does not exists.\n").to_stdout
      end
    end

    context "when review app does not exist" do
      before do
        stub_request(
          :get,
          "https://api.heroku.com/pipelines/#{pipeline}"
        ).with(
          headers: {
            "Accept" => "application/vnd.heroku+json; version=3",
            "Authorization" => "Bearer #{heroku_api_token}"
          }
        ).to_return(status: 200, headers: {
                      "Content-Type" => "application/json"
                    }, body: {
                      "id" => app_id
                    }.to_json)

        stub_request(
          :get,
          "https://api.heroku.com/pipelines/#{app_id}/review-apps"
        ).with(
          headers: {
            "Accept" => "application/vnd.heroku+json; version=3",
            "Authorization" => "Bearer #{heroku_api_token}"
          }
        ).to_return(status: 404, headers: {
                      "Content-Type" => "application/json"
                    }, body: [].to_json)
      end

      it "displays a error message" do
        expect do
          described_class.new.invoke(:delete_app, [branch, pipeline])
        end.to output("Review app not exists.\n").to_stdout
      end
    end
  end

  describe "#create_app" do
    let(:pipeline) { "sample-app" }
    let(:pipeline_id) { SecureRandom.uuid }
    let(:branch) { "feature/add-sample" }
    let(:heroku_api_token) { SecureRandom.hex(20) }
    let(:app_id) { SecureRandom.uuid }
    let(:pr_number) { 10 }
    let(:repository) { "sample/app" }

    before do
      ENV["HEROKU_REVIEW_APPS_MANAGER_HEROKU_API_KEY"] = heroku_api_token
      ENV["HEROKU_REVIEW_APPS_MANAGER_GITHUB_TOKEN"] = "gh_token"
    end

    context "when Review app exists" do
      before do
        org = repository.split("/").first
        stub_request(
          :get,
          "https://api.heroku.com/pipelines/#{pipeline}"
        ).with(
          headers: {
            "Accept" => "application/vnd.heroku+json; version=3",
            "Authorization" => "Bearer #{heroku_api_token}"
          }
        ).to_return(status: 200, headers: {
                      "Content-Type" => "application/json"
                    }, body: {
                      "id" => pipeline_id
                    }.to_json)

        stub_request(
          :head,
          "https://api.github.com/repos/#{repository}/tarball/#{ERB::Util.url_encode(branch)}"
        ).to_return(status: 302, headers: {
                      "Location" => "https://github-cloud.s3.amazonaws.com/fake.tar.gz"
                    })

        stub_request(
          :get,
          "https://api.github.com/repos/#{repository}/pulls"
        ).with(
          query: {
            head: "#{org}:#{branch}",
            state: "all"
          }
        ).to_return(
          status: 200,
          body: [
            {
              "id" => pr_number
            }
          ]
        )

        stub_request(
          :get,
          "https://api.heroku.com/pipelines/#{pipeline_id}/review-apps"
        ).with(
          headers: { "Accept" => "application/vnd.heroku+json; version=3",
                     "Authorization" => "Bearer #{heroku_api_token}" }
        ).to_return(status: 200, headers: {
                      "Content-Type" => "application/json"
                    }, body: [
                      {
                        "branch" => branch
                      }
                    ].to_json)
      end

      it "displays a error message" do
        expect do
          described_class.new.invoke(:create_app, [branch, pipeline, repository], { json: true })
        end.to output("Review app already exists.\n").to_stdout
      end
    end

    context "when review app was changed to errored status" do
      let(:source_blob_url) do
        "https://github-cloud.s3.amazonaws.com/fake.tar.gz"
      end
      before do
        org = repository.split("/").first
        stub_request(
          :get,
          "https://api.heroku.com/pipelines/#{pipeline}"
        ).with(
          headers: {
            "Accept" => "application/vnd.heroku+json; version=3",
            "Authorization" => "Bearer #{heroku_api_token}"
          }
        ).to_return(status: 200, headers: {
                      "Content-Type" => "application/json"
                    }, body: {
                      "id" => pipeline_id
                    }.to_json)

        stub_request(
          :head,
          "https://api.github.com/repos/#{repository}/tarball/#{ERB::Util.url_encode(branch)}"
        ).to_return(status: 302, headers: {
                      "Location" => source_blob_url
                    })

        stub_request(
          :get,
          "https://api.github.com/repos/#{repository}/pulls"
        ).with(
          query: {
            head: "#{org}:#{branch}",
            state: "all"
          }
        ).to_return(
          status: 200,
          body: [
            {
              number: pr_number
            }
          ]
        )

        stub_request(
          :get,
          "https://api.heroku.com/pipelines/#{pipeline_id}/review-apps"
        ).with(
          headers: { "Accept" => "application/vnd.heroku+json; version=3",
                     "Authorization" => "Bearer #{heroku_api_token}" }
        ).to_return(status: 200, headers: {
                      "Content-Type" => "application/json"
                    }, body: [].to_json)

        stub_request(
          :post,
          "https://api.heroku.com/review-apps"
        ).with(
          headers: {
            "Accept" => "application/vnd.heroku+json; version=3",
            "Content-Type" => "application/json",
            "Authorization" => "Bearer #{heroku_api_token}"
          },
          body: {
            branch: branch,
            pipeline: pipeline_id,
            source_blob: {
              url: source_blob_url,
              version: "v1.0.0"
            },
            pr_number: pr_number
          }.to_json
        ).to_return(
          status: 200,
          headers: {
            "Content-Type" => "application/json"
          },
          body: {
            id: app_id
          }.to_json
        )

        stub_request(
          :get,
          "https://api.heroku.com/review-apps/#{app_id}"
        ).with(
          headers: {
            "Accept" => "application/vnd.heroku+json; version=3",
            "Authorization" => "Bearer #{heroku_api_token}"
          }
        ).to_return(
          status: 200,
          headers: {
            "Content-Type" => "application/json"
          },
          body: {
            status: "errored"
          }.to_json
        )
      end

      it "displays a error message" do
        expect do
          described_class.new.invoke(:create_app, [branch, pipeline, repository], { json: true })
        end.to output(/Review app was changed to errored status\.\n?\z/).to_stdout
      end
    end

    context "when review app was changed to created status" do
      let(:source_blob_url) do
        "https://github-cloud.s3.amazonaws.com/fake.tar.gz"
      end
      let(:pipeline_app_id) { SecureRandom.uuid }
      let(:web_url) { "https://dummy.heroku.com" }
      let(:database_url) { "postgres://dummy_user:dummy_password@localhost:5432/dummy_db" }
      before do
        org = repository.split("/").first
        stub_request(
          :get,
          "https://api.heroku.com/pipelines/#{pipeline}"
        ).with(
          headers: {
            "Accept" => "application/vnd.heroku+json; version=3",
            "Authorization" => "Bearer #{heroku_api_token}"
          }
        ).to_return(status: 200, headers: {
                      "Content-Type" => "application/json"
                    }, body: {
                      "id" => pipeline_id
                    }.to_json)

        stub_request(
          :head,
          "https://api.github.com/repos/#{repository}/tarball/#{ERB::Util.url_encode(branch)}"
        ).to_return(status: 302, headers: {
                      "Location" => source_blob_url
                    })

        stub_request(
          :get,
          "https://api.github.com/repos/#{repository}/pulls"
        ).with(
          query: {
            head: "#{org}:#{branch}",
            state: "all"
          }
        ).to_return(
          status: 200,
          body: [
            {
              number: pr_number
            }
          ]
        )

        stub_request(
          :get,
          "https://api.heroku.com/pipelines/#{pipeline_id}/review-apps"
        ).with(
          headers: { "Accept" => "application/vnd.heroku+json; version=3",
                     "Authorization" => "Bearer #{heroku_api_token}" }
        ).to_return(status: 200, headers: {
                      "Content-Type" => "application/json"
                    }, body: [].to_json)

        stub_request(
          :post,
          "https://api.heroku.com/review-apps"
        ).with(
          headers: {
            "Accept" => "application/vnd.heroku+json; version=3",
            "Content-Type" => "application/json",
            "Authorization" => "Bearer #{heroku_api_token}"
          },
          body: {
            branch: branch,
            pipeline: pipeline_id,
            source_blob: {
              url: source_blob_url,
              version: "v1.0.0"
            },
            pr_number: pr_number
          }.to_json
        ).to_return(
          status: 200,
          headers: {
            "Content-Type" => "application/json"
          },
          body: {
            id: app_id
          }.to_json
        )

        stub_request(
          :get,
          "https://api.heroku.com/review-apps/#{app_id}"
        ).with(
          headers: {
            "Accept" => "application/vnd.heroku+json; version=3",
            "Authorization" => "Bearer #{heroku_api_token}"
          }
        ).to_return(
          status: 200,
          headers: {
            "Content-Type" => "application/json"
          },
          body: {
            status: "created",
            app: {
              id: pipeline_app_id
            }
          }.to_json
        )

        stub_request(
          :get,
          "https://api.heroku.com/apps/#{pipeline_app_id}"
        ).with(
          headers: {
            "Accept" => "application/vnd.heroku+json; version=3",
            "Authorization" => "Bearer #{heroku_api_token}"
          }
        ).to_return(
          status: 200,
          headers: {
            "Content-Type" => "application/json"
          },
          body: {
            web_url: web_url
          }.to_json
        )

        stub_request(
          :get,
          "https://api.heroku.com/apps/#{pipeline_app_id}/config-vars"
        ).with(
          headers: {
            "Accept" => "application/vnd.heroku+json; version=3",
            "Authorization" => "Bearer #{heroku_api_token}"
          }
        ).to_return(
          status: 200,
          headers: {
            "Content-Type" => "application/json"
          },
          body: {
            "DATABASE_URL": database_url
          }.to_json
        )
        @uri = URI.parse(database_url)
      end

      it "displays application info" do
        result = {
          url: web_url,
          db: {
            host: @uri.host,
            port: @uri.port,
            name: @uri.path[1..],
            user: @uri.user,
            password: @uri.password
          }
        }.to_json
        expect do
          described_class.new.invoke(:create_app, [branch, pipeline, repository], { json: true })
        end.to output(/#{result}\n/).to_stdout
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
