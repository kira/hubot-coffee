# Description:
#   What do I need to make X cups of coffee?
#
# Commands:
#   hubot coffee [cups] - What you need to make [cups] cups of coffee.


# water = 3/16 * cups
# scoops = .75 * cups + 2

module.exports = (robot) ->
  robot.respond /coffee (\d+)$/i, (msg) ->
    cups = msg.match[1]

    water = (3/16) * cups
    scoops = (0.75 * cups) + 2

    msg.send "You need #{scoops} level scoops and #{water} L of water."
