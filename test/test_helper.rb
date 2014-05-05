require 'rubygems'
require 'sinatra'

set :environment, :test

$:.unshift File.expand_path('../../', __FILE__)
require 'app'

require 'minitest/autorun'
require 'minitest/reporters'
Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new

require 'rack/test'
require 'webrat'

class MiniTest::Unit::TestCase
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
