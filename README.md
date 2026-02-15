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

### `HEROKU_REVIEW_APPS_MANAGER_PIPELINE_NAME` (Optional)

The default Heroku pipeline name. This is used as a fallback when the pipeline name is not specified in commands.

```bash
export HEROKU_REVIEW_APPS_MANAGER_PIPELINE_NAME=my-pipeline
```

### `HEROKU_REVIEW_APPS_MANAGER_TARGET_GITHUB_REPOSITORY` (Optional)

The default GitHub repository in the format `org/repo` (e.g., `myorg/myrepo`). This is used as a fallback when the repository is not specified in the `create-app` command.

```bash
export HEROKU_REVIEW_APPS_MANAGER_TARGET_GITHUB_REPOSITORY=myorg/myrepo
```

## Usage

### List review apps

List all review apps for a given pipeline:

```bash
$ heroku-review-apps-manager list-app [PIPELINE_NAME]
```

The `PIPELINE_NAME` parameter is optional. If not provided, it will use the value from the `HEROKU_REVIEW_APPS_MANAGER_PIPELINE_NAME` environment variable.

With JSON output:

```bash
$ heroku-review-apps-manager list-app [PIPELINE_NAME] --json
```

### Create a review app

Create a review app for a specific branch and pull request:

```bash
$ heroku-review-apps-manager create-app BRANCH [PIPELINE_NAME] [REPOSITORY]
```

The `PIPELINE_NAME` parameter is optional. If not provided, it will use the value from the `HEROKU_REVIEW_APPS_MANAGER_PIPELINE_NAME` environment variable.

The `REPOSITORY` parameter is optional. If not provided, it will use the value from the `HEROKU_REVIEW_APPS_MANAGER_TARGET_GITHUB_REPOSITORY` environment variable. The repository should be in the format `org/repo`.

Example with all parameters specified:

```bash
$ heroku-review-apps-manager create-app feature-branch my-pipeline myorg/myrepo
```

Example using environment variables:

```bash
$ heroku-review-apps-manager create-app feature-branch
```

With JSON output:

```bash
$ heroku-review-apps-manager create-app BRANCH [PIPELINE_NAME] [REPOSITORY] --json
```

### List review app formations

List formation info for a review app by branch:

```bash
$ heroku-review-apps-manager list-formation BRANCH [PIPELINE_NAME]
```

The `PIPELINE_NAME` parameter is optional. If not provided, it will use the value from the `HEROKU_REVIEW_APPS_MANAGER_PIPELINE_NAME` environment variable.

With JSON output:

```bash
$ heroku-review-apps-manager list-formation BRANCH [PIPELINE_NAME] --json
```

### Update review app formation quantity

Update formation quantity (default process type is `web`) for a review app by branch:

```bash
$ heroku-review-apps-manager update-formation BRANCH [PIPELINE_NAME] --quantity QUANTITY
```

The `PIPELINE_NAME` parameter is optional. If not provided, it will use the value from the `HEROKU_REVIEW_APPS_MANAGER_PIPELINE_NAME` environment variable.
The `--formation-type` option is optional. If not provided, it defaults to `web`.
The `--quantity` option is optional. If not provided, it defaults to `1`.

With JSON output:

```bash
$ heroku-review-apps-manager update-formation BRANCH [PIPELINE_NAME] --quantity QUANTITY --json
```

Specify formation type:

```bash
$ heroku-review-apps-manager update-formation BRANCH [PIPELINE_NAME] --quantity QUANTITY --formation-type worker
```

### Delete a review app

Delete a review app for a specific branch:

```bash
$ heroku-review-apps-manager delete-app BRANCH [PIPELINE_NAME]
```

The `PIPELINE_NAME` parameter is optional. If not provided, it will use the value from the `HEROKU_REVIEW_APPS_MANAGER_PIPELINE_NAME` environment variable.

Example with pipeline name specified:

```bash
$ heroku-review-apps-manager delete-app feature-branch my-pipeline
```

Example using environment variable:

```bash
$ heroku-review-apps-manager delete-app feature-branch
```

With JSON output:

```bash
$ heroku-review-apps-manager delete-app BRANCH [PIPELINE_NAME] --json
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
