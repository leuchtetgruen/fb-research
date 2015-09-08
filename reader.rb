def reader(databases=@databases, timespan=1.days.ago)
  posts = databases[:posts].posts_newer_than(timespan)
  show_posts(posts, databases)
  nil
end

def show_posts(posts, databases=@databases)
  ignored_pages = []
  posts.each do |post|
    post.page.query_data(databases[:pages])
    next if ignored_pages.include? post.page.id
    puts post
    puts "#{databases[:likes].for_post(post).size} likes"
    puts "#{databases[:comments].for_post(post).size} comments"
    puts "(O)pen in Browser, Show (C)omments, Show (L)ikes, (I)gnore page, E(X)it"
    option = STDIN.getch.upcase

    break if option == "X"
    case option
    when 'O'
      system("open \"https://facebook.com/#{post.id}\"")
    when 'L'
      likes = databases[:likes].for_post(post).map { |l| "* #{databases[:people].get(l.person.id).name}" }
      puts likes.join("\r\n")
    when 'C'
      comments = databases[:comments].for_post(post)
      comments.each do |comment|
        puts "  #{comment.to_s(false)}"
        puts "  --- (X) back to posts, (O)pen in Browser, Show (A)ll comments without keypress"
        option = STDIN.getch.upcase if option != "A"
        break if option == "X"
        system("open \"https://facebook.com/#{comment.id}\"") if option == "O"
      end
    when 'I'
      ignored_pages << post.page.id
    end

    if ['O', 'L'].include?(option)
      puts "Press any key for next post"
      STDIN.getch
    end
  end
end
