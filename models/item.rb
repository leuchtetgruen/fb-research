class Item
  attr_accessor :id, :data
   
  def initialize(hash_or_id, query_data=Conf::QUERY_DATA)
    if hash_or_id.kind_of? String
      @id = hash_or_id
    else
      @id = hash_or_id["id"]
      fill_from_hash(hash_or_id)
    end
    query_data(query_data) if query_data
  end

  def query_data(database=true)
		if (database and (database.respond_to?(:get)))
			obj = database.get(@id)
			# if database does not contain obj query it from fb
			obj = query_data(true) unless obj

			fill_from_hash(obj.to_h)

			puts "Saving #{self.to_h} to #{database}" if Conf::DEBUG
			database.put(self) unless database.include?(self)
		else
			url = "https://graph.facebook.com/v2.4/#{@id}/?access_token=#{Conf::OAUTH_TOKEN}"
			res = Net::HTTP.get(URI.parse(url))
			j_res = JSON.parse(res)
			@data = j_res
			fill_from_hash @data
		end
  end

  def to_h(depth=0, query_data=false, database=false)
    return nil if depth > Conf::MAX_DEPTH
		return {id: @id} if ((depth > 0) and database)
    query_data if query_data
    res = @data
    getters = methods.select { |m| 
      ( m.to_s.end_with? "=" ) && (!m.to_s.end_with? "==" ) && (!m.to_s.end_with? "!=" )
    }.map { |m| 
      m[0...-1].to_sym
    }

    attrs = getters.map { |getter|
      obj = self.send(getter)

      [Person, Event, NamedItem, Comment, Item, Post, Page, Like].each do |klass|
        if obj.kind_of? klass
          obj = obj.to_h(depth + 1, query_data, database)
        end
      end

      [ getter.to_s ,  obj ]
    }
    h_attrs = {}
    attrs.each { |attr| h_attrs[attr[0]] = attr[1] }
    h_ret = h_attrs.merge(@data || {})
		h_ret.delete("data") if database

		h_ret
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

	def show
		url = "https://facebook.com/#{id}"
		system("open \"#{url}\"")
	end
end
