local API = require("api")
local StateMachine = require("state-machine")
local utils = require("jakeutils")

API.SetDrawLogs(false)  -- Disable the console logs window

local sm = StateMachine:new()

-- Northern Anachronia Course (30-50)
local currentObstacle = 1
local playerInCorrectArea = nil
local afk = os.time()

local function idleCheck()
    if not API.Read_LoopyLoop() then return end
    local timeDiff = os.difftime(os.time(), afk)
    local randomTime = math.random(180, 280)

    if timeDiff > randomTime then
        API.PIdle2()
        afk = os.time()
    end
end

local function sleep(min_millis, max_millis)
    if not max_millis then
        API.RandomSleep2(min_millis)
    else
        API.RandomSleep2(math.random(min_millis, max_millis))
    end
end

local function isAtCoord(x, y, z)
    local tile = WPOINT.new(x, y, z)
    local waitTime = 20
    local start = os.time()
    while API.Read_LoopyLoop() and API.Math_DistanceW(API.PlayerCoord(), tile) > 0 do
        sleep(10, 40)
        if (os.time() - start >= waitTime) then
            return false
        end
    end
    return true
end

local function waitForAnimation(animationId, maxWaitInSeconds)
    local animation = animationId or 0
    local waitTime = maxWaitInSeconds or 5
    local start = os.time()
    while API.Read_LoopyLoop() and os.time() - start < waitTime do
        if API.ReadPlayerAnim() == animation then
            return true
        end
        sleep(100, 200)
    end
    return false
end

local function activateSurge()
    if not API.Read_LoopyLoop() then return end
    local surgeAB = utils.getSkillOnBar("Surge")
    if surgeAB ~= nil then
        API.DoAction_Ability("Surge", 1, 3808)
        sleep(45, 85)
    end
end

local function interactWithObstacle(id, destX, destY)
    if not API.Read_LoopyLoop() then return false end
    
    idleCheck()
    API.DoRandomEvents()
    
    local startPos = API.PlayerCoord()
    print("Crossing obstacle ID: " .. id .. " from: " .. startPos.x .. ", " .. startPos.y .. " to destination: " .. destX .. ", " .. destY)
    API.DoAction_Object1(0xb5, API.OFF_ACT_GeneralObject_route0, {id}, 50)
    
    -- Wait a moment for interaction to start
    sleep(500, 700)
    
    -- Wait for animation to finish and reach near destination
    local maxWait = 15  -- 15 seconds timeout
    local start = os.time()
    local reached = false
    
    while API.Read_LoopyLoop() and os.time() - start < maxWait do
        local playerPos = API.PlayerCoord()
        local dx = math.abs(playerPos.x - destX)
        local dy = math.abs(playerPos.y - destY)
        local dist = dx + dy
        
        -- Within 2 tiles is good enough
        if dist <= 2 then
            print("Near destination! Distance: " .. dist)
            reached = true
            break
        end
        
        -- Check if we stopped moving
        local anim = API.ReadPlayerAnim()
        if anim == 0 or anim == -1 then
            -- Check if we're close enough even if animation stopped
            if dist <= 5 then
                print("Close enough to destination. Distance: " .. dist)
                reached = true
                break
            end
        end
        
        sleep(200, 300)
    end
    
    if not reached then
        local finalPos = API.PlayerCoord()
        print("Timeout - Final position: " .. finalPos.x .. ", " .. finalPos.y)
        return false
    end
    
    -- Wait a moment for any remaining animation
    sleep(300, 500)
    return true
end

local function shouldRunCourse()
    return true  -- Always check if we should run
end

local function runCourse()
    if not API.Read_LoopyLoop() then 
        print("DEBUG: Read_LoopyLoop is false")
        return 
    end
    
    local obstacles = {
        {id = 113468, finalCoords = {5427, 2381}},
        {id = 113469, finalCoords = {5423, 2379}},
        {id = 113470, finalCoords = {5415, 2383}},
        {id = 113471, finalCoords = {5415, 2390}},
        {id = 113472, finalCoords = {5415, 2398}},
        {id = 113473, finalCoords = {5415, 2405}},
        {id = 113474, finalCoords = {5423, 2407}}
    }

    -- Check if player is in the course area
    if playerInCorrectArea == nil then
        local playerPos = API.PlayerCoord()
        print("DEBUG: Checking area - Player pos: " .. playerPos.x .. ", " .. playerPos.y)
        
        if API.PInArea21(5410, 5430, 2375, 2415) then
            playerInCorrectArea = true
            print("Player detected in Anachronia course area")
            
            -- Find the nearest obstacle to start from
            local minDist = math.huge
            local startObstacle = 1
            
            for i, obstacle in ipairs(obstacles) do
                local dx = math.abs(playerPos.x - obstacle.finalCoords[1])
                local dy = math.abs(playerPos.y - obstacle.finalCoords[2])
                local dist = dx + dy
                if dist < minDist then
                    minDist = dist
                    startObstacle = i
                end
            end
            
            currentObstacle = startObstacle
            print("Starting from obstacle " .. currentObstacle .. " (Distance: " .. minDist .. ")")
        else
            print("DEBUG: Not in Anachronia course area - move to coordinates 5410-5430, 2375-2415")
            return
        end
    end

    if playerInCorrectArea then
        local anim = API.ReadPlayerAnim()
        print("DEBUG: In area, checking animation: " .. tostring(anim) .. ", Current obstacle: " .. currentObstacle)
        
        if anim == 0 or anim == -1 then
            if currentObstacle <= 7 then
                local obstacle = obstacles[currentObstacle]
                print("Attempting obstacle " .. currentObstacle .. " (ID: " .. obstacle.id .. ")")
                
                if interactWithObstacle(obstacle.id, obstacle.finalCoords[1], obstacle.finalCoords[2]) then
                    print("Successfully completed obstacle " .. currentObstacle)
                    
                    -- Use surge after obstacle 3 if available
                    if currentObstacle == 3 then
                        activateSurge()
                    end
                    
                    currentObstacle = currentObstacle + 1
                    
                    if currentObstacle > 7 then
                        print("Course completed, restarting...")
                        currentObstacle = 1
                    end
                else
                    print("Failed obstacle " .. currentObstacle .. ", will retry")
                end
            end
        else
            print("DEBUG: Waiting for animation to finish: " .. tostring(anim))
        end
    end
end

sm:addState("RUN_COURSE", shouldRunCourse, runCourse)
sm:addState("IDLE", function() return true end, function() end)

return {
    name = "agility-anachronia.lua",
    sm = sm,
    isReadyToPause = function() 
        local loc = { x = 5427, y = 2381, z = 0 }
        return utils.isAtLocation(loc, 10)
    end
}
