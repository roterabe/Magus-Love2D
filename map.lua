local sti = require 'sti'
local bump = require 'bump.bump'
local bump_debug = require 'bump.bump_debug'
local enemy = require 'enemy'
local gamera = require 'gamera-master.gamera'
local character = require 'player'

local cellsize = 16
local map_path = 'assets/dungeon/level.lua'
local level = 'level'
-- local timer = 5
-- local initialtime = love.timer.getTime()

local map = sti(map_path, {'bump'}, 0, 0)
local map0 = sti('assets/dungeon/dummy.lua', {'bump'}, 1500, 1500)

-- Create physics world.
local world = bump.newWorld(cellsize)

-- Create layer for characters.
local layer = map:addCustomLayer("Sprites", 5)

-- Position main character on spawn point.
local spawn
for k, object in pairs(map.objects) do
    if object.name == "Player" then
        spawn = object
        break
    end
end

function drawDebug(scale, scale0)
    bump_debug.draw(world, scale, scale0)
    love.graphics.setColor(255, 255, 255)
end

-- Filter how to collide with various objects.
local playerFilter = function(item, other)
    if other.name == 'andonov' then
        map.layers['andonov'].opacity = 1
        return 'cross'
    elseif other.name == 'Black' then
        -- map:swapTile(map.tileInstances[gid], map.tiles[1])
        return 'cross'
    elseif other.name == 'ladder' then
        level = 'dummy'
        map_path = 'assets/dungeon/dummy.lua'
        return 'cross'
    else
        return 'slide'
    end
    -- else return nil
end

-- Calculate distance between two points.
function dist(x1, y1, x2, y2)
    return ((x2 - x1) ^ 2 + (y2 - y1) ^ 2) ^ 0.5
end

-- Implement player movement.
function movePlayer(direction, po, p, dt)
    local goalX, goalY = po:move(direction, p, dt)

    local actualX, actualY, cols, len = world:move(p, goalX, goalY, playerFilter)
    p.x, p.y = actualX, actualY

    -- Scan square around character and return what's around him.
    local x1, y1 = p.x - 100, p.y - 100
    local w, h = 200, 200
    local items, len1 = world:queryRect(x1, y1, w, h)

    -- Tried implementing fog of war.. Not possible at this time.. Beginning again...
    --[[ for i = 1, len1 do
        if items[i].x ~= nil and items[i].y ~= nil then
            --world.get
            local nx, ny = map:convertPixelToTile(items[i].x, items[i].y)
            nx, ny = math.floor(nx), math.floor(ny)
            local xcoord, ycoord = items[i].x, items[i].y

            local tileInstance = map:getInstanceByPixel(xcoord, ycoord, 'fog')
            if tileInstance ~= nil then
                map:removeInstance(tileInstance)
                print('success')
            end
        end
    end ]]

    -- deal with the collisions.
    for i = 1, len do
        if cols[i].other.name == 'andonov' then
            print('collided with ' .. tostring(cols[i].other.name))

        elseif cols[i].other.name == 'Stairs' then

        else
            print('collided with ' .. tostring(cols[i].other))
        end
    end

end

-- Enemy movement across map. Trajectory is pretty simple (square movement).
function moveEnemy(eo, po, e, p, dt)
    local goalX, goalY
    goalX, goalY, e.dir = eo:walk(e.x, e.y, e.dir, dt)

    local x1, y1 = e.x - 100, e.y - 100
    local w, h = 200, 200
    local items, len1 = world:queryRect(x1, y1, w, h)

    for i = 1, len1 do
        if items[i].name == 'player' then
            -- print(items[i].info)
            goalX, goalY = eo:chase(e.x, e.y, p.x, p.y, dt)
        end
    end

    -- If close enough to player, simply attack.
    if dist(e.x, e.y, p.x, p.y) < 10 then
        if po.health <= 0 then
            po.health = 210
            local oX, oY = po:resetPos()
            p.x, p.y = oX, oY
            world:remove(p)
            -- world:add(p, p.x, p.y, p.sprite:getWidth() / 100, p.sprite:getHeight() / 50)
            world:add(p, p.x, p.y, 16 / 10, 16 / 50)
        end
        po.health = eo:attack(po)
        print('Miss me with that gay shit.')
    end
    local actualX, actualY, cols, len = world:move(e, goalX, goalY, playerFilter)

    -- Flip sprite direction.
    if actualX < e.x then
        eo:flip(1)
    elseif actualX > e.x then
        eo:flip(-1)
    end
    e.x, e.y = actualX, actualY

    -- Direction switching implemented. Fixed collision release teleportation.

    for i = 1, len do
        if cols[i].other.name == 'andonov' then
            -- print('collided with ' .. tostring(cols[i].other.name))

        end
        -- print('collided with ' .. tostring(cols[i].other))
    end
end

-- Choose which enemy needs to take damage.
function enemySelector(po, p, dt)
    local x1, y1 = p.x - 100, p.y - 100
    local w, h = 200, 200
    local items, len = world:queryRect(x1, y1, w, h)

    for i = 1, len do
        if items[i].name == 'enemy' then
            local target = items[i]
            if dist(p.x, p.y, target.x, target.y) < 10 then
                if items[i].ob.health <= 0 then
                    items[i].ob.alive = false
                    world:remove(items[i])
                    break
                end
                items[i].ob.health = po:attack(items[i].ob)
            end
        end
    end
