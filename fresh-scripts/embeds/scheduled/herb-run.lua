package.path = package.path .. ";../../lib/?.lua"

local API = require("api")
local StateMachine = require("state-machine")
local utils = require("utils")
local timestamps = require("timestamps")

local PRESET = 8

local sm = StateMachine:new()

local function isAtCroesus()
    local CROESUS_AREA = { x = 0, y = 0, z = 0 }
    utils.isAtLocation(CROESUS_AREA, 50)
end

local function shouldTeleWars()
    local invContainsTrove = utils.inventoryContains("Elder Trove")
    local invFull = API.InvFull_()
    
    if invFull and not invContainsTrove then
        return true
    end

    if invContainsTrove then
        return true
    end

    if not utils.isInWarsRetreat() and not isAtCroesus() then
        return true
    end

    return false
end

local function teleWars()
    API.DoAction_Ability("Retreat Teleport", 1, 3808)
    utils.waitUntil(utils.isInWarsRetreat, 3)

    if utils.inventoryContains("Elder Trove") then
        timestamps.storeTimestamp("bik-trove")
    end
end

local function shouldWithdrawPreset()
    return utils.isInWarsRetreat() and API.InvFull_() and not utils.inventoryContains("Elder Trove")
end

local function withdrawPreset()
    if not API.BankOpen2() then
        API.DoAction_Object_string1(0x2e, 0, { "Bank" }, 50)
        utils.waitUntil(API.BankOpen2, 3600)
    end

    if API.BankOpen2() then
        API.DoAction_Interface(0x24, 0xffffffff, 1, 517, 119, PRESET, 3808)
        local function bankClosed() return not API.BankOpen2() end
        utils.waitUntil(bankClosed, 2)
    end
end

local function shouldTeleCroesus()
    return utils.isInWarsRetreat() and not API.InvFull_()
end

local function teleCroesus()
    API.DoAction_Object_string1(0x39, 0, { "Portal (Croesus)" }, 50)
    utils.waitUntil(isAtCroesus, 10)
end

local function shouldHunt()
    return isAtCroesus() and not API.InvFull_() and not utils.inventoryContains("Elder Trove") and API.ReadPlayerAnim() == 0
end

local function hunt()
    if not API.DoAction_NPC(0xa7,1488,{ 28424, 28421, 28418, 28415 },50) then
        API.DoAction_NPC(0xa7,1488,{ 28423, 28420, 28417, 28414 },50)
    end
end

sm:addState("SPY", utils.shouldSpy, utils.spy)
sm:addState("HUNT", shouldHunt, hunt)
sm:addState("WITHDRAW_PRESET", shouldWithdrawPreset, withdrawPreset)
sm:addState("TELE_WARS", shouldTeleWars, teleWars)
sm:addState("TELE_CROESUS", shouldTeleCroesus, teleCroesus)
sm:addState("IDLE", function () return true end, function () end)

local function shouldRun()
    -- local diff = timestamps.retrieveTimestampDiff("bik-trove")
    -- if diff == nil then return true end

    -- return diff > 600
    return false
end

return {
    name = "herb-run.lua",
    sm = sm,
    shouldRun = shouldRun
}