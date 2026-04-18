-- This Script is Part of the Prometheus Obfuscator
--
-- obfuscator-interactive.lua
--
-- This Script provides an interactive interface for the Prometheus Obfuscator

-- ANSI color codes
local Prometheus = require("src.prometheus")
local Logger = require("src.logger")
local colors = {
	reset = "\27[0m",
	red = "\27[31m",
	green = "\27[32m",
	yellow = "\27[33m",
	blue = "\27[34m",
	magenta = "\27[35m",
	cyan = "\27[36m",
	white = "\27[37m",
}

local function colorPrint(color, str)
	print(colors[color] .. str .. colors.reset)
end

local function obfuscate(file, preset)
    colorPrint("blue", "Obfuscating file: " .. file)
	if not preset then
		preset = Prometheus.Presets.Strong
	end
	if not file then
		colorPrint("red", "Error: no file specified")
		return
	end
    local fileContent = io.open(file, "r"):read("*all")
    if not fileContent then
        colorPrint("red", "Error: failed to read file")
        return
    end
    colorPrint("blue", "Creating pipeline...")
	local pipeline = Prometheus.Pipeline:fromConfig(preset)
    Prometheus.Logger.logLevel = Prometheus.Logger.LogLevel.Error
    colorPrint("blue", "Obfuscating file...")
    local obfuscated = pipeline:apply(fileContent)
    if not obfuscated then
        colorPrint("red", "Error: failed to obfuscate file")
        return
    end
    local outFile = file .. ".obfuscated.lua"
    colorPrint("green", "Obfuscated file " .. outFile .. "!")
    if file:sub(-4) == ".lua" then
        outFile = file:sub(0, -5) .. ".obfuscated.lua"
    else
        outFile = file .. ".obfuscated.lua"
    end
    local handle = io.open(outFile, "w")
    handle:write(obfuscated)
    handle:close()
	return obfuscated
end

local commands = {
	help = function()
		colorPrint("yellow", "Available commands:")
		colorPrint("cyan", "  help      - show this help message")
		colorPrint("cyan", "  obfuscate - obfuscate a file (usage: obfuscate <filename>)")
		colorPrint("cyan", "  exit      - exit the REPL")
	end,
	obfuscate = obfuscate,
    obf = obfuscate,
	obfdir = function(dir)
		if not dir then
			colorPrint("red", "Error: no directory specified")
			return
		end
		colorPrint("blue", "Obfuscating all files in directory: " .. dir)
		local handle = io.popen('ls "' .. dir .. '"/*.lua 2>/dev/null')
		if not handle then
			colorPrint("red", "Error: failed to list directory")
			return
		end
		local files = handle:read("*all")
		handle:close()
		for file in files:gmatch("[^\r\n]+") do
			obfuscate(file)
		end
		colorPrint("green", "Finished obfuscating directory!")
	end,
	exit = function()
		colorPrint("magenta", "Goodbye!")
		os.exit(0)
	end,
}

local function split(str, sep)
	local fields = {}
	local pattern = string.format("([^%s]+)", sep)
	str:gsub(pattern, function(c)
		fields[#fields + 1] = c
	end)
	return fields
end

local function cliPrint(str)
	print(colors.blue .. "CLI: " .. colors.reset .. str)
end

colorPrint("green", "Welcome to the Prometheus REPL!")
colorPrint("yellow", "Use the help command to get started.")
print(colors.cyan .. "--------------------------------" .. colors.reset)
while true do
	-- pcall(function()
		io.write(colors.green .. "> " .. colors.reset)
		local input = io.read()
		if not input or input == "" then
			return
		end
		local args = split(input, " ")
		local command = args[1]
		local commandArgs = args[2]
		if not commands[command] then
			colorPrint("red", "Command not found: " .. command)
			return
		end
		commands[command](commandArgs)
	-- end)
end