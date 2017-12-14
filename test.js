const Tado = require('./client.js');

let client = new Tado();
client.login('username', 'password').then((success) => {
  client.api('/me').then((result) => {
    console.log('me', result);
  });
});
