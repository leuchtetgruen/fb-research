require 'net/http'
require 'uri'
require 'json'
require 'pry'

$: << "."

require "config.rb"
require "helpers.rb"
require "models/database.rb"
require "models/item.rb"
require "models/named_item.rb"
require "models/page.rb"
require "models/post.rb"
require "models/person.rb"
require "models/media_item.rb"
require "models/comment.rb"
require "models/event.rb"

peopleDatabase = PeopleDatabase.new
commentsDatabase = CommentsDatabase.new

binding.pry

