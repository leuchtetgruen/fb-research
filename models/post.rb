class Post < Item
  attr_accessor :message, :story, :created_time 

  def likes
    query_people(url_for("likes"))
  end

  def comments
    query_comments(url_for("comments"))
  end
end
