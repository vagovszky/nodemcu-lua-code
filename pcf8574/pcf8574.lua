-- PCF8574A Module

local M={}

M.addr=0x20

-- No registers here, so read/write is extremely simple
M.read = function()
    i2c.start(0)
    i2c.address(0, M.addr, i2c.RECEIVER)
    local data=i2c.read(0, 1)
    i2c.stop(0)
    return data
end

M.write = function(data)
    i2c.start(0)
    i2c.address(0, M.addr, i2c.TRANSMITTER)
    local bytes = i2c.write(0, data)
    i2c.stop(0)
    return bytes
end

return M
