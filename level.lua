-- level.lua

function loadLevel()
	require "charm"
	
	-- "Consts"
	GRID_SIZE = 9
	GRID_TL = {}
	GRID_TL.x = (love.graphics.getWidth() - (CHARM_SIZE * GRID_SIZE)) / 2
	GRID_TL.y = (love.graphics.getHeight() - (CHARM_SIZE * GRID_SIZE)) / 2
	CORNER_BUFFER = {}
	CORNER_BUFFER.x = frameC:getWidth() - CHARM_SIZE
	CORNER_BUFFER.y = frameC:getHeight() - CHARM_SIZE
	
	-- Objectives
	objectives = {}
	-- One objective per charm type
	objectives[1] = 0
	objectives[2] = 0
	objectives[3] = 0
	objectives[4] = 0
	-- Objectives for clear size
	objectives["small"] = 0
	objectives["medium"] = 0
	objectives["large"] = 0
	objectives["square"] = 0
	objectives["sijiao"] = 0
	
	-- Charm array
	charms = {}
	for i = 1, GRID_SIZE do
		table.insert(charms, {})
	end
	
	for y = 1, GRID_SIZE do
		for x = 1, GRID_SIZE do
			charms[x][y] = Charm(x, y)
		end
	end
	
	-- Selector
	tileSelected = false
	dragging = false
	-- Position from which dragging started
	lockX = 1
	lockY = 1
	-- Previous position while dragging
	lastX = 1
	lastY = 1
	
	-- State
	levelStates = {}
	levelStates.default = 1
	levelStates.clearing = 2
	levelStates.special = 3
	currentState = levelStates.default
	
	-- Saved coordinates to clear: x1, y1, x2, y2
	clearCoords = {1, 1, 1, 1}
	clearTime = 0
	-- The time clearing should take in seconds
	clearTotal = 0.45
	clearElapsed = 0
	clearRect = {}
	clearRect.alpha = clearTotal
	
	-- Score
	cleared = {}
	cleared[1] = {}
	cleared[1].score = 0
	cleared[2] = {}
	cleared[2].score = 0
	cleared[3] = {}
	cleared[3].score = 0
	cleared[4] = {}
	cleared[4].score = 0
	cleared["small"] = 0
	cleared["medium"] = 0
	cleared["large"] = 0
	cleared["square"] = 0
	cleared["sijiao"] = 0
	cleared.speed = 1
	cleared.ease = "expoout"
	theFont = love.graphics.newFont("assets/fnt/Merienda-Bold.ttf", 42)
	scoreText = {love.graphics.newText(theFont, 100),
							love.graphics.newText(theFont, 100),
							love.graphics.newText(theFont, 100),
							love.graphics.newText(theFont, 100)}
	scoreText[1]:set("0")
	scoreText[2]:set("0")
	scoreText[3]:set("0")
	scoreText[4]:set("0")
	scoreCharms = {Charm(20, 20, 1),
								Charm(20, 100, 2),
								Charm(20, 180, 3),
								Charm(20, 260, 4)}
	
	-- Recent clears for combo
	recent = {}
	comboTween = {}
	comboTween.diag = 1
	comboTween.last = 0
	comboTween.time = 1.5
	
	-- Text feedback
	noticeFont = love.graphics.newFont("assets/fnt/Acme-Regular.ttf", 36)
	notice = {}
	notice.timeScaleIn = 0.08
	notice.timeScaleOut = 0.6
	notice.timeDelay = 0.2
	notice.easeIn = "expoout"
	notice.easeOut = "expoin"
	notice.text = love.graphics.newText(noticeFont, 80)
	notice.scale = 0
	notice.r = 0.15
	notice.x = 0
	notice.y = 0
	notice.offX = 0
	notice.offY = notice.text:getHeight() / 2
	
	square = {}
	square.text = love.graphics.newText(noticeFont, "Square!")
	square.scale = 0
	square.x = 0
	square.y = 0
	square.offX = square.text:getWidth() / 2
	square.offY = square.text:getHeight() / 2
	
	sijiaoFont = love.graphics.newFont("assets/fnt/Acme-Regular.ttf", 112)
	sijiaoDisplay = {}
	sijiaoDisplay.ease = "backin"
	sijiaoDisplay.timeIn = 1.0
	sijiaoDisplay.timeOut = 1.2
	sijiaoDisplay.timeTotal = sijiaoDisplay.timeIn + sijiaoDisplay.timeOut
	sijiaoDisplay.text = love.graphics.newText(sijiaoFont, "SIJIAO")
	sijiaoDisplay.scale = 0
	sijiaoDisplay.alpha = 1
	sijiaoDisplay.x = love.graphics.getWidth() / 2
	sijiaoDisplay.y = love.graphics.getHeight() / 2
	sijiaoDisplay.offX = sijiaoDisplay.text:getWidth() / 2
	sijiaoDisplay.offY = sijiaoDisplay.text:getHeight() / 2
	
	specialDisplay = {}
	specialDisplay.text = love.graphics.newText(noticeFont, 80)
	specialDisplay.text:set("All clear!")
	specialDisplay.rStart = 0
	specialDisplay.rEnd = 0.1
	specialDisplay.r = specialDisplay.rStart
	specialDisplay.scale = 0
	specialDisplay.x = GRID_TL.x - CHARM_SIZE * 1.1
	specialDisplay.y = GRID_TL.y + ((GRID_SIZE - 4.3) * CHARM_SIZE)
	specialDisplay.offX = specialDisplay.text:getWidth() / 2
	specialDisplay.offY = specialDisplay.text:getHeight() / 2
	specialDisplay.timeDelay = 1
	specialDisplay.timeRotate = notice.timeScaleIn + specialDisplay.timeDelay + notice.timeScaleOut

	-- Sfx
	sfxWood = love.audio.newSource("assets/snd/wood.wav", "static")
	sfxWood2 = love.audio.newSource("assets/snd/wood2.wav", "static")
	sfxRelease = love.audio.newSource("assets/snd/release.wav", "static")
	sfxSuccess = love.audio.newSource("assets/snd/success.wav", "static")
	sfxSquare = love.audio.newSource("assets/snd/kalimbaclean.wav", "static")
	sfxClearing = love.audio.newSource("assets/snd/clearing.wav", "static")
	sfxSijiao = love.audio.newSource("assets/snd/sijiao.wav", "static")
