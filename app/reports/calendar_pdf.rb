module Reports
  class CalendarPDF < Ruport::Formatter::PDF
    renders :pdf, :for => CalendarController

    build :calendar do
      pad_bottom(10) do
        add_text options[:title]
      end         
      render_grouping data, options.to_hash.merge(:formatter => pdf_writer)
    end
  
  end
end