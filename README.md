# hubot-coffee

A hubot script for announcing & claiming coffee

See [`src/coffee.coffee`](src/coffee.coffee) for full documentation.

## Installation

In hubot project repo, run:

`npm install hubot-coffee --save`

Then add **hubot-coffee** to your `external-scripts.json`:

```json
[
  "hubot-coffee"
]
```

## Sample Interaction

```
user1>> hubot brewing
hubot>> @team Brew started by @user1! :relaxed:
        To grab a spot use: .dibs
        To end the brew use: .fresh pot
```
