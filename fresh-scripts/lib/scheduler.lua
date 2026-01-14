-- Simple coroutine-based scheduler
local scheduler = {
    tasks = {}
}

function scheduler:enqueue(task)
    table.insert(self.tasks, task)
end

function scheduler:run()
    while #self.tasks > 0 do
        local task = table.remove(self.tasks, 1)
        local co = coroutine.create(task)
        coroutine.resume(co)
    end
end

-- Delays execution by a given number of seconds using coroutine.yield
local function delay(seconds)
    local targetTime = os.time() + seconds
    repeat
        coroutine.yield()
    until os.time() >= targetTime
end

-- Attempts to do something every 1 second until the predicate returns true or max tries are exhausted
function asyncDoUntilTrue(action, predicate, maxTries)
    scheduler:enqueue(function()
        local tries = 0
        repeat
            tries = tries + 1
            local success = action()
            if predicate(success) then
                print("Success after " .. tries .. " tries.")
                return
            else
                delay(1) -- Non-blocking delay
            end
        until tries >= maxTries
        print("Exhausted " .. maxTries .. " tries without success.")
    end)
end

-- Example usage
local function action()
    -- Simulate an action that might fail or succeed randomly
    return math.random() > 0.5
end

local function predicate(result)
    return result == true
end

math.randomseed(os.time()) -- Seed the random number generator

asyncDoUntilTrue(action, predicate, 5)

scheduler:run()
