# Description:
#   Queries Harvest for information about invoices
#
# Configuration:
#   HUBOT_HARVEST_USER
#   HUBOT_HARVEST_PASSWORD
#   HUBOT_HARVEST_SUBDOMAIN
#
# Commands:
#   open invoices - returns the total count of open invoices and their sum
#   list open invoices - returns the ID, subject, amount, due date, and URL for each open invoice

harvest_request = (msg, url, handler) ->
  harvest_user = "#{process.env.HUBOT_HARVEST_USER}"
  harvest_password = "#{process.env.HUBOT_HARVEST_PASSWORD}"
  auth = new Buffer("#{harvest_user}:#{harvest_password}").toString('base64')
  harvest_url = "https://#{process.env.HUBOT_HARVEST_SUBDOMAIN}.harvestapp.com"
  msg.http("#{harvest_url}/#{url}")
    .headers(Authorization: "Basic #{auth}", Accept: "application/json")
      .get() (err, res, body) ->
        if err
          msg.send "Harvest says: #{err}"
          return
        content = JSON.parse(body)
        handler content


module.exports = (robot) ->

  robot.respond /open invoices$/i, (msg) ->
    harvest_request msg, '/invoices?status=open', (invoices) ->
      invoice_count = invoices.length
      invoice_sum = Math.round (Number invoice.invoices.amount for invoice in invoices).reduce (x, y) -> x + y
      msg.send "#{invoice_count} open invoices for $#{invoice_sum}"

  robot.respond /list open invoices$/i, (msg) ->
    harvest_request msg, '/invoices?status=open', (invoices) ->
      for invoice_data in invoices
        invoice = invoice_data.invoices
        msg.send "##{invoice.number} #{invoice.subject} for #{invoice.amount} and due #{invoice.due_at} (http://wellfire.harvestapp.com/invoices/#{invoice.id})"
