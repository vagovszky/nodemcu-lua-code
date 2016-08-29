wifi.setmode(wifi.STATION)
wifi.setphymode(wifi.PHYMODE_N)
wifi.sta.config('WIFI_SSID', 'wifipassword')
wifi.sta.connect()
wifi.sta.setip({ip='192.168.0.254',netmask='255.255.255.0',gateway='192.168.0.1'})
uart.setup(0, 9600, 8, uart.PARITY_NONE, uart.STOPBITS_1, 0)
m = mqtt.Client('rele',90,'mqttuser','mqttpssword')
function loop()
 if wifi.sta.status() == 5 then
   tmr.stop(0)
   m:connect('192.168.0.2', 8883, 1, 1, function(conn)
      m:subscribe('/rele/command', 0)
      m:on("message", function(client, topic, data) 
      if data ~= nil then
       uart.write(0, data)
      end
     end)   
   end)  
 end
end
tmr.alarm(0, 1500, 1, function() loop() end)
