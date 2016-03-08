WAIT_TIME = 3500
RAND_ON_TOP_TIME = 2000

OUTPUT_DIR = "output/post-screenshots"

fs = require('fs')
_ = require('underscore')
system = require('system')

console.log "Loading posts..."

casper = require('casper').create()
casper.start().thenOpen 'https://facebook.com/', () ->
  console.log "Facebook loaded"

casper.then () ->
  @evaluate () ->
    document.getElementById("pass").value= system.env['FB_PASSWORD']
    document.getElementById("email").value= system.env['FB_EMAIL']
    document.getElementById("loginbutton").children[0].click()

casper.then () ->
  post_ids.forEach (post_id) ->
    url = "https://facebook.com/#{post_id}"
    fn = "#{OUTPUT_DIR}/#{post_id}.jpg"
    if !fs.exists(fn)
      casper.thenOpen url, () ->
        i = post_ids.indexOf(post_id)
        console.log "#{i} / #{post_ids.length}..."
        console.log "Opened post #{post_id}"
        wait_time = WAIT_TIME + (Math.random() * RAND_ON_TOP_TIME)
        @wait(wait_time)

      casper.then () ->
        console.log("Make a screenshot and save it as #{fn}")
        @capture(fn)
    else
      console.log "Screenshot for #{post_id} already exists"

casper.run()
