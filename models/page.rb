class Page < NamedItem
  def events
    query_events(url_for("events"))
  end

  def feed
    query_posts(url_for("feed")).map { |p| p.page = self; p }
  end
end

class PagesDatabase < Database
	def initialize(filename="output/pages.json")
		super(filename, Page)
	end
end
