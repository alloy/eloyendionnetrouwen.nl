require 'config'
require 'helpers'

class Invitation < ActiveRecord::Base
  class EmailMessage
    include Helpers

    def initialize(invitation)
      @invitation = invitation
    end

    def to_s
<<END_OF_MESSAGE
From: Eloy en Dionne trouwen! <#{FROM_EMAIL}>
To: <#{@invitation.email}>
Subject: Eloy en Dionne trouwen! #{address 'Kom je', 'Komen jullie'} ook?

Hoi #{@invitation.attendees_sentence},

Eloy en Dionne trouwen op 1 juni en zouden #{address 'jou', 'jullie'} er graag bij hebben!
Klik op onderstaande link om aan te geven of en wanneer #{address 'je komt', 'jullie komen'}:

  http://eloyendionnetrouwen.nl/#{@invitation.id}

Hopelijk tot dan!
END_OF_MESSAGE
    end
  end

  def self.send_invitations!
    require 'net/smtp'
    Net::SMTP.start(SMTP_HOST, SMTP_PORT, SMTP_HELO, SMTP_USER, SMTP_PASS, :cram_md5) do |smtp|
      where(:sent => false).where(arel_table[:email].not_eq(nil)).each do |invitation|
        message = EmailMessage.new(invitation).to_s
        logger.info(message)
        smtp.send_message(message, FROM_EMAIL, invitation.email)
        invitation.update_attribute(:sent, true)
      end
    end
  end

  before_save :ensure_attending_party_if_attending_dinner

  def email=(address)
    if address && address.strip.empty?
      address = nil
    end
    write_attribute(:email, address)
  end

  def vegetarians=(amount)
    write_attribute(:vegetarians, amount.to_i)
  end

  def omnivores
    attendees_list.size - vegetarians
  end

  def ensure_attending_party_if_attending_dinner
    self.attending_party = true if attending_dinner?
  end

  def attendees=(attendees)
    write_attribute(:attendees, list(attendees).reject(&:empty?).join(", "))
  end

  def attendees_list
    list(attendees)
  end

  def attendees_sentence
    list = attendees_list
    if list.size == 1
      list.first
    else
      list[0..-2].join(", ") << " en #{list.last}"
    end
  end

  def attending?
    attending_wedding? || attending_party?
  end

  private

  def list(str)
    str.split(",").map { |a| a.strip }
  end

  def not_more_vegetarians_than_attendees
    if vegetarians > attendees_list.size
      errors.add(:vegetarians, "Er kunnen niet meer vegetariërs (#{vegetarians}) dan gasten (#{attendees_list.size}) zijn.")
    end
  end

  validates_presence_of :attendees, :message => "De gastenlijst mag niet leeg zijn."
  validate :not_more_vegetarians_than_attendees
end
