# The Sanitize configuration we like is RELAXED, as follows:

# class Sanitize
#   module Config
#     RELAXED = {
#       :elements => [
#         'a', 'b', 'blockquote', 'br', 'caption', 'cite', 'code', 'col',
#         'colgroup', 'dd', 'dl', 'dt', 'em', 'i', 'img', 'li', 'ol', 'p', 'pre',
#         'q', 'small', 'strike', 'strong', 'sub', 'sup', 'table', 'tbody', 'td',
#         'tfoot', 'th', 'thead', 'tr', 'u', 'ul'],
# 
#       :attributes => {
#         'a'          => ['href', 'title'],
#         'blockquote' => ['cite'],
#         'col'        => ['span', 'width'],
#         'colgroup'   => ['span', 'width'],
#         'img'        => ['align', 'alt', 'height', 'src', 'title', 'width'],
#         'ol'         => ['start', 'type'],
#         'q'          => ['cite'],
#         'table'      => ['summary', 'width'],
#         'td'         => ['abbr', 'axis', 'colspan', 'rowspan', 'width'],
#         'th'         => ['abbr', 'axis', 'colspan', 'rowspan', 'scope',
#                          'width'],
#         'ul'         => ['type']
#       },
# 
#       :protocols => {
#         'a'          => {'href' => ['ftp', 'http', 'https', 'mailto',
#                                     :relative]},
#         'blockquote' => {'cite' => ['http', 'https', :relative]},
#         'img'        => {'src'  => ['http', 'https', :relative]},
#         'q'          => {'cite' => ['http', 'https', :relative]}
#       }
#     }
#   end
# end

# We extend it with a few things:
class Sanitize
  module Config
    WALNUT = Sanitize::Config::RELAXED.merge({ :elements => ['h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'pre', 'address'] }) { |key, old_val, new_val| old_val + new_val}
  end
end
