# Fix a bug in Rails 2.3.2 stable. Should be able to remove this after upgrading. https://rails.lighthouseapp.com/projects/8994/tickets/2784-private-method-split-called-for-mimetype0x226f618
class Mime::Type
  delegate :split, :to => :to_s
end
