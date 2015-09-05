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

	def comments_by(person)
		@data.values.select { |c| c.author == person }
	end
end
