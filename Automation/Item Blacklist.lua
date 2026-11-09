-- Automation/Item Blacklist.lua
return {
	type    = "dropdown",
	label   = "Item Blacklist",
	order   = 3,
	options = { "Sword", "Shield", "Potion" }, -- populate however you want
	onChange = function(selected)
		-- handle selection
	end,
}
