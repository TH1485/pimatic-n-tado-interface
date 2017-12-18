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
     
      @loginPromise =
        retry(() => @client.login(loginname, password),
        {max_tries: 10, interval: 100, backoff: 2}
        ).then((connected) =>
          env.logger.info("Login established, connected with tado web interface")
          return @client.me().then( (home_info) =>
            env.logger.info("acquired home: #{home_info.homes[0].name}")
            if @config.debug
              env.logger.debug(JSON.stringify(home_info))
            @setHome(home_info.homes[0])
            Promise.resolve(home_info)
          )
        ).catch((err) ->
          env.logger.error("Could not connect to tado web interface", err)
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
        .then( (state) =>
          if @config.debug
            env.logger.debug("state received: #{JSON.stringify(state)}")
          @_temperature = state.sensorDataPoints.insideTemperature.celsius
          @_humidity = state.sensorDataPoints.humidity.percentage
          @emit "temperature", @_temperature
          @emit "humidity", @_humidity
          Promise.resolve(state)
        )        
      ).catch( (err) =>
        env.logger.error(err)
        if @config.debug
          env.logger.debug("homeId=:" +plugin.home.id)
        Promise.reject(err)
      )
     

    getTemperature: -> Promise.resolve(@_temperature)
    getHumidity: -> Promise.resolve(@_humidity)

  return plugin
