def get_follow_redirects(uri, request_max = 5)
  raise "Max number of redirects reached" if request_max <= 0

  response = Net::HTTP.get_response(uri)
  case response.code.to_i
  when 200
    response.body
  when 301..303
    get_follow_redirects(URI(response['location']), request_max - 1)
  else
    response.code
  end
end


def query(url, klass, wait_after_each_request=Conf::DO_WAIT_AFTER_EACH_REQUEST)
    next_url = url
    a_results = []
    while next_url do
      p next_url if Conf::DEBUG
      begin
        res = Net::HTTP.get(URI.parse(next_url))
        j_res = JSON.parse(res)
        p j_res if Conf::DEBUG
        a_results << j_res["data"]
        next_url = if j_res["paging"]
                     j_res["paging"]["next"]
                   else
                     nil
                   end
      rescue Exception => e
        j_res = {"error" =>  "Could not query data from #{url} for class #{klass.to_s} due to Exception #{e.to_s}"}
      end

      if j_res["error"]
        puts "An error occured. Maybe check your OAUTH_TOKEN in config.rb or your ENV variables"
        p j_res["error"]
      end

      wait if wait_after_each_request
    end
    a_results = a_results.compact.flatten
    a_results.map do |h_result|
      klass.new(h_result)
    end
end

def query_people(url)
  query(url, Person)
end

def query_comments(url)
  query(url, Comment)
end

def query_events(url)
  query(url, Event)
end

def query_pages(url)
  query(url, Page)
end

def query_posts(url)
  posts = query(url, Post)
end

def wait
  puts "Waiting for #{Conf::WAIT_SECONDS} seconds..." if Conf::DEBUG
  sleep(Conf::WAIT_SECONDS)
end

def json(obj,database=false)
  if obj.kind_of? Array
		if database
			obj.map { |o| o.to_h(0, false, true) }.to_json
		else
			obj.map(&:to_h).to_json
		end
  else
		if database
			obj.to_h(0, false, true).to_json
		else
			obj.to_h.to_json
		end
  end
end

def from_json(s, klass)
  obj = JSON.parse(s)
  if obj.kind_of? Array
    obj.map { |h| klass.new(h) }
  else
    klass.new(obj)
  end
end

def csv(obj, seperator=";")
  if obj.kind_of? Array
    ks = obj.first.to_h.keys
    hs = obj.map(&:to_h).map do |item|
      ks.map { |k| item[k] }.join(seperator)
    end

    s = ks.join(seperator) + "\r\n"
    s += hs.join("\r\n")
    s
  else
    h_obj = obj.to_h
    ks = h_obj.keys
    vs = ks.map { |k| h_obj[k] }.join(seperator)
    s = ks.join(seperator) + "\r\n"
    s += vs
    s
  end
end

def save(string, filename)
  File.write(filename, string)
end

def load(filename)
  File.read(filename)
end

def find_friends_instructions(person)
	jsStatement = 'a = document.querySelectorAll(".fsl a"); re = new RegExp("id\=(.*)\&"); b = []; for (var i=0; i < a.length; i++) { if (a[i].attributes["data-hovercard"]) { b.push(a[i].attributes["data-hovercard"].nodeValue.match(re)[1]) } }; console.log(JSON.stringify(b))'
	url = "https://facebook.com/#{person.id}"

	puts "The profile page of th person will open now. Go to their friends page and scroll down until all their friends are loaded."
	puts "Then open the developer console and insert this statement"
	puts jsStatement
	puts "then run  fiend_friends(Person.new(#{person.id}), RESULT, peopleDatabase) where RESULT is what you received from the console"
	system("echo '#{jsStatement}' | pbcopy")
	system("open #{url}")
end

def find_friends(person, array, peopleDatabase)
	friends = array.map { |id| Person.new(id) }
	person.friends = friends
	peopleDatabase.put(person)
	friends.each_with_index { |f, idx| puts "Inserting #{idx} into peopleDatabase..."; peopleDatabase.query_put_get(f); }
	peopleDatabase.persist
	person
end

def import_new_posts(databases)
  pagesDatabase = databases[:pages]
  postsDatabase = databases[:posts]
	raise "Should be PagesDatabase" unless pagesDatabase.kind_of?(PagesDatabase)
	raise "Should be PostsDatabase" unless postsDatabase.kind_of?(PostsDatabase)
	
	pagesDatabase.active.each do |page|
		puts "Querying #{page.name} for new posts..."
		feed = page.feed
		postsDatabase.putNew(feed)
	end
  postsDatabase.persist
end

def import_event(event, databases=@databases)
  eventsDatabase = databases[:events]
  puts "Querying event data..."
  event.query_data
  eventsDatabase.put(event)
  puts "Saving event"
  eventsDatabase.persist

  invitationsDatabase = databases[:invitations]
  puts "Querying invitations..."
  invitations = event.all_invitations
  invitationsDatabase.putAll(invitations)
  puts "Saving invitations"
  invitationsDatabase.persist

  peopleDatabase = databases[:people]
  puts "Saving people (#{invitations.size})..."
  people = invitations.map(&:person)
  peopleDatabase.putAll(people, true)
  peopleDatabase.persist
end

