class Person < Item
  attr_accessor :name, :about, :address, :bio, :birthday, :email, :first_name, :gender, :hometown, :last_name, :location, :website, :friends

	def initialize(hash, query_data=Conf::QUERY_DATA)
		@hash = hash
    super(hash, query_data)
    @friends = hash["friends"].map { |h| Person.new(h) }  if hash["friends"]
	end

  def events
    query_events(url_for("events"))
  end

  def likes
    query_pages(url_for("likes"))
  end

	def hash
		@hash
	end

  def to_s(query=true)
    query_data if query
    name
  end

end

class PeopleDatabase < Database
	def initialize(filename="output/people.json")
		super(filename, Person)
	end

	def people_named(name)
		rxName = Regexp.new(name)
		all.select { |p| p.name =~ rxName }
	end

	def people_with_friends
		all.select { |p| !p.friends.nil? }
	end

	def friends_of(person)
		(people_with_friends.select { |p| p.friends.map(&:id).include?(person.id) } + (person.friends || []))
	end

	def real_id(person)
		person.query_data(self)
		unique_person_named(person.name)
	end

	def unique_person_named(name)
		people_named(name).select { |p| p.id.start_with?("1") }.first
	end
end
