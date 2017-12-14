const Tado = require('./client.js');

const client = new Tado(username,password);
client.login().then((success) => {
  client.api('/me').then((result) => {
    console.log('me', result);
  });
});
