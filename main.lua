local sti = require('sti.init')

function love.load()

    -- Brush object - player.
    Brush = {}
    Brush.x = 150
    Brush.y = 600
    Brush.w = 16
    Brush.h = 16

    love.graphics.setBackgroundColor(255, 153, 0)

    map = sti('assets/pp.lua')
    local layer = map:addCustomLayer("Sprites", 3)

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
        w = 16,
        h = 16
    }

    layer.update = function(self, dt)
        -- 96 pixels per second
        local speed = 96

        -- Move player up
        if love.keyboard.isDown("w") or love.keyboard.isDown("up") then
            self.player.y = self.player.y - speed * dt
        end

        -- Move player down
        if love.keyboard.isDown("s") or love.keyboard.isDown("down") then
            self.player.y = self.player.y + speed * dt
        end

        -- Move player left
        if love.keyboard.isDown("a") or love.keyboard.isDown("left") then
            self.player.x = self.player.x - speed * dt
        end

        -- Move player right
        if love.keyboard.isDown("d") or love.keyboard.isDown("right") then
            self.player.x = self.player.x + speed * dt
        end
    end

    -- Draw player
    layer.draw = function(self)
        love.graphics.draw(self.player.sprite, math.floor(self.player.x), math.floor(self.player.y), 0, 0.1, 0.1,
            self.player.ox, self.player.oy)

        -- Temporarily draw a point at our location so we know
        -- that our sprite is offset properly
        love.graphics.setPointSize(5)
        love.graphics.points(math.floor(self.player.x), math.floor(self.player.y))
        love.graphics.circle('fill', player.x, player.y, 16, 16)
    end

    -- Remove unneeded object layer
    map:removeLayer("Spawn Point")

end

function collision(x1, y1, w1, h1, x2, y2, w2, h2)
    return x1 < x2 + w2 and x2 < x1 + w1 and y1 < y2 + h2 and y2 < y1 + h1
end

function love.update(dt)
    if love.keyboard.isDown('d') then
        Brush.x = Brush.x + 1 * dt * 300
    elseif love.keyboard.isDown('a') then
        Brush.x = Brush.x - 1 * dt * 300
    end
    if love.keyboard.isDown('w') then
        Brush.y = Brush.y - 1 * dt * 300
    elseif love.keyboard.isDown('s') then
        Brush.y = Brush.y + 1 * dt * 300
    end
    map:update(dt)

end

function love.draw()
    --[[ local player = map.layers["Sprites"].player
    local tx = math.floor(player.x - love.graphics.getWidth() / 2)
    local ty = math.floor(player.y - love.graphics.getHeight() / 2)
    love.graphics.translate(-tx, -ty) ]]
    map:draw()
    love.graphics.setColor(169, 169, 169, 64)

    -- love.graphics.circle("fill", Brush.x, Brush.y, Brush.w, Brush.h)
end
