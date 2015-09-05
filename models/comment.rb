class Comment < Item
  attr_accessor :author, :message, :refers_to

  def initialize(hash, query_data=Conf::QUERY_DATA)
    super(hash, query_data)
    @author = Person.new(hash["from"]) if hash["from"]
		@author = Person.new(hash["author"]) if hash["author"]
		@refers_to = Post.new(hash["refers_to"]) if hash["refers_to"]
  end
end

class CommentsDatabase < Database
	def initialize(filename="output/comments.json")
		super(filename, Comment)
	end

	def by_person(person)
		all.select { |c| c.author == person }
	end

	def for_post(post)
		all.select { |c| c.refers_to == post }
	end

	def on_page(page)
		all.select { |c| c.refers_to.page == page }
	end

	def pages
		all.map { |c| c.refers_to.page }.uniq { |p| p.id }
	end

	def load_authors(peopleDatabase)
		all.each { |c| c.author.query_data(peopleDatabase) }
	end

	def load_posts(postDatabase, pageDatabase=nil)
		postDatabase.load_pages(pageDatabase) if pageDatabase
		all.each { |c| c.page.query_data(pageDatabase) }
	end
end
