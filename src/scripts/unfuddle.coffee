# Interacting with unfuddle
#
# <project shortcut> #ticket_number - display unfuddle ticket
#

Http  = require 'http'
Https = require 'https'
Qs    = require 'querystring'
XML   = require 'libxmljs'

module.exports = (robot) ->
  host     = process.env.HUBOT_UNFUDDLE_SUBDOMAIN + ".unfuddle.com"
  user     = process.env.HUBOT_UNFUDDLE_USER
  password = process.env.HUBOT_UNFUDDLE_PASSWORD
  projects = process.env.HUBOT_UNFUDDLE_PROJECTS.split(",")
  auth     = new Buffer(user + ':' + password).toString("base64")
  headers  =
    'Authorization': 'Basic ' + auth
    'Accept': 'application/xml'

  options = (method, path) ->
    {host: host, port: 443, method: method, path: path, headers: headers}

  request = (method, path, params, callback) ->
    req = Https.request options(method, path), (response) ->
      data = ""

      response.setEncoding "utf8"

      response.on "data", (chunk) ->
        data += chunk

      response.on "end", ->
        callback data

    req.write params
    req.end()

  respond = (project) ->
    [project_prefix, project_id] = project.split(':')
    robot.respond new RegExp(project_prefix + ' #(.*)', 'i'), (msg) ->
      path = "/api/v1/projects/" + project_id + "/tickets/by_number/" + msg.match[1]
      param = Qs.stringify {}
      request 'GET', path, param, (data) ->
        try
          xml = XML.parseXmlString data
          if xml
            msg.send "[Socialspring ticket #" + msg.match[1] + "] " + xml.get('//summary').text()
            msg.send "[component] " + xml.get('//component').text()
            msg.send "[status] " + xml.get('//status').text()
            msg.send "[resolution] " + xml.get('//resolution').text() + ": " + xml.get('//resolution-description').text()
            msg.send "[description] " + xml.get('//description').text()
        catch e
          msg.send "Failed to parse ticket ... *-.-*"

  respond(project) for project in projects
