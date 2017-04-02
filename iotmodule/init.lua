MQTT_HOST="mqtt.mydevices.com"
MQTT_CLIENT_ID="92cecdb0-af06-11e6-82f1-ed3c04eeee58"
MQTT_USER_NAME="10a8c9a0-aef0-11e6-bfa5-7b3dd1a0d34e"
MQTT_PASSWORD="9e1de88de1c6e2de8c3b651eb3e72b38791d7e03"

MQTT_STATUS_LED = 4

gpio.mode(MQTT_STATUS_LED, gpio.OUTPUT)
gpio.write(MQTT_STATUS_LED, gpio.HIGH)

m = mqtt.Client(MQTT_CLIENT_ID,120,MQTT_USER_NAME,MQTT_PASSWORD)

blinker = tmr.create()
status = true
tmr.register(blinker, 1000, tmr.ALARM_AUTO, function()
    gpio.write(MQTT_STATUS_LED, status and gpio.HIGH or gpio.LOW)
    status = not status
end)

enduser_setup.start(
  function()
    running, mode = tmr.state(blinker)
    if running == true then
        tmr.stop(blinker)
    end
    main()
  end,
  function(err, str)
    running, mode = tmr.state(blinker)
    if running ~= true then
        tmr.start(blinker)
    end
  end
);

function main()
    m:connect(MQTT_HOST, 1883, 0, 1, function(client)
        gpio.write(MQTT_STATUS_LED, gpio.LOW)
        mainloop = tmr.create()
        tmr.alarm(mainloop, 10000, 1, function() 
          gpio.write(MQTT_STATUS_LED, gpio.HIGH)
          m:publish('v1/'..MQTT_USER_NAME..'/things/'..MQTT_CLIENT_ID..'/data/0', 'temp,c=40' ,0,0)
          tmr.create():alarm(200, tmr.ALARM_SINGLE, function()
            gpio.write(MQTT_STATUS_LED, gpio.LOW)
          end)
        end)
    end, function(client, reason)
        running, mode = tmr.state(blinker)
        if running ~= true then
            tmr.start(blinker)
        end
   end)
end
