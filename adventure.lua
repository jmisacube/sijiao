adventureObjectives = {}
currentLevel = 1

-- Set the objective of level #n
-- ch1-4 are charm counts
-- sm, med, and lg are sizes
-- sq is square and sj is sijiao
function setObjective(n, ch1, ch2, ch3, ch4, sm, med, lg, sq, sj)
	local t = {
		[1] = ch1,
		[2] = ch2,
		[3] = ch3,
		[4] = ch4,
		["small"] = sm,
		["medium"] = med,
		["large"] = lg,
		["square"] = sq,
		["sijiao"] = sj
	}
	
	table.insert(adventureObjectives, t)
end

setObjective(1, 10, 0, 0, 0, 0, 0, 0, 0, 0)
setObjective(2, 10, 10, 0, 0, 0, 0, 0, 0, 0)
setObjective(3, 0, 0, 20, 20, 0, 0, 0, 0, 0)
setObjective(4, 20, 20, 20, 20, 0, 0, 0, 0, 0)
setObjective(5, 0, 0, 0, 0, 5, 0, 0, 0, 0)
setObjective(6, 0, 0, 0, 0, 0, 5, 0, 0, 0)
setObjective(7, 0, 0, 0, 0, 0, 0, 5, 0, 0)
setObjective(8, 0, 0, 0, 0, 0, 0, 0, 10, 0)
setObjective(9, 0, 0, 0, 0, 0, 0, 0, 0, 1)
setObjective(10, 20, 20, 0, 0, 10, 0, 0, 0, 0)
setObjective(11, 0, 0, 20, 20, 0, 10, 0, 0, 0)
setObjective(12, 0, 0, 0, 0, 10, 10, 10, 0, 0)