end

function map:drawHealth()
    return layer.sprites.player.ob.health
end

-- Generate enemies.
local enemies = {}
local coord = {}
local reverse = 1
coord.x, coord.y = 200, 200
for i = 1, 100 do
    enemies[i] = enemy:new()
    enemies[i]:setPos(coord.x, coord.y)
    coord.x, coord.y = math.random(200, 1850), math.random(200, 1850)
end

-- Load all sprites.
local spr_list = love.graphics.newImage('assets/dungeon/0x72_16x16DungeonTileset.v4.png')

-- Load specific player sprite.
local char_spr = love.graphics.newQuad(80, 144, 16, 16, spr_list:getWidth(), spr_list:getHeight())

-- Load specific enemy sprite.
local en_spr = love.graphics.newQuad(80, 176, 16, 16, spr_list:getWidth(), spr_list:getHeight())

-- Set sprite for enemy characters.
for i = 1, 100 do
    enemies[i]:setSprite(en_spr)
end

-- Create player obj.
local player = character:new()
player:setPos(spawn.x, spawn.y)

-- player:setSprite('assets/sprite.png')

-- Set player sprite.
player:setSprite(char_spr)

-- Create sprite objects to display on map.
layer.sprites = {
    player = {
        sprite = player.sprite,
        x = player.xPos,
        y = player.yPos,
        -- ox = player.sprite:getWidth() / 2,
        -- oy = player.sprite:getHeight() / 1.35,
        collidable = true,
        name = 'player',
        ob = player
    }
}

-- Create enemy sprites.
local tmp = {}
for i = 1, 100 do
    tmp = {
        sprite = enemies[i].sprite,
        x = enemies[i].xPos,
        y = enemies[i].yPos,
        collidable = true,
        dir = -1,
        name = 'enemy',
        ob = enemies[i]
    }
    table.insert(layer.sprites, tmp)
end

map:bump_init(world)

-- Add character to collision world.
world:add(layer.sprites.player, layer.sprites.player.x, layer.sprites.player.y, 16 / 10, 16 / 50)

-- -- Add enemies to collision world.
for key, value in pairs(layer.sprites) do
    if value.name == 'enemy' then
        world:add(value, value.x, value.y, 16 / 10, 16 / 50)
    end
end

-- Remove unneeded object layer.
map:removeLayer("Spawn Point")

-- Draw player and the rest of the characters on layer Sprite.
layer.draw = function(self)
    love.graphics.draw(spr_list, self.sprites.player.sprite, math.floor(self.sprites.player.x),
        math.floor(self.sprites.player.y), 0, self.sprites.player.ob.dir, 1, 16 / 2, 16 / 1.1)

    for i = 1, 100 do
        for key, value in pairs(self.sprites) do
            if value.name == 'enemy' and value.ob.alive == true then
                local enemy = value
                love.graphics.draw(spr_list, enemy.sprite, math.floor(enemy.x), math.floor(enemy.y), 0, enemy.ob.dir, 1,
                    16 / 2, 16 / 1.1)
            end
        end
    end

    -- Temporarily draw a point at our location so we know
    -- that our sprite is offset properly.
    -- love.graphics.setPointSize(4)
    -- love.graphics.points(math.floor(self.sprites.player.x), math.floor(self.sprites.player.y))

end

layer.update = function(self, dt)
    -- 50 pixels per second
    local speed = 50

    -- Implement enemy smart movement.
    for key, value in pairs(self.sprites) do
        if value.name == 'enemy' then
            local enemy = value
            if enemy.ob.alive == true then
                moveEnemy(enemy.ob, self.sprites.player.ob, enemy, self.sprites.player, dt)
            end
        end
    end

    -- Move player up.
    if love.keyboard.isDown('w') or love.keyboard.isDown("up") then
        self.sprites.player.y = self.sprites.player.y - speed * dt
        movePlayer('up', self.sprites.player.ob, self.sprites.player, dt)

    end

    -- Move player down.
    if love.keyboard.isDown('s') or love.keyboard.isDown("down") then
        self.sprites.player.y = self.sprites.player.y + speed * dt
        movePlayer('down', self.sprites.player.ob, self.sprites.player, dt)
    end

    -- Move player left.
    if love.keyboard.isDown('a') or love.keyboard.isDown("left") then
        self.sprites.player.x = self.sprites.player.x - speed * dt
        movePlayer('left', self.sprites.player.ob, self.sprites.player, dt)
        self.sprites.player.ob:flip(1)
    end

    -- Move player right.
    if love.keyboard.isDown('d') or love.keyboard.isDown("right") then
        self.sprites.player.x = self.sprites.player.x + speed * dt
        movePlayer('right', self.sprites.player.ob, self.sprites.player, dt)
        self.sprites.player.ob:flip(-1)
    end

    if love.keyboard.isDown('k') then
        enemySelector(self.sprites.player.ob, self.sprites.player, dt)
    end

end

return map
