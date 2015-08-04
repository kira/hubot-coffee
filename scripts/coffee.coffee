# Description:
#   Kira Caffienation Support Tools
#
# Commands:
#   hubot coffee [cups] - What you need to make [cups] cups of coffee.
#   hubot brewing - Start a new brewing lineup
#   hubot fresh pot - Announce that a pot is finished
#   hubot fp - Alias for: hubot fresh pot
#   hubot dibs - Reserve your spot in line for a current brew


# water = 3/16 * cups
# scoops = .75 * cups + 2

StatusEmoji = require('./status-emoji')

dibsLimit = process.env.HUBOT_COFFEE_DIBS_LIMIT || 1

freshPots = [
  "http://stream1.gifsoup.com/view6/3131142/chug-coffee-o.gif",
  "http://a4.files.blazepress.com/image/upload/MTI4OTg3NDE5MTAwODc4MDk4.gif",
  "http://38.media.tumblr.com/tumblr_m8wmtj5uqw1qzqwamo1_500.gif",
  "https://images.encyclopediadramatica.se/5/51/I_dont_like_coffee.gif",
  "http://spoonuniversity.com/wp-content/uploads/2015/07/anigif_enhanced-19737-1400112478-17.gif",
  "http://i.huffpost.com/gadgets/slideshows/335861/slide_335861_3385763_free.gif",
  "http://queenmobs.com/wp-content/uploads/2015/07/coffee-sylvester-cat.gif",
  "http://www.meltingmama.net/.a/6a00d8345190c169e20192aa97b3c0970d-pi",
  "https://s-media-cache-ak0.pinimg.com/originals/7c/f0/bc/7cf0bc80401a35b6413fcb7685e87bdc.jpg",
  "http://ak-hdl.buzzfed.com/static/2015-07/7/13/enhanced/webdr12/anigif_enhanced-24754-1436291259-3.gif",
  "http://i.imgur.com/vnuJQ4S.gif",
  "http://25.media.tumblr.com/tumblr_m5bndgzQsI1qic1zfo1_500.gif",
  "https://38.media.tumblr.com/tumblr_m5bnrxFuDj1qic1zfo1_500.gif",
  "https://38.media.tumblr.com/tumblr_mash62P7pW1ro71p1o1_500.gif",
  "https://thelordofthenerds.files.wordpress.com/2014/07/colbert-loves-coffee-o.gif",
  "http://cdn1.theodysseyonline.com/files/2015/06/26/635709513164674737586848637_coffee-talk.gif",
  "http://cdn1.theodysseyonline.com/files/2015/07/10/635720909538639483647877704_coffee-Elf.gif",
]

module.exports = (robot) ->
  statusEmoji = new StatusEmoji

  robot.respond /coffee (\d+)$/i, (msg) ->
    cups = msg.match[1]

    water = (3/16) * cups
    scoops = (0.75 * cups) + 2

    msg.send "You need #{scoops} level scoops and #{water} L of water."

  brewing = {}

  robot.respond /brewing\s*$/i, (msg) ->
    if isBrewing()
      msg.send "A brew is already underway by (@#{brewing.barista})! #{statusEmoji.random('failure')}\n" +
        freeSpots()
      return

    createBrew msg

  robot.respond /(fresh[ -]pot|fp)\s*$/i, (msg) ->
    return handleNoBrew msg if not isBrewing()

    endBrew msg

  robot.respond /dibs\s*$/i, (msg) ->
    return handleNoBrew msg if not isBrewing()

    dibber = robot.brain.usersForFuzzyName(msg.message.user['name'])[0].name

    if dibber in brewing.dibs
      msg.send "Nice try @#{dibber}, you already grabbed a spot! #{statusEmoji.random('failure')}"
      return

    if brewing.dibs.length >= dibsLimit
      msg.send "Sorry! All spots have been claimed. #{statusEmoji.random('failure')}"
      return

    brewing.dibs.push(dibber)

    threadedMsg(msg).send "Ok @#{dibber}, you grabbed :coffee: ##{brewing.dibs.length}! #{statusEmoji.random('success')}"

  isBrewing = ->
    return brewing.dibs?

  threadedMsg = (msg) ->
    # Ensure that the vote response sticks to the original thread
    metadata = msg.envelope.metadata || {}
    metadata.room = brewing.messageMetadata.room if brewing.messageMetadata.room
    metadata.thread_id = brewing.messageMetadata.thread_id if brewing.messageMetadata.thread_id
    metadata.message_id = brewing.messageMetadata.message_id if brewing.messageMetadata.message_id
    msg.envelope.metadata = metadata
    msg

  handleNoBrew = (msg) ->
    msg.send "There is no brew happening! #{statusEmoji.random('failure')}"

  createBrew = (msg) ->
    barista = robot.brain.usersForFuzzyName(msg.message.user['name'])[0].name
    brewing =
      barista: barista
      dibs: [barista],
      messageMetadata: msg.envelope.message.metadata,

    msg.send "@team Brew started by @#{brewing.barista}! #{statusEmoji.random('success')}\n" +
      "To grab a spot use: #{robot.alias}dibs\n" +
      "To end the brew use: #{robot.alias}fresh pot"

  endBrew = (msg) ->

    teamNotify = brewing.dibs.length < dibsLimit

    threadedMsg(msg).send "#{if teamNotify then '@team: ' else ''}Fresh Pot!!! #{msg.random freshPots}" +
      "The dibbed spots are…\n" +
      (":coffee: ##{(parseInt index)+1}: @#{dibber}#{if dibber == brewing.barista then ' (barista)' else ''}" for index, dibber of brewing.dibs).join("\n")

    brewing = {}

  freeSpots = ->
    remaining = dibsLimit - brewing.dibs.length
    "#{remaining} dib#{if remaining == 1 then '' else 's'}"
