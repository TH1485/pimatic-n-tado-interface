module.exports = (env) ->

  # Require the  bluebird promise library
  Promise = env.require 'bluebird'
  # Require the [cassert library](https://github.com/rhoot/cassert).
  assert = env.require 'cassert'
  tadoClient = require "./client.coffee"
  retry = require 'bluebird-retry'

  
  class TadoPlugin2 extends env.plugins.Plugin

    init: (app, @framework, @config) =>
      
      @client = new tadoClient
      loginname= @config.loginname
      password = @config.password
      #@framework.on 'after init', =>
      #@client.login(loginname, password).then( (connected) =>
         # env.logger.info("Login established, connected with tado web interface")
         # return @client.me().then( (home_info) =>
         #   env.logger.info("acquired home_id: "+ home_info.homes[0].id)
         #   @_setHome(home_info.homes[0])
         #   Promise.resolve home_info.homes[0]
         #   )
         # ).catch((err)->
         #   env.logger.info(err)
         #   Promise.reject err
        #  )
      @loginPromise =
        retry(() => @client.login(loginname, password),
        {
          max_tries: 10
          interval: 100
          backoff: 2
        }
        ).then((connected) =>
          env.logger.debug("Login established, connected with tado web interface")
          return @client.me().then( (home_info) =>
            env.logger.debug("acquired home: "+ JSON.stringify(home_info))
            @setHome(home_info.homes[0])
            Promise.resolve(home_info)
          )
        ).catch((err) ->
          env.logger.debug("Could not connect to tado web interface")
          env.logger.error(err)
          Promise.reject(err)
        )

      deviceConfigDef = require("./device-config-schema")

      @framework.deviceManager.registerDeviceClass("ZoneClimate", {
        configDef: deviceConfigDef.ZoneClimate,
        createCallback: (config, lastState) ->
          device = new ZoneClimate(config, lastState)
          return device
      })
    
    setHome: (home) ->
      if home?
        @home = home

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
      #if plugin.home?.id
      plugin.loginPromise
      .then( (success) =>
        return plugin.client.state(plugin.home.id, @zone)
        .then( (climate) =>
          env.logger.debug("state received: " + JSON.stringify(climate))
          @_temperature = climate.sensorDataPoints.insideTemperature.celsius
          @_humidity = climate.sensorDataPoints.humidity.percentage
          @emit "temperature", @_temperature
          @emit "humidity", @_humidity
          Promise.resolve(climate)
        )        
      ).catch( (err) =>
        env.logger.error(err)
        env.logger.debug("homeId=:" +plugin.home.id)
        Promise.reject(err)
      )
     

    getTemperature: -> Promise.resolve(@_temperature)
    getHumidity: -> Promise.resolve(@_humidity)

  return plugin
