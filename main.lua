-- TODO Make enemy name and object class somehow integrated so as to be found by scan.
local sti = require 'sti'
local bump = require 'bump.bump'
local bump_debug = require 'bump.bump_debug'
local enemy = require 'enemy'
local gamera = require 'gamera-master.gamera'
local character = require 'player'

local cellsize = 16
local timer = 5
local initialtime = love.timer.getTime()

local map = sti('assets/dungeon/new_dungeon1.lua', {'bump'})

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

-- Create physics world.
local world = bump.newWorld(cellsize)

-- Generate enemies.
local enemies = {}
for i = 1, 2 do
    enemies[i] = enemy:new()
end

enemies[1]:setPos(300, 300)
enemies[2]:setPos(600, 600)

enemies[1]:setSprite('assets/sprite.png')
enemies[2]:setSprite('assets/sprite.png')

local player = character:new()

player:setPos(spawn.x, spawn.y)
local spr_list = love.graphics.newImage('assets/dungeon/0x72_16x16DungeonTileset.v4.png')
local char_spr = love.graphics.newQuad(80, 144, 16, 16, spr_list:getWidth(), spr_list:getHeight())
-- player:setSprite('assets/sprite.png')
player:setSprite(char_spr)

-- Create sprite objects to display on map.
layer.player = {
    sprite = player.sprite,
    x = player.xPos,
    y = player.yPos,
    -- ox = player.sprite:getWidth() / 2,
    -- oy = player.sprite:getHeight() / 1.35,
    collidable = true,
    name = 'player',
    ob = player
}

layer.enemy1 = {
    sprite = enemies[1].sprite,
    x = enemies[1].xPos,
    y = enemies[1].yPos,
    ox = enemies[1].sprite:getWidth() / 2,
    oy = enemies[1].sprite:getHeight() / 1.35,
    collidable = true,
    dir = 1,
    name = 'enemy',
    ob = enemies[1]
}

layer.enemy2 = {
    sprite = enemies[2].sprite,
    x = enemies[2].xPos,
    y = enemies[2].yPos,
    ox = enemies[2].sprite:getWidth() / 2,
    oy = enemies[2].sprite:getHeight() / 1.35,
    collidable = true,
    dir = -1,
    name = 'enemy',
    ob = enemies[2]
}

-- Debug map with the help of Bump. Custom implementation.
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

        elseif cols[i].other.name == 'Black' then

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

    if dist(e.x, e.y, p.x, p.y) < 10 then
        if po.health <= 0 then
            po.health = 210
            local oX, oY = po:resetPos()
            p.x, p.y = oX, oY
            world:remove(p)
            world:add(p, p.x, p.y, p.sprite:getWidth() / 100, p.sprite:getHeight() / 50)
        end
        po.health = eo:attack(po)
        print('Miss me with that gay shit.')
    end
    local actualX, actualY, cols, len = world:move(e, goalX, goalY, playerFilter)
    e.x, e.y = actualX, actualY

    -- Direction switching implemented. Fixed collision release teleportation.

    for i = 1, len do
        if cols[i].other.name == 'andonov' then
            -- print('collided with ' .. tostring(cols[i].other.name))

        end
        -- print('collided with ' .. tostring(cols[i].other))
    end
end

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

-- Load various things in love and the game itself.
function love.load()

    love.graphics.setBackgroundColor(0, 0, 0)
    local font = love.graphics.newFont()
    love.graphics.setFont(font, 144)
    map:bump_init(world)

    -- Add characters to collision world.
    world:add(layer.player, layer.player.x, layer.player.y, 16 / 160, 16 / 160)
    world:add(layer.enemy1, layer.enemy1.x, layer.enemy1.y, enemies[1].sprite:getWidth() / 100,
        layer.enemy1.ob.sprite:getHeight() / 50)
    world:add(layer.enemy2, layer.enemy2.x, layer.enemy2.y, enemies[2].sprite:getWidth() / 100,
        layer.enemy2.ob.sprite:getHeight() / 50)

    layer.update = function(self, dt)
        -- 200 pixels per second
        local speed = 50

        -- Implement enemy smart movement.
        if self.enemy1.ob.alive == true then
            moveEnemy(self.enemy1.ob, self.player.ob, self.enemy1, self.player, dt)
        end
        if self.enemy2.ob.alive == true then
            moveEnemy(self.enemy2.ob, self.player.ob, self.enemy2, self.player, dt)
        end

        -- Move player up.
        if love.keyboard.isDown('w') or love.keyboard.isDown("up") then
            self.player.y = self.player.y - speed * dt
            movePlayer('up', self.player.ob, self.player, dt)

        end

        -- Move player down.
        if love.keyboard.isDown('s') or love.keyboard.isDown("down") then
            self.player.y = self.player.y + speed * dt
            movePlayer('down', self.player.ob, self.player, dt)
        end

        -- Move player left.
        if love.keyboard.isDown('a') or love.keyboard.isDown("left") then
            self.player.x = self.player.x - speed * dt
            movePlayer('left', self.player.ob, self.player, dt)
        end

        -- Move player right.
        if love.keyboard.isDown('d') or love.keyboard.isDown("right") then
            self.player.x = self.player.x + speed * dt
            movePlayer('right', self.player.ob, self.player, dt)
        end

        if love.keyboard.isDown('k') then
            enemySelector(self.player.ob, self.player, dt)
        end

    end

    -- Draw player and the rest of the characters on layer Sprite.
    layer.draw = function(self)
        love.graphics.draw(spr_list, self.player.sprite, math.floor(self.player.x), math.floor(self.player.y), 0, 1, 1,
            16 / 2, 16 / 1.1)

        if self.enemy1.ob.alive then
            love.graphics.draw(self.enemy1.sprite, math.floor(self.enemy1.x), math.floor(self.enemy1.y), 0, 0.1, 0.1,
                self.enemy1.ox, self.enemy1.oy)
        end

        if self.enemy2.ob.alive then
            love.graphics.draw(self.enemy2.sprite, math.floor(self.enemy2.x), math.floor(self.enemy2.y), 0, 0.1, 0.1,
                self.enemy2.ox, self.enemy2.oy)
        end
        -- Temporarily draw a point at our location so we know
        -- that our sprite is offset properly.
        -- love.graphics.setPointSize(5)
        -- love.graphics.points(math.floor(self.player.x), math.floor(self.player.y))

    end

    -- Remove unneeded object layer.
    map:removeLayer("Spawn Point")

end

function love.update(dt)
    -- map:resize(700, 700)
    map:update(dt)
end

function love.draw()

    love.graphics.print(player.health, 980, 710)

    -- Scale world.
    local scale = 3
    local screen_width = love.graphics.getWidth() / scale
    local screen_height = love.graphics.getHeight() / scale
    local sw, sh = 250, 200

    -- Translate world so that player is always centred
    local player = map.layers["Sprites"].player
    local tx = math.floor(player.x - sw / 2)
    local ty = math.floor(player.y - sh / 2)

    -- As basic as fog of war can get. Thank god I wasted 10 hours on more unoptimal solutions.
    map:resize(250, 200)
    map:draw(-tx, -ty, scale, scale)

    -- Collision map.
    -- map:bump_draw(world)
    -- drawDebug()

    -- Reset colour.
    love.graphics.setColor(255, 255, 255, 255)

end
