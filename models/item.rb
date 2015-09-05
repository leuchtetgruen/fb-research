class Item
  attr_accessor :id, :data
   
  def initialize(hash_or_id, query_data=Conf::QUERY_DATA)
    if hash_or_id.kind_of? String
      @id = hash_or_id
    else
      @id = hash_or_id["id"]
      fill_from_hash(hash_or_id)
    end
    query_data if query_data
  end

  def query_data
    url = "https://graph.facebook.com/v2.4/#{@id}/?access_token=#{Conf::OAUTH_TOKEN}"
    res = Net::HTTP.get(URI.parse(url))
    j_res = JSON.parse(res)
    @data = j_res
    fill_from_hash @data
  end

  def to_h(depth=0, query_data=false)
    return nil if depth > Conf::MAX_DEPTH
    query_data if query_data
    res = @data
    getters = methods.select { |m| 
      ( m.to_s.end_with? "=" ) && (!m.to_s.end_with? "==" ) && (!m.to_s.end_with? "!=" )
    }.map { |m| 
      m[0...-1].to_sym
    }

    attrs = getters.map { |getter|
      obj = self.send(getter)

      [Person, Event, NamedItem, Comment, Item].each do |klass|
        if obj.kind_of? klass
          obj = obj.to_h(depth + 1, query_data)
        end
      end

      [ getter.to_s ,  obj ]
    }
    h_attrs = {}
    attrs.each { |attr| h_attrs[attr[0]] = attr[1] }
    h_attrs.merge(@data || {})
  end

  def url_for(what)
    "https://graph.facebook.com/v2.4/#{@id}/#{what}?access_token=#{Conf::OAUTH_TOKEN}"
  end

  def fill_from_hash(hash)
    hash.each do |k,v|
      m = (k.to_s + "=").to_sym
      if respond_to? m
        puts "Setting #{m} #{v}" if Conf::DEBUG
        send m, v
      end
    end
  end

  def ==(other)
    (@id == other.id)
  end
end