end

function updateLevel(dt)
	-- Get mouse grid position
	mx, my = love.mouse.getPosition()
	mx, my = mx - GRID_TL.x, my - GRID_TL.y
	-- mouse position now expressed in terms of its grid position in [1, 9]
	mx, my = math.floor(mx / CHARM_SIZE) + 1, math.floor(my / CHARM_SIZE) + 1
	
	-- Testing if mouse in valid tile area
	if mx >= 1 and mx <= GRID_SIZE and my >= 1 and my <= GRID_SIZE then
		tileSelected = true
	else
		tileSelected = false
	end
	
	-- Default state
	if currentState == levelStates.default then
		-- Starting dragging from a valid tile area
		if tileSelected and love.mouse.isDown(1) and not dragging then
			dragging = true
			lockX, lockY = mx, my
			lastX, lastY = mx, my
			if sfxWood:isPlaying() then sfxWood:stop() end
			sfxWood:play()
		end
		-- Continuing dragging once started
		if dragging then
			-- Sfx
			local thisX, thisY = reign(mx, my)
			if thisX ~= lastX or thisY ~= lastY then
				if sfxWood2:isPlaying() then sfxWood2:stop() end
				sfxWood2:play()
				lastX, lastY  = thisX, thisY
			end	
			
			-- End dragging
			if not love.mouse.isDown(1) then
				dragging = false
				evalClear(lockX, lockY, mx, my)
			end
		end
	elseif currentState == levelStates.clearing then
		--doClear(clearCoords)
	elseif currentState == levelStates.special then
		-- ???
	end
end

