schedulable
===========

Handling recurring events in rails. 

### Install

Put the following into your Gemfile and run `bundle install`
```cli
gem 'ice_cube'
gem 'schedulable'
```

Install schedule migration and model
```cli
rails g schedulable:install
```

### Basic Usage

Create an event model
```cli
rails g scaffold Event name:string
```

Configure your model to be schedulable:
```
# app/models/event.rb
class Event < ActiveRecord::Base
  acts_as_schedulable
end
```
This will add an association to the model named 'schedule' which holds the schedule information. 

Now you're ready to setup form fields for the schedule association using the fields_for-form_helper. 

### Attributes
The schedule object respects the following attributes:
<table>
  <tr>
    <th>Name</th><th>Type</th><th>Description</th>
  </tr>
  <tr>
    <td>rule</td><td>String</td><td>One of 'singular', 'daily', 'weekly', 'monthly'</td>
  </tr>
  <tr>
    <td>date</td><td>Date</td><td>The date-attribute is used for singular events and also as startdate of the schedule</td>
  </tr>
  <tr>
    <td>time</td><td>Time</td><td>The time-attribute is used for singular events and also as starttime of the schedule</td>
  </tr>
  <tr>
    <td>days</td><td>Array</td><td>An array of weekday-names, i.e. ['monday', 'wednesday']</td>
  </tr>
  <tr>
    <td>day_of_week</td><td>Hash</td><td>A hash of weekday-names, containing arrays with indices, i.e. {:monday => [1, -1]} ('every first and last monday in month')</td>
  </tr>
  <tr>
    <td>interval</td><td>Integer</td><td>Specifies the interval of the recurring rule, i.e. every two weeks</td>
  </tr>
  <tr>
    <td>until</td><td>Date</td><td>Specifies the enddate of the schedule. Required for terminating events.</td>
  </tr>
  <tr>
    <td>count</td><td>Integer</td><td>Specifies the total number of occurrences. Required for terminating events.</td>
  </tr>
</table>

#### SimpleForm
A custom input for simple_form is provided with the plugin. Make sure, you installed [SimpleForm](https://github.com/plataformatec/simple_form) and executed `rails generate simple_form:install`.

```cli
rails g schedulable:simple_form
```

```ruby
<%# app/views/events/_form.html.erb %>
<%= simple_form_for(@event) do |f| %>
  
  <div class="field">
    <%= f.label :name %><br>
    <%= f.text_field :name %>
  </div>
  
  <div class="field">
    <%= f.label :schedule %><br>
    <%= f.input :schedule, as: :schedule %>
  </div>

  <div class="actions">
    <%= f.submit %>
  </div>
  
<% end %>

```

#### Strong parameters

```
# app/controllers/event_controller.rb
def event_params
  params.require(:event).permit(:name, schedule_attributes: Schedulable::ScheduleSupport.param_names)
end
```

### IceCube
The schedulable plugin uses ice_cube for calculating occurrences. 
You can access ice_cube-methods via the schedule association:

```ruby
<%# app/views/events/show.html.erb %>
<p>
  <strong>Schedule:</strong>
  <%# prints out a human-friendly description of the schedule, such as %> 
  <%= @event.schedule %>
</p>
```

```
# prints all occurrences of the event until one year from now
puts @event.schedule.occurrences(Time.now + 1.year)
# export to ical
puts @event.schedule.to_ical
```
See [IceCube](https://github.com/seejohnrun/ice_cube) for more information.

### Internationalization

At first you need to make sure you included all neccessary datetime translations. 
A basic setup can be found [here](https://github.com/svenfuchs/rails-i18n/tree/master/rails/locale).

#### Localize Schedulable
Use the locale-generator to create a .yml-file containing schedulable messages in english:
```cli
rails g schedulable:locale en
```

Schedulable has also bundled messages in german. Use `de` as identifier.

#### Localize Ice-Cube
Internationalization of ice-cube itself can be integrated by using [this fork](https://github.com/joelmeyerhamme/ice_cube):
```ruby
gem 'ice_cube', git: 'git://github.com/joelmeyerhamme/ice_cube.git', branch: 'international' 
```


### Persist event occurrences
We need to have the occurrences persisted because we want to query the database for all occurrences of all instances of an event model or need to add additional attributes and functionality, such as allowing users to attend to a specific occurrence of an event.
The schedulable gem handles this for you. 
Your occurrence model must include an attribute of type 'datetime' with name 'date' as well as a reference to your event model to setup up the association properly:  

```ruby
rails g model EventOccurrence event_id:integer date:datetime
```

```ruby
# app/models/event_occurrence.rb
class EventOccurrence < ActiveRecord::Base
  belongs_to :event
end
```

Then you can simply declare your occurrences with the acts_as_schedule-method like this:
```
# app/models/event.rb
class Event < ActiveRecord::Base
  acts_as_schedulable occurrences: :event_occurrences
end
```
This will add a has_many-association with the name 'event_occurences' to your event-model. 
Instances of remaining occurrences are built when the schedule is saved. 
If the schedule has changed, the occurrences will be rebuilt if dates have also changed. Otherwise the time of the occurrence record will be adjusted to the new time.
As in real life, previous occurrences will always stay untouched.

#### Terminating and non-terminating events
An event is terminating if an until- or count-attribute has been specified. 
Since non-terminating events have infinite occurrences, we cannot build all occurrences at once ;-)
So we need to limit the number of occurrences in the database. 
By default this will be one year from now. 
This can be configured via the 'build_max_count' and 'build_max_period'-options. 
See notes on configuration. 

#### Automate build of occurrences
Since we cannot build all occurrences at once, we will need a task that adds occurrences as time goes by. 
Schedulable comes with a rake-task that performs an update on all scheduled occurrences. 

```cli
rake schedulable:build_occurrences
```

You may add this task to crontab. 

##### Using 'whenever' to schedule build of occurrences

With the 'whenever' gem this can be easily achieved. 

```
gem 'whenever', :require => false
```

Generate the 'whenever'-configuration file:

```cli
wheneverize .
```

Open up the file 'config/schedule.rb' and add the job:

```ruby
set :environment, "development"
set :output, {:error => "log/cron_error_log.log", :standard => "log/cron_log.log"}

every 1.day do
  rake "schedulable:build_occurrences"
end
```

Write to crontab:

```cli
whenever -w
```

### Configuration
Generate the configuration file

```cli
rails g schedulable:config
```

Open 'config/initializers/schedulable.rb' and edit options as you need:

```ruby
Schedulable.configure do |config|
  config.max_build_count = 0
  config.max_build_period = 1.year
end
```
