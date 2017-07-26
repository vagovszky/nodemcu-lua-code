pcf8574=require("pcf8574")

MQTT_HOST="mqtt.mydevices.com"
MQTT_CLIENT_ID="00c34be0-1887-11e7-a843-53205e0fd615"
MQTT_USER_NAME="10a8c9a0-aef0-11e6-bfa5-7b3dd1a0d34e"
MQTT_PASSWORD="9e1de88de1c6e2de8c3b651eb3e72b38791d7e03"

MQTT_STATUS_LED = 4
DHT_DATA_PIN = 6
INT_PIN = 5
SCL_PIN = 2
SDA_PIN = 1

register = 255
bitSet = 0
dhtEnabled = false
pcf8574enabled = false

tmr.create():alarm(2000, tmr.ALARM_SINGLE, function() setup() end)

function setup()
    gpio.mode(MQTT_STATUS_LED, gpio.OUTPUT)
    gpio.write(MQTT_STATUS_LED, gpio.HIGH)
    gpio.mode(INT_PIN,gpio.INT,gpio.PULLUP)
    i2c.setup(0, SDA_PIN, SCL_PIN, i2c.SLOW)

    m = mqtt.Client(MQTT_CLIENT_ID,120,MQTT_USER_NAME,MQTT_PASSWORD)
    -- Check if modules are available
    status, temp, humi, temp_dec, humi_dec = dht.read(DHT_DATA_PIN)
    numB = pcf8574.write(register)
    if numB > 0 then pcf8574enabled = true end
    if status == dht.OK then dhtEnabled = true end

    if(pcf8574enabled) then
        m:on("message", function(m,topic,data)
            local id = topic:match("/(%d+)$")
            if data~=nil and id~=nil then
                local hash, state = data:match("([^,]+),([^,]+)")
                if state == '1' then
                    register = bit.clear(register, id)
                else
                    register = bit.set(register, id)
                end
                pcf8574.write(register)
                m:publish('v1/'..MQTT_USER_NAME..'/things/'..MQTT_CLIENT_ID..'/data/'..id, 'digital_actuator,null='..state ,0,0)
                m:publish('v1/'..MQTT_USER_NAME..'/things/'..MQTT_CLIENT_ID..'/response', 'ok,'..hash ,0,0)
            end 
        end)
    end

    enduser_setup.start(function() main() end);
end

function main()
    m:connect(MQTT_HOST, 1883, 0, 1, function(client)
        
        gpio.write(MQTT_STATUS_LED, gpio.LOW)
        m:publish('v1/'..MQTT_USER_NAME..'/things/'..MQTT_CLIENT_ID..'/sys/model', 'IoT Module' ,0,0)
        m:publish('v1/'..MQTT_USER_NAME..'/things/'..MQTT_CLIENT_ID..'/sys/version', '1.0' ,0,0)
        m:publish('v1/'..MQTT_USER_NAME..'/things/'..MQTT_CLIENT_ID..'/sys/cpu/model', 'ESP8266' ,0,0)
        m:publish('v1/'..MQTT_USER_NAME..'/things/'..MQTT_CLIENT_ID..'/sys/cpu/speed', '80000000000' ,0,0)
        
        if pcf8574enabled then
            for i = 0,7 do 
                m:subscribe('v1/'..MQTT_USER_NAME..'/things/'..MQTT_CLIENT_ID..'/cmd/'..i, 0)
                m:publish('v1/'..MQTT_USER_NAME..'/things/'..MQTT_CLIENT_ID..'/data/'..i, 'digital_actuator,null=0' ,0,0)
            end
            for i = 0,7 do 
                m:publish('v1/'..MQTT_USER_NAME..'/things/'..MQTT_CLIENT_ID..'/data/'..i+8, 'digital_sensor,d=0' ,0,0)
            end
            -- interupt function
            gpio.trig(INT_PIN, "down", function(level, when) 
                local port = string.byte(pcf8574.read())
                if port ~= nil then
                    if port ~= 255 then
                        for i = 0,7 do
                            if bit.isclear(port, i) then
                                bitSet = i
                                m:publish('v1/'..MQTT_USER_NAME..'/things/'..MQTT_CLIENT_ID..'/data/'..i+8, 'digital_sensor,d=1' ,0,0)
                            end
                        end
                    else
                        m:publish('v1/'..MQTT_USER_NAME..'/things/'..MQTT_CLIENT_ID..'/data/'..bitSet+8, 'digital_sensor,d=0' ,0,0)
                    end
                end
            end)
        end
        -- main loop
        tmr.create():alarm(10000, tmr.ALARM_AUTO, function() 
            if dhtEnabled then
                status, temp, humi, temp_dec, humi_dec = dht.read(DHT_DATA_PIN)
                if status == dht.OK then
                    m:publish('v1/'..MQTT_USER_NAME..'/things/'..MQTT_CLIENT_ID..'/data/17', 'temp,c='..string.format('%d.%01d', math.floor(temp), temp_dec),0,0)
                    m:publish('v1/'..MQTT_USER_NAME..'/things/'..MQTT_CLIENT_ID..'/data/18', 'rel_hum,p='..string.format('%d.%01d', math.floor(humi), humi_dec) ,0,0)
                end
            end
            gpio.write(MQTT_STATUS_LED, gpio.HIGH)
            m:publish('v1/'..MQTT_USER_NAME..'/things/'..MQTT_CLIENT_ID..'/data/16', 'rssi,dbm='..wifi.sta.getrssi() ,0,0)
            tmr.create():alarm(200, tmr.ALARM_SINGLE, function() gpio.write(MQTT_STATUS_LED, gpio.LOW) end)
        end)
   end)
end
