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

  def teardown
    Invitation.delete_all
    Net::SMTP.reset!
  end
end

set :environment, :test

require 'net/smtp'
module Net
  class SMTP
    class Mock
      Email = Struct.new(:message, :from, :to)

      def sent_emails
        @sent_emails ||= []
      end

      def send_message(message, from, to)
        sent_emails << Email.new(message, from, to)
      end
    end

    class << self
      def smtp_mock
        @smtp_mock ||= Mock.new
      end

      def reset!
        @smtp_mock = nil
      end

      def sent_emails
        smtp_mock.sent_emails
      end

      def start(*)
        yield smtp_mock
      end
    end
  end
end
