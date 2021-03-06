class Like < Item
	attr_accessor :refers_to_page, :refers_to_post, :refers_to_comment, :person

  def initialize(hash, query_data=Conf::QUERY_DATA)
    super(hash.clone, query_data)
    @refers_to_page = Page.new(hash["refers_to_page"]) if hash["refers_to_page"]
		@refers_to_post = Post.new(hash["refers_to_post"]) if hash["refers_to_post"]
		@refers_to_comment = Comment.new(hash["refers_to_comment"]) if hash["refers_to_comment"]
		@person = Person.new(hash["person"]) if hash["person"]
		
		build_id
	end

	def build_id
		@id = if @refers_to_page
						"#{@person.id}->#{@refers_to_page.id}"
					elsif @refers_to_post
						"#{@person.id}->#{@refers_to_post.id}"
					elsif @refers_to_comment
						"#{@person.id}->#{@refers_to_comment.id}"
					end
	end

  def to_s(query=true)
    person.to_s(query)
  end
end

class LikesDatabase < Database
	def initialize(filename="output/likes.json")
		super(filename, Like)
	end

	def load_people(peopleDatabase)
		all.each { |l| l.query_data(peopleDatabase) }
	end

	def load_posts(postsDatabase)
		all.each { |l| l.refers_to_post.query_data(postsDatabase) }
	end

	def by_person(p)
		all.select { |l| l.person.id == p.id }
	end

  def by_people(people)
    all.select do |comment|
      people.include? comment.person
    end
  end

	def has_post?(p)
		all.map(&:refers_to_post).map(&:id).include?(p.id)
	end

  def for_post(p)
    all.select { |l| l.refers_to_post && (l.refers_to_post.id == p.id) }
  end

  def exists_for_post?(p)
    all.any? { |l| l.refers_to_post && (l.refers_to_post.id == p.id) }
  end

  def for_comment(c)
    all.select { |l| l.refers_to_comment && (l.refers_to_comment.id == c.id)}
  end

  def exists_for_comment?(c)
    all.any? { |l| l.refers_to_comment && (l.refers_to_comment.id == c.id) }
  end
end