def import_comments_and_likes_from_after(timestamp, databases)
  postsDatabase = databases[:posts]
  pagesDatabase = databases[:pages]
  commentsDatabase = databases[:comments]
  likesDatabase = databases[:likes]
  peopleDatabase = databases[:people]
	raise "Should be PostsDatabase" unless postsDatabase.kind_of?(PostsDatabase)
	raise "Should be PagesDatabase" unless pagesDatabase.kind_of?(PagesDatabase)
	raise "Should be CommentsDatabase" unless commentsDatabase.kind_of?(CommentsDatabase)
	raise "Should be LikesDatabase" unless likesDatabase.kind_of?(LikesDatabase)
	raise "Should be PeopleDatabase" unless peopleDatabase.kind_of?(PeopleDatabase)

	posts = postsDatabase.posts_newer_than(timestamp).select { |post|
		post.page.query_data(pagesDatabase)
		!post.page.ignore
	}
	posts.each_with_index do |post, idx|
		print "Querying #{idx}/#{posts.size}."
		comments = post.comments
		commentsDatabase.putNew(comments)
    comments.each { |c|
      print ","
      c_likes = c.likes
      likesDatabase.putNew(c_likes)
      peopleDatabase.putNew(c_likes.map(&:person))
    }
		print "."
		likes = post.likes
		likesDatabase.putNew(likes)

		print "."
		likes.map(&:person).each { |p| peopleDatabase.query_put_get(p) }
		puts "."
		comments.map(&:author).each { |p| peopleDatabase.query_put_get(p) }
	end
	puts "Saving databases..."
	commentsDatabase.persist
	likesDatabase.persist
	peopleDatabase.persist

	puts "Done."
end

def import_news(dbs=@databases,timespan=1.days.ago)
  puts "Importing new posts from pages..."
  import_new_posts(dbs)
  puts "Importing likes and comments..."
  import_comments_and_likes_from_after(timespan, dbs)
end

def import_page(page, databases, ignore_existing=false)
	pagesDatabase = databases[:pages]
	postsDatabase = databases[:posts]
	commentsDatabase = databases[:comments]
	likesDatabase = databases[:likes]
	peopleDatabase = databases[:people]
	eventsDatabase = databases[:events]
	invitationsDatabase = databases[:invitations]
	raise "Should be PagesDatabase" unless pagesDatabase.kind_of?(PagesDatabase)
	raise "Should be PostsDatabase" unless postsDatabase.kind_of?(PostsDatabase)
	raise "Should be CommentsDatabase" unless commentsDatabase.kind_of?(CommentsDatabase)
	raise "Should be LikesDatabase" unless likesDatabase.kind_of?(LikesDatabase)
	raise "Should be PeopleDatabase" unless peopleDatabase.kind_of?(PeopleDatabase)
	raise "Should be EventsDatabase" unless eventsDatabase.kind_of?(EventsDatabase)
	raise "Should be InvitationsDatabase" unless invitationsDatabase.kind_of?(InvitationsDatabase)

	pagesDatabase.put(page)
	pagesDatabase.persist

	puts "Querying events..."
	events = page.events
	eventsDatabase.putAll(events)
	events.each_with_index do |event, idx|
		print "Querying #{idx}/#{events.size}."
		invitations = event.all_invitations
		invitationsDatabase.putAll(invitations)

		puts "."
		invitations.map(&:person).each { |p| peopleDatabase.query_put_get(p) }
	end
	puts "Saving databases (for events)..."
	eventsDatabase.persist
	invitationsDatabase.persist
	peopleDatabase.persist

	puts "Querying posts..."
	posts = page.feed
	if ignore_existing
		posts = posts.select { |p| !commentsDatabase.has_post?(p) }
	end
	posts.each_with_index do |post, idx|
		print "Querying #{idx}/#{posts.size}."
		comments = post.comments
		commentsDatabase.putAll(comments)
		print "."
		likes = post.likes
		likesDatabase.putAll(likes)

		print "."
		likes.map(&:person).each { |p| peopleDatabase.query_put_get(p) }
		puts "."
		comments.map(&:author).each { |p| peopleDatabase.query_put_get(p) }


		if (((idx % 100)==0) and (idx > 1))
			puts "Saving databases (for posts)..."
			commentsDatabase.persist
			likesDatabase.persist
			peopleDatabase.persist
		end
	end
	puts "Saving databases (for posts)..."
	commentsDatabase.persist
	likesDatabase.persist
	peopleDatabase.persist


	puts "Done."
end

def import_all_comment_likes(databases=@databases)
  likesDatabase = databases[:likes]
  commentsDatabase = databases[:comments]
  peopleDatabase = databases[:people]
  coll = commentsDatabase.all.reverse
  sz = coll.size
  coll.each_with_index do |comment, i|
    print "#{i}/#{sz}..."
    if ((i % 1000 == 0) and (i > 0))
      puts "Saving databases..."
      likesDatabase.persist
      peopleDatabase.persist
    end
    if likesDatabase.exists_for_comment?(comment)
      puts ""
      next
    else 
      puts "."
    end

    likes = comment.likes
    likesDatabase.putAll(likes)
    peopleDatabase.putNew(likes.map(&:person))
  end
end

def likelyness(p1, p2, databases=@databases)
  likesDatabase = databases[:likes]
  likes_p1 = likesDatabase.by_person(p1)
  likes_p2 = likesDatabase.by_person(p2)

  p1_p2 = likes_p1  & likes_p2

  perct_common_p1 = (p1_p2).size.to_f / likes_p1.size.to_f
  perct_common_p2 = (p1_p2).size.to_f / likes_p2.size.to_f

  puts "#{p2.name} likes #{perct_common_p1 * 100}% of #{p1.name}'s likes'"
  puts "#{p1.name} likes #{perct_common_p2 * 100}% of #{p2.name}'s likes'"
end
