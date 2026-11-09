-- Loader.lua
-- Fetches feature configs from GitHub, then boots the UI renderer.
-- Add new features by pushing a new .lua file to the right folder on GitHub.
-- No changes needed here or in UI.lua.

local HttpService = game:GetService("HttpService")

local BASE_RAW = "https://raw.githubusercontent.com/sassparillapop/PinkieGui/main/"

-- Map GitHub folder names → UI page names (must match your sidebar tab names)
local FOLDER_MAP = {
	Automation = "Auto",
	Player     = "Player",
	Visuals    = "Visuals",
	Settings   = "Settings",
	Stats      = "Stats",
	Donor      = "Donor",
}

-- Files inside each folder (add the filename here when you push a new feature to GitHub)
local FOLDER_FILES = {
	Automation = {
		"Auto Barnaby Glide.lua",
		"Item Blacklist.lua",
		"PinkiesHelper(Auto).lua",
		"Webhook.lua",
	},
	Player   = { "Noclip.lua" },
	Visuals  = { "Fullbright.lua" },
	Settings = { "idk.lua" },
	Stats    = { "Floor Completion.lua" },
	Donor    = { "Gamepasses.lua" },
}

local function fetchConfig(folder, filename)
	local url = BASE_RAW .. folder .. "/" .. filename
	local ok, result = pcall(function()
		return HttpService:GetAsync(url, true)
	end)
	if not ok then
		warn("Loader: failed to fetch " .. url .. " → " .. tostring(result))
		return nil
	end
	-- Each feature file returns a table via loadstring
	local fn, err = loadstring(result)
	if not fn then
		warn("Loader: parse error in " .. filename .. ": " .. tostring(err))
		return nil
	end
	local cfg = fn()
	if type(cfg) ~= "table" then
		warn("Loader: " .. filename .. " did not return a table")
		return nil
	end
	return cfg
end

-- Collect all configs with their page assignment injected
local allConfigs = {}
for folder, files in pairs(FOLDER_FILES) do
	local page = FOLDER_MAP[folder]
	if not page then
		warn("Loader: no page mapping for folder '" .. folder .. "'")
		continue
	end
	for order, filename in ipairs(files) do
		local cfg = fetchConfig(folder, filename)
		if cfg then
			cfg.page  = page
			cfg.order = cfg.order or order  -- file can override order, otherwise insertion order wins
			table.insert(allConfigs, cfg)
		end
	end
end

-- Sort across all pages by page then order
table.sort(allConfigs, function(a, b)
	if a.page ~= b.page then return a.page < b.page end
	return (a.order or 0) < (b.order or 0)
end)

-- Hand off to the UI renderer
local UIModule = require(script.Parent:WaitForChild("UI"))
UIModule.boot(allConfigs)
