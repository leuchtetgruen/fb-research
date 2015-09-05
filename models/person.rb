class Person < Item
  attr_accessor :name, :about, :address, :bio, :birthday, :email, :first_name, :gender, :hometown, :last_name, :location, :website


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

class PeopleDatabase < Database
	def initialize(filename="output/people.json")
		super(filename, Person)
	end

	def people_named(name)
		rxName = Regexp.new(name)
		all.select { |p| p.name =~ rxName }
	end
end
