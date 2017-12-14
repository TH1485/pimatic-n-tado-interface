const Tado = require('./client.js');

let client = new Tado(username,password);
client.login().then((success) => {
  client.api('/me').then((result) => {
    console.log('me', result);
  });
});