function drawLevel()
	-- Corners
	-- 								(frameC,   x,  y, r, h, v)
	love.graphics.draw(frameC, GRID_TL.x - CORNER_BUFFER.x, GRID_TL.y - CORNER_BUFFER.y, 0, 1, 1)
	love.graphics.draw(frameC, GRID_TL.x + (CHARM_SIZE * GRID_SIZE) + CORNER_BUFFER.x, GRID_TL.y - CORNER_BUFFER.y, 0, -1, 1)
	love.graphics.draw(frameC, GRID_TL.x + (CHARM_SIZE * GRID_SIZE) + CORNER_BUFFER.x, GRID_TL.y + (CHARM_SIZE * GRID_SIZE) + CORNER_BUFFER.y, 0, -1, -1)
	love.graphics.draw(frameC, GRID_TL.x - CORNER_BUFFER.x, GRID_TL.y + (CHARM_SIZE * GRID_SIZE) + CORNER_BUFFER.y, 0, 1, -1)
	
	-- Edges
	for i = 1, (GRID_SIZE - 2) do
		love.graphics.draw(frameH, GRID_TL.x + CHARM_SIZE * i, GRID_TL.y - CORNER_BUFFER.y)
		love.graphics.draw(frameH, GRID_TL.x + CHARM_SIZE * i, GRID_TL.y + (CHARM_SIZE * GRID_SIZE))
		love.graphics.draw(frameV, GRID_TL.x - CORNER_BUFFER.x, GRID_TL.y + CHARM_SIZE * i)
		love.graphics.draw(frameV, GRID_TL.x + (CHARM_SIZE * GRID_SIZE), GRID_TL.y + CHARM_SIZE * i)
		--love.graphics.draw(frameH, 307 + 72 * i, 14)
		--love.graphics.draw(frameH, 307 + 72 * i, 675)
		--love.graphics.draw(frameV, 294, 27 + 72 * i)
		--love.graphics.draw(frameV, 955, 27 + 72 * i)
	end
	
	-- Center
	for y = 1, GRID_SIZE do
		for x = 1, GRID_SIZE do
			love.graphics.draw(bgtile, GRID_TL.x + CHARM_SIZE * (x - 1), GRID_TL.y + CHARM_SIZE * (y - 1))
			--love.graphics.draw(bgtile, 307 + 72 * x, 27 + 72 * y)
			charms[x][y]:draw()
		end
	end
	
	-- Cursor
	if dragging and currentState ~= levelStates.special then
		-- Draw selector around lockX, lockY and mx, my
		if not tileSelected then
			mx, my = reign(mx, my)
		end
		local lessX = math.min(lockX, mx)
		local lessY = math.min(lockY, my)
		local moreX = math.max(lockX, mx)
		local moreY = math.max(lockY, my)
		-- "Real" x, y values for drawing purposes; rx2 > rx1 and ry2 > ry1
		rx1 = GRID_TL.x + (lessX - 1) * CHARM_SIZE
		ry1 = GRID_TL.y + (lessY - 1) * CHARM_SIZE
		rx2 = GRID_TL.x + (moreX - 1) * CHARM_SIZE
		ry2 = GRID_TL.y + (moreY - 1) * CHARM_SIZE
		
		-- Highlight
		love.graphics.setColor(1, 0.65, 0.45, 0.6)
		love.graphics.rectangle("line", rx1, ry1, rx2 - rx1 + CHARM_SIZE, ry2 - ry1 + CHARM_SIZE)
		love.graphics.setColor(1, 0.65, 0.45, 0.2)
		love.graphics.rectangle("fill", rx1, ry1, rx2 - rx1 + CHARM_SIZE, ry2 - ry1 + CHARM_SIZE)
		love.graphics.setColor(1, 1, 1, 1)
		
		-- Selector
		love.graphics.draw(selectUL, rx1, ry1)
		love.graphics.draw(selectUR, rx2, ry1)
		love.graphics.draw(selectBR, rx2, ry2)
		love.graphics.draw(selectBL, rx1, ry2)
	elseif tileSelected then
		-- If not dragging, draw all select corners at current highlighted grid
		local selectX = GRID_TL.x + (mx - 1) * CHARM_SIZE
		local selectY = GRID_TL.y + (my - 1) * CHARM_SIZE
		
		-- If in state special, change colour
		if currentState == levelStates.special then
			love.graphics.setBlendMode("lighten", "premultiplied")
		end
		love.graphics.draw(selectUL, selectX, selectY)
		love.graphics.draw(selectUR, selectX, selectY)
		love.graphics.draw(selectBR, selectX, selectY)
		love.graphics.draw(selectBL, selectX, selectY)
		love.graphics.setBlendMode("alpha")
	end
	
	if currentState == levelStates.clearing then
		love.graphics.setColor(1, 1, 1, clearRect.alpha)
		love.graphics.rectangle("fill", rx1, ry1, rx2 - rx1 + CHARM_SIZE, ry2 - ry1 + CHARM_SIZE)
		love.graphics.setColor(1, 1, 1, 1)
	end
	
	love.graphics.draw(specialDisplay.text, specialDisplay.x, specialDisplay.y, specialDisplay.r, specialDisplay.scale, specialDisplay.scale, specialDisplay.offX, specialDisplay.offY)
	love.graphics.draw(notice.text, notice.x, notice.y, notice.r, notice.scale, notice.scale, notice.offX, notice.offY)
	love.graphics.draw(square.text, square.x, square.y, notice.r, square.scale, square.scale, square.offX, square.offY)
	
	-- Sijiao
	love.graphics.setColor(1, 1, 1, sijiaoDisplay.alpha)
	love.graphics.draw(sijiaoDisplay.text, sijiaoDisplay.x, sijiaoDisplay.y, 0, sijiaoDisplay.scale, sijiaoDisplay.scale, sijiaoDisplay.offX, sijiaoDisplay.offY)
	love.graphics.setColor(1, 1, 1, 1)
	
	-- Recents
	for i in pairs(recent) do
		recent[i]:draw()
	end
	
	-- Score
	drawScore()
