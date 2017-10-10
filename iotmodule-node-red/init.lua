pcf8574=require("pcf8574")

MQTT_HOST="192.168.0.1"
MQTT_CLIENT_ID="IOT-Module"
MQTT_USER_NAME=""
MQTT_PASSWORD=""

WIFICFG={}
WIFICFG.ssid="iot-hub"
WIFICFG.pwd=""

MQTT_STATUS_LED = 4
DHT_DATA_PIN = 6
INT_PIN = 5
SCL_PIN = 2
SDA_PIN = 1

register = 255
dhtEnabled = false
pcf8574enabled = false

print("IOT Module initializing...")

tmr.create():alarm(2000, tmr.ALARM_SINGLE, function() setup() end)

function setup()
    print("IOT Module entering setup...")
    gpio.mode(MQTT_STATUS_LED, gpio.OUTPUT)
    gpio.write(MQTT_STATUS_LED, gpio.HIGH)
    gpio.mode(INT_PIN,gpio.INT,gpio.PULLUP)
    i2c.setup(0, SDA_PIN, SCL_PIN, i2c.SLOW)
    m = mqtt.Client(MQTT_CLIENT_ID,120,MQTT_USER_NAME,MQTT_PASSWORD)
    m:on("message", function(m,topic,data) 
        print(topic .. " " .. data)
        if pcf8574enabled and topic == 'iotmodule/output' then
            local dataJson = sjson.decode(data)
            if dataJson.bit~=nil and dataJson.state~=nil then
                id = tonumber(dataJson.bit)
                if tonumber(dataJson.state) == 1 then
                    register = bit.clear(register, id)
                elseif tonumber(dataJson.state) == 0 then
                    register = bit.set(register, id)
                end
                pcf8574.write(register)
            end 
        end
    end)
    -- Check if modules are available
    status, temp, humi, temp_dec, humi_dec = dht.read(DHT_DATA_PIN)
    numB = pcf8574.write(register)
    if numB > 0 then 
        pcf8574enabled = true 
        print("PCF8574 connected...")
    end
    if status == dht.OK then 
        dhtEnabled = true 
        print("DHT module connected...")
    end
    print("Starting wifi...")
    wifi.setmode(wifi.STATION)
    wifi.setphymode(wifi.PHYMODE_N)
    wifi.sta.config(WIFICFG)
    wifi.sta.connect()
    local wifiT = tmr.create()
    wifiT:alarm(1000, tmr.ALARM_AUTO, function()
        print("Connecting to wifi...")
        if wifi.sta.status() == 5 then
            print("Connected to wifi...")
            tmr.unregister(wifiT)
            main()
        end
    end)
end

function main()
    m:connect(MQTT_HOST, 1883, 0, 1, function(client)
        print("Connected to MQTT...")
        gpio.write(MQTT_STATUS_LED, gpio.LOW)
        -- MQTT subscribe
        if pcf8574enabled then
            print("Subscribing topics iotmodule/output")
            m:subscribe('iotmodule/output', 0)
        end
        -- Handle button press
        gpio.trig(INT_PIN, "down", function(level, when) 
            local port = string.byte(pcf8574.read())
            if port ~= nil then
                if port ~= register then
                    local pxor = bit.bxor(port, register)
                    local bitN = 0
                    for i = 0,7 do
                        if (2 ^ i) == pxor then
                            bitN = i
                            break
                        end
                    end
                    m:publish('iotmodule/input', bitN ,0,0, function(client)
                        print('iotmodule/input '..bitN) 
                    end)
                end
            end
        end)
        -- Main loop
        tmr.create():alarm(10000, tmr.ALARM_AUTO, function() 
            local sensorData = {}
            sensorData.temperature = 0
            sensorData.humidity = 0
            sensorData.wifi = 0
            if dhtEnabled then
                status, temp, humi, temp_dec, humi_dec = dht.read(DHT_DATA_PIN)
                if status == dht.OK then
                    sensorData.temperature = string.format('%d.%01d', math.floor(temp), temp_dec)
                    sensorData.humidity = string.format('%d.%01d', math.floor(humi), humi_dec)
                end
            end
            sensorData.wifi = wifi.sta.getrssi()
            gpio.write(MQTT_STATUS_LED, gpio.HIGH)
            print('iotmodule/sensors '..sjson.encode(sensorData))
            m:publish('iotmodule/sensors', sjson.encode(sensorData) ,0,0)
            tmr.create():alarm(200, tmr.ALARM_SINGLE, function() gpio.write(MQTT_STATUS_LED, gpio.LOW) end)
        end)
    end)
end
