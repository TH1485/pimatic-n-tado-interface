Tado = require('./client.js')
var client = new Tado();
var login='';
var pwd='';
client.login(login, pwd).then((success) => {
  console.log("login: " + success);
  return client.api('/me').then((result) => {
    console.log('me',result);
    console.log("homeid: " + result.homes[0].id);
  });
}).catch( (error) => {
  console.log("Error:" + error);
});
client.api('/me').then((result) => {
  console.log('me',result);
  console.log("homeid: " + result.homes[0].name);
}).catch( (error) => {
  console.log("Error:" + error);
});
