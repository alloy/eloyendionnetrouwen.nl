require 'config'
require 'helpers'
require 'mailer'
require 'validates_email_san'

class Invitation < ActiveRecord::Base
  def self.send_invitations!
    invitations = where(:sent => false).where(arel_table[:email].not_eq(nil))
    Mailer.send_invitations(invitations) do |invitation|
      invitation.update_attribute(:sent, true)
    end
  end

  before_save :ensure_attending_party_if_attending_dinner
  before_create :set_token

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
      list[0..-2].join(", ") << "#{english? ? ', and' : ' en'} #{list.last}"
    end
  end

  def attending?
    attending_wedding? || attending_party?
  end

  private

  def list(str)
    str.split(",").map { |a| a.strip }
  end

  def set_token
    token = nil
    loop do
      token = generate_token
      break if Invitation.find_by_token(token).nil?
    end
    write_attribute :token, token
  end

  def generate_token
    [1,2].map { |i| [1,2].map { (i.odd? ? ('a'..'z') : ('0'..'9')).to_a.random_element }.join }.join
  end

  def amount_of_vegetarians
    if vegetarians < 0
      errors.add(:vegetarians, "Het aantal vegetariërs kan niet negatief zijn.")
    elsif vegetarians > attendees_list.size
      errors.add(:vegetarians, "Er kunnen niet meer vegetariërs (#{vegetarians}) dan gasten (#{attendees_list.size}) zijn.")
    end
  end

  validates_presence_of :attendees, :message => "De gastenlijst mag niet leeg zijn."
  validate :amount_of_vegetarians
  validates_email :email, :allow_nil => true, :message => "Het opgegeven email adres is niet valide."
end
