module Reports
  class CalendarController < Ruport::Controller
    stage           :calendar
    required_option :appointments
    required_option :title
  
    def setup
      @appointments = Array(options[:appointments])
      @title        = options[:title]
      
      table = Table(["Date", "Start", "End", "Length", "Service"]) do |t|
        @appointments.each do |appt|
          t << [appt.start_at.to_s(:appt_day), appt.start_at.to_s(:appt_time), appt.end_at.to_s(:appt_time), Duration.to_words(appt.duration), appt.service.name]
        end
      end
    
      self.data = Grouping(table, :by => "Date")
    end
  end
end