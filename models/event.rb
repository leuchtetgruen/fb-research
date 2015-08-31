class Event < NamedItem
  attr_accessor :name, :start_time, :end_time, :description

  def people(invitation_mode)
    query_people("https://graph.facebook.com/v2.4/#{@id}/#{invitation_mode}?access_token=#{Conf::OAUTH_TOKEN}")
  end
  

  def attendees
    people("attending")
  end

  def declined_invites
    people("declined")
  end

  def maybe_invites
    people("maybe")
  end

  def nonreplying_invites
    people("noreply")
  end

  def all_invitations
    all_p = []
    all_p << attendees
    all_p << declined_invites
    all_p << maybe_invites
    all_p << nonreplying_invites
    all_p.flatten.uniq { |p| p.id }
  end

  def admins
    people("admins")
  end

  def comments
    comments = query_comments(url_for("comments"))
    comments.each do |c|
      c.refers_to = @id
    end
  end

  def photos
    query(url_for("photos"), MediaItem)
  end
end
