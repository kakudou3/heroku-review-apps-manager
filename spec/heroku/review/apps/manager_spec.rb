# frozen_string_literal: true

RSpec.describe Heroku::Review::Apps::Manager do
  it "has a version number" do
    expect(Heroku::Review::Apps::Manager::VERSION).not_to be nil
  end
end