end

function evalClear(x1, y1, x2, y2)
	-- Make in bounds
	x1, y1 = reign(x1, y1)
	x2, y2 = reign(x2, y2)

	-- Exit if x1 == x2 or y1 == y2
	if x1 == x2 or y1 == y2 then
		if sfxRelease:isPlaying() then sfxRelease:stop() end
		sfxRelease:play()
		return
	end
	
	local least = math.min(charms[x1][y1].type, charms[x2][y1].type, charms[x1][y2].type, charms[x2][y2].type)
	local most = math.max(charms[x1][y1].type, charms[x2][y1].type, charms[x1][y2].type, charms[x2][y2].type)
	-- If least == most then all corners are the same charm type
	if least == most then
		currentState = levelStates.clearing
		clearCoords = {x1, y1, x2, y2}
		clearTime = love.timer.getTime()
		clearRect.alpha = clearTotal
		
		-- Tween & count
		local count = 0
		local easeType = "expoin"
		local easeTime = clearTotal
		-- Sijiao check
		if (math.abs(x1 - x2) + 1) * (math.abs(y1 - y2) + 1) == GRID_SIZE * GRID_SIZE then
			easeType = sijiaoDisplay.ease
			easeTime = sijiaoDisplay.timeTotal
		end
		
		local type = charms[x1][y1].type
		for y = math.min(y1, y2), math.max(y1, y2) do
			for x = math.min(x1, x2), math.max(x1, x2) do
				count = count + 1
				-- Make all charms in the box the same type
				charms[x][y] = Charm(x, y, type)
				-- Tween
				flux.to(charms[x][y], easeTime, {scale = 0}):ease(easeType):oncomplete(function () doClear(x, y)  end)
			end
		end
		
		-- Do Sijiao feedback
		if count == GRID_SIZE * GRID_SIZE then
			sijiaoDisplay.scale = 0
			sijiaoDisplay.alpha = 1
			flux.to(sijiaoDisplay, sijiaoDisplay.timeIn, {scale = 1}):after(sijiaoDisplay.timeOut, {alpha = 0})
		end
		
		-- Tween clear rectangle
		flux.to(clearRect, clearTotal, {alpha = 0}):ease("linear")
		
		-- Add to score and recent charms
		addScore(type, count)
		addRecent(type)
		
		-- Play sfx
		sfxSuccess:play()
		
		-- Notice
		notice.x = GRID_TL.x + (math.max(x1, x2)) * CHARM_SIZE + CORNER_BUFFER.x
		notice.y = GRID_TL.y + (math.abs(y1 - y2) / 2 + math.min(y1, y2) - 1) * CHARM_SIZE + CORNER_BUFFER.y * 2
		notice.scale = 1
		notice.r = love.math.random() * 0.4 - 0.2
		flux.to(notice, notice.timeScaleOut, {scale = 0}):ease(notice.easeOut):delay(notice.timeDelay)
		
		-- Check size and square
		checkSize(x1, y1, x2, y2)
	else
		if sfxRelease:isPlaying() then sfxRelease:stop() end
		sfxRelease:play()
	end
