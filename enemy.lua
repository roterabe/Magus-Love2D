Enemy = {xPos = 0, yPos = 0, width = 16, height = 16}

function Enemy:new (o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  return o
end