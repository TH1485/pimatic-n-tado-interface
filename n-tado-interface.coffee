module.exports = (env) ->

  # Require the  bluebird promise library
  Promise = env.require 'bluebird'
  
  # Require the [cassert library](https://github.com/rhoot/cassert).
  assert = env.require 'cassert'
  #commons = require('pimatic-plugin-commons')(env)
  # Require node-tado (https://github.com/dVelopment/node-tado/)
  tadoClient = env.require 'node-tado'
  
  class TadoPlugin2 extends env.plugins.Plugin

    init: (app, @framework, @config) =>
      
      #@base = commons.base @, 'TadoPlugin'
      
      client = new tadoClient()
      #connect to tado
      client.login(@config.loginname, @config.password)
        .try((success) => 
        env.logger.debug "Login established, connected with tado webinterface"
        return client.me().then((home_info) =>
          jsonHome = JSON.parse(home_info)
          @home = jsonHome.homes[0]
          env.logger.debug('Acquired home: '  + JSON.stringify(@home))
          resolve(success)
        )
      ).catch((err) =>
        env.logger.error('Error on connecting to tado: #{err.message}')
        env.logger.debug(err.stack)
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
      @requestValueIntervalId = setInterval( ( => @requestValue() ), @config.interval)

    destroy: () ->
      clearInterval @requestValueIntervalId if @requestValueIntervalId?
      super()

    requestValue: ->
      plugin.client.state(@home.id, @zone).then((climate) =>
        try
          jsonClimate = JSON.parse(climate)
          @_temperature = jsonClimate.temperature
          @_humidity = jsonClimate.humidity
        catch e
          throw e
        @emit "temperature", @_temperature
        @emit "humidity", @_humidity
      ).catch((err) =>
        env.logger.error("Error reading Tado-state of zone #{@zone}: #{err.message}")
        env.logger.debug(err.stack)
      )

    getTemperature: -> Promise.resolve(@_temperature)
    getHumidity: -> Promise.resolve(@_humidity)

  return plugin