end

function doClear(x, y)
	replaceCharm(x, y)
	
	-- Only return to default state if not doing a special clear
	if currentState ~= levelStates.special then
		currentState = levelStates.default
	end
end

-- Takes a local tile coordinate and constrains it to [1, 9].
-- Returns two values, normalized x and y.
function reign(x, y)
	if x < 1 then x = 1 elseif x > 9 then x = 9 end
	if y < 1 then y = 1 elseif y > 9 then y = 9 end
	return x, y
end

function drawScore()
	for i = 1, 4 do
		scoreText[i]:set(tostring(math.ceil(cleared[i].score)))
		local ch = scoreCharms[i]
		love.graphics.draw(ch.img, ch.x, ch.y)
		love.graphics.draw(scoreText[i], 120, -48 + (80 * i))
	end
	
	local sizes = {"small", "medium", "large", "square", "sijiao"}
	local fx = GRID_TL.x + (GRID_SIZE * CHARM_SIZE) + (CORNER_BUFFER.x * 2)
	local fy = GRID_TL.y
	local fw = GRID_TL.x - CORNER_BUFFER.x * 3
	for i = 1, #sizes do
		local ft = sizes[i]:gsub("^%l", string.upper) .. ": " .. tostring(cleared[sizes[i]])
		love.graphics.printf(ft, theFont, fx, fy + CHARM_SIZE * (i-1) - 8, fw, "justify")
	end
end

function addScore(type, count)
	flux.to(cleared[type], cleared.speed, {score = cleared[type].score + count}):ease(cleared.ease)
	--cleared[type] = cleared[type] + count
end

-- Determines the size of the area (small, medium, large, or yosumin), and adds to cleared count; also checks for squares
function checkSize(x1, y1, x2, y2)
	local x = math.abs(x1 - x2) + 1
	local y = math.abs(y1 - y2) + 1
	local area = x * y
	
	-- Small <= 14, medium <= 35, large <= 80
	if area <= 14 then
		cleared["small"] = cleared["small"] + 1
		notice.text:set("Small!")
	elseif area <= 35 then
		cleared["medium"] = cleared["medium"] + 1
		notice.text:set("Medium!")
	elseif area <= 80 then
		cleared["large"] = cleared["large"] + 1
		notice.text:set("Large!")
	else
		cleared["sijiao"] = cleared["sijiao"] + 1
		notice.text:set("")
	end
	
	notice.offX = notice.text:getWidth() / 2
	
	-- Check square
	if x == y then
		cleared["square"] = cleared["square"] + 1
		-- Add to recent again because square
		addRecent()
		-- If not yosumin, then play sfx and show square notice
		if area ~= GRID_SIZE * GRID_SIZE then
			square.x = notice.x
			square.y = notice.y + CHARM_SIZE / 2
			square.scale = 1
			flux.to(square, notice.timeScaleOut, {scale = 0}):ease(notice.easeOut):delay(notice.timeDelay)
			if sfxSquare:isPlaying() then sfxSquare:stop() end
			sfxSquare:play()
		else-- yosumin
			sfxSijiao:play()
		end
	end
end

