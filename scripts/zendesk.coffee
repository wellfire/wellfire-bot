# Description:
#   Queries Zendesk for information about outstanding tickets
#
# Configuration:
#   HUBOT_ZENDESK_USER
#   HUBOT_ZENDESK_PASSWORD
#   HUBOT_ZENDESK_SUBDOMAIN
#
# Commands:
#   open tickets - returns the total count of open, new, unassigned tickets
#   list open tickets - returns a list of all open/new/unassigned tickets
#   ticket {ID} - returns status, requester, asssignee, type, and latest comment for ticket


module.exports = (robot) ->
  robot.respond /open tickets$/i, (msg) ->
    zendesk_request msg, "search.json?query=\"status:open type:ticket\"", (tickets) ->
      ticket_count = tickets.count
      msg.send "#{ticket_count} open tickets"

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
