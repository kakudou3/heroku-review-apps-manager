# frozen_string_literal: true

require_relative "manager/version"
require_relative "manager/cli"

module Heroku
  module Review
    module Apps
      module Manager
        class Error < StandardError; end
      end
    end
  end
end
