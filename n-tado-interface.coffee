module.exports = (env) ->

  # Require the  bluebird promise library
  Promise = env.require 'bluebird'
  
  # Require the [cassert library](https://github.com/rhoot/cassert).
  assert = env.require 'cassert'
  tadoClient = require "./client.coffee"

  class TadoPlugin2 extends env.plugins.Plugin

    init: (app, @framework, @config) =>
      
      client = new tadoClient
      
      
      @loginname = @config.loginname?
      @password = @config.password?
       
      
      @_login= client.login(@loginname, @password).then((connected) =>
        env.logger.debug "Login established, connected with tadowebinterface"
        return client.me().then((home_info) =>
          @_home = home_info.homes[0]
          env.logger.debug('Acquired home: ' + @_home.id)
          resolve(true)
        )
      ).catch((err) ->
        env.logger.error('Error on connecting to tado:' + err)
        env.logger.debug(err)
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
      plugin._login.then( (success) =>
        return plugin.client.state(plugin.home.id, @zone).then((climate) =>
          @_temperature = climate.temperature
          @_humidity = climate.humidity
          @emit "temperature", @_temperature
          @emit "humidity", @_humidity
          )
        ).catch((err) =>
          env.logger.error("Error reading Tado-state of zone #{@zone}: #{err}")
          env.logger.debug(err.error)
        )

    getTemperature: -> Promise.resolve(@_temperature)
    getHumidity: -> Promise.resolve(@_humidity)

  return plugin
