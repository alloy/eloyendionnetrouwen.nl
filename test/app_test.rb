require File.expand_path('../test_helper', __FILE__)

class InviteeTest < Test::Unit::TestCase
  it "sees an invitation page" do
    get '/123'
    assert_have_tag 'form[@action="/invitations"][@method=post]' do
      assert_have_tag 'input[@name="attendees"][@value="Bassie, Adriaan"]'
    end
  end
end

