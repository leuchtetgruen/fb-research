class MediaItem < Item
  def likes
    query_people(url_for("likes"))
  end

  def comments
    comments = query_comments(url_for("comments"))
    comments.each do |c|
      c.refers_to = @id
    end
  end
end
