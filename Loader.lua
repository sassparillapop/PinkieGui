-- Loader.lua
-- Executor entry point: loadstring(game:HttpGet("...Loader.lua"))()

local BASE_RAW = "https://raw.githubusercontent.com/sassparillapop/PinkieGui/refs/heads/main/"

local FOLDER_MAP = {
	Automation = "Auto",
	Player     = "Player",
	Visuals    = "Visuals",
	Settings   = "Settings",
	Stats      = "Stats",
	Donor      = "Donor",
}

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
	local ok, raw = pcall(game.HttpGet, game, url)
	if not ok or not raw or raw == "" then
		warn("Loader: failed to fetch " .. url .. " → " .. tostring(raw))
		return nil
	end
	local fn, err = loadstring(raw)
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

local allConfigs = {}
for folder, files in pairs(FOLDER_FILES) do
	local page = FOLDER_MAP[folder]
	if not page then continue end
	for order, filename in ipairs(files) do
		local cfg = fetchConfig(folder, filename)
		if cfg then
			cfg.page  = page
			cfg.order = cfg.order or order
			table.insert(allConfigs, cfg)
		end
	end
end

table.sort(allConfigs, function(a, b)
	if a.page ~= b.page then return a.page < b.page end
	return (a.order or 0) < (b.order or 0)
end)

-- Load and boot the UI
local ok2, uiRaw = pcall(game.HttpGet, game, BASE_RAW .. "Main/UI.lua")
if not ok2 or not uiRaw or uiRaw == "" then
	error("Loader: could not fetch UI.lua → " .. tostring(uiRaw))
end
local uiFn, uiErr = loadstring(uiRaw)
if not uiFn then error("Loader: UI.lua parse error: " .. tostring(uiErr)) end
uiFn()(allConfigs)
