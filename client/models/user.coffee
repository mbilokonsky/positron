_  = require 'underscore'
Backbone = require 'backbone'
sd = require('sharify').data
async = require 'async'
request = require 'superagent'

module.exports = class User extends Backbone.Model

  urlRoot: "#{sd.API_URL}/users/me"

  isAdmin: ->
    @get('type') is 'Admin'

  refresh: ->
    request.get("#{sd.API_URL}/users/me/refresh")
      .set('X-Access-Token': @get('access_token'))
      .end (err, res) ->
        console.log err
        console.log res

  isOutdated: (callback) ->
    async.parallel [
      (cb) =>
        request.get("#{sd.ARTSY_URL}/api/v1/me")
          .set('X-Access-Token': @get('access_token')).end cb
      (cb) =>
        request.get("#{sd.ARTSY_URL}/api/v1/me/partners")
          .set('X-Access-Token': @get('access_token')).end cb
      (cb) =>
        request.get("#{sd.API_URL}/channels?user_id=#{@get('id')}")
          .set('X-Access-Token': @get('access_token')).end cb
    ], (err, results) =>
      return callback true if err
      user = results[0]?.body
      user.partner_ids = _.map (results[1]?.body or []), (partner) ->
        partner._id
      user.channel_ids = _.pluck results[2]?.body.results, 'id'

      for attr in ['id', 'type', 'name', 'email']
        return callback true if not _.isEqual user[attr], @get(attr)
      for attr in ['channel_ids', 'partner_ids']
        return callback true if _.difference(user[attr], @get(attr)).length > 0
      callback false
