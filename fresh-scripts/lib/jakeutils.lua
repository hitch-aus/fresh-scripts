local API = require("api")
local utils = {}

function utils.createAntiAfk()
    local lastAntiAfkAction = os.time()

    return function()
        local timeDiff = os.difftime(os.time(), lastAntiAfkAction)
        local randomTime = math.random(3 * 60, 4.5 * 60)

        if timeDiff > randomTime then
            API.PIdle2()
            lastAntiAfkAction = os.time()
        end
    end
end

function utils.sleep(ms)
    API.RandomSleep2(ms, 0, 0)
end

function utils.waitUntil(predicate, timeout)
    local startTime = os.clock()
    local currentTime

    repeat
        if predicate() then
            return true
        end

        API.RandomSleep2(100, 0, 0)
        currentTime = os.clock()
    until (currentTime - startTime) >= timeout

    return false
end

function utils.waitUntilWithCallback(predicate, callback, timeout)
    local startTime = os.clock()
    local currentTime

    repeat
        if predicate() then
            return true
        end

        callback()
        API.RandomSleep2(100, 0, 0)
        currentTime = os.clock()
    until (currentTime - startTime) >= timeout

    return false
end

function utils.isAtLocation(location, distance)
    local distance = distance or 20
    return API.PInArea(location.x, distance, location.y, distance, location.z)
end

function utils.handleRandoms()
    API.DoRandomEvents()
    API.DoAction_NPC(0x29,1488,{ 24521 },50)
    API.DoAction_NPC(0x29,1488,{ 30599 },50)
end

function utils.shouldSpy()
    ---@diagnostic disable-next-line: param-type-mismatch
    return #API.GetAllObjArrayInteract_str({ "Agent 001", "Agent 002", "Agent 003", "Agent 004", "Agent 005", "Agent 006", "Agent 007" }, 1000, {1}) > 0

end

function utils.spy()
    return API.DoAction_NPC_str(0x29, 1488, { "Agent 001", "Agent 002", "Agent 003", "Agent 004", "Agent 005", "Agent 006", "Agent 007" }, 50)
end

function utils.find(vec, element)
    for i = 1, #vec do
        if vec[i] == element then
            return true
        end
    end

    return false
end

function utils.isInWarsRetreat()
    return #API.GetAllObjArrayInteract_str({ "War" }, 50, {1}) > 0
end

function utils.inventoryContains(item)
    return API.InvItemcount_String(item) > 0
end

function utils.withdrawPresetWarsRetreat(preset)
    if not API.BankOpen2() then
        API.DoAction_Object_string1(0x2e, 80, { "Bank" }, 50, true)
        utils.waitUntil(API.BankOpen2, 3600)
    end

    if API.BankOpen2() then
        API.DoAction_Interface(0x24, 0xffffffff, 1, 517, 119, preset, 3808)
        local function bankClosed() return not API.BankOpen2() end
        utils.waitUntil(bankClosed, 2)
    end
end

function utils.vecToTable(userdata)
    local vec = {}
    for i = 1, #userdata do
        vec[i] = userdata[i]
    end

    return vec
end

return utils