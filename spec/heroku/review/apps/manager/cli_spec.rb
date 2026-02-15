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
      ENV["NO_COLOR"] = "true"
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
        end.to output("Pipleline does not exists.\n").to_stderr
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
        end.to output("Pipleline does not exists.\n").to_stderr
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
        end.to output("Review app not exists.\n").to_stderr
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
        end.to output("Review app already exists.\n").to_stderr
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
        end.to output("Review app was changed to errored status.\n").to_stderr
      end
    end

    context "when review app was changed to created status" do
      let(:source_blob_url) do
        "https://github-cloud.s3.amazonaws.com/fake.tar.gz"
      end
      let(:pipeline_app_id) { SecureRandom.uuid }
      let(:app_name) { "dummy" }
      let(:web_url) { "https://#{app_name}.heroku.com" }
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
            name: app_name,
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

        allow(Whirly).to receive(:configure)
        allow(Whirly).to receive(:start) do |*_args, &block|
          block&.call
          nil
        end
        allow(Whirly).to receive(:stop)
        allow(Whirly).to receive(:status=)
      end

      it "displays application info" do
        result = {
          url: web_url,
          name: app_name,
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

  describe "#list_formation" do
    let(:pipeline) { "sample-app" }
    let(:branch) { "feature/add-sample" }
    let(:heroku_api_token) { SecureRandom.hex(20) }
    let(:pipeline_id) { SecureRandom.uuid }
    let(:app_id) { SecureRandom.uuid }
    let(:formation_id) { SecureRandom.uuid }

    before do
      ENV["HEROKU_REVIEW_APPS_MANAGER_HEROKU_API_KEY"] = heroku_api_token
    end

    context "when review app exists" do
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
                      "id" => pipeline_id
                    }.to_json)

        stub_request(
          :get,
          "https://api.heroku.com/pipelines/#{pipeline_id}/review-apps"
        ).with(
          headers: {
            "Accept" => "application/vnd.heroku+json; version=3",
            "Authorization" => "Bearer #{heroku_api_token}"
          }
        ).to_return(status: 200, headers: {
                      "Content-Type" => "application/json"
                    }, body: [
                      {
                        "branch" => branch,
                        "app" => {
                          "id" => app_id
                        }
                      }
                    ].to_json)

        stub_request(
          :get,
          "https://api.heroku.com/apps/#{app_id}/formation"
        ).with(
          headers: {
            "Accept" => "application/vnd.heroku+json; version=3",
            "Authorization" => "Bearer #{heroku_api_token}"
          }
        ).to_return(status: 200, headers: {
                      "Content-Type" => "application/json"
                    }, body: [
                      {
                        "id" => formation_id,
                        "type" => "web",
                        "size" => "standard-1x",
                        "quantity" => 1,
                        "state" => "up"
                      }
                    ].to_json)
      end

      it "displays formation info" do
        expect do
          described_class.new.invoke(:list_formation, [branch, pipeline], { json: true })
        end.to output("#{[{
          "id" => formation_id,
          "type" => "web",
          "size" => "standard-1x",
          "quantity" => 1,
          "state" => "up"
        }].to_json}\n").to_stdout
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
          described_class.new.invoke(:list_formation, [branch, ""], { json: true })
        end.to output("Pipleline does not exists.\n").to_stderr
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
                      "id" => pipeline_id
                    }.to_json)

        stub_request(
          :get,
          "https://api.heroku.com/pipelines/#{pipeline_id}/review-apps"
        ).with(
          headers: {
            "Accept" => "application/vnd.heroku+json; version=3",
            "Authorization" => "Bearer #{heroku_api_token}"
          }
        ).to_return(status: 200, headers: {
                      "Content-Type" => "application/json"
                    }, body: [].to_json)
      end

      it "displays a error message" do
        expect do
          described_class.new.invoke(:list_formation, [branch, pipeline], { json: true })
        end.to output("Review app not exists.\n").to_stderr
      end
    end
  end

  describe "#update_formation" do
    let(:pipeline) { "sample-app" }
    let(:branch) { "feature/add-sample" }
    let(:quantity) { 2 }
    let(:formation_type) { "web" }
    let(:heroku_api_token) { SecureRandom.hex(20) }
    let(:pipeline_id) { SecureRandom.uuid }
    let(:app_id) { SecureRandom.uuid }
    let(:formation_id) { SecureRandom.uuid }

    before do
      ENV["HEROKU_REVIEW_APPS_MANAGER_HEROKU_API_KEY"] = heroku_api_token
    end

    context "when review app exists" do
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
                      "id" => pipeline_id
                    }.to_json)

        stub_request(
          :get,
          "https://api.heroku.com/pipelines/#{pipeline_id}/review-apps"
        ).with(
          headers: {
            "Accept" => "application/vnd.heroku+json; version=3",
            "Authorization" => "Bearer #{heroku_api_token}"
          }
        ).to_return(status: 200, headers: {
                      "Content-Type" => "application/json"
                    }, body: [
                      {
                        "branch" => branch,
                        "app" => {
                          "id" => app_id
                        }
                      }
                    ].to_json)

        stub_request(
          :patch,
          "https://api.heroku.com/apps/#{app_id}/formation/#{formation_type}"
        ).with(
          headers: {
            "Accept" => "application/vnd.heroku+json; version=3",
            "Authorization" => "Bearer #{heroku_api_token}",
            "Content-Type" => "application/json"
          },
          body: {
            quantity: quantity
          }.to_json
        ).to_return(status: 200, headers: {
                      "Content-Type" => "application/json"
                    }, body: {
                      "id" => formation_id,
                      "type" => formation_type,
                      "size" => "standard-1x",
                      "quantity" => quantity,
                      "state" => "up"
                    }.to_json)
      end

      it "updates formation info" do
        expect do
          described_class.new.invoke(:update_formation, [branch, pipeline], { json: true, quantity: quantity })
        end.to output("#{{
          "id" => formation_id,
          "type" => formation_type,
          "size" => "standard-1x",
          "quantity" => quantity,
          "state" => "up"
        }.to_json}\n").to_stdout
      end

      context "when quantity is omitted and provided by option default" do
        let(:quantity) { 1 }

        it "updates formation with default quantity 1" do
          expect do
            described_class.new.invoke(:update_formation, [branch, pipeline], { json: true })
          end.to output("#{{
            "id" => formation_id,
            "type" => formation_type,
            "size" => "standard-1x",
            "quantity" => quantity,
            "state" => "up"
          }.to_json}\n").to_stdout
        end
      end

      context "when formation type is specified" do
        let(:formation_type) { "worker" }

        it "updates specified formation type" do
          expect do
            described_class.new.invoke(:update_formation, [branch, pipeline],
                                       { json: true, formation_type: formation_type, quantity: quantity })
          end.to output("#{{
            "id" => formation_id,
            "type" => formation_type,
            "size" => "standard-1x",
            "quantity" => quantity,
            "state" => "up"
          }.to_json}\n").to_stdout
        end
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
          described_class.new.invoke(:update_formation, [branch, ""], { json: true, quantity: quantity })
        end.to output("Pipleline does not exists.\n").to_stderr
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
                      "id" => pipeline_id
                    }.to_json)

        stub_request(
          :get,
          "https://api.heroku.com/pipelines/#{pipeline_id}/review-apps"
        ).with(
          headers: {
            "Accept" => "application/vnd.heroku+json; version=3",
            "Authorization" => "Bearer #{heroku_api_token}"
          }
        ).to_return(status: 200, headers: {
                      "Content-Type" => "application/json"
                    }, body: [].to_json)
      end

      it "displays a error message" do
        expect do
          described_class.new.invoke(:update_formation, [branch, pipeline], { json: true, quantity: quantity })
        end.to output("Review app not exists.\n").to_stderr
      end
    end

    context "when formation does not exist" do
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
                      "id" => pipeline_id
                    }.to_json)

        stub_request(
          :get,
          "https://api.heroku.com/pipelines/#{pipeline_id}/review-apps"
        ).with(
          headers: {
            "Accept" => "application/vnd.heroku+json; version=3",
            "Authorization" => "Bearer #{heroku_api_token}"
          }
        ).to_return(status: 200, headers: {
                      "Content-Type" => "application/json"
                    }, body: [
                      {
                        "branch" => branch,
                        "app" => {
                          "id" => app_id
                        }
                      }
                    ].to_json)

        stub_request(
          :patch,
          "https://api.heroku.com/apps/#{app_id}/formation/#{formation_type}"
        ).with(
          headers: {
            "Accept" => "application/vnd.heroku+json; version=3",
            "Authorization" => "Bearer #{heroku_api_token}",
            "Content-Type" => "application/json"
          },
          body: {
            quantity: quantity
          }.to_json
        ).to_return(status: 404, headers: {
                      "Content-Type" => "application/json"
                    })
      end

      it "displays a error message" do
        expect do
          described_class.new.invoke(:update_formation, [branch, pipeline], { json: true, quantity: quantity })
        end.to output("Formation not exists.\n").to_stderr
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
