-- Default enemy object.
Player = {
    xPos = 0,
    yPos = 0,
    mapPosX = 0,
    mapPosY = 0,
    width = 16,
    height = 16,
    damage = 1,
    health = 420,
    dir = 1,
    lives = 5,
    alive = true
}

-- Initialize player object.
function Player:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

-- Self explanatory.
function Player:attack(eo)
    local result = eo.health - self.damage
    return result
end

-- Set player position.
function Player:setPos(xPos, yPos)
    self.xPos = xPos
    self.yPos = yPos
    self.originX = xPos
    self.originY = yPos
end

-- Flip sprite.
function Player:flip(flip)
    self.flip = flip
end

-- Set player sprite.
function Player:setSprite(path)
    self.sprite = path
    -- self.sprite = love.graphics.newImage(path)
end

-- Move player
function Player:move(direction, p, dt)
    local goalX, goalY
    local speed = 50

    if direction == 'up' then
        goalX, goalY = p.x, p.y - speed * dt
    end
    if direction == 'down' then
        goalX, goalY = p.x, p.y + speed * dt
    end
    if direction == 'left' then
        goalX, goalY = p.x - speed * dt, p.y
    end
    if direction == 'right' then
        goalX, goalY = p.x + speed * dt, p.y
    end

    return goalX, goalY
end

-- Reset player position in case of death for instance.
function Player:resetPos()
    self.xPos, self.yPos = self.originX, self.originY
    return self.originX, self.originY
end

-- Calculate distance between two points.
function dist(x1, y1, x2, y2)
    return ((x2 - x1) ^ 2 + (y2 - y1) ^ 2) ^ 0.5
end

function Player:flip(direction)
    self.dir = direction
end

function Player:die()
    self.lives = self.lives - 1
    if self.lives <= 0 then
        self.alive = false
    end
end

function Player:revive()
    self.health = 421
end

function Player:heal(health)
    self.health = health
end

return Player
