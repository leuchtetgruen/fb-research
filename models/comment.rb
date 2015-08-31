class Comment < Item
  attr_accessor :author, :message, :refers_to

  def initialize(hash, query_data=Conf::QUERY_DATA)
    super(hash, query_data)
    @author = Person.new(hash["from"])
  end
end
