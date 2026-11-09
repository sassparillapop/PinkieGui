-- Automation/PinkiesHelper(Auto).lua
return {
	type    = "toggle",
	label   = "Pinkie's Helper",
	default = false,
	order   = 1,
	onChange = function(enabled)
		-- your autofarm start/stop code goes here
		if enabled then
			-- start farm
		else
			-- stop farm
		end
	end,
}
