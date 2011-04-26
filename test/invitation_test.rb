require File.expand_path('../test_helper', __FILE__)

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

class InvitationTest < Test::Unit::TestCase
  def setup
    @invitation = Invitation.new(:attendees => 'Bassie, Adriaan', :email => 'bassie@caravan.es')
  end

  def teardown
    Invitation.delete_all
    Net::SMTP.reset!
  end

  it "is invalid without any attendees" do
    assert @invitation.valid?
    @invitation.attendees = ''
    assert !@invitation.valid?
  end

  it "is invalid with more vegetarians than attendees" do
    assert @invitation.valid?
    @invitation.vegetarians = 1
    assert @invitation.valid?
    @invitation.vegetarians = 2
    assert @invitation.valid?
    @invitation.vegetarians = 3
    assert !@invitation.valid?
  end

  it "cleans the whitespace between the names" do
    @invitation.attendees = "Bassie, "
    assert_equal 'Bassie', @invitation.attendees
    @invitation.attendees = "Bassie,Adriaan"
    assert_equal 'Bassie, Adriaan', @invitation.attendees
    @invitation.attendees = "  Bassie\t \t,Adriaan   "
    assert_equal 'Bassie, Adriaan', @invitation.attendees
  end

  it "returns a sentence for the list of attendees" do
    assert_equal 'Bassie en Adriaan', @invitation.attendees_sentence
    @invitation.attendees = 'Greet'
    assert_equal 'Greet', @invitation.attendees_sentence
    @invitation.attendees = 'Rini, Sander, Mats, Mila, Nena, Jacky, Yuka'
    assert_equal 'Rini, Sander, Mats, Mila, Nena, Jacky en Yuka', @invitation.attendees_sentence
  end

  it "returns wether or not they will attend at all" do
    assert !@invitation.attending?
    @invitation.attending_wedding = true
    assert @invitation.attending?
    @invitation.attending_party = true
    assert @invitation.attending?
    @invitation.attending_wedding = false
    assert @invitation.attending?
    @invitation.attending_party = false
    assert !@invitation.attending?
  end

  it "ensures that #vegetarians isn't nil" do
    assert_equal 0, @invitation.vegetarians
    @invitation.vegetarians = ''
    assert_equal 0, @invitation.vegetarians
  end

  it "returns the amount of omnivores" do
    assert_equal 2, @invitation.omnivores
    @invitation.vegetarians = 1
    assert_equal 1, @invitation.omnivores
    @invitation.vegetarians = 2
    assert_equal 0, @invitation.omnivores
  end

  it "ensures that attending_party is set if the attendee attends the dinner, but not the reverse" do
    assert !@invitation.attending_party?
    @invitation.update_attributes :attending_dinner => true, :attending_party => false
    assert @invitation.reload.attending_party?
    @invitation.update_attributes :attending_dinner => false
    assert @invitation.reload.attending_party?
  end

  it "sanitizes the email address to not be empty" do
    @invitation.email = ""
    assert_nil @invitation.email
    @invitation.email = "  "
    assert_nil @invitation.email
    @invitation.email = "\t  \n  "
    assert_nil @invitation.email
  end

  it "sends invitation emails to those that have not received one yet and have an email address" do
    invitation1 = Invitation.create!(:attendees => 'Bassie', :email => 'bassie@caravan.es')
    invitation2 = Invitation.create!(:attendees => 'Rogier, Fransje', :email => 'rogier@example.org')
    invitation3 = Invitation.create!(:attendees => 'Tomas, Daphne', :email => 'tomas@example.org', :sent => true)
    invitation4 = Invitation.create!(:attendees => 'Opa, Oma', :email => '')
    Invitation.send_invitations!
    [invitation1, invitation2, invitation3, invitation4].each(&:reload)
    emails = Net::SMTP.sent_emails

    assert_equal 2, emails.size

    assert invitation1.sent?
    assert_equal FROM_EMAIL, emails[0].from
    assert_equal invitation1.email, emails[0].to
    assert emails[0].message.include?("Bassie,")
    assert emails[0].message.include?("http://eloyendionnetrouwen.nl/#{invitation1.id}")

    assert invitation2.sent?
    assert_equal FROM_EMAIL, emails[1].from
    assert_equal invitation2.email, emails[1].to
    assert emails[1].message.include?("Rogier en Fransje,")
    assert emails[1].message.include?("http://eloyendionnetrouwen.nl/#{invitation2.id}")

    assert !invitation4.sent?
  end
end
