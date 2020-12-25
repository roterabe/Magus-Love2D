Enemy = {
    xPos = 0,
    yPos = 0,
    width = 16,
    height = 16,
    flip = false
}

function Enemy:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function Enemy:attack()

end

local direction = -1
local initialtime = love.timer.getTime()
local smart = false
local smartTimes = 0

function Enemy:walk(goalX, goalY, dt)
    local stoptimer = 5 -- 5 seconds
    speed = 50

    timer = love.timer.getTime() - initialtime
    if timer > stoptimer then
        smartTimes = smartTimes + 1
        initialtime = love.timer.getTime()
        direction = smartTimes % 2 == 0 and direction * -1 or direction * 1
        smart = smart == false and true or false

    end

    if smart == true then
        goalY = goalY + speed * dt * direction
    else
        goalX = goalX + speed * dt * direction
    end

    return goalX, goalY

end

function Enemy:setPos(xPos, yPos)
    self.xPos = xPos
    self.yPos = yPos
    self.originX = xPos
    self.originY = yPos
end

function Enemy:flip(flip)
    self.flip = flip
end

function Enemy:setSprite(path)
    self.sprite = love.graphics.newImage(path)
end

return Enemy
