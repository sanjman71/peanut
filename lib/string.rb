class String
  def to_url_param
    gsub(' ', '-')
  end
  
  def to_s_param
    gsub('-', ' ')
  end
end