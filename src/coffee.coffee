# Description
#   A hubot script for announcing & claiming coffee
#
# Configuration:
#   HUBOT_COFFEE_DIBS_LIMIT Set the dibs limit (Default 6)
#   HUBOT_COFFEE_DIBS_DURATION Set the dibs time limit in seconds (Default 600 seconds (10 minutes))
#
# Commands:
#   hubot brewing - Start a new brewing lineup
#   hubot fresh pot - Announce that a pot is finished
#   hubot fp - Alias for: hubot fresh pot
#   hubot dibs - Reserve your spot in line for a current brew
#   hubot coffee balance [user] - Check your coffee balance (defaults to you)
#   hubot coffee top [n] - See the top coffee balances (defaults to 10)
#   hubot coffee bottom [n] - See the bottom coffee balances (defaults to 10)
#   hubot coffee bounty <n> - Issue a bounty worth `<n>` :coffee:s to be claimed by the next barista
#
#
# Author:
#   brent@kiratalent.com, Kira Talent Inc.

dateformat = require 'dateformat'

dibsLimit = process.env.HUBOT_COFFEE_DIBS_LIMIT || 6
dibsDuration = process.env.HUBOT_COFFEE_DIBS_DURATION || (60 * 10)

class StatusEmoji
  success: [':dancer:', ':relaxed:', ':grin:', ':smile:', ':sunglasses:'],
  pending: [':worried:', ':see_no_evil:', ':no_mouth:', ':neutral_face:']
  failure: [':cry:', ':angry:', ':fearful:', ':sob:', ':disappointed:']

  random: (status) ->
    emojis = @[status] || []
    return emojis[Math.floor(Math.random() * emojis.length)]

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
  "https://media.giphy.com/media/11Lz1Y4n1f2j96/giphy.gif",
  "http://imagesmtv-a.akamaihd.net/uri/mgid:file:http:shared:mtv.com/news/wp-content/uploads/2015/10/coffee-iv-1443999849.gif",
  "https://media.giphy.com/media/yLpNlfdHBaXQs/giphy.gif",
  "http://i.imgur.com/EYRpuaz.gif",
  "http://i0.kym-cdn.com/photos/images/newsfeed/000/605/727/cae.gif",
  "http://img.memecdn.com/this-coffee-is-fantastic-now-where-is-your-peroxide_o_588657.gif",
  "http://img.memecdn.com/le-coffee_o_523768.gif",
  "https://s-media-cache-ak0.pinimg.com/originals/bb/74/cb/bb74cbbed8dca8ca4e25f8ffa5156620.gif",
  "http://31.media.tumblr.com/3ae02ce94f54ed9e47a7f214f1e390c2/tumblr_n6mycaAO111somw7ho1_250.gif",
  "https://ak-hdl.buzzfed.com/static/2015-05/10/20/imagebuzz/webdr11/anigif_optimized-15275-1431304767-6.gif",
  "https://media.giphy.com/media/iHgMN3wishlde/giphy.gif",
  "https://media.giphy.com/media/oZEBLugoTthxS/giphy.gif",
  "https://media.giphy.com/media/3oKIPx16LFvftHPLiM/giphy.gif",
  "https://media.giphy.com/media/26uffErnoIpeQ3PmU/giphy.gif",
  "https://media.giphy.com/media/ceeFbVxiZzMBi/giphy.gif",
  "https://media.giphy.com/media/xThuWjDsB8IbJggCME/giphy.gif",
  "https://media.giphy.com/media/Rf3rGzWqKXsw8/giphy.gif",
  "https://media.giphy.com/media/xT5LMT6SSx83oZz464/giphy.gif",
  "https://media.giphy.com/media/3o85xrFlGdyGk2t9aU/giphy.gif",
  "https://media.giphy.com/media/3o6Ztfg45ZhI9oagxO/giphy.gif",
  "https://media.giphy.com/media/l0MYFwjgTKh5X4jew/giphy.gif",
]

module.exports = (robot) ->
  statusEmoji = new StatusEmoji

  brewing = {}
  robot.brain.on 'loaded', =>
    robot.brain.data.coffee ?= {brewing: {}}
    brewing = robot.brain.data.coffee.brewing ?= {}

  bounty = {}

  coffeeconomy = new Coffeeconomy robot

  robot.respond /coffee balance(?:\s+@?([^ ]+)\s*)?$/i, (msg) ->
    clientName = msg.match[1] || msg.message.user.name
    matchedClients = robot.brain.usersForFuzzyName(clientName)

    if matchedClients.length > 1
      msg.send "Did you mean: #{matchedClients.join ', '}?"
      return

    client = matchedClients[0]

    if not client
      msg.send "Sorry, I don't know anyone named #{clientName}! #{statusEmoji.random('failure')}"
      return

    if not coffeeconomy.hasAccount client
      msg.send "#{client.name} hasn't opened an account by `#{robot.alias}brewing` or " +
          "`#{robot.alias}dibs`ing yet! #{statusEmoji.random('failure')}"
      return
    msg.send coffeeconomy.accountFormatter coffeeconomy.account client

  robot.respond /coffee top(?:\s+(\d+))?$/i, (msg) ->
    limit = parseInt msg.match[1]?.trim() || 10
    count = 1
    topList = (
      coffeeconomy.topListEntryFormatter count++, account\
      for account in coffeeconomy.top limit
    )
    msg.send "These are the top :coffee: accounts:\n #{topList.join('\n')}"

  robot.respond /coffee bottom(?:\s+(\d+))?$/i, (msg) ->
    limit = parseInt msg.match[1]?.trim() || 10
    total = coffeeconomy.length()

    bottomList = (
      coffeeconomy.topListEntryFormatter total--, account\
      for account in coffeeconomy.bottom limit
    )

    msg.send "These are the bottom :coffee: accounts:\n #{bottomList.join('\n')}"

  robot.respond /brewing\s*$/i, (msg) ->
    if isBrewing()
      msg.send "A brew is already underway by (@#{brewing.barista})! " +
          "#{statusEmoji.random('failure')}\n" + freeSpots()
      return

    createBrew msg

  robot.respond /coffee bounty\s+(\d+)$/i, (msg) ->
    if isBrewing()
      msg.send "A brew is already underway by (@#{brewing.barista})!" +
          "#{statusEmoji.random('failure')}\n" + freeSpots()
      return

    issuer = robot.brain.usersForFuzzyName(msg.message.user['name'])[0].name
    proposedReward = parseInt msg.match[1]?.trim() || 0
    account = coffeeconomy.account issuer

    if not proposedReward
      return

    if not coffeeconomy.hasAccount issuer
      msg.send "Sorry @#{issuer}, you don't have an account with us! #{statusEmoji.random('failure')}"
      return

    if proposedReward > account.balance
      msg.send "Whoa whoa whoa @#{issuer}, you don't have that many :coffee:s cowboy. #{statusEmoji.random('failure')} \n" +
        "Your current balance is: \n#{coffeeconomy.accountFormatter account}"
      return

    if hasBounty() and proposedReward > bounty.reward
      if issuer is bounty.issuer
        msg.send "@#{issuer} has raised the bounty from #{bounty.reward} to #{proposedReward}."
      else
        msg.send "@#{issuer} has outbid @#{bounty.issuer}'s bounty of #{bounty.reward} by increasing it to #{proposedReward}."
    else if hasBounty() and proposedReward <= bounty.reward
      msg.send "A bounty of #{bounty.reward} by #{issuer} has already been issued. #{statusEmoji.random('failure')}"
      return
    else
      msg.send "@team #{issuer} has issued a bounty of #{proposedReward}."

    createBounty issuer, proposedReward

  robot.respond /(fresh[ -]?pot|fp)\s*$/i, (msg) ->
    return handleNoBrew msg if not isBrewing()

    endBrew msg

  robot.respond /dibs\s*$/i, (msg) ->
    return handleNoBrew msg if not isBrewing()

    dibber = robot.brain.usersForFuzzyName(msg.message.user['name'])[0].name
    dib dibber, msg

  hasBounty = -> bounty.reward > 0

  clearBounty = ->
    bounty = {}

  createBounty = (issuer, reward) ->
    bounty =
      issuer: issuer,
      reward: reward,


  dib = (dibber, msg) ->
    if dibber in brewing.dibs
      msg.send "Nice try @#{dibber}, you already grabbed a spot! #{statusEmoji.random('failure')}"
      return

    if brewing.dibs.length >= dibsLimit
      msg.send "Sorry! All spots have been claimed. #{statusEmoji.random('failure')}"
      return

    brewing.dibs.push(dibber)

    if hasBounty() and bounty.issuer is dibber
        threadedMsg(msg).send "@#{dibber} has been automatically granted :coffee: spot ##{brewing.dibs.length} for their _outstanding_ bounty! " +
            "#{statusEmoji.random('success')}"
    else
        threadedMsg(msg).send "Ok @#{dibber}, you grabbed :coffee: ##{brewing.dibs.length}! " +
            "#{statusEmoji.random('success')}"

  isBrewing = ->
    return brewing.dibs?

  threadedMsg = (msg) ->
