MQTT_HOST="192.168.1.2"
MQTT_CLIENT_ID="DOOR_SENSOR"
MQTT_USER_NAME=""
MQTT_PASSWORD=""
WIFI_NAME=""
WIFI_PASSWORD=""

MQTT_STATUS_LED = 4
GPIO_16 = 0

gpio.mode(GPIO_16, gpio.OUTPUT)
gpio.write(GPIO_16, gpio.LOW)
gpio.mode(MQTT_STATUS_LED, gpio.OUTPUT)
gpio.write(MQTT_STATUS_LED, gpio.HIGH)

m = mqtt.Client(MQTT_CLIENT_ID,120,MQTT_USER_NAME,MQTT_PASSWORD)

wifi.setmode(wifi.STATION)
wifi.setphymode(wifi.PHYMODE_N)
wifi.sta.config(WIFI_NAME, WIFI_PASSWORD)
wifi.sta.connect()
tmr.alarm(0, 500, 1, function()
    if wifi.sta.status() == 5 then
        tmr.stop(0)
        gpio.write(MQTT_STATUS_LED, gpio.LOW)
        m:connect(MQTT_HOST, 1883, 0, 1, function(client)
            m:publish('home/sensors/doors/entry', cjson.encode({open=true}) ,0,0, function()
                gpio.write(MQTT_STATUS_LED, gpio.HIGH)
                node.dsleep(0,2)
            end)
        end)
    end
end)
