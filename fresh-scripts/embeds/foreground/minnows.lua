package.path = package.path .. ";../../lib/?.lua"

local API = require("api")
local StateMachine = require("state-machine")
local utils = require("jakeutils")
API.SetDrawTrackedSkills(true)

local sm = StateMachine:new()

local isRunning = false

local lastFishedAt = os.time() - 60
local function shouldFish()
    local lastFishedMoreThan30SecsAgo = os.difftime(os.time(), lastFishedAt) > 30
    return (API.ReadPlayerAnim() == 0 or lastFishedMoreThan30SecsAgo or API.Local_PlayerInterActingWith_() == "Electrifying blue blubber jellyfish") and not API.InvFull_()
end

local function shouldBank()
    return API.InvFull_()
end

local function shouldResume()
    return utils.isInWarsRetreat()
end

local function resume()
    if API.ReadPlayerAnim() == 8939 then return end 
    API.DoAction_Interface(0xffffffff, 0xae06, 2, 1464, 15, 2, 3808)
end

local function fish()
    if API.DoAction_NPC_str(0x3c, API.OFF_ACT_InteractNPC_route, { "Minnow shoal" }, 50) then
        utils.waitUntil(function() return API.ReadPlayerAnim() ~= 0 end, 5)
        lastFishedAt = os.time()
    end
end

local function bank()
    API.DoAction_Object1(0x3c,4128,{ 110860 },50)
    utils.waitUntil(shouldFish, 15)
end

-- sm:addState("SPY", utils.shouldSpy, utils.spy)
sm:addState("RESUME", shouldResume, resume)
sm:addState("FISH", shouldFish, fish)
sm:addState("BANK", shouldBank, bank)
sm:addState("IDLE", function() return true end, function() end)

return {
    name = "minnows.lua",
    sm = sm
}