'use strict'
request = require('request')
moment = require('moment')
BASE_URL = 'https://my.tado.com'
AUTH_URL = 'https://auth.tado.com'
CLIENT_ID = 'tado-web-app'
CLIENT_SECRET = 'wZaRN7rpjn3FoNyF5IFuxg9uMzYJcvOoQ8QWiIqS3hfk6gLhVlG57j5YNoZL2Rtc'
REFERER = 'https://my.tado.com/'

modules.exports = ->

  login = (username, password) ->
    new Promise((resolve, reject) ->
      request.post {
        url: AUTH_URL + '/oauth/token'
        qs:
          client_id: CLIENT_ID
          client_secret: CLIENT_SECRET
          grant_type: 'password'
          password: password
          username: username
          scope: 'home.user'
        json: true
      }, (err, response, result) ->
        if err or response.statusCode != 200
          reject err or result
        else
          @saveToken result
          resolve true
        return
      return
)

  saveToken = (token) ->
    @token = token
    @token.expires_in = moment().add(token.expires_in, 'seconds').toDate()
    return

  refreshToken = ->
    new Promise((resolve, reject) ->
      if !@token
        return reject(new Error('not logged in'))
      if moment().subtract(5, 'seconds').isBefore(@token.expires_in)
        return resolve()
      request.get {
        url: AUTH_URL + '/oauth/token'
        qs:
          client_id: CLIENT_ID
          grant_type: 'refresh_token'
          refresh_token: @token.refresh_token
        json: true
      }, (err, response, result) ->
        if err or response.statusCode != 200
          reject err or result
        else
          @saveToken result
          resolve true
        return
      return
)

  api = (path) ->
    @refreshToken().then ->
      new Promise((resolve, reject) ->
        request.get {
          url: BASE_URL + '/api/v2' + path
          json: true
          headers: referer: REFERER
          auth: bearer: @token.access_token
        }, (err, response, result) ->
          if err or response.statusCode != 200
            reject err or result
          else
            resolve result
          return
        return
)

  me = ->
    @api '/me'

  home = (homeId) ->
    @api '/homes/${homeId}'

  zones = (homeId) ->
    @api '/homes/${homeId}/zones'

  weather = (homeId) ->
    @api '/homes/${homeId}/weather'

  state = (homeId, zoneId) ->
    @api '/homes/${homeId}/zones/${zoneId}/state'

  return
