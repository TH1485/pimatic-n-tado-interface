'use strict';
const request = require('request');
const moment = require('moment');

const BASE_URL = 'https://my.tado.com';
const AUTH_URL = 'https://auth.tado.com';
const CLIENT_ID = 'tado-web-app';
const CLIENT_SECRET = 'wZaRN7rpjn3FoNyF5IFuxg9uMzYJcvOoQ8QWiIqS3hfk6gLhVlG57j5YNoZL2Rtc';
const REFERER = 'https://my.tado.com/';

module.exports = function () {
    
    class Client {
       
       constructor (username,password) {
           this.username=username;
           this.password=password;
       }
        
       login() {
            return new Promise(function (resolve, reject) {
                request.post({
                    url: AUTH_URL + '/oauth/token',
                    qs: {
                        client_id: CLIENT_ID,
                        client_secret: CLIENT_SECRET,
                        grant_type: 'password',
                        password: this.password,
                        username: this.username,
                        scope: 'home.user'
                    },
                    json: true
                }, function (err, response, result) {
                    if (err || response.statusCode !== 200) {
                        reject(err || result);
                    } else {
                        this.saveToken(result);
                        resolve(true);
                    }
                });
            });
        }

        saveToken(token) {
            this.token = token;
            this.token.expires_in = moment().add(token.expires_in, 'seconds').toDate();
        }

        refreshToken() {
            return new Promise(function (resolve, reject) {
                if (!this.token) {
                    return reject(new Error('not logged in'));
                }

                if (moment().subtract(5, 'seconds').isBefore(this.token.expires_in)) {
                    return resolve();
                }

                request.get({
                    url: AUTH_URL + '/oauth/token',
                    qs: {
                        client_id: CLIENT_ID,
                        grant_type: 'refresh_token',
                        refresh_token: this.token.refresh_token
                    },
                    json: true
                }, function (err, response, result) {
                    if (err || response.statusCode !== 200) {
                        reject(err || result);
                    } else {
                        this.saveToken(result);
                        resolve(true);
                    }
                });
            });
        }

        api(path) {
            return this.refreshToken()
                .then(() => {
                    return new Promise(function (resolve, reject) {
                        request.get({
                            url: BASE_URL + '/api/v2' + path,
                            json: true,
                            headers: {
                                referer: REFERER
                            },
                            auth: {
                                bearer: this.token.access_token
                            }
                        }, function (err, response, result) {
                            if (err || response.statusCode !== 200) {
                                reject(err || result);
                            } else {
                                resolve(result);
                            }
                        });
                    });
                });
        }

        me() {
            return this.api('/me');
        }

        home(homeId) {
            return this.api('/homes/${homeId}');
        }

        zones(homeId) {
            return this.api('/homes/${homeId}/zones');
        }

        weather(homeId) {
            return this.api('/homes/${homeId}/weather');
        }

        state(homeId, zoneId) {
            return this.api('/homes/${homeId}/zones/${zoneId}/state' );
        }


    }
return Client;
}

                      
                  
