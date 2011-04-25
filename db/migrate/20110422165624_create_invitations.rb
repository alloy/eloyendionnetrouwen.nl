class CreateInvitations < ActiveRecord::Migration
  def self.up
    create_table :invitations do |t|
      t.string :email
      t.string :attendees
      t.boolean :attending_wedding, :default => false
      t.boolean :attending_party, :default => false
      t.boolean :attending_dinner, :default => false
      t.boolean :vegetarian_dinner, :default => false
      t.boolean :confirmed, :default => false
    end
  end

  def self.down
  end
end
