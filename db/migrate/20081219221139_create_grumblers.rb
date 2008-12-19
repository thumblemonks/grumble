class CreateGrumblers < ActiveRecord::Migration
  def self.up
    create_table :grumblers do |t|
      t.string      :name, :null => false
      t.uuid        :add_index => false # active_record_uuid migrations under Edge are busted
      t.timestamps
    end
    add_index      :grumblers, :uuid, :unique => true
  end

  def self.down
    drop_table :grumblers
  end
end
