def query(url, klass)
    next_url = url
    a_results = []
    while next_url do
      p next_url if Conf::DEBUG
      res = Net::HTTP.get(URI.parse(next_url))
      j_res = JSON.parse(res)
      p j_res if Conf::DEBUG

      if j_res["error"]
        puts "An error occured. Maybe check your OAUTH_TOKEN in config.rb or your ENV variables"
        p j_res["error"]
      end

      a_results << j_res["data"]
      next_url = if j_res["paging"]
                   j_res["paging"]["next"]
                 else
                   nil
                 end
    end
    a_results.flatten!
    a_results.map do |h_result|
      klass.new(h_result)
    end
end

def query_people(url)
  query(url, Person)
end

def query_comments(url)
  query(url, Comment)
end

def query_events(url)
  query(url, Event)
end

def query_pages(url)
  query(url, Page)
end

def query_posts(url)
  query(url, Post)
end

def json(obj,database=false)
  if obj.kind_of? Array
		if database
			obj.map { |o| o.to_h(0, false, true) }.to_json
		else
			obj.map(&:to_h).to_json
		end
  else
		if database
			obj.to_h(0, false, true).to_json
		else
			obj.to_h.to_json
		end
  end
end

def from_json(s, klass)
  obj = JSON.parse(s)
  if obj.kind_of? Array
    obj.map { |h| klass.new(h) }
  else
    klass.new(obj)
  end
end

def csv(obj, seperator=";")
  if obj.kind_of? Array
    ks = obj.first.to_h.keys
    hs = obj.map(&:to_h).map do |item|
      ks.map { |k| item[k] }.join(seperator)
    end

    s = ks.join(seperator) + "\r\n"
    s += hs.join("\r\n")
    s
  else
    h_obj = obj.to_h
    ks = h_obj.keys
    vs = ks.map { |k| h_obj[k] }.join(seperator)
    s = ks.join(seperator) + "\r\n"
    s += vs
    s
  end
end

def save(string, filename)
  File.write(filename, string)
end

def load(filename)
  File.read(filename)
end
