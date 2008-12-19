class CreateGrumblers < ActiveRecord::Migration
  def self.up
    create_table :grumblers do |t|
      t.string      :name, :null => false
      t.uuid
      t.timestamps
    end
  end

  def self.down
    drop_table :grumblers
  end
end
