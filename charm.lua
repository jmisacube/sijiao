Object = require "classic"
Charm = Object:extend()

CHARM_SIZE = 72

function Charm:new(x, y, type)
	-- Local grid position; not coordinates
	--if x < 1 or x > 9 or y < 1 or y > 9 then
		--print("x, y must be between [1, 9]")
	--end
	self.x = x
	self.y = y
	self:setType(type)
	self.scale = 1
end

function Charm:draw()
	-- If type 0, nothing to draw
	if self.type ~= 0 then
		local ox, oy = GRID_TL.x - CHARM_SIZE, GRID_TL.y - CHARM_SIZE
		-- Adjust from grid coords to real window coords
		local finalX, finalY  = ox + self.x * CHARM_SIZE, oy + self.y * CHARM_SIZE
		-- Adjust for scale tweening
		finalX = finalX + (1 - self.scale) * (CHARM_SIZE / 2)
		finalY = finalY + (1 - self.scale) * (CHARM_SIZE / 2)
		love.graphics.draw(self.img, finalX, finalY, 0, self.scale)
	end
end

function Charm:setType(type)
	self.type = type or love.math.random(4)
	if type ~= 0 then
		self.img = types[self.type]
	end
end
