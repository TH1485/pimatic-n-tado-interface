"use strict";
var Client;

Client = (function() {
  var AUTH_URL, BASE_URL, CLIENT_ID, CLIENT_SECRET, REFERER, moment, request;

  request = require('request');

  moment = require('moment');

  BASE_URL = 'https://my.tado.com';

  AUTH_URL = 'https://auth.tado.com';

  CLIENT_ID = 'tado-web-app';

  CLIENT_SECRET = 'wZaRN7rpjn3FoNyF5IFuxg9uMzYJcvOoQ8QWiIqS3hfk6gLhVlG57j5YNoZL2Rtc';

  REFERER = 'https://my.tado.com/';

  function Client() {}

  Client.prototype.login = function(username, password) {
    return new Promise((function(_this) {
      return function(resolve, reject) {
        return request.post({
          url: AUTH_URL + '/oauth/token',
          qs: {
            client_id: CLIENT_ID,
            client_secret: CLIENT_SECRET,
            grant_type: 'password',
            password: password,
            username: username,
            scope: 'home.user'
          },
          json: true
        }, function(err, response, result) {
          if (err || response.statusCode !== 200) {
            return reject(err || result);
          } else {
            _this.saveToken(result);
            return resolve(true);
          }
        });
      };
    })(this));
  };

  Client.prototype.saveToken = function(token) {
    this.token = token;
    return this.token.expires_in = moment().add(token.expires_in / 2, 'seconds').toDate();
  };

  Client.prototype.refreshToken = function() {
    return new Promise((function(_this) {
      return function(resolve, reject) {
        if (!_this.token) {
          return reject(new Error('not logged in'));
        }
        if (moment().subtract(5, 'seconds').isBefore(_this.token.expires_in)) {
          return resolve();
        }
        return request.post({
          url: AUTH_URL + '/oauth/token',
          qs: {
            client_id: CLIENT_ID,
            client_secret: CLIENT_SECRET,
            grant_type: 'refresh_token',
            refresh_token: _this.token.refresh_token,
            scope: 'home.user'
          },
          json: true
        }, function(err, response, result) {
          if (err || response.statusCode !== 200) {
            return reject(err || result);
          } else {
            _this.saveToken(result);
            return resolve(true);
          }
        });
      };
    })(this));
  };

  Client.prototype.api = function(path) {
    return this.refreshToken().then((function(_this) {
      return function() {
        return new Promise(function(resolve, reject) {
          return request.get({
            url: BASE_URL + '/api/v2' + path,
            json: true,
            headers: {
              referer: REFERER
            },
            auth: {
              bearer: _this.token.access_token
            }
          }, function(err, response, result) {
            if (err || response.statusCode !== 200) {
              return reject(err || result);
            } else {
              return resolve(result);
            }
          });
        });
      };
    })(this));
  };

  Client.prototype.me = function() {
    return this.api('/me');
  };

  Client.prototype.home = function(homeId) {
    return this.api('/homes/${homeId}');
  };

  Client.prototype.zones = function(homeId) {
    return this.api('/homes/${homeId}/zones');
  };

  Client.prototype.weather = function(homeId) {
    return this.api('/homes/${homeId}/weather');
  };

  Client.prototype.state = function(homeId, zoneId) {
    return this.api('/homes/${homeId}/zones/${zoneId}/state');
  };

  return Client;

})();

module.exports = Client;

