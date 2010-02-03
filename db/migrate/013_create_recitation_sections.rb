class CreateRecitationSections < ActiveRecord::Migration
  def self.up
    create_table :recitation_sections do |t|
      # the serial number of the recitation (1 for R01)
      t.integer :serial, :null => false
      # the user ID of the recitation leader
      t.integer :leader_id, :null => false
      # the scheduled time of the recitation (WF 10am)
      t.string :time, :limit => 64, :null => false
      # the scheduled room of the recitation (36-144) 
      t.string :location, :limit => 64, :null => false

      # auditing goodness
      t.timestamps
    end
    
    add_index :recitation_sections, :serial, :unique => true
  end

  def self.down
    drop_table :recitation_sections
  end
end
