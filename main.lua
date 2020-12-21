local sti = require 'sti'
local bump = require 'bump.bump'
local bump_debug = require 'bump.bump_debug'

cellsize = 16

map = sti('assets/dungeon/dungeon.lua', {'bump'})

map.layers['ground'].opacity, map.layers['decorations'].opacity = 0, 0

world = bump.newWorld(cellsize)

local layer = map:addCustomLayer("Sprites", 4)

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

function drawDebug(scale, scale0)
    bump_debug.draw(world, scale, scale0)
    love.graphics.setColor(255, 255, 255)
end

local playerFilter = function(item, other)
    if other.name == 'andonov' then
        map.layers['andonov'].opacity = 1
        return 'cross'
    else
        return 'slide'
    end
    -- else return nil
end

function movePlayer(direction, player, dt)
    local speed = 96
    local goalX, goalY

    if direction == 'up' then
        goalX, goalY = player.x, player.y - speed * dt
    end
    if direction == 'down' then
        goalX, goalY = player.x, player.y + speed * dt
    end
    if direction == 'left' then
        goalX, goalY = player.x - speed * dt, player.y
    end
    if direction == 'right' then
        goalX, goalY = player.x + speed * dt, player.y
    end

    local actualX, actualY, cols, len = world:move(player, goalX, goalY, playerFilter)
    player.x, player.y = actualX, actualY
    local x1, y1 = player.x - 100, player.y - 100
    local x2, y2 = player.x + 100, player.y + 100
    local items, len1 = world:querySegment(x1, y1, x2, y2)

    for i = 1, len1 do
        if items[i].name == 'ground' or items[i].name == 'decorations' then

        end
    end

    -- deal with the collisions
    for i = 1, len do
        if cols[i].other.name == 'andonov' then
            print('collided with ' .. tostring(cols[i].other.name))

        end
        print('collided with ' .. tostring(cols[i].other))
    end
end

function love.load()

    love.graphics.setBackgroundColor(0, 0, 0)

    map:bump_init(world)
    world:add(layer.player, layer.player.x, layer.player.y, sprite:getWidth() / 100, sprite:getHeight() / 50)

    layer.update = function(self, dt)
        -- 96 pixels per second
        local speed = 50

        -- Move player up
        if love.keyboard.isDown("w") or love.keyboard.isDown("up") then
            self.player.y = self.player.y - speed * dt
            movePlayer('up', self.player, dt)
        end

        -- Move player down
        if love.keyboard.isDown("s") or love.keyboard.isDown("down") then
            self.player.y = self.player.y + speed * dt
            movePlayer('down', self.player, dt)
        end

        -- Move player left
        if love.keyboard.isDown("a") or love.keyboard.isDown("left") then
            self.player.x = self.player.x - speed * dt
            movePlayer('left', self.player, dt)
        end

        -- Move player right
        if love.keyboard.isDown("d") or love.keyboard.isDown("right") then
            self.player.x = self.player.x + speed * dt
            movePlayer('right', self.player, dt)
        end

        --[[ if len ~= nil then
            for i = 1, len do
                _, _, tcols, tlen = world:check(player, player.x, cols[i].touch.y - 2)
                _, _, bcols, blen = world:check(player, player.x, cols[i].touch.y + 2)
            end
        end ]]
    end

    -- Draw player
    layer.draw = function(self)
        love.graphics.draw(self.player.sprite, math.floor(self.player.x), math.floor(self.player.y), 0, 0.1, 0.1,
            self.player.ox, self.player.oy)

        -- Temporarily draw a point at our location so we know
        -- that our sprite is offset properly
        love.graphics.setPointSize(5)
        love.graphics.points(math.floor(self.player.x), math.floor(self.player.y))
        -- love.graphics.circle('fill', player.x, player.y, 16, 16)
    end

    -- Remove unneeded object layer
    map:removeLayer("Spawn Point")

end

function love.update(dt)
    map:update(dt)
    -- world:update(dt)
end

function love.draw()

    -- Scale world
    local scale = 1
    local screen_width = love.graphics.getWidth() / scale
    local screen_height = love.graphics.getHeight() / scale

    -- Translate world so that player is always centred
    local player = map.layers["Sprites"].player
    local tx = math.floor(player.x - screen_width / 2)
    local ty = math.floor(player.y - screen_height / 2)

    map:draw(-tx, -ty, scale, scale)

    -- Collision map
    -- map:bump_draw(world)
    -- drawDebug()

    -- Reset colour
    love.graphics.setColor(255, 255, 255, 255)

end
