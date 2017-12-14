Tado= require('./client.js')
var client = new Tado();
var login='';
var pwd='';
client.login(login, pwd).then((success) => {
  console.log("login: " + success);
  return client.api('/me').then((result) => {
    console.log('me',result);
  });
}).catch( (error) => {
  console.log("Error:" + error);
});
