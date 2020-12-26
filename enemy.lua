-- Default enemy object.
Enemy = {
    xPos = 0,
    yPos = 0,
    width = 16,
    height = 16,
    flip = false
}

-- Initialize enemy object.
function Enemy:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

-- Self explanatory.
function Enemy:attack()

end

-- Prerequisites for movement.
--local direction = -1
local initialtime = love.timer.getTime()
local smart = false
local smartTimes = 0


-- Default enemy movement.
function Enemy:walk(goalX, goalY, dir, dt)
    local stoptimer = 5 -- 5 seconds
    local speed = 50

    timer = love.timer.getTime() - initialtime
    if timer > stoptimer then
        smartTimes = math.random(1, 9)
        initialtime = love.timer.getTime()
        dir = smartTimes % 3 == 0 and dir * -1 or dir * 1
        smart = smart == false and true or false

    end

    if smart == true then
        goalY = goalY + speed * dt * dir
    else
        goalX = goalX + speed * dt * dir
    end

    return goalX, goalY, dir

end

-- Set enemy position.
function Enemy:setPos(xPos, yPos)
    self.xPos = xPos
    self.yPos = yPos
    self.originX = xPos
    self.originY = yPos
end

-- Flip sprite.
function Enemy:flip(flip)
    self.flip = flip
end

-- Set enemy sprite.
function Enemy:setSprite(path)
    self.sprite = love.graphics.newImage(path)
end

-- Calculate distance between two points.
function dist(x1, y1, x2, y2)
    return ((x2 - x1) ^ 2 + (y2 - y1) ^ 2) ^ 0.5
end

-- Function to return what coordinates to chase.
function Enemy:chase(actualX, actualY, playerX, playerY, dt)
    local speed = 80
    local goalX = playerX - actualX
    local goalY = playerY - actualY
    local distance = math.sqrt(goalX * goalX + goalY * goalY)
    if dist(actualX, actualY, playerX, playerY) ~= 0 then -- avoid division by zero
        actualX = actualX + goalX / distance * speed * dt
        actualY = actualY + goalY / distance * speed * dt
    end
    return actualX, actualY
end

return Enemy
