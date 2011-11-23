# Track the status and trigger buid for hudson CI.
#
# ci list all/projects - list all the projects on Hudson
# ci status <project name> - see a project's status
# ci build <project name> - triger a build on hudson

Http = require 'http'
QS   = require 'querystring'

module.exports = (robot) ->
  host = process.env.HUBOT_CI_HOST
  port = process.env.HUBOT_CI_PORT
  user = process.env.HUBOT_CI_USER
  password = process.env.HUBOT_CI_PASSWORD
  auth     = new Buffer(user + ':' + password).toString("base64")
  headers  = 'Authorization': 'Basic ' + auth
  error_message = "WTF... Is the Hudson down or it's crazy? I can't parse what it said."

  options = (method, path) ->
    {host: host, port: port, method: method, path: path, headers: headers}

  request = (method, path, params, callback) ->
    req = Http.request options(method, path), (response) ->
      data = ""
      response.setEncoding
      response.on "data", (chunk) ->
        data += chunk
      response.on "end", ->
        callback data
    req.write params
    req.end()


  list = (parameter, msg) ->
    switch parameter
      when "all", "projects"
        path = "/api/json"
        param = QS.stringify {}
        request 'GET', path, param, (data) ->
          try
            json = JSON.parse(data)
            if json
              for i of json.jobs
                name = json.jobs[i].name
                status = if json.jobs[i].color == "red" then "FAILING" else "SUCCESS"
                url = json.jobs[i].url
                msg.send("name: #{name}, status: #{status}, url: #{url}")
          catch e
            msg.send error_message

  status = (parameter, msg) ->
    path = "/api/json"
    param = QS.stringify {}
    request 'GET', path, param, (data) ->
      try
        json = JSON.parse(data)
        if json
          match = false
          for i of json.jobs
            if parameter == json.jobs[i].name
              match = true
              status = if json.jobs[i].color == "red" then "FAILING" else "SUCCESS"
              url = json.jobs[i].url
              msg.send("status: #{status}, url: #{url}")

          msg.send("Hmmm... Are you kidding me? Please input the right project name. Or you can use 'ci list projects' to list all projects.") unless match
      catch e
        msg.send error_message

  build = (parameter, msg) ->
    path = "/job/#{parameter}/build"
    param = QS.stringify {}
    request 'GET', path, param, (data) ->
      msg.send("I have told Hudson, please wait...")

  robot.respond /ci (.*) (.*)/i, (msg) ->
    command = msg.match[1]
    parameter = msg.match[2]
    switch command
      when "list" then list(parameter, msg)
      when "status" then status(parameter, msg)
      when "build" then build(parameter, msg)


