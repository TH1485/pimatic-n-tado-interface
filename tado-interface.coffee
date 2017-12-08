module.exports = (env) ->
  #require('babel-core').transform('code', {
  #presets: ['full-node4']
  #});
  # Require the  bluebird promise library
  Promise = env.require 'bluebird'

  # Require the [cassert library](https://github.com/rhoot/cassert).
  assert = env.require 'cassert'

  #sensorLib = require 'node-dht-sensor'

  class TadoPlugin extends env.plugins.Plugin

    init: (app, @framework, @config) =>

      deviceConfigDef = require("./device-config-schema")

      @framework.deviceManager.registerDeviceClass("TadoClimate", {
        configDef: deviceConfigDef.TadoClimate,
        createCallback: (config, lastState) ->
          device = new TadoClimate(config, lastState)
          return device
      })
      @loginname = @config.loginname
      @password = @config.password
  
  plugin = new TadoPlugin

  class TadoClimate extends env.devices.TemperatureSensor
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
      spawn = require('child_process').spawn
      py = spawn('python3', ['/home/pi/pimatic-app/node_modules/pimatic-tado-interface/getClimate.py'])
      _data = {"login": plugin.loginname, "password": plugin.password, "zone": @zone}
      dataString = ''
      py.stdout.on('data', (data) =>
        env.logger.debug('stdout: ' + data)
        dataString += data
      )
      py.stderr.on('data', (data) =>
        env.logger.debug('stderr: ' + data)
      )
      py.stdout.on('end', () =>
        try
          jsonData = JSON.parse(dataString)
          @_temperature = jsonData.temperature
          @_humidity = jsonData.humidity
        catch (e)
          env.logger.error("Error reading Tado-data: #{e.message}")
          env.logger.debug(e.stack)
          
        @emit "temperature", @_temperature
        @emit "humidity", @_humidity
      )
      env.logger.debug('stdin: ' + JSON.stringify(_data))
      py.stdin.write(JSON.stringify(_data))
      py.stdin.end()

    getTemperature: -> Promise.resolve(@_temperature)
    getHumidity: -> Promise.resolve(@_humidity)

 
  return plugin