# Ensure that the vote response sticks to the original thread if using the flowdock adapter
    if robot.adatperName = 'flowdock'
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

    if bounty.reward > 0 and barista is bounty.issuer
      msg.send "Hey @#{bounty.issuer} you can't collect your own bounty! **Your bounty has been cancelled.** #{statusEmoji.random('failure')}"
      clearBounty()

    brewing =
      barista: barista
      dibs: [barista],
      messageMetadata: msg.envelope.message?.metadata,

    robot.brain.save()

    if hasBounty()
      msg.send "@team A bountied brew has been started by @#{brewing.barista}! #{statusEmoji.random('success')}\n" +
          "@#{brewing.barista} will be rewarded #{bounty.reward} :coffee:s for this brew.\n" +
          "To grab a spot use: `#{robot.alias}dibs`\n" +
          "To end the brew use: `#{robot.alias}fresh pot`"

      dib bounty.issuer, msg
    else
      msg.send "@team Brew started by @#{brewing.barista}! #{statusEmoji.random('success')}\n" +
          "To grab a spot use: `#{robot.alias}dibs`\n" +
          "To end the brew use: `#{robot.alias}fresh pot`"

  endBrew = (msg) ->
    expiry = new Date (new Date()).getTime() + dibsDuration * 1000

    claims = []
    for i in [1..dibsLimit]
      dibber = brewing.dibs[i - 1]

      if dibber
        client = robot.brain.userForName dibber

        if dibber == brewing.barista
          coffeeconomy.deposit client, dibsLimit - 1

          if hasBounty()
            coffeeconomy.withdraw bounty.issuer, bounty.reward
            coffeeconomy.deposit client, bounty.reward
        else
          coffeeconomy.withdraw client, 1

        account = coffeeconomy.account client

        dibberLabel = "**@#{dibber}**"

        txIcon = ":chart_with_downwards_trend:"
        if dibber == brewing.barista
          txIcon = ":chart_with_upwards_trend:"
          dibberLabel += " _(barista)_"
        else if hasBounty() and dibber == bounty.issuer
          dibberLabel += " _(#{bounty.reward} :coffee:#{if bounty.reward != 1 then 's' else ''} bounty issuer)_"


        claims.push("#{dibberLabel} #{txIcon} " +
            "#{coffeeconomy.balanceFormatter account.balance}")
      else
        claims.push "_Unclaimed!_"

    threadMsg = threadedMsg(msg)
    threadMsg.send "Fresh Pot!!! #{msg.random freshPots} " +
        ":coffee: Claims (valid until #{dateformat expiry, 'h:MM:ss tt'}):\n" +
        ("#{(parseInt index) + 1}. #{claim}" for index, claim of claims).join("\n")

    if claims.length > 1
      setTimeout ->
        threadMsg.send "Claims have expired!"
      , dibsDuration * 1000

    brewing = {}
    clearBounty()
    robot.brain.save()

  freeSpots = ->
    remaining = dibsLimit - brewing.dibs.length
    "#{remaining} dib#{if remaining == 1 then '' else 's'}"


