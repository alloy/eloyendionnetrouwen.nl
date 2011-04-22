require 'rubygems'
require 'sinatra'

set :environment, :test

require File.expand_path('../../app', __FILE__)
require 'test/unit'
require 'rack/test'
require 'webrat'

class Test::Unit::TestCase
  def self.it(description, &block)
    define_method("test: #{description}", &block)
  end

  include Rack::Test::Methods

  include Webrat::Matchers
  include Webrat::HaveTagMatcher

  def response_body
    last_response.body
  end

  def app
    Sinatra::Application
  end
end

set :environment, :test

