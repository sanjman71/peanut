module InvoicesHelper

  def build_invoice_when_links(when_collection, current, options={})
    default = options[:default]
    
    when_collection.each do |s|
      # add css 'current' class for the current link
      klass = (s == current) ? 'current' : ''
      
      if s == default
        # no when parameter for the default value
        # link  = link_to(s.titleize, invoices_path(:subdomain => @subdomain), :class => klass)
        link  = link_to(s.titleize, url_for(:controller => 'invoices', :action => 'index', :when => nil, :subdomain => @subdomain), :class => klass)
      else
        # use when parameter
        # link  = link_to(s.titleize, invoices_path(:subdomain => @subdomain, :when => s), :class => klass)
        link  = link_to(s.titleize, url_for(:controller => 'invoices', :action => 'index', :when => s.to_url_param, :subdomain => @subdomain), :class => klass)
      end
      
      # use separator unless its the last element
      separator = (s == when_collection.last) ? '' : '&nbsp;|&nbsp;'
      
      yield link, separator
    end
  end
  
end