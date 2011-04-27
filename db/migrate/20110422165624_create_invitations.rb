class CreateInvitations < ActiveRecord::Migration
  def self.up
    create_table :invitations do |t|
      t.string :email
      t.string :token
      t.string :attendees
      t.boolean :sent, :default => false
      t.boolean :english, :default => false
      t.boolean :confirmed, :default => false
      t.boolean :attending_wedding, :default => false
      t.boolean :attending_party, :default => false
      t.boolean :attending_dinner, :default => false
      t.integer :vegetarians, :default => 0, :null => false
    end
  end

  def self.down
  end
end
