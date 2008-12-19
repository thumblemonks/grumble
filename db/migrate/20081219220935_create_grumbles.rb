class CreateGrumbles < ActiveRecord::Migration
  def self.up
    create_table :grumbles do |t|
      t.belongs_to :target
      t.belongs_to :grumbler
      t.text       :subject, :body, :null => false
      t.string     :anon_grumbler_name
      t.uuid
      t.timestamps
    end
  end

  def self.down
    drop_table :grumbles
  end
end