-- Adds to the "recent" table with the latest charm type clear
function addRecent(type)
	-- Ignore if already 4 in recent (square edge case)
	if #recent == 4 then
		return
	-- If no type supplied, assume same as last
	elseif #recent ~= 0 then
		type = type or recent[1].type
	else
		-- If recent is empty and no type was supplied, then addRecent was called again after removeType and should therefore be ignored
		if type == nil then return end
	end
	
	-- If no entries or different type being added
	if #recent == 0 then
		clearRecent()
	elseif recent[1].type ~= type then
		clearRecent()
	end
	
	-- Add the newest charm
	table.insert(recent, Charm(-0.5, GRID_SIZE - (#recent), type))
	
	-- If recent reaches 4, clear the board of type
	if #recent == 4 then
		removeType(type)
	end
end

-- Clears the "recent" table
function clearRecent()
	for i in pairs(recent) do
		recent[i] = nil
	end
end

-- Clears the "recent" table with a tween
function wipeRecent()
	-- Visual feedback for secret activation
	flux.to(specialDisplay, notice.timeScaleIn, {scale = 1}):ease(notice.easeIn):after(notice.timeScaleOut, {scale = 0}):delay(specialDisplay.timeDelay):ease(notice.easeOut)
	flux.to(specialDisplay, specialDisplay.timeRotate, {r = specialDisplay.rEnd}):ease("linear"):oncomplete(function() specialDisplay.r = specialDisplay.rStart end)
	
	-- Clear recent display table
	for i in pairs(recent) do
		flux.to(recent[i], clearTotal, {scale = 0}):ease("expoin"):oncomplete(function () recent[i] = nil end)
	end
	
	-- Play sfx
	sfxClearing:play()
end

-- Removes all charms of type "type" from the board
function removeType(type)
	-- Starts tweening through diagonals
	-- Every time comboTween.diag changes, removeDiag(type) will be called
	-- Once finished, clearRecent() will be called
	currentState = levelStates.special
	comboTween.diag = 1
	flux.to(comboTween, comboTween.time, {diag = GRID_SIZE * 2 - 1}):ease("quartinout"):delay(clearTotal * 2):onstart(function () wipeRecent() end):onupdate(function () removeDiag(type) end):oncomplete(function () finishRemoving() end)
end

function finishRemoving()
	clearRecent()
	currentState = levelStates.default
end

-- Performs the removal of like charms from one diagonal (at comboTween.diag)
function removeDiag(type)
	-- Make diag an integer
	local d = math.floor(comboTween.diag)
	-- Only if diag has changed
	if d ~= comboTween.last then
		-- y will iterate from max value (== diag) down to 1
		local x = 1
		local y = d
		-- invert will correct x, y values past 9, 9
		local invert = 0
		local realMax = d
		if d > GRID_SIZE then
			invert = d - GRID_SIZE
			realMax = GRID_SIZE
			y = realMax
		end
		-- Loop from 1 to the current diag value
		for x = x + invert, realMax do
			if charms[x][y].type == type then
				--print("Replacing charm at " .. tostring(x) .. ", " .. tostring(y) .. " of type " .. tostring(charms[x][y].type))
				local xx, yy = x, y
				flux.to(charms[xx][yy], clearTotal, {scale = 0}):ease("expoin"):oncomplete(function () replaceCharm(xx, yy, type) end)
			end
			-- Decrement y
			y = y - 1
		end
		
		-- Update last
		comboTween.last = d
	end
end

-- Makes a new charm at (x, y) that is not of type notType (optional)
function replaceCharm(x, y, notType)
	--print("We heard you; replacing charm at " .. tostring(x) .. ", " .. tostring(y))
	-- Safety inspection
	notType = notType or 0
	if x < 1 or y < 1 or x > GRID_SIZE or y > GRID_SIZE or notType < 0 or notType > 4 then return end
	-- Generate number and avoid notType
	local t = nil
	if notType ~= 0 then
		t = love.math.random(3)
		if notType ~= 4 then
			if t >= notType then
				t = t + 1
			end
		end
	else
		t = love.math.random(4)
	end
	-- Make charm in array
	print("Making charm type " .. tostring(t) .. " at " .. tostring(x) .. ", " .. tostring(y))
	charms[x][y] = Charm(x, y, t)
	-- Setup tween in
	charms[x][y].scale = 0
	flux.to(charms[x][y], clearTotal, {scale = 1}):ease("expoout")
end
