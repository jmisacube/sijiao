-- main.lua
-- Handles game state and update/draw loops

function love.load()
	-- Requires
	require "level"
	Object = require "classic"
	flux = require "flux"
	
	-- Game state
	gameStates = {}
	gameStates.menu = 1
	gameStates.level = 2
	currentGameState = gameStates.level
	
	-- Images
	bgtile = love.graphics.newImage("assets/bgtile.png")
	frameC = love.graphics.newImage("assets/framecorner.png")
	frameH = love.graphics.newImage("assets/frameh.png")
	frameV = love.graphics.newImage("assets/framev.png")
	
	selectUL = love.graphics.newImage("assets/selectUL.png")
	selectUR = love.graphics.newImage("assets/selectUR.png")
	selectBR = love.graphics.newImage("assets/selectBR.png")
	selectBL = love.graphics.newImage("assets/selectBL.png")
	
	types = {}
	types[1] = love.graphics.newImage("assets/1.png")
	types[2] = love.graphics.newImage("assets/2.png")
	types[3] = love.graphics.newImage("assets/3.png")
	types[4] = love.graphics.newImage("assets/4.png")
	
	if currentGameState == gameStates.level then
		loadLevel()
	end
end

function love.update(dt)
	-- Tween
	flux.update(dt)
	
	if currentGameState == gameStates.level then
		updateLevel()
	end
end

function love.draw()
	if currentGameState == gameStates.level then
		drawLevel()
	end
end
