class Post < Item
  attr_accessor :message, :story, :created_time , :page
	
	def initialize(hash, query_data=Conf::QUERY_DATA)
    super(hash, query_data)
	end

  def likes
		people = query_people(url_for("likes"))
		people.map do |p|
			l = Like.new({})
			l.person = p
			l.refers_to_post = self
			l.build_id
			l
		end

	end

  def comments
    query_comments(url_for("comments")).map { |c| c.refers_to_post = self; c }
  end

  def to_s(query=true)
    query_data if query
    title = "BY #{page.to_s} (#{created_time})"
    line = ("=" * title.length)
    msg = message or ""
    sty = story or ""

    "#{title}\r\n#{line}\r\n#{msg}\r\nStory: #{sty}"
  end

  def fill_from_hash(hash)
    super(hash)
    @page = Page.new(hash["page"]) if hash["page"]
  end
end

class PostsDatabase < Database
	def initialize(filename="output/posts.json")
		super(filename, Post)
	end

	def load_pages(pagesDatabase)
		all.each { |p| p.page.query_data(pagesDatabase) }
	end

	def posts_by(page)
		all.select { |p| p.page == page }
	end

  def posts_liked_by(person, databases)
    likesDatabase = databases[:likes]
    posts = likesDatabase.by_person(person).map(&:refers_to_post).compact
    posts.each { |p| p.query_data(self) }
    posts
  end

  def posts_commented_by(person, databases)
    commentsDatabase = databases[:comments]
    posts = commentsDatabase.by_person(person).map(&:refers_to).compact
    posts.each { |p| p.query_data(self) }
    posts
  end

	def pages
		all.map(&:page).uniq { |p| p.id }
	end

	def posts_newer_than(timestamp)
		all.select do |post|
			DateTime.parse(post.created_time) >= timestamp
		end
	end

	def save_likes(likesDatabase,saveEvery=100)
		all.each_with_index { |p,idx| puts idx; likesDatabase.putAll(p.likes) unless likesDatabase.has_post?(p); likesDatabase.persist if (idx%saveEvery==0) }
	end

	def save_comments(commentsDatabase,saveEvery=100)
		all.each_with_index { |p,idx| puts idx; commentsDatabase.putAll(p.comments) unless commentsDatabase.has_post?(p); commentsDatabase.persist if (idx%saveEvery==0) }
	end
end
