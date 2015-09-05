class Post < Item
  attr_accessor :message, :story, :created_time , :page
	
	def initialize(hash, query_data=Conf::QUERY_DATA)
    super(hash, query_data)
    @page = Page.new(hash["page"]) if hash["page"]
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
    query_comments(url_for("comments")).map { |c| c.refers_to = self; c }
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

	def pages
		all.map(&:page).uniq { |p| p.id }
	end

	def save_likes(likesDatabase)
		all.each_with_index { |p,idx| puts idx; likesDatabase.putAll(p.likes) unless likesDatabase.has_post?(p); likesDatabase.persist if (idx%50==0) }
	end
end
