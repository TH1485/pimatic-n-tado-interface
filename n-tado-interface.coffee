module.exports = (env) ->

  # Require the  bluebird promise library
  Promise = env.require 'bluebird'
  
  # Require the [cassert library](https://github.com/rhoot/cassert).
  assert = env.require 'cassert'
  tadoClient = require "./client.coffee"
  settled = (promise) -> Promise.settle([promise])
  
  class TadoPlugin2 extends env.plugins.Plugin

    init: (app, @framework, @config) =>
      
      client = new tadoClient
      client.login("thomas.hensing@gmail.com", "supermij11").then( (connected) =>
        env.logger.info("Login established, connected with tado web interface")
        return client.me().then( (home_info) =>
          home = home_info.homes[0]
          env.logger.info("homeid: " + home.id)
          home_info
        )
      ).catch((err)->
        env.logger.info(err)
      )

      deviceConfigDef = require("./device-config-schema")

      @framework.deviceManager.registerDeviceClass("ZoneClimate", {
        configDef: deviceConfigDef.ZoneClimate,
        createCallback: (config, lastState) ->
          device = new ZoneClimate(config, lastState)
          return device
      })

  plugin = new TadoPlugin2

  class ZoneClimate extends env.devices.TemperatureSensor
    _temperature: null
    _humidity: null

    attributes:
      temperature:
        description: "The measured temperature"
        type: "number"
        unit: '°C'
      humidity:
        description: "The actual degree of Humidity"
        type: "number"
        unit: '%'

    constructor: (@config, lastState) ->
      @name = @config.name
      @id = @config.id
      @zone = @config.zone
      @_temperature = lastState?.temperature?.value
      @_humidity = lastState?.humidity?.value
      super()

      @requestValue()
      @requestValueIntervalId =
        setInterval( ( => @requestValue() ), @config.interval)

    destroy: () ->
      clearInterval @requestValueIntervalId if @requestValueIntervalId?
      super()

    requestValue: ->
      if plugin.home?.id
        plugin.client.state(plugin._home.id, @zone).then((climate) =>
          env.logger.info("state received: " + climate)
          @_temperature = climate.temperature
          @_humidity = climate.humidity
          @emit "temperature", @_temperature
          @emit "humidity", @_humidity
          climate
        ).catch((err) =>
          env.logger.error(err)
        )

    getTemperature: -> Promise.resolve(@_temperature)
    getHumidity: -> Promise.resolve(@_humidity)

  return plugin
