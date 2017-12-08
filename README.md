pimatic-tado-interface
================

Support for tado temperature and humidity sensor.

**This plugin uses the python interface PyTado, written by Chris Jewell chrism0dwk@gmail.com - > https://github.com/chrism0dwk/PyTado

### Plugin Configuration

Add the plugin to the plugin section:

```json
{ 
  "plugin": "tado-interface",
  "login" : "mylogin@email.com",
  "password" : "mypassword"
}
```
to device section
```json
{
  "id": "mylivingroom",
  "name": "My Living Room",
  "class": "TadoClimate",
  "zone": 1,
  "interval": 60000
 }
```
