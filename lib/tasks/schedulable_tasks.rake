require 'rake'
desc 'Builds occurrences for schedulable models'
namespace :schedulable do
  task :build_occurrences => :environment do
    #puts "Hello"
    Schedule.uniq.pluck(:schedulable_type).each do |schedulable_type|
      clazz = schedulable_type.constantize
      occurrences_associations = Schedulable::ActsAsSchedulable.occurrences_associations_for(clazz)
      occurrences_associations.each do |association|
        #puts association.to_s
        clazz.send("build_" + association.to_s)
      end
    end
  end
end