class Person < Item
  attr_accessor :name, :data


  def events
    query_events(url_for("events"))
  end

  def likes
    query_pages(url_for("likes"))
  end

  def friends
    query_people(url_for("friends"))
  end
end
