-- Coordinate calculations

--[[
This defines various standard rectangles to be used with RectAnchorAt to
determine various anchors.
The Screen rectangle should change dynamically.

These only work with fullscreen mode, otherwise it gets a bit complicated.
Also, the fullscreen mode should be initialised before this library is
loaded.
--]]

local Screen = {
   0,
   0,
   function() return WIDTH end,
   function() return HEIGHT end,
}

local _width,_height

if WIDTH > HEIGHT then
   _width = HEIGHT
   _height = WIDTH
else
   _width = WIDTH
   _height = HEIGHT
end

-- Rectangles defining the screen
local Landscape = {0,0,_height,_width}
local Portrait = {0,0,_width,_height}

-- Origin, x-vector, y-vector of orientation relative to Portrait
local OrientationCoordinates = {}
OrientationCoordinates[PORTRAIT] = {vec2(0,0), vec2(1,0), vec2(0,1)}
OrientationCoordinates[PORTRAIT_UPSIDE_DOWN] = {vec2(_width,_height), vec2(-1,0), vec2(0,-1)}
OrientationCoordinates[LANDSCAPE_LEFT] = {vec2(_width,0), vec2(0,1), vec2(-1,0)}
OrientationCoordinates[LANDSCAPE_RIGHT] = {vec2(0,_height), vec2(0,-1), vec2(1,0)}

-- Origin, x-vector, y-vector of Portrait relative to orientation
local OrientationInverseCoordinates = {}
OrientationInverseCoordinates[PORTRAIT] = {vec2(0,0), vec2(1,0), vec2(0,1)}
OrientationInverseCoordinates[PORTRAIT_UPSIDE_DOWN] = {vec2(_width,_height), vec2(-1,0), vec2(0,-1)}
OrientationInverseCoordinates[LANDSCAPE_LEFT] = {vec2(0,_width), vec2(0,-1), vec2(1,0)}
OrientationInverseCoordinates[LANDSCAPE_RIGHT] = {vec2(_height,0), vec2(0,1), vec2(-1,0)}

-- Transformation to translate following commands to Portrait view
local OrientationTransform = {}
OrientationTransform[PORTRAIT] = function() end
OrientationTransform[PORTRAIT_UPSIDE_DOWN] = function() translate(_width,_height) rotate(180) end
OrientationTransform[LANDSCAPE_LEFT] = function() translate(_width,0) rotate(90) end
OrientationTransform[LANDSCAPE_RIGHT] = function() translate(0,_height) rotate(-90) end

-- Transformation to translate following commands from Portrait view
local OrientationInverseTransform = {}
OrientationInverseTransform[PORTRAIT] = function() end
OrientationInverseTransform[PORTRAIT_UPSIDE_DOWN] = function() translate(_width,_height) rotate(180) end
OrientationInverseTransform[LANDSCAPE_LEFT] = function() rotate(-90) translate(-_width,0) end
OrientationInverseTransform[LANDSCAPE_RIGHT] = function() rotate(90) translate(0,-_height) end

--[[
Resolve an ambigous orientation
--]]

function ResolveOrientation(o,oo)
    if o == PORTRAIT_ANY then
        if oo == PORTRAIT_UPSIDE_DOWN then
            return PORTRAIT_UPSIDE_DOWN
        else
            return PORTRAIT
        end
    elseif o == LANDSCAPE_ANY then
        if oo == LANDSCAPE_RIGHT then
            return LANDSCAPE_RIGHT
        else
            return LANDSCAPE_LEFT
        end
    end
    return o
end

--[[
Transform vector x relative to orientation o into a vector relative to
the current orientation.
--]]
function Orientation(o,x)
    o = ResolveOrientation(o,CurrentOrientation)
   if CurrentOrientation == o then
      return x
   end
   local y = x.x * OrientationCoordinates[o][2]
      + x.y * OrientationCoordinates[o][3]
      + OrientationCoordinates[o][1]
   local z = y.x * OrientationInverseCoordinates[CurrentOrientation][2]
      + y.y * OrientationInverseCoordinates[CurrentOrientation][3]
      + OrientationInverseCoordinates[CurrentOrientation][1]
   return z
