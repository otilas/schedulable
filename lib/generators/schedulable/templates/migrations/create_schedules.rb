class CreateSchedules < ActiveRecord::Migration
  def self.up
    create_table :schedules do |t|
      t.references :schedulable, polymorphic: true
      
      t.date :date # TODO: Check if we remove this
      t.time :time # TODO: Check if we remove this
      
      t.date :start_date
      t.date :end_date
      
      t.time :start_time
      t.time :end_time
      
      t.string :rule
      t.string :interval
      
      t.text :day
      t.text :day_of_week
      
      t.datetime :until # TODO: Check if we remove this
      t.integer :count
      
      t.timestamps
    end
  end

  def self.down
    drop_table :schedules
  end
end