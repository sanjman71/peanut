# Be sure to restart your server when you modify this file.

# Add new mime types for use in respond_to blocks:
# Mime::Type.register "text/richtext", :rtf
# Mime::Type.register_alias "text/html", :iphone

# PDF type is defined by prawn gem/plugin
Mime::Type.register "text/plain", :email

# Mobile device support
Mime::Type.register_alias "text/html", :mobile
