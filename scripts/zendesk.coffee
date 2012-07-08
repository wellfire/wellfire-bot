# Description:
#   Queries Zendesk for information about support tickets
#
# Configuration:
#   HUBOT_ZENDESK_USER
#   HUBOT_ZENDESK_PASSWORD
#   HUBOT_ZENDESK_SUBDOMAIN
#
# Commands:
#   (all) tickets - returns the total count of all unsolved tickets. The 'all'
#                   keyword is optional.
#   new tickets - returns the count of all new tickets
#   open tickets - returns the count of all open tickets
#   list (all) tickets - returns a list of all unsolved tickets. The 'all'
#                   keyword is optional.
#   list new tickets - returns a list of all new tickets
#   list open tickets - returns a list of all open tickets
#   ticket <ID> - returns informationa about the specified ticket

sys = require 'sys' # Used for debugging

queries =
  unsolved: "search.json?query=\"status<solved type:ticket\""
  open: "search.json?query=\"status:open type:ticket\""
  new: "search.json?query=\"status:new type:ticket\""
  tickets: "tickets"
  users: "users"


zendesk_request = (msg, url, handler) ->
  zendesk_user = "#{process.env.HUBOT_ZENDESK_USER}"
  zendesk_password = "#{process.env.HUBOT_ZENDESK_PASSWORD}"
  auth = new Buffer("#{zendesk_user}:#{zendesk_password}").toString('base64')
  zendesk_url = "https://#{process.env.HUBOT_ZENDESK_SUBDOMAIN}.zendesk.com/api/v2"
  msg.http("#{zendesk_url}/#{url}")
    .headers(Authorization: "Basic #{auth}", Accept: "application/json")
      .get() (err, res, body) ->
        if err
          msg.send "zendesk says: #{err}"
          return
        content = JSON.parse(body)
        handler content

# FIXME this works about as well as a brick floats
zendesk_user = (msg, user_id) ->
  zendesk_request msg, "#{queries.users}/#{user_id}.json", (result) ->
    if result.error
      msg.send result.description
      return
    result.user


module.exports = (robot) ->

  robot.respond /(all )?tickets$/i, (msg) ->
    zendesk_request msg, queries.unsolved, (results) ->
      ticket_count = results.count
      msg.send "#{ticket_count} unsolved tickets"

  robot.respond /new tickets$/i, (msg) ->
    zendesk_request msg, queries.new, (results) ->
      ticket_count = results.count
      msg.send "#{ticket_count} new tickets"

  robot.respond /open tickets$/i, (msg) ->
    zendesk_request msg, queries.open, (results) ->
      ticket_count = results.count
      msg.send "#{ticket_count} open tickets"

  robot.respond /list (all )?tickets$/i, (msg) ->
    zendesk_request msg, queries.unsolved, (results) ->
      for result in results.results
        msg.send "#{result.id} is #{result.status}: #{result.subject}"

  robot.respond /list new tickets$/i, (msg) ->
    zendesk_request msg, queries.new, (results) ->
      for result in results.results
        msg.send "#{result.id} is #{result.status}: #{result.subject}"

  robot.respond /list open tickets$/i, (msg) ->
    zendesk_request msg, queries.open, (results) ->
      for result in results.results
        msg.send "#{result.id} is #{result.status}: #{result.subject}"

  robot.respond /ticket ([\d]+)$/i, (msg) ->
    ticket_id = msg.match[1]
    zendesk_request msg, "#{queries.tickets}/#{ticket_id}.json", (result) ->
      if result.error
        msg.send result.description
        return
      message = "#{result.ticket.subject} ##{result.ticket.id} (#{result.ticket.status.toUpperCase()})"
      message += "\nUpdated: #{result.ticket.updated_at}"
      message += "\nAdded: #{result.ticket.created_at}"
      message += "\nDescription:\n-------\n#{result.ticket.description}\n--------"
      msg.send message
