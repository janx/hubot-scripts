# Invite people to the server
#
# invite <john@example.com> msg - Invite john@example.com to join the conversation
#

Check = require('validator').check
Mailer = require('nodemailer')

class SmtpBot
  constructor: (options) ->
    @host = options.host
    @port = options.port
    @username = options.username
    @password = options.password
    @ssl = (options.ssl is "true")
    @use_authentication = @username?

    Mailer.SMTP =
      host: @host
      port: @port
      ssl: @ssl
      use_authentication: @use_authentication
      user: @username
      pass: @password

    console?.log Mailer.SMTP

  send: (mail, callback) ->
    Mailer.send_mail mail, (err, success) ->
      if success
        callback 'Email sent'
      else
        callback err

Smtp = new SmtpBot
  host: process.env.HUBOT_SMTP_HOST
  port: process.env.HUBOT_SMTP_PORT
  username: process.env.HUBOT_SMTP_USERNAME
  password: process.env.HUBOT_SMTP_PASSWORD
  use_authentication: process.env.HUBOT_SMTP_USE_AUTHENTICATION
  ssl: process.env.HUBOT_SMTP_SSL

module.exports = (robot) ->
  robot.respond /invite ([a-zA-Z0-9\.\_\-]+@[a-zA-Z0-9\.]+) (.*)/i, (msg) ->
    email = msg.match[1]
    message = msg.match[2]
    invite msg, email, message

invite = (msg, email, message) ->
  try
    Check(email).notNull().isEmail()
    mail =
      to: email
      sender: "irc@intridea.com"
      subject: msg.message.user.name + " invite you to join intridea irc " + msg.message.user.room
      body: message

    Smtp.send mail, (message) ->
      msg.send message
  catch error
    console?.log error
    msg.send "Are you kidding me? Be serious to provide valid email?"