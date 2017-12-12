pimatic-n-tado-interface
================

Currently Support for:
- Tado temperature and humidity readout via the public preview api.

**This plugin uses the node-tado, (https://github.com/dVelopment/node-tado)

### Plugin Configuration

Add the plugin to the plugin section:

```json
{ 
  "plugin": "n-tado-interface",
  "login" : "mylogin@email.com",
  "password" : "mypassword"
}
```
to device section
```json
{
  "id": "mylivingroom",
  "name": "My Living Room",
  "class": "ZoneClimate",
  "zone": 1,
  "interval": 120000
 }
```