class Coffeeconomy
  constructor: (@robot, brain_ns = 'coffeeconomy') ->
    @brain = @robot.brain
    @storage = {}
    @brain.on 'loaded', =>
      @storage = @brain.data[brain_ns] ?= {}
      @robot.logger.info "Coffeeconomy loaded. #{this.length()} accounts loaded."

  accountNumber: (client) ->
    if typeof client is 'string'
      client = @brain.userForName client

    return client.id if 'id' of client

  client: (accountNumber) ->
    @brain.userForId accountNumber

  accountFormatter: (account) ->
    "**#{@clientFormatter account.accountNumber}**: #{@balanceFormatter account.balance} " +
      "(#{@accountDetailsFormatter account})"

  shortDateFormatter: (date) ->
    dateformat date, "mmm d yyyy h:MMtt"

  longDateFormatter: (date) ->
    dateformat date, "ddd mmm d yyyy 'at' h:MM:ss tt Z"

  clientFormatter: (accountNumber) ->
    "#{(@client accountNumber).name}"

  balanceFormatter: (balance) ->
    "#{balance} :coffee:#{unless balance == 1 then 's' else ''}"

  accountDetailsFormatter: (account) ->
    if account.totals.rewards
      rewardsSummary = "(_+#{account.totals.rewards.earned || 0}_ / " +
        "_-#{account.totals.rewards.paid || 0}_ as/for rewards) "

    "_+#{account.totals.deposited}_ / _-#{account.totals.withdrawn}_ " +
      "#{rewardsSummary||''}" +
      "_Txs:_ #{account.transactions}, _Opened:_ #{@shortDateFormatter account.created}" +
      " #{if account.updated then ", _Updated:_ #{@longDateFormatter account.updated}" else ""}"

  topListEntryFormatter: (index, account) ->
    "_#{index}._ **#{@clientFormatter account.accountNumber}** #{@balanceFormatter account.balance}"

  deposit: (client, amount, reward = false) ->
    @transaction client, amount, reward

  withdraw: (client, amount, reward=false) ->
    @transaction client, (-1 * amount), reward

  transaction: (client, amount, reward=false) ->
    account = @account client
    account.balance += amount

    if reward and not account.totals.rewards
      @initRewards account

    if amount > 0
      account.totals.deposited += amount
      if reward
        account.totals.rewards.earned += amount
    else
      account.totals.withdrawn -= amount
      if reward
        account.totals.rewards.paid -= amount
    account.transactions++
    @saveAccount account

    txType = if amount > 0 then 'deposited to' else 'withdrawn from'

    @robot.logger.info "#{amount} :coffee:s #{txType} #{if reward then "reward " else ""}"+
        "#{client.name} (#{client.id})"

  balance: (client) ->
    (@account client).balance

  hasAccount: (client) ->
    (@accountNumber client) of @storage

  account: (client) ->
    @storage[@accountNumber client] || @openAccount client

  openAccount: (client) ->
    accountNumber: @accountNumber client
    balance: 0
    transactions: 0
    totals:
      deposited: 0
      withdrawn: 0
    created: new Date()

  initRewards: (account) ->
    account.totals.rewards =
      earned: 0
      paid: 0

  saveAccount: (account) ->
    account.updated = new Date()
    @storage[account.accountNumber] = account
    @brain.save()

  orderedAccounts: (descending = true, limit = false) ->
    accounts = ( {
      accountNumber: accountNumber,
      balance: account.balance
    } for accountNumber, account of @storage )

    first = if descending then 1 else 0
    second = if descending then 0 else 1
    accounts.sort -> arguments[first].balance - arguments[second].balance
    accounts[...(limit || accounts.length())]

  top: (limit = 10) ->
    @orderedAccounts true, limit

  bottom: (limit = 10) ->
    @orderedAccounts false, limit

  length: ->
    Object.getOwnPropertyNames(@storage).length
