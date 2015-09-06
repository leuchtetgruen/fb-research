class Event < NamedItem
  attr_accessor :name, :start_time, :end_time, :description, :page

  def initialize(hash, query_data=Conf::QUERY_DATA)
    super(hash.clone, query_data)
		@page = Page.new(hash["page"]) if hash["page"]
	end

  def people(invitation_mode, inv_status)
    query_people("https://graph.facebook.com/v2.4/#{@id}/#{invitation_mode}?access_token=#{Conf::OAUTH_TOKEN}").map do |p|
			i = Invitation.new({})
			i.person = p
			i.event = self
			i.invitation_status = inv_status
			i.build_id
			i
		end
  end
  

  def attendees
    people("attending", Invitation::ATTENDING)
  end

  def declined_invites
    people("declined", Invitation::DECLINED)
  end

  def maybe_invites
    people("maybe", Invitation::MAYBE)
  end

  def nonreplying_invites
    people("noreply", Invitation::NOREPLY)
  end

  def all_invitations
    all_i = []
    all_i << attendees
    all_i << declined_invites
    all_i << maybe_invites
    all_i << nonreplying_invites
    all_i.flatten.uniq { |i| i.id }
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

class EventsDatabase < Database
	def initialize(filename="output/events.json")
		super(filename, Event)
	end

	def by_page(page)
		all.select { |e| e.page.id == page.id }
	end

	def save_invitations(invitationsDatabase)
		all.each_with_index do |e,idx|
			puts "#{e} (#{idx})"
			unless invitationsDatabase.has_event?(e)
				invitations = e.all_invitations
				invitationsDatabase.putAll(invitations)
			end
		end
	end

	def load_pages(pagesDatabase)
		all.each { |e| e.page.query_data(pagesDatabase) }
	end
end
