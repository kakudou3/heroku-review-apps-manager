# heroku-review-apps-manager <a href="https://badge.fury.io/rb/heroku-review-apps-manager"><img src="https://badge.fury.io/rb/heroku-review-apps-manager.svg" alt="Gem Version" height="18"></a>

A command-line tool to manage Heroku Review Apps. This gem provides an easy way to list, create, and delete Heroku review apps associated with GitHub pull requests.

## Installation

Install the gem by executing:

```bash
$ gem install heroku-review-apps-manager
```

Or add to your application's Gemfile:

```ruby
gem 'heroku-review-apps-manager'
```

And then execute:

```bash
$ bundle install
```

## Configuration

This tool requires the following environment variables to be set:

### `HEROKU_REVIEW_APPS_MANAGER_HEROKU_API_KEY`

Your Heroku API key for authentication. You can find your API key in your [Heroku Account Settings](https://dashboard.heroku.com/account).

```bash
export HEROKU_REVIEW_APPS_MANAGER_HEROKU_API_KEY=your_heroku_api_key
```

### `HEROKU_REVIEW_APPS_MANAGER_GITHUB_TOKEN`

Your GitHub personal access token (required for creating review apps). You can create a token in your [GitHub Settings](https://github.com/settings/tokens).

```bash
export HEROKU_REVIEW_APPS_MANAGER_GITHUB_TOKEN=your_github_token
```

### `HEROKU_REVIEW_APPS_MANAGER_TARGET_GITHUB_REPOSITORY` (Optional)

The default GitHub repository in the format `org/repo` (e.g., `myorg/myrepo`). This is used as a fallback when the repository is not specified in the `create_app` command.

```bash
export HEROKU_REVIEW_APPS_MANAGER_TARGET_GITHUB_REPOSITORY=myorg/myrepo
```

## Usage

### List review apps

List all review apps for a given pipeline:

```bash
$ heroku-review-apps-manager list_app PIPELINE_NAME
```

With JSON output:

```bash
$ heroku-review-apps-manager list_app PIPELINE_NAME --json
```

### Create a review app

Create a review app for a specific branch and pull request:

```bash
$ heroku-review-apps-manager create_app PIPELINE_NAME BRANCH [REPOSITORY]
```

The `REPOSITORY` parameter is optional. If not provided, it will use the value from the `HEROKU_REVIEW_APPS_MANAGER_TARGET_GITHUB_REPOSITORY` environment variable. The repository should be in the format `org/repo`.

Example with repository specified:

```bash
$ heroku-review-apps-manager create_app my-pipeline feature-branch myorg/myrepo
```

Example using environment variable:

```bash
$ heroku-review-apps-manager create_app my-pipeline feature-branch
```

With JSON output:

```bash
$ heroku-review-apps-manager create_app PIPELINE_NAME BRANCH [REPOSITORY] --json
```

### Delete a review app

Delete a review app for a specific branch:

```bash
$ heroku-review-apps-manager delete_app PIPELINE_NAME BRANCH
```

Example:

```bash
$ heroku-review-apps-manager delete_app my-pipeline feature-branch
```

With JSON output:

```bash
$ heroku-review-apps-manager delete_app PIPELINE_NAME BRANCH --json
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/kakudou3/heroku-review-apps-manager. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/kakudou3/heroku-review-apps-manager/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the heroku-review-apps-manager project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/kakudou3/heroku-review-apps-manager/blob/main/CODE_OF_CONDUCT.md).

## Author

kakudooo <kakudou3@gmail.com>
