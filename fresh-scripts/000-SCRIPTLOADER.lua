local function getScriptDir()
    local sourcePath = debug.getinfo(1,'S').source
    if sourcePath:sub(1,1) == "@" then
        local path = sourcePath:sub(2):match("(.*/)") or sourcePath:sub(2):match("(.*\\)")
        return path or error("Could not determine the script's directory")
    else
        return error("Script source is not a file. Cannot determine directory.")
    end
end

local rootPath = getScriptDir()
local libPath = rootPath .. "lib/?.lua;"
local foregroundPath = rootPath .. "embeds/foreground/?.lua;"
local backgroundPath = rootPath .. "embeds/background/?.lua;"
local scheduledPath = rootPath .. "embeds/scheduled/?.lua;"

package.path = package.path .. ";" .. libPath .. ";" .. foregroundPath .. ";" .. backgroundPath .. ";" .. scheduledPath

local API = require("api")
local utils = require("jakeutils")

API.SetDrawLogs(false)  -- Disable console logs window

local foregroundScripts = {}
local loadedScript = nil

local scheduledScripts = {}
local loadedScheduledScripts = {}

local function getLuaFilenamesFromDirectory(dir)
    local filenames = {}
    local directory = rootPath .. dir

    for filename in io.popen('dir "' .. directory .. '" /b'):lines() do
        if filename:match(".lua$") then
            table.insert(filenames, filename)
        end
    end

    return filenames
end

local function loadScript(scriptName)
    local scriptName = string.gsub(scriptName, ".lua", "")
    local script = require(scriptName)

    if script then
        return script
    end
end

local refresh = 1000

local antiAfk = utils.createAntiAfk()

local selectedScript = "spectre-agility.lua"

API.Write_LoopyLoop(true)
while (API.Read_LoopyLoop()) do
    -- anti-afk
    antiAfk()

    -- randoms
    utils.handleRandoms()

    -- LOAD FOREGROUND SCRIPTS
    if #foregroundScripts == 0 then
        foregroundScripts = getLuaFilenamesFromDirectory("embeds\\foreground")
    end

    if utils.find(foregroundScripts, selectedScript) then
        if loadedScript == nil or loadedScript.name ~= selectedScript then
            loadedScript = loadScript(selectedScript)
        end
    end
    
    -- LOAD SCHEDULED SCRIPTS
    local runningScheduledScript = false

    if #scheduledScripts == 0 then
        scheduledScripts = getLuaFilenamesFromDirectory("embeds\\scheduled")
    end

    if #loadedScheduledScripts == 0 then
        for i = 1, #scheduledScripts do
            local script = loadScript(scheduledScripts[i])
            if script then
                table.insert(loadedScheduledScripts, script)
            end
        end
    end

    for i = 1, #loadedScheduledScripts do
        local script = loadedScheduledScripts[i]
        if script then
            local foregroundScriptIsReady = true
            
            -- if loadedScript then
            --     foregroundScriptIsReady = loadedScript.isReadyToPause()
            -- end

            -- if script.shouldRun() then
            --     script.sm:run()
            --     runningScheduledScript = true
            -- end
        end
    end

    -- RUN FOREGROUND SCRIPT
    if loadedScript and not runningScheduledScript then
        loadedScript.sm:run()
    end

    -- wait $refresh ms before looping
    utils.sleep(refresh)
end