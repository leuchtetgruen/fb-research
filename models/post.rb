class Post < Item
  attr_accessor :message, :story, :created_time , :page
	
	def initialize(hash, query_data=Conf::QUERY_DATA)
    super(hash, query_data)
    @page = Page.new(hash["page"]) if hash["page"]
	end

  def likes
    query_people(url_for("likes"))  
	end

  def comments
    query_comments(url_for("comments")).map { |c| c.refers_to = self }
  end
end
