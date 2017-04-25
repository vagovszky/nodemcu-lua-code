MQTT_HOST="mqtt.mydevices.com"
MQTT_CLIENT_ID="00c34be0-1887-11e7-a843-53205e0fd615"
MQTT_USER_NAME="10a8c9a0-aef0-11e6-bfa5-7b3dd1a0d34e"
MQTT_PASSWORD="9e1de88de1c6e2de8c3b651eb3e72b38791d7e03"

MQTT_STATUS_LED = 4
DHT_DATA_PIN = 6

gpio.mode(MQTT_STATUS_LED, gpio.OUTPUT)
gpio.write(MQTT_STATUS_LED, gpio.HIGH)

m = mqtt.Client(MQTT_CLIENT_ID,120,MQTT_USER_NAME,MQTT_PASSWORD)

enduser_setup.start(function() main() end);

function main()
    m:connect(MQTT_HOST, 1883, 0, 1, function(client)
        
        gpio.write(MQTT_STATUS_LED, gpio.LOW)
        m:publish('v1/'..MQTT_USER_NAME..'/things/'..MQTT_CLIENT_ID..'/sys/model', 'IoT Module' ,0,0)
        m:publish('v1/'..MQTT_USER_NAME..'/things/'..MQTT_CLIENT_ID..'/sys/version', '1.0' ,0,0)
        m:publish('v1/'..MQTT_USER_NAME..'/things/'..MQTT_CLIENT_ID..'/sys/cpu/model', 'ESP8266' ,0,0)
        m:publish('v1/'..MQTT_USER_NAME..'/things/'..MQTT_CLIENT_ID..'/sys/cpu/speed', '80000000000' ,0,0)
           
        -- main loop
        tmr.create():alarm(10000, tmr.ALARM_AUTO, function() 
            local status, temp, humi, temp_dec, humi_dec = dht.readxx(DHT_DATA_PIN)
            if status == dht.OK then
                m:publish('v1/'..MQTT_USER_NAME..'/things/'..MQTT_CLIENT_ID..'/data/1', 'temp,c='..string.format('%d.%01d', math.floor(temp), temp_dec),0,0)
                m:publish('v1/'..MQTT_USER_NAME..'/things/'..MQTT_CLIENT_ID..'/data/2', 'rel_hum,p='..string.format('%d.%01d', math.floor(humi), humi_dec) ,0,0)
            end
            gpio.write(MQTT_STATUS_LED, gpio.HIGH)
            m:publish('v1/'..MQTT_USER_NAME..'/things/'..MQTT_CLIENT_ID..'/data/3', 'rssi,dbm='..wifi.sta.getrssi() ,0,0)
            --m:publish('v1/'..MQTT_USER_NAME..'/things/'..MQTT_CLIENT_ID..'/data/4', 'analog_sensor,null='..adc.read(0) ,0,0)
            tmr.create():alarm(200, tmr.ALARM_SINGLE, function() gpio.write(MQTT_STATUS_LED, gpio.LOW) end)
        end)
   end)
end
