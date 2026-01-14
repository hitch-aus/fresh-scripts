package.path = package.path .. ";../../lib/?.lua"

local API = require("api")
local StateMachine = require("state-machine")
local utils = require("jakeutils")

local PRESET = 4
local SPOT = 117124
local MAT_CACHE = false

local sm = StateMachine:new()

local function isOutsideKharidetDigsite()
    local KharidetDigsite = { x = 3440, y = 3450, z = 0 }
    return not utils.isAtLocation(KharidetDigsite, 50)
end

local function shouldResume()
    return utils.isInWarsRetreat()
end

local function resume()
    if API.ReadPlayerAnim() == 8939 then return end
    API.DoAction_Interface(0xffffffff, 0xae06, 2, 1464, 15, 2, 3808)
end

local function shouldBank()
    return utils.isInWarsRetreat() and (API.InvFull_() or not utils.inventoryContains("Auto-screener"))
end

local function bank()
    utils.withdrawPresetWarsRetreat(PRESET)
end

local function shouldTeleportToDigsite()
    return utils.isInWarsRetreat() and utils.inventoryContains("Auto-screener") and not API.InvFull_()
end

local function teleportToDigsite()
    if API.Compare2874Status(0, false) then
        -- teleport on master outfit
        API.DoAction_Interface(0xffffffff, 0xae06, 2, 1464, 15, 2, 3808)
    else
        -- teleport on interface
        API.DoAction_Interface(0xffffffff, 0xae06, 2, 1464, 15, 2, 3808)
    end
end

local function enterDigsite()
    if API.Compare2874Status(0, false) then
        -- click entrance
        API.DoAction_Interface(0xffffffff, 0xae06, 2, 1464, 15, 2, 3808)
    else
        -- teleport on interface
        API.DoAction_Interface(0xffffffff, 0xae06, 2, 1464, 15, 2, 3808)
    end
end

local function FindHl(objects, maxdistance, highlight)
    local objObjs = API.GetAllObjArray1(objects, maxdistance, {0})
    local hlObjs = API.GetAllObjArray1(highlight, maxdistance, {4})
    local sprite = {}

    for hl = 1, #hlObjs do
        for obj = 1, #objObjs do
            if objObjs[obj].Tile_XYZ.x == hlObjs[hl].Tile_XYZ.x and objObjs[obj].Tile_XYZ.y == hlObjs[hl].Tile_XYZ.y then
                sprite = objObjs[obj]
                break
            end
        end
    end
    
    return sprite
end

local function shouldDig()
    local spots = API.GetAllObjArrayInteract({ SPOT }, 50, 12)

    return #spots > 0
end

local lastDugPosition = nil
local function dig()
    local spots = API.GetAllObjArrayInteract({ SPOT }, 50, 12)

    if #spots == 0 then
        print("No spots found")
        return
    end

    if MAT_CACHE and not API.CheckAnim(22) then
        API.DoAction_Object_valid1(0x2, 0, { SPOT }, 50, true)
    end

    local sprite = FindHl({ SPOT }, 30, { 7307 })
    if sprite.Id ~= nil then
        local spritePos = WPOINT.new(sprite.TileX / 512, sprite.TileY / 512, sprite.TileZ / 512)

        -- Compare sprite's current position with the last dug position
        if lastDugPosition == nil or (spritePos.x ~= lastDugPosition.x or spritePos.y ~= lastDugPosition.y or spritePos.z ~= lastDugPosition.z) then
            utils.sleep(1000)
            API.DoAction_Object2(0x2, 0, { sprite.Id }, 50, spritePos)
            utils.sleep(1000)
            API.WaitUntilMovingEnds()
            lastDugPosition = spritePos -- Update the last dug position
        end
    else
        if not API.CheckAnim(22) then
            API.DoAction_Object1(0x2, 0, { SPOT }, 50)
        end
    end
end

sm:addState("RESUME", shouldResume, resume)
sm:addState("BANK", shouldBank, bank)
sm:addState("TELEPORT_TO_DIGSITE", shouldTeleportToDigsite, teleportToDigsite)
sm:addState("ENTER_DIGSITE", function() return true end, enterDigsite)
sm:addState("DIG", shouldDig, dig)
sm:addState("IDLE", function() return true end, function() end)

return {
    name = "arch.lua",
    sm = sm
}
