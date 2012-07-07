# Description:
#   Queries Zendesk for information about outstanding tickets
#
# Configuration:
#   HUBOT_ZENDESK_USER
#   HUBOT_ZENDESK_PASSWORD
#   HUBOT_ZENDESK_SUBDOMAIN
#
# Commands:
#   tickets - returns the total count of all unsolved tickets
#   new tickets - returns the count of all new tickets
#   open tickets - returns the count of all open tickets

module.exports = (robot) ->

  robot.respond /(all )?tickets$/i, (msg) ->
    zendesk_request msg, search.unsolved, (tickets) ->
      ticket_count = tickets.count
      msg.send "#{ticket_count} unsolved tickets"

  robot.respond /new tickets$/i, (msg) ->
    zendesk_request msg, search.new, (tickets) ->
      ticket_count = tickets.count
      msg.send "#{ticket_count} new tickets"

  robot.respond /open tickets$/i, (msg) ->
    zendesk_request msg, search.open, (tickets) ->
      ticket_count = tickets.count
      msg.send "#{ticket_count} open tickets"

  search =
    unsolved: "search.json?query=\"status<solved type:ticket\""
    open: "search.json?query=\"status:open type:ticket\""
    new: "search.json?query=\"status:new type:ticket\""

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
