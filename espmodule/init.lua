LED_GREEN = 2
LED_RED = 1
PUBLISH_INTERVAL = 20

LED_STATUS = 0

gpio.mode(LED_GREEN, gpio.OUTPUT, gpio.PULLUP)
gpio.mode(LED_RED, gpio.OUTPUT, gpio.PULLUP)
gpio.write(LED_GREEN, gpio.LOW)
gpio.write(LED_RED, gpio.LOW)

m = mqtt.Client('ESPMODULE',120,'username','password')

function ledOnOff(rg)
    LED_STATUS = rg
    if rg == 0 then
       gpio.write(LED_GREEN, gpio.LOW)
       gpio.write(LED_RED, gpio.LOW)
    elseif rg == 1 then
       gpio.write(LED_GREEN, gpio.LOW)
       gpio.write(LED_RED, gpio.HIGH)
    elseif rg == 2 then
       gpio.write(LED_GREEN, gpio.HIGH)
       gpio.write(LED_RED, gpio.LOW)
    end
end

function led(rg, blink)
    running, mode = tmr.state(1)
    if blink == true then
        if running ~= true then
            tmr.alarm(1, 800, tmr.ALARM_AUTO, function() 
               if LED_STATUS == 0 then
                ledOnOff(rg)
               else
                ledOnOff(0)
               end
            end)
        end
    else
        if running == true then
            tmr.stop(1)
        end
    end
    ledOnOff(rg)
end
led(1, true)
wifi.setmode(wifi.STATIONAP)
wifi.ap.config({ssid="ESPMODULE", auth=wifi.OPEN})
enduser_setup.manual(true)
enduser_setup.start(
  function()
    led(2, true)
    enduser_setup.stop()
    main()
  end,
  function(err, str)
    led(1, false)
  end
);
function main()
    m:connect('mqtt.thingspeak.com', 1883, 0, 1, function(client)
        tmr.alarm(0, PUBLISH_INTERVAL * 1000, 1, function() 
          led(1, false)
          m:publish('channels/<CHANNEL>/publish/fields/field1/<KEY>', adc.read(0) ,0,0)
          tmr.alarm(2, 200, tmr.ALARM_SINGLE, function() led(2, false) end)
        end)
    end, function(client, reason)
        led(1, false)
   end)
end