end

--[[
Transform vector x relative to the current orientation o into a
vector relative to the current orientation.
--]]

function OrientationInverse(o,x)
    o = ResolveOrientation(o,CurrentOrientation)
   if CurrentOrientation == o then
      return x
   end
   local y = x.x * OrientationCoordinates[CurrentOrientation][2]
      + x.y * OrientationCoordinates[CurrentOrientation][3]
      + OrientationCoordinates[CurrentOrientation][1]
   local z = y.x * OrientationInverseCoordinates[o][2]
      + y.y * OrientationInverseCoordinates[o][3]
      + OrientationInverseCoordinates[o][1]
   return z
end

function Orientations(o,oo,x)
    o = ResolveOrientation(o,oo)
    oo = ResolveOrientation(oo,o)
   if oo == o then
      return x
   end
   local y = x.x * OrientationCoordinates[o][2]
      + x.y * OrientationCoordinates[o][3]
      + OrientationCoordinates[o][1]
   local z = y.x * OrientationInverseCoordinates[oo][2]
      + y.y * OrientationInverseCoordinates[oo][3]
      + OrientationInverseCoordinates[oo][1]
   return z
end

function TransformTouch(o,t)
    o = ResolveOrientation(o,CurrentOrientation)
    local tt = {}
    local ofn
    if type(o) == "function" then
        ofn = o
    else
        ofn = function(u) return OrientationInverse(o,u) end
    end
    local v = ofn(t)
    tt.x = v.x
    tt.y = v.y
    v = ofn(vec2(t.prevX,t.prevY))
    tt.prevX = v.x
    tt.prevY = v.y
    tt.deltaX = tt.x - v.x
    tt.deltaY = tt.y - v.y
    for _,u in ipairs({"state","tapCount","id"}) do
        tt[u] = t[u]
    end
    return tt
end

--[[
Apply a transformation to transform the following drawing commands
relative to orientation o into commands relative to the current
orientation.
--]]

function TransformOrientation(o)
    o = ResolveOrientation(o,CurrentOrientation)
   if CurrentOrientation == o then
      return
   end
   OrientationInverseTransform[CurrentOrientation]()
   OrientationTransform[o]()
end

--[[
Apply a transformation to transform the following drawing commands
relative to the current orientation into commands relative to the
specified orientation.
--]]

function TransformInverseOrientation(o)
    o = ResolveOrientation(o,CurrentOrientation)
   if CurrentOrientation == o then
      return
   end
   OrientationInverseTransform[o]()
   OrientationTransform[CurrentOrientation]()
end

function TransformOrientations(o,oo)
    o = ResolveOrientation(o,oo)
    oo = ResolveOrientation(oo,o)
   if oo == o then
      return
   end
   OrientationInverseTransform[o]()
   OrientationTransform[oo]()
end

--[[
This is an auxilliary function used by the "Textarea" class which
works out the coordinate of a rectangle as specified by an "anchor"
(the notions used here are inspired by the "TikZ/PGF" LaTeX package).
This returns the lower-left coordinate of a rectangle of width w
and height h so that the anchor is at the specified x,y coordinate.
--]]

function RectAnchorAt(x,y,w,h,a,A)
    if type(x) == "table" then
      a = y
      x,y,w,h,A = unpack(x)
    end
    if type(x) == "function" then
       x = x()
    end
    if type(y) == "function" then
       y = y()
    end
    if type(w) == "function" then
       w = w()
    end
    if type(h) == "function" then
       h = h()
    end
    -- (x,y) is south-west
    local v = vec2(0,0)
    if a == "north" then
       v = vec2(w/2,h)
    elseif a == "south" then
       v = vec2(w/2,0)
    elseif a == "east" then
       v = vec2(w,h/2)
    elseif a == "west" then
       v = vec2(0,h/2)
    elseif a == "north west" then
       v = vec2(0,h)
    elseif a == "south east" then
       v = vec2(w,0)
    elseif a == "north east" then
       v = vec2(w,h)
    elseif a == "south west" then
       v = vec2(0,0)
    elseif a == "centre" then
       v = vec2(w/2,h/2)
    elseif a == "center" then
       v = vec2(w/2,h/2)
    end
    if A and A ~= 0 then
        v = v:rotate(math.rad(A))
    end
    return x - v.x,y - v.y
