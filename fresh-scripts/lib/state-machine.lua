local API = require("api")

local StateMachine = {}

function StateMachine:new()
    local newObj = {
        states = {}, -- Stores state actions
        conditions = {}, -- Stores conditions for each state
        order = {}, -- Tracks the order of insertion
    }
    self.__index = self
    return setmetatable(newObj, self)
end

function StateMachine:addState(name, condition, action)
    if not self.states[name] then -- Ensure the state is only added once
        table.insert(self.order, name) -- Track the order of insertion
    end
    self.states[name] = action
    self.conditions[name] = condition
end

function StateMachine:getState()
    for _, name in ipairs(self.order) do -- Iterate in insertion order
        local condition = self.conditions[name]
        if condition and condition() then
            return name
        end
    end
    return nil
end

function StateMachine:run()
    local currentState = self:getState()

    API.Write_ScripCuRunning0(currentState)

    if currentState and self.states[currentState] then
        self.states[currentState]() -- Execute the action for the current state
    end
end

return StateMachine
