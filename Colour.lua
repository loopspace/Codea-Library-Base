-- Colour manipulation
-- Author: Andrew Stacey
-- Website: http://www.math.ntnu.no/~stacey/HowDidIDoThat/iPad/Codea.html
-- Licence: CC0 (http://wiki.creativecommons.org/CC0)

--[[
This provides some functions for basic colour manipulation such as
colour blending.  The functions act on "color" objects and also return
"color" objects.
--]]

--[[
Although we are not a class, we work in the "Colour" namespace to keep
ourselves from interfering with other classes.
--]]
cache = true
local Colour = Colour or {}

-- Should we modify the alpha of our colours?
local ModifyAlpha = false

function Colour.hsl(h,s,l,a)
    h = (h-math.floor(h))*6
    s = s or 1
    l = l or 1
    a = a or 255
    local c = (1-2*math.abs(2*l-1))*s*255
    local m = l*255 - c/2
    local x = c*(1 - math.abs(h%2 - 1))
    if h < 1 then
        return color(c+m,x+m,m,a)
    elseif h < 2 then
        return color(x+m,c+m,m,a)
    elseif h < 3 then
        return color(m,c+m,x+m,a)
    elseif h < 4 then
        return color(m,x+m,c+m,a)
    elseif h < 5 then
        return color(x+m,m,c+m,a)
    else
        return color(c+m,m,x+m,a)
    end
end

function Colour.tohsl(r,g,b,a)
    if type(r) == "userdata" then
        r,g,b,a = r.r,r.g,r.b,r.a
    end
    r = r/255
    g = g/255
    b = b/255
    local M = math.max(r,g,b)
    local m = math.min(r,g,b)
    local c = M - m
    local h,s,l
    if c == 0 then
        h = 0
    elseif M == r then
        h = (g-b)/c/6
        h = h - math.floor(h)
    elseif M == g then
        h = ((b-r)/c+2)/6
    else
        h = ((r-g)/c+4)/6
    end
    l = (M + m)/2
    if l == 0 then
        s = 0
    else
        s = c/(1-math.abs(2*l-1))
    end
    return h,s,l,a
end

function Colour.tohsv(r,g,b,a)
    if type(r) == "userdata" then
        r,g,b,a = r.r,r.g,r.b,r.a
    end
    r = r/255
    g = g/255
    b = b/255
    local M = math.max(r,g,b)
    local m = math.min(r,g,b)
    local c = M - m
    local h,s,v
    if c == 0 then
        h = 0
    elseif M == r then
        h = (g-b)/c/6
        h = h - math.floor(h)
    elseif M == g then
        h = ((b-r)/c+2)/6
    else
        h = ((r-g)/c+4)/6
    end
    v = M
    if v == 0 then
        s = 0
    else
        s = c/v
    end
    return h,s,v,a
end

function Colour.hsv(h,s,v,a)
    h = (h-math.floor(h))*6
    s = s or 1
    v = v or 1
    a = a or 255
    local m = (v - s*v)*255
    local c = s*v*255
    local x = c*(1 - math.abs(h%2 - 1))
    if h < 1 then
        return color(c+m,x+m,m,a)
    elseif h < 2 then
        return color(x+m,c+m,m,a)
    elseif h < 3 then
        return color(m,c+m,x+m,a)
    elseif h < 4 then
        return color(m,x+m,c+m,a)
    elseif h < 5 then
        return color(x+m,m,c+m,a)
    else
        return color(c+m,m,x+m,a)
    end
end

--[[
This blends the two specified colours according to the parameter given
as the middle argument (the syntax is based on that of the "xcolor"
LaTeX package) which is the percentage of the first colour.
--]]

function Colour.blend(cc,t,c,m)
    local s,r,g,b,a
    m = m or ModifyAlpha
   s = t / 100
   r = s * cc.r + (1 - s) * c.r
   g = s * cc.g + (1 - s) * c.g
   b = s * cc.b + (1 - s) * c.b
   if m then
      a = s * cc.a + (1 - s) * c.a
   else
      a = cc.a
   end
   return color(r,g,b,a)
end

--[[
This "tints" the specified colour which means blending it with white.
The parameter is the percentage of the specified colour.
--]]

function Colour.tint(c,t,m)
   local s,r,g,b,a 
    m = m or ModifyAlpha
   s = t / 100
   r = s * c.r + (1 - s) * 255
   g = s * c.g + (1 - s) * 255
   b = s * c.b + (1 - s) * 255
   if m then
      a = s * c.a + (1 - s) * 255
   else
      a = c.a
   end
   return color(r,g,b,a)
end

--[[
This "shades" the specified colour which means blending it with black.
The parameter is the percentage of the specified colour.
--]]

function Colour.shade(c,t,m)
   local s,r,g,b,a 
    m = m or ModifyAlpha
   s = t / 100
   r = s * c.r
   g = s * c.g
   b = s * c.b
   if m then
      a = s * c.a
   else
      a = c.a
   end
   return color(r,g,b,a)
end

--[[
This "tones" the specified colour which means blending it with gray.
The parameter is the percentage of the specified colour.
--]]

function Colour.tone(c,t,m)
   local s,r,g,b,a 
    m = m or ModifyAlpha
   s = t / 100
   r = s * c.r + (1 - s) * 127
   g = s * c.g + (1 - s) * 127
   b = s * c.b + (1 - s) * 127
   if m then
      a = s * c.a + (1 - s) * 127
   else
      a = c.a
   end
   return color(r,g,b,a)
end

--[[
This returns the complement of the given colour.
--]]

function Colour.complement(c,m)
    local r,g,b,a
        m = m or ModifyAlpha
   r = 255 - c.r
   g = 255 - c.g
   b = 255 - c.b
   if m then
      a = 255 - c.a
   else
      a = c.a
   end
   return color(r,g,b,a)
end

--[[
This forces each channel to an on/off state.
--]]

function Colour.posterise(c,t,m)
    local r,g,b,a
    m = m or ModifyAlpha
    t = t or 127
    if c.r > t then
        r = 255
    else
        r = 0
    end
    if c.g > t then
        g = 255
    else
        g = 0
    end
    if c.b > t then
        b = 255
    else
        b = 0
    end
   if m then
    if c.a > t then
        a = 255
    else
        a = 0
    end
   else
      a = c.a
   end
   return color(r,g,b,a)
end

--[[
These functions adjust the alpha.
--]]

function Colour.opacity(c,t)
    return color(c.r,c.g,c.b,t*c.a/100)
end

function Colour.opaque(c)
    return color(c.r,c.g,c.b,255)
end

--[[
This "pretty prints" the colour, converting it to a string.
--]]

function Colour.tostring(c)
    return "R:" .. c.r .. " G:" .. c.g .. " B:" .. c.b .. " A:" .. c.a
end

function Colour.fromstring(c)
    local r,g,b,a
    r = string.match(c,"R:(%d+)")
    g = string.match(c,"G:(%d+)")
    b = string.match(c,"B:(%d+)")
    a = string.match(c,"A:(%d+)")
    return color(r,g,b,a)
end

function Colour.readData(t,k,c)
    local f
    if t == "global" then
        f = readGlobalData
    elseif t == "project" then
        f = readProjectData
    else
        f = readLocalData
    end
    local col = f(k)
    if col then
        return Colour.fromstring(col)
    else
        return c
    end
end

function Colour.saveData(t,k,c)
    local f
    if t == "global" then
        f = saveGlobalData
    elseif t == "project" then
        f = saveProjectData
    else
        f = saveLocalData
    end
    f(k,Colour.tostring(c))
end

--[[
This searches for a colour by name from a specified list (such as
"svg" or "x11").  It looks for a match for the given string at the
start of the name of the colour, without regard for case.
--]]

function Colour.byName(t,n)
   local ln,k,v,s,lk
   ln = "^" .. string.lower(n)
   for k,v in pairs(Colour[t]) do
      lk = string.lower(k)
      s = string.find(lk,ln)
      if s then
         return v
      end
   end
   print("Colour Error: No colour of name " .. n .. " exists in type " .. t)
end

--[[
Get a random colour, either from a list or random.
But not black.
--]]

local __colourlists = {}

function Colour.random(s)
    if s then
        if __colourlists[s] then
            return __colourlists[s][math.random(#__colourlists[s])]
        elseif Colour[s] then
            __colourlists[s] = {}
            for k,v in pairs(Colour[s]) do
                if k ~= "Black" then
                    table.insert(__colourlists[s],v)
                end
            end
            return __colourlists[s][math.random(#__colourlists[s])]
        end
    end
    local r,g,b = 0,0,0
    while r+g+b < 20 do
        r,g,b = math.random(256)-1,
                math.random(256)-1,math.random(256)-1
    end
    return color(r,g,b,255)
end
            
if _M then
    return Colour
else
    _G["Colour"] = Colour
end


