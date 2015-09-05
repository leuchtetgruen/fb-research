class Invitation < Item
	attr_accessor :person, :event, :invitation_status

	ATTENDING = "attending"
	DECLINED = "declined"
	MAYBE = "maybe"
	NOREPLY = "noreply"

  def initialize(hash, query_data=Conf::QUERY_DATA)
    super(hash.clone, query_data)
		@person = Person.new(hash["person"]) if hash["person"]
		@event = Event.new(hash["event"]) if hash["event"]
		
		build_id
	end

	def build_id
		@id = "#{@person.id}->#{@event.id}" if @person and @event
	end
end


class InvitationsDatabase < Database
	def initialize(filename="output/invitations.json")
		super(filename, Invitation)
	end

	def for_event(e)
		all.select { |i| i.event.id == e.id }
	end

	def has_event?(e)
		all.map(&:event).map(&:id).include?(e.id)
	end

	def load_people(peopleDatabase)
		all.map { |i| i.person.query_data(peopleDatabase) }
	end

	def load_events(eventsDatabase)
		all.map { |i| i.event.query_data(eventsDatabase) }
	end

	def events
		all.map(&:event).uniq { |e| e.id }
	end
end
