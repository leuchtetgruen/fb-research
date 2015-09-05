class Page < NamedItem
  def events
    query_events(url_for("events"))
  end

  def feed
    query_posts(url_for("feed")).map { |p| p.page = self }
  end
end
