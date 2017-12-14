const Tado = require('./client.js');

let client = new Tado();
client.login('username', 'password').then((success) => {
  // use the client now
});
