require File.expand_path('../test_helper', __FILE__)

class InviteeTest < Test::Unit::TestCase
  it "sees an invitation page" do
    get '/123'
    assert_have_tag 'form[@action="/invitations"]'
  end
end

