--TODO Make game cool.
local map = require 'map'

-- Load various things in love and the game itself.
function love.load()

    love.graphics.setBackgroundColor(0, 0, 0)
    local font = love.graphics.newFont()
    love.graphics.setFont(font, 144)

end

function love.update(dt)
    -- map:resize(700, 700)
    map:update(dt)
end

function love.draw()

    love.graphics.print('AD: ~30 DPS', 850, 710)
    love.graphics.print('Health:', 920, 710)
    love.graphics.print(map:drawHealth(), 980, 710)

    -- Scale world.
    local scale = 3
    local screen_width = love.graphics.getWidth() / scale
    local screen_height = love.graphics.getHeight() / scale
    local sw, sh = 250, 200

    -- Translate world so that player is always centred
    local player = map.layers["Sprites"].sprites.player
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
