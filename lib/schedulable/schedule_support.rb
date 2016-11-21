module Schedulable
  
  module ScheduleSupport
    
    def self.param_names
      [:id, :start_date, :end_date, :start_time, :end_time, :date, :time, :rule, :until, :count, :interval, 
        day: [], day_of_week: [monday: [], tuesday: [], wednesday: [], thursday: [], friday: [], saturday: [], sunday: []]]
    end
    
  end
end