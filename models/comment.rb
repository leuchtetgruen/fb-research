class Comment < Item
  attr_accessor :author, :message, :refers_to_post, :refers_to_comment

  def initialize(hash, query_data=Conf::QUERY_DATA)
    super(hash, query_data)
    @author = Person.new(hash["from"]) if hash["from"]
		@author = Person.new(hash["author"]) if hash["author"]
		@refers_to_post = Post.new(hash["refers_to"]) if hash["refers_to"]
		@refers_to_post = Post.new(hash["refers_to_post"]) if hash["refers_to_post"]
		@refers_to_comment = Post.new(hash["refers_to_comment"]) if hash["refers_to_comment"]
  end

  def likes
		people = query_people(url_for("likes"))
		people.map do |p|
			l = Like.new({})
			l.person = p
			l.refers_to_comment = self
			l.build_id
			l
		end
  end

  def comments
    comments = query_comments(url_for("comments"))
    comments.each do |c|
      c.refers_to_comment = self
    end
    comments
  end

  def to_s(query=true)
    @author.query_data if query

    "#{author.to_s} : #{message}"
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
		all.select { |c| c.refers_to_post == post }
	end

	def on_page(page)
		all.select { |c| c.refers_to_post.page == page }
	end

	def pages
		all.map { |c| c.refers_to_post.page }.uniq { |p| p.id }
	end

	def containing(text)
		rxText = Regexp.new(text)
		all.select { |c| c.message =~ rxText }
	end

	def load_authors(peopleDatabase)
		all.each { |c| c.author.query_data(peopleDatabase) }
	end

	def load_posts(postsDatabase, pageDatabase=nil)
		postDatabase.load_pages(pageDatabase) if pageDatabase
		all.each { |c| c.refers_to_post.query_data(postsDatabase) }
	end

	def has_post?(p)
		all.map(&:refers_to_post).map(&:id).include?(p.id)
	end

  def has_comments_for_comment?(comment)
    all.any? { |c| c.refers_to_comment && (c.refers_to_comment.id == comment.id) }
  end
end
