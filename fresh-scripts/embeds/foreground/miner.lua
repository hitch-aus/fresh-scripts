local API = require("api")
local StateMachine = require("state-machine")
local MINER = require("000usableScripts.MookMiner.ores")

API.SetMaxIdleTime(15)
MINER.Version = "v1.1.4"

local sm = StateMachine:new()

-- Initialize MINER with level-based ore selection
MINER.Level_Map = {
    [1]   = "Copper",
    [5]   = "Tin",
    [10]  = "Iron",
    [20]  = "Coal",
    [30]  = "Mithril",
    [40]  = "Adamantite",
    [50]  = "Runite",
    [60]  = "Orichalcite",
    [75]  = "Phasmatite",
    [81]  = "Banite",
    [90]  = "LightAnimica",
    [100] = "Novite"
}
MINER.DefaultBanking = true
MINER.DefaultOre = nil  -- nil = level-based selection
MINER.StartPaused = false
MINER.Run = true
MINER:Init()
math.randomseed(os.time())

-- Select ore based on level on startup
MINER:SelectOre()
print("Mining script initialized - Selected ore: " .. (MINER.Selected and MINER.Selected.Name or "None"))

local function shouldCheckInventory()
    return Inventory:FreeSpaces() == 0
end

local function checkInventory()
    print("Inventory full")
    
    -- Wait for mining animation to finish
    while API.ReadPlayerAnim() == 32562 and API.Read_LoopyLoop() do
        print("Waiting for mining animation to finish")
        API.RandomSleep2(300, 200, 400)
    end
    
    if MINER:ShouldBank() == false then
        print("Banking disabled, dropping ores")
        local oreIds = MINER.Selected.OreID
        if MINER:CheckInventory() == false then
            print("Failed to open inventory")
            return
        end
        
        for _,id in ipairs(oreIds) do
            while Inventory:InvItemcount(id) > 0 and API.Read_LoopyLoop() do
                API.DoAction_Inventory1(id, 0, 8, API.OFF_ACT_GeneralInterface_route2)
                API.RandomSleep2(400, 200, 800)
            end
        end
        print("Finished dropping")
        return
    end
    
    if MINER.Selected.UseOreBox and MINER:HasOreBox() then
        MINER:SetStatus("Checking ore box")
        print("Checking ore box")
        MINER:FillOreBox()
        
        if Inventory:InvFull() then
            print("Ore box full, banking")
            MINER:SetStatus("Banking")
            MINER.Selected:Bank()
        end
    else
        MINER:SetStatus("Banking")
        MINER.Selected:Bank()
    end
end

local function shouldTraverse()
    if API.ReadPlayerMovin2() then
        return false
    end
    
    if MINER.Selected == nil then
        return false
    end
    
    if MINER:SpotCheck() == false and (MINER.Selected.SpotCheck ~= nil and MINER.Selected:SpotCheck() == false) then
        local nearbyRocks = API.GetAllObjArray1(MINER.Selected.RockIDs, 25, { 0 })
        return #nearbyRocks == 0
    end
    
    return false
end

local function traverse()
    print("Traversing to ore location")
    MINER:Traverse(MINER.Selected)
    API.RandomSleep2(1200, 800, 1600)
end

local function shouldMine()
    -- Ensure ore is selected before attempting to mine
    if MINER.Selected == nil then
        MINER:SelectOre()
    end
    return MINER.Selected ~= nil and Inventory:FreeSpaces() > 0 and API.ReadPlayerAnim() == 0
end

local function mine()
    if MINER.Selected == nil then
        MINER:SelectOre()
    end
    if MINER.Selected then
        MINER.Selected:Mine()
    end
end

sm:addState("CHECK_INVENTORY", shouldCheckInventory, checkInventory)
sm:addState("TRAVERSE", shouldTraverse, traverse)
sm:addState("MINE", shouldMine, mine)
sm:addState("IDLE", function() return true end, function() end)

return {
    name = "miner.lua",
    sm = sm,
    isReadyToPause = function() return API.ReadPlayerAnim() == 0 end
}
