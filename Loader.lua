-- Loader.lua (Fuckbro)
-- loadstring(game:HttpGet("https://raw.githubusercontent.com/sassparillapop/PinkieGui/refs/heads/main/Loader.lua"))()

local RAW     = "https://raw.githubusercontent.com/sassparillapop/PinkieGui/refs/heads/main/"
local API     = "https://api.github.com/repos/sassparillapop/PinkieGui/contents/"
local BRANCH  = "main"

-- GitHub folder name → UI page name (matches your sidebar tab names)
local FOLDER_MAP = {
	Automation = "Auto",
	Player     = "Player",
	Visuals    = "Visuals",
	Settings   = "Settings",
	Stats      = "Stats",
	Donor      = "Donor",
}

local HttpService = game:GetService("HttpService")

-- Hit the GitHub contents API to list all .lua files in a folder dynamically
local function listFolder(folder)
	local url = API .. folder .. "?ref=" .. BRANCH
	local ok, raw = pcall(game.HttpGet, game, url)
	if not ok or not raw or raw == "" then
		warn("Loader: could not list folder '" .. folder .. "': " .. tostring(raw))
		return {}
	end
	local ok2, data = pcall(HttpService.JSONDecode, HttpService, raw)
	if not ok2 or type(data) ~= "table" then
		warn("Loader: bad JSON for folder '" .. folder .. "'")
		return {}
	end
	local files = {}
	for _, entry in ipairs(data) do
		if entry.type == "file" and entry.name:match("%.lua$") then
			table.insert(files, entry.name)
		end
	end
	return files
end

-- Fetch and safely execute one feature file
-- Returns a valid config table or nil — never errors the whole script
local function fetchConfig(folder, filename, order)
	local url = RAW .. folder .. "/" .. filename
	local ok, raw = pcall(game.HttpGet, game, url)
	if not ok or not raw or raw == "" then
		warn("Loader: could not fetch " .. filename)
		return nil
	end
	-- File is empty or whitespace only — skip silently
	if raw:match("^%s*$") then return nil end

	local fn, err = loadstring(raw)
	if not fn then
		warn("Loader: syntax error in " .. filename .. ": " .. tostring(err))
		return nil
	end
	local ok2, result = pcall(fn)
	if not ok2 then
		warn("Loader: runtime error in " .. filename .. ": " .. tostring(result))
		return nil
	end
	-- File must return a table with at least type and label — anything else silently ignored
	if type(result) ~= "table" or not result.type or not result.label then
		return nil
	end
	result.order = result.order or order
	return result
end

-- Discover and load all features across all mapped folders
local allConfigs = {}
for folder, page in pairs(FOLDER_MAP) do
	local files = listFolder(folder)
	for order, filename in ipairs(files) do
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

-- Pull and boot UI
local ok3, uiRaw = pcall(game.HttpGet, game, RAW .. "Main/UI.lua")
if not ok3 or not uiRaw or uiRaw == "" then
	error("Loader: could not fetch UI.lua")
end
local uiFn, uiErr = loadstring(uiRaw)
if not uiFn then error("Loader: UI.lua parse error: " .. tostring(uiErr)) end
uiFn()(allConfigs)
