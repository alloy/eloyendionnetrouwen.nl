require 'config'
require 'helpers'
require 'mailer'

module Mailer
  class Message
    include Helpers

    def initialize(invitation)
      @invitation = invitation
    end

    class Invitation < Message
      def to_s
        @invitation.english? ? english : dutch
      end

      def dutch
<<END_OF_MESSAGE
From: Eloy en Dionne trouwen <#{FROM_EMAIL}>
To: <#{@invitation.email}>
Subject: Eloy en Dionne trouwen! #{address 'Kom je', 'Komen jullie'} ook?

Hoi #{@invitation.attendees_sentence},

Eloy en Dionne trouwen op 1 juni en zouden #{address 'jou', 'jullie'} er graag bij hebben!
Klik op onderstaande link om aan te geven of en wanneer #{address 'je komt', 'jullie komen'}:

  http://eloyendionnetrouwen.nl/#{@invitation.id}

Hopelijk tot dan!
END_OF_MESSAGE
      end

      def english
<<END_OF_MESSAGE
From: Eloy and Dionne are getting married <#{FROM_EMAIL}>
To: <#{@invitation.email}>
Subject: Eloy and Dionne are getting married! Will you join us?

Hi #{@invitation.attendees_sentence},

Eloy and Dionne are getting married on june the 1st and would love to have you join us!

Reply to this email, in case you would like to come over, and provide the following details:
* Who? #{@invitation.attendees_sentence}.
* Will you attend the wedding ceremony at 13:30?
* Will you attend the party starting at 15:00?
* Will you attend the BBQ at 18:00 and would you prefer vegetarian?

Hope to see you there!
END_OF_MESSAGE
      end
    end

    class Confirmation < Message
      def subject
        if @invitation.attending?
          "Leuk dat #{address 'je komt', 'jullie komen'}!"
        else
          "Jammer dat #{address 'je niet kunt', 'jullie niet kunnen'} komen."
        end
      end

      def body
        if @invitation.attending?
          "De volgende gegevens zijn bij ons bekend:\n\n* #{summary.join("\n* ")}\n\nTot 1 juni!"
        else
          "Zodra er foto's beschikbaar zijn laten we het je nog weten."
        end
      end

      def to_s
<<END_OF_MESSAGE
From: Eloy en Dionne trouwen <#{FROM_EMAIL}>
To: <#{@invitation.email}>
Subject: #{subject}

#{body}
END_OF_MESSAGE
      end
    end
  end

  def self.connection
    require 'net/smtp'
    Net::SMTP.start(SMTP_HOST, SMTP_PORT, SMTP_HELO, SMTP_USER, SMTP_PASS, :cram_md5) do |smtp|
      yield smtp
    end
  end

  def self.send_invitations(invitations)
    connection do |smtp|
      invitations.each do |invitation|
        message = Message::Invitation.new(invitation).to_s
        ActiveRecord::Base.logger.info(message)
        smtp.send_message(message, FROM_EMAIL, invitation.email)
        yield invitation
      end
    end
  end

  def self.send_confirmation(invitation)
    connection do |smtp|
      message = Message::Confirmation.new(invitation).to_s
      ActiveRecord::Base.logger.info(message)
      smtp.send_message(message, FROM_EMAIL, invitation.email)
    end
  end
end
