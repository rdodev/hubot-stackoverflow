# Description:
#   Fetch and display StackOverflow rep for a user
#
# Dependencies:
#   request
#
# Configuration:
#   HUBOT_STACKEXCHANGE_KEY
#
# Commands:
#   <roboto_name> rep addme {user_guid}
#   <roboto_name> rep me
#
# Notes:
#   None 
#
# Author:
#   rdodev, rgbkrk

r = require('request')
z = require('zlib')

base_url = 'https://api.stackexchange.com/2.1/users/'
url_args = '?site=stackoverflow&key='
storage_prefix = "SOREP_"
so_api_key =  process.env.HUBOT_STACKEXCHANGE_KEY

handle_response = (msg, req, template) ->
  gunzip = z.createGunzip()
  json = "";

  gunzip.on('data', (data) ->
      json += data.toString()
  );

  gunzip.on('end', () ->
      msg.send template JSON.parse json
  );

  req.pipe(gunzip)


get_rep = (msg, template, user_id) ->
  req = r.get base_url + user_id + url_args + so_api_key, {headers: {accept: "application/json", 'Accept-Encoding': 'gzip'}}
  if not req.error
    handle_response(msg, req, template)
  else
    msg.send 'wah wah something broke :~('


module.exports = (robot) ->
  
    robot.respond /rep me/i, (msg) -> 
        # At least for IRC, we need to not be case sensitive
        # Writing back to the user should be in their chosen casing though
        canon_user = msg.message.user.name.toLowerCase()

        so_guid = robot.brain.get storage_prefix + canon_user

        if(so_guid == null)
          msg.send "Sorry, #{msg.message.user.name}, you're not registered."
          msg.send "To register say '#{robot.name} rep addme <stackoverflow_id>'"
          return

        template = (resp) -> 
          message = ""
          message += "*** StackOverflow Reputation for: #{ resp.items[0].display_name }! ***\n"
          message += "Total: #{ resp.items[0].reputation }\n"
          message += "Week: #{ resp.items[0].reputation_change_week }\n"
          message += "Day: #{ resp.items[0].reputation_change_day }"
        
        get_rep msg, template, so_guid

    robot.respond /rep addme (\d+)/i, (msg) -> 
        canon_user = msg.message.user.name.toLowerCase()

        u = robot.brain.get storage_prefix + canon_user
        if not u
            robot.brain.set storage_prefix + canon_user, msg.match[1].trim()
        message = "#{msg.message.user.name}: your StackOverflow id has been registered with me\n"
        msg.send message

    robot.respond /rep delme/i, (msg) -> 
        canon_user = msg.message.user.name.toLowerCase()
        robot.brain.remove storage_prefix + canon_user
        msg.send "#{msg.message.user.name}: your StackOverflow id has been destroyed"
