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
require "models/invitation.rb"
require "models/event.rb"
require "models/like.rb"

puts "Loading people..."
peopleDatabase = PeopleDatabase.new

puts "Loading pages..."
pagesDatabase = PagesDatabase.new

puts "Loading posts..."
postsDatabase = PostsDatabase.new

puts "Loading events..."
eventsDatabase = EventsDatabase.new

puts "Loading invitations..."
invitationsDatabase = InvitationsDatabase.new

puts "Loading likes..."
likesDatabase = LikesDatabase.new

puts "Loading comments..."
commentsDatabase = CommentsDatabase.new

binding.pry

