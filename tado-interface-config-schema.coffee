# #tado-interface configuration options
module.exports = {
  title: "my plugin config options"
  type: "object"
  properties: {
    loginname:
      description:"Tado weblogin"
      type: "string"
      required: true
    password:
      description:"Tado webpassword"
      type: "string"
      required: true
  } 
}
