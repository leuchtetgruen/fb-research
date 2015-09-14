class Page < NamedItem

  def events
    query_events(url_for("events")).map { |e| e.page = self; e }
  end

  def feed
    query_posts(url_for("feed")).map { |p| p.page = self; p }
  end

  def to_s(query=true)
    query_data if query
    name
  end
end

class PagesDatabase < Database
	def initialize(filename="output/pages.json")
		super(filename, Page)
	end

  def active
    all.select { |p| !p.ignore }
  end

	def pages_named(name)
		rxName = Regexp.new(name)
		all.select { |p| p.name =~ rxName }
	end
end
