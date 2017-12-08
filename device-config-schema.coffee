module.exports = {
  title: "pimatic-tado-interface device config schemas"
  TadoClimate: {
    title: "TadoClimate config options"
    type: "object"
    extensions: ["xLink", "xAttributeOptions"]
    properties:
      zone:
        description: "Zone id"
        type: "integer"
        required: true
      interval:
        interval: "Interval in ms to interace with Tado web, the minimal reading interval should be 60000 (1 min)"
        type: "integer"
        default: 60000
        required: true
  }
}
