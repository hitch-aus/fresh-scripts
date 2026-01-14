local timestamps = {}
local memoizeCache = {}

function timestamps.clearMemoizeCache()
    memoizeCache = {}
end

function timestamps.storeTimestamp(key)
    local appDataPath = os.getenv("LOCALAPPDATA") -- Get the local AppData path
    local filePath = appDataPath .. "\\MemoryErrorScripts\\timestamps.txt" -- Define the file path
    
    -- Ensure the directory exists
    os.execute("mkdir \"" .. appDataPath .. "\\MemoryErrorScripts\"")
    
    -- Read the existing contents, if any
    local lines = {}
    local file = io.open(filePath, "r")
    if file then
        for line in file:lines() do
            if not line:match("^" .. key .. "=") then
                table.insert(lines, line)
            end
        end
        file:close()
    end
    
    -- Add or update the timestamp for the key
    table.insert(lines, key .. "=" .. os.time())
    
    -- Write back to the file
    file = io.open(filePath, "w")
    for _, line in ipairs(lines) do
        file:write(line .. "\n")
    end
    file:close()
    
    -- Clear the memoize cache since the file has changed
    timestamps.clearMemoizeCache()
end

function timestamps.retrieveTimestampDiff(key)
    -- Return cached result if available
    if memoizeCache[key] then
        return memoizeCache[key]
    end
    
    local appDataPath = os.getenv("LOCALAPPDATA")
    local filePath = appDataPath .. "\\MemoryErrorScripts\\timestamps.txt"
    local file = io.open(filePath, "r")
    if not file then return nil end -- File doesn't exist
    
    for line in file:lines() do
        local k, value = line:match("^(.-)=(.-)$")
        if k == key then
            file:close()
            local timestamp = tonumber(value)
            local currentTime = os.time()
            local diff = os.difftime(currentTime, timestamp) -- Difference in seconds
            -- Cache the result before returning
            memoizeCache[key] = diff
            return diff
        end
    end
    
    file:close()
    return nil -- Key not found
end

return timestamps