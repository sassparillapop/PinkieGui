-- Loader.lua
local RAW    = "https://raw.githubusercontent.com/sassparillapop/PinkieGui/refs/heads/main/"
local API    = "https://api.github.com/repos/sassparillapop/PinkieGui/contents/"
local BRANCH = "main"

local Players     = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local lp          = Players.LocalPlayer
local playerGui   = lp:WaitForChild("PlayerGui")

-- Wipe any existing copy (re-runs)
local existing = playerGui:FindFirstChild("HomeUI")
if existing then existing:Destroy() end

-- Create the ScreenGui so UI.lua can find it
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "HomeUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

local FOLDER_MAP = {
	Automation = "Auto",
	Player     = "Player",
	Visuals    = "Visuals",
	Settings   = "Settings",
	Stats      = "Stats",
	Donor      = "Donor",
}

local function listFolder(folder)
	local url = API .. folder .. "?ref=" .. BRANCH
	local ok, raw = pcall(game.HttpGet, game, url)
	if not ok or not raw or raw == "" then return {} end
	local ok2, data = pcall(HttpService.JSONDecode, HttpService, raw)
	if not ok2 or type(data) ~= "table" then return {} end
	local files = {}
	for _, entry in ipairs(data) do
		if entry.type == "file" and entry.name:match("%.lua$") then
			table.insert(files, entry.name)
		end
	end
	return files
end

local function fetchConfig(folder, filename, order)
	local url = RAW .. folder .. "/" .. filename
	local ok, raw = pcall(game.HttpGet, game, url)
	if not ok or not raw or raw:match("^%s*$") then return nil end
	local fn, err = loadstring(raw)
	if not fn then return nil end
	local ok2, result = pcall(fn)
	if not ok2 or type(result) ~= "table" or not result.type or not result.label then return nil end
	result.order = result.order or order
	return result
end

local allConfigs = {}
for folder, page in pairs(FOLDER_MAP) do
	for order, filename in ipairs(listFolder(folder)) do
		local cfg = fetchConfig(folder, filename, order)
		if cfg then
			cfg.page = page
			table.insert(allConfigs, cfg)
		end
	end
end

table.sort(allConfigs, function(a, b)
	if a.page ~= b.page then return a.page < b.page end
	return (a.order or 0) < (b.order or 0)
end)

local ok3, uiRaw = pcall(game.HttpGet, game, RAW .. "Main/UI.lua")
if not ok3 or not uiRaw or uiRaw == "" then error("Loader: could not fetch UI.lua") end
local uiFn, uiErr = loadstring(uiRaw)
if not uiFn then error("Loader: UI.lua parse error: " .. tostring(uiErr)) end
uiFn()(allConfigs)
