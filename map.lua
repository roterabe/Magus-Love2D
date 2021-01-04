local sti = require 'sti'
local bump = require 'bump.bump'
local bump_debug = require 'bump.bump_debug'

local cellsize = 16
local timer = 5
local initialtime = love.timer.getTime()

local map = sti('assets/dungeon/new_dungeon1.lua', {'bump'})

-- Create physics world.
local world = bump.newWorld(cellsize)