end

--[[
This is the reverse of the above: it gives the location of the anchor
on the rectangle of width w and height h with lower-left corner at x,y.
--]]

function RectAnchorOf(x,y,w,h,a)
    if type(x) == "table" then
      a = y
      x,y,w,h = unpack(x)
    end
    --- "bake" the coordinates
    if type(x) == "function" then
       x = x()
    end
    if type(y) == "function" then
       y = y()
    end
    if type(w) == "function" then
       w = w()
    end
    if type(h) == "function" then
       h = h()
    end
    -- not quite anchors, more dimensions
    if a == "x" then
       return x
    end
    if a == "y" then
       return y
    end
    if a == "width" then
       return w
    end
    if a == "height" then
       return h
    end
    if a == "size" then
       return w,h
    end
    -- (x,y) is south-west
    if a == "north" then
        return x + w/2, y + h
    end
    if a == "south" then
        return x + w/2, y
    end
    if a == "east" then
        return x + w, y + h/2
    end
    if a == "west" then
        return x, y + h/2
    end
    if a == "north west" then
        return x, y + h
    end
    if a == "south east" then
        return x + w, y
    end
    if a == "north east" then
        return x + w, y + h
    end
    if a == "south west" then
        return x, y
    end
    if a == "centre" then
        return x + w/2, y + h/2
    end
    if a == "center" then
        return x + w/2, y + h/2
    end
    return x,y
end


--[[
This is for positioning text at a location, given by an anchor, but with an extra separation.  The width and height are of the text.
--]]

function TextAnchorAt(x,y,w,h,a,s)
    x,y = RectAnchorAt(x,y,w+2*s,h+2*s,a)
    return x+s,y+s
end

-- Should use RectAnchorOf(__,"width/height")

function WidthOf(t)
    if type(t[3]) == "function" then
        return t[3]()
    else
        return t[3]
    end
end

function HeightOf(t)
    if type(t[4]) == "function" then
        return t[4]()
    else
        return t[4]
    end
end

function RectTouchedBy(x,y,w,h,t)
    if type(x) == "table" then
      t = y
      x,y,w,h = unpack(x)
    end
    --- "bake" the coordinates
    if type(x) == "function" then
       x = x()
    end
    if type(y) == "function" then
       y = y()
    end
    if type(w) == "function" then
       w = w()
    end
    if type(h) == "function" then
       h = h()
    end
    if t.x < x or t.x > x + w then
        return false
    end
    if t.y < y or t.y > y + h then
        return false
    end
    return true
end


local exports = {
   Screen = Screen,
   Landscape = Landscape,
   Portrait = Portrait,
   OrientationCoordinates = OrientationCoordinates,
   OrientationInverseCoordinates = OrientationInverseCoordinates,
   OrientationTransform = OrientationTransform,
   OrientationInverseTransform = OrientationInverseTransform,
   ResolveOrientation = ResolveOrientation,
   Orientation = Orientation,
   OrientationInverse = OrientationInverse,
   Orientations = Orientations,
   TransformTouch = TransformTouch,
   TransformOrientation = TransformOrientation,
   TransformInverseOrientation = TransformInverseOrientation,
   TransformOrientations = TransformOrientations,
   RectAnchorAt = RectAnchorAt,
   RectAnchorOf = RectAnchorOf,
   TextAnchorAt = TextAnchorAt,
   WidthOf = WidthOf,
   HeightOf = HeightOf,
   RectTouchedBy = RectTouchedBy
	}
if _M then
    cmodule.export(exports)
else
    for k,v in pairs(exports) do
        _G[k] = v
    end
end
