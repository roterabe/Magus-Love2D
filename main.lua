local sti = require 'sti'
local bump = require 'bump.bump'
local bump_debug = require 'bump.bump_debug'
local enemy = require 'enemy'

local cellsize = 16
local timer = 5
local initialtime = love.timer.getTime()

local map = sti('assets/dungeon/dungeon.lua', {'bump'})

local world = bump.newWorld(cellsize)

local enemies = {}
for i = 1, 2 do
    enemies[i] = enemy:new()
end

enemies[1]:setPos(300, 300)
enemies[2]:setPos(600, 600)

enemies[1]:setSprite('assets/sprite.png')
enemies[2]:setSprite('assets/sprite.png')
-- Enemy:attack()

-- Create layer for characters.
local layer = map:addCustomLayer("Sprites", 4)

-- Position main character on spawn point.
local player
for k, object in pairs(map.objects) do
    if object.name == "Player" then
        player = object
        break
    end
end

local sprite = love.graphics.newImage('assets/sprite.png')
layer.player = {
    sprite = sprite,
    x = player.x,
    y = player.y,
    ox = sprite:getWidth() / 2,
    oy = sprite:getHeight() / 1.35,
    collidable = true
}

layer.enemy1 = {
    sprite = enemies[1].sprite,
    x = enemies[1].xPos,
    y = enemies[1].yPos,
    ox = enemies[1].sprite:getWidth() / 2,
    oy = enemies[1].sprite:getHeight() / 1.35,
    collidable = true
}

layer.enemy2 = {
    sprite = enemies[2].sprite,
    x = enemies[2].xPos,
    y = enemies[2].yPos,
    ox = enemies[2].sprite:getWidth() / 2,
    oy = enemies[2].sprite:getHeight() / 1.35,
    collidable = true
}

-- Debug map with the help of Bump. Custom implementation.
function drawDebug(scale, scale0)
    bump_debug.draw(world, scale, scale0)
    love.graphics.setColor(255, 255, 255)
end

--Filter how to collide with various objects.
local playerFilter = function(item, other)
    if other.name == 'andonov' then
        map.layers['andonov'].opacity = 1
        return 'cross'
    else
        return 'slide'
    end
    -- else return nil
end

--Implement player movement.
function movePlayer(direction, p, dt)
    local speed = 50
    local goalX, goalY

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

    local actualX, actualY, cols, len = world:move(p, goalX, goalY, playerFilter)
    p.x, p.y = actualX, actualY

    -- Scan square around character and return what's around him.
    local x1, y1 = p.x - 100, p.y - 100
    local x2, y2 = p.x + 100, p.y + 100
    local items, len1 = world:querySegment(x1, y1, x2, y2)

    -- Tried implementing fog of war.. Not possible at this time.
    for i = 1, len1 do
        if items[i].name == 'ground' or items[i].name == 'decorations' then

        end
    end

    -- deal with the collisions.
    for i = 1, len do
        if cols[i].other.name == 'andonov' then
            print('collided with ' .. tostring(cols[i].other.name))

        end
        print('collided with ' .. tostring(cols[i].other))
    end

end

-- Enemy movement across map. Trajectory is pretty simple (square movement).
function moveEnemy(e, dt)
    local goalX, goalY
    goalX, goalY = enemies[1]:walk(e.x, e.y, dt)

    local actualX, actualY, cols, len = world:move(e, goalX, goalY, playerFilter)
    e.x, e.y = actualX, actualY

    -- Direction switching implemented. Fixed collision release teleportation.

    for i = 1, len do
        if cols[i].other.name == 'andonov' then
            print('collided with ' .. tostring(cols[i].other.name))

        end
        print('collided with ' .. tostring(cols[i].other))
    end
end

-- Load various things in love and the game itself.
function love.load()

    love.graphics.setBackgroundColor(0, 0, 0)

    map:bump_init(world)

    -- Add characters to collision world.
    world:add(layer.player, layer.player.x, layer.player.y, sprite:getWidth() / 100, sprite:getHeight() / 50)
    world:add(layer.enemy1, layer.enemy1.x, layer.enemy1.y, enemies[1].sprite:getWidth() / 100,
        enemies[1].sprite:getHeight() / 50)
    world:add(layer.enemy2, layer.enemy2.x, layer.enemy2.y, enemies[2].sprite:getWidth() / 100,
        enemies[2].sprite:getHeight() / 50)

    layer.update = function(self, dt)
        -- 200 pixels per second
        local speed = 200

        -- Implement enemy smart movement.
        moveEnemy(self.enemy1, dt)
        moveEnemy(self.enemy2, dt)

        -- Move player up.
        if love.keyboard.isDown("w") or love.keyboard.isDown("up") then
            self.player.y = self.player.y - speed * dt
            movePlayer('up', self.player, dt)

        end

        -- Move player down.
        if love.keyboard.isDown("s") or love.keyboard.isDown("down") then
            self.player.y = self.player.y + speed * dt
            movePlayer('down', self.player, dt)
        end

        -- Move player left.
        if love.keyboard.isDown("a") or love.keyboard.isDown("left") then
            self.player.x = self.player.x - speed * dt
            movePlayer('left', self.player, dt)
        end

        -- Move player right.
        if love.keyboard.isDown("d") or love.keyboard.isDown("right") then
            self.player.x = self.player.x + speed * dt
            movePlayer('right', self.player, dt)
        end

    end

    -- Draw player and the rest of the characters on layer Sprite.
    layer.draw = function(self)
        love.graphics.draw(self.player.sprite, math.floor(self.player.x), math.floor(self.player.y), 0, 0.1, 0.1,
            self.player.ox, self.player.oy)

        love.graphics.draw(self.enemy1.sprite, math.floor(self.enemy1.x), math.floor(self.enemy1.y), 0, 0.1, 0.1,
            self.enemy1.ox, self.enemy1.oy)

            love.graphics.draw(self.enemy2.sprite, math.floor(self.enemy2.x), math.floor(self.enemy2.y), 0, 0.1, 0.1,
            self.enemy2.ox, self.enemy2.oy)

        -- Temporarily draw a point at our location so we know
        -- that our sprite is offset properly.
        -- love.graphics.setPointSize(5)
        -- love.graphics.points(math.floor(self.player.x), math.floor(self.player.y))

    end

    -- Remove unneeded object layer.
    map:removeLayer("Spawn Point")

end

function love.update(dt)
    map:update(dt)
end

function love.draw()

    -- Scale world.
    local scale = 1
    local screen_width = love.graphics.getWidth() / scale
    local screen_height = love.graphics.getHeight() / scale

    -- Translate world so that player is always centred
    local player = map.layers["Sprites"].player
    local tx = math.floor(player.x - screen_width / 2)
    local ty = math.floor(player.y - screen_height / 2)

    map:draw(-tx, -ty, scale, scale)

    -- Collision map.
    -- map:bump_draw(world)
    -- drawDebug()

    -- Reset colour.
    love.graphics.setColor(255, 255, 255, 255)

end
