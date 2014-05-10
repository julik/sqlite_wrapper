class DoMigrate < ActiveRecord::Migration
  def self.up
    create_table :even_more_things do | t |
      t.string :name
    end
  end
  
  def self.down
    drop_table :even_more_things
  end
end