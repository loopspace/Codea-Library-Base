-- Rectangle class
    
local __RectAnchors = {}

-- Order is l,d,r,u
__RectAnchors.lowerleft = function(v,l,d,r,u) return v.x,v.y,r,u end
__RectAnchors.southwest = __RectAnchors.lowerleft 
__RectAnchors["south west"]= __RectAnchors.lowerleft 
__RectAnchors["lower left"]= __RectAnchors.lowerleft 
__RectAnchors.lowerright = function(v,l,d,r,u) return l,v.y,v.x,u end
__RectAnchors.southeast = __RectAnchors.lowerright
__RectAnchors["south east"]= __RectAnchors.lowerright
__RectAnchors["lower right"]= __RectAnchors.lowerright
__RectAnchors.upperleft = function(v,l,d,r,u) return v.x,d,r,v.y end
__RectAnchors.northwest = __RectAnchors.upperleft
__RectAnchors["north west"]= __RectAnchors.upperleft
__RectAnchors["upper left"]= __RectAnchors.upperleft
__RectAnchors.upperright = function(v,l,d,r,u) return l,d,v.x,v.y end
__RectAnchors.northeast = __RectAnchors.upperright 
__RectAnchors["north east"]= __RectAnchors.upperright 
__RectAnchors["upper right"]= __RectAnchors.upperright 
__RectAnchors.north = function(v,l,d,r,u,s)
       if l then
           r = 2*v.x - l
       elseif r then
           l = 2*v.x - r
       else
           l = v.x - s.x/2
           r = v.x + s.x/2
       end
        u = v.y
        return l,d,r,u
    end
__RectAnchors.top = __RectAnchors.north
__RectAnchors.south = function(v,l,d,r,u,s)
       if l then
           r = 2*v.x - l
       elseif r then
           l = 2*v.x - r
       else
           l = v.x - s.x/2
           r = v.x + s.x/2
       end
        d = v.y
        return l,d,r,u
    end
__RectAnchors.bottom = __RectAnchors.south
__RectAnchors.west = function(v,l,d,r,u,s)
       if d then
           u = 2*v.y - d
       elseif r then
           d = 2*v.y - u
       else
           d = v.y - s.y/2
           u = v.y + s.y/2
       end
        l = v.x
        return l,d,r,u
    end
__RectAnchors.left = __RectAnchors.west
__RectAnchors.east = function(v,l,d,r,u,s)
       if d then
           u = 2*v.y - d
       elseif r then
           d = 2*v.y - u
       else
           d = v.y - s.y/2
           u = v.y + s.y/2
       end
        r = v.x
        return l,d,r,u
    end
__RectAnchors.right = __RectAnchors.east
__RectAnchors.centre = function(v,l,d,r,u,s)
       if l then
           r = 2*v.x - l
       elseif r then
           l = 2*v.x - r
       else
           l = v.x - s.x/2
           r = v.x + s.x/2
       end
       if d then
           u = 2*v.y - d
       elseif u then
           d = 2*v.y - u
       else
           d = v.y - s.y/2
           u = v.y + s.y/2
       end
    return l,d,r,u
   end
__RectAnchors.center = __RectAnchors.centre
__RectAnchors.middle = __RectAnchors.centre

local Rectangle = class()

function Rectangle:init(t)
   t = t or {}
   if t.size and t.ll then
       -- quick clone/initialiser
       self.size = t.size
       self.ll = t.ll
       return self
   end
   local s = vec2(1,1)
   if t.width then
       s.x = t.width
   end
   if t.height then
       s.y = t.height
   end
   if t.size then
       s = t.size
   end
   local l,r,u,d
    for k,v in pairs(t) do
        if __RectAnchors[k] then
            l,d,r,u = __RectAnchors[k](v,l,d,r,u,s)
        end
    end
   if l and r then
       s.x = r - l
   elseif r then
       l = r - s.x
   else
       l = 0
   end
   if u and d then
       s.y = u - d
   elseif u then
       d = u - s.y
   else
       d = 0
   end
   self.ll = vec2(l,d)
   self.size = s
end

function Rectangle:clone()
   return Rectangle(self)
end

function Rectangle:anchor(a)
   if a == "width" then
       return self.size.x
   end
   if a == "height" then
       return self.size.y
   end
   if a == "size" then
       return self.size
   end
   if a == "centre" then
       return self.ll + .5*self.size
   end
   if a == "center" then
       return self.ll + .5*self.size
   end
   if a == "south west" then
       return self.ll
   end
   if a == "south east" then
       return self.ll + vec2(self.size.x,0)
   end
   if a == "north west" then
       return self.ll + vec2(0,self.size.y)
   end
   if a == "north east" then
       return self.ll + self.size
   end
   if a == "south" then
       return self.ll + vec2(.5*self.size.x,0)
   end
   if a == "north" then
       return self.ll + vec2(.5*self.size.x,self.size.y)
   end
   if a == "west" then
       return self.ll + vec2(0,.5*self.size.y)
   end
   if a == "east" then
       return self.ll + vec2(self.size.x,.5*self.size.y)
   end
end

function Rectangle:TransformToScreen(v)
   if v then
       return vec2(
           (v.x - self.ll.x)/self.size.x*WIDTH,
           (v.y - self.ll.y)/self.size.y*HEIGHT
       )
   else
       scale(WIDTH/self.size.x,HEIGHT/self.size.y)
       translate(-self.ll.x,-self.ll.y)
   end
end

function Rectangle:TransformFromScreen(v)
   if v then
       return vec2(
           v.x*self.size.x/WIDTH + self.ll.x,
           v.y*self.size.y/HEIGHT + self.ll.y
       )
   else
       translate(self.ll.x,self.ll.y)
       scale(self.size.x/WIDTH,self.size.y/HEIGHT)
   end
end

function Rectangle:TransformToOrientation(o,v)
    local w,h
    if o == LANDSCAPE_LEFT or o == LANDSCAPE_RIGHT then
        w,h = RectAnchorOf(Landscape,"size")
    else
        w,h = RectAnchorOf(Portrait,"size")
    end
   if v then
       return vec2(
           (v.x - self.ll.x)/self.size.x*w,
           (v.y - self.ll.y)/self.size.y*h
       )
   else
       scale(w/self.size.x,h/self.size.y)
       translate(-self.ll.x,-self.ll.y)
   end
end

function Rectangle:TransformFromOrientation(o,v)
    local w,h
    if o == LANDSCAPE_LEFT or o == LANDSCAPE_RIGHT then
        w,h = RectAnchorOf(Landscape,"size")
    else
        w,h = RectAnchorOf(Portrait,"size")
    end
   if v then
       return vec2(
           v.x*self.size.x/w + self.ll.x,
           v.y*self.size.y/h + self.ll.y
       )
   else
       translate(self.ll.x,self.ll.y)
       scale(self.size.x/w,self.size.y/h)
   end
end

function Rectangle:TransformDirToScreen(v)
   if v then
       return vec2(
           v.x/self.size.x*WIDTH,
           v.y/self.size.y*HEIGHT
       )
   else
       scale(WIDTH/self.size.x,HEIGHT/self.size.y)
   end
end

function Rectangle:TransformDirFromScreen(v)
   if v then
       return vec2(
           v.x*self.size.x/WIDTH,
           v.y*self.size.y/HEIGHT
       )
   else
       scale(self.size.x/WIDTH,self.size.y/HEIGHT)
   end
end

function Rectangle:Compose(r)
   local ll = self.ll + vec2(r.ll.x*self.size.x, r.ll.y*self.size.y)
   local s = vec2(r.size.x*self.size.x, r.size.y*self.size.y)
   return Rectangle({ll = ll, size = s})
end

function Rectangle:Translate(v)
   return Rectangle({ll = self.ll + v, size = self.size})
end

function Rectangle:ScaleAboutCentre(v)
   local s
   if type(v) == "number" then
       s = vec2(self.size.x * v,self.size.y * v)
   else
       s = vec2(self.size.x * v.x,self.size.y * v.y)
   end
   local ll = self.ll + .5 * self.size - .5*s
   return Rectangle({ll = ll, size = s})
end

function Rectangle:Scale(v)
   local s
   if type(v) == "number" then
       s = vec2(self.size.x * v,self.size.y * v)
   else
       s = vec2(self.size.x * v.x,self.size.y * v.y)
   end
   return Rectangle({ll = self.ll, size = s})
end

function Rectangle:ScaleAboutPoint(v,p)
   local px = (p.x - self.ll.x)/self.size.x
   local py = (p.y - self.ll.y)/self.size.y
   local s
   if type(v) == "number" then
       s = vec2(self.size.x * v,self.size.y * v)
   else
       s = vec2(self.size.x * v.x,self.size.y * v.y)
   end
   local ll = p - vec2(px*s.x,py*s.y)
   return Rectangle({ll = ll, size = s})
end

function Rectangle:isInside(v)
    if v.x < self.ll.x or v.x > self.ll.x + self.size.x or v.y < self.ll.y or v.y > self.ll.y + self.size.y then
        return false
    end
    return true
end

function Rectangle:draw()
    pushStyle()
    rectMode(CORNER)
    rect(self.ll.x,self.ll.y,self.size.x,self.size.y)
    popStyle()
end

function Rectangle:setAnchor(a,v,w)
    a = string.lower(a)
    a = string.gsub(a," ","")
    if a == "inside" or a == "insideverticalhorizontal" or a == "insidehorizontalvertical" then
        self.ll.x = math.min(v.x,w.x)
        self.ll.y = math.min(v.y,w.y)
        self.size.x = math.max(v.x,w.x)
        self.size.y = math.max(v.y,w.y)
        self.size = self.size - self.ll
        return
    end
    if a == "insidehorizontal" then
        self.ll.x = math.min(v.x,w.x)
        self.size.x = math.max(v.x,w.x) - self.ll.x
        return
    end
    if a == "insidevertical" then
        self.ll.y = math.min(v.y,w.y)
        self.size.y = math.max(v.y,w.y) - self.ll.y
        return
    end
    if a == "centre" or a == "center" then
        self.ll = v - self.size/2
        return
    end
    if a == "southwest" or a == "lowerleft" then
        self.size = self.size + self.ll - v
        self.ll = v
        return 
    end
    if a == "northwest" or a == "upperleft" then
        self.size.y = v.y - self.ll.y
        self.size.x = self.size.x + self.ll.x - v.x
        self.ll.x = v.x
        return 
    end
    if a == "southeast" or a == "lowerright" then
        self.size.y = self.size.y + self.ll.y - v.y
        self.size.x = v.x - self.ll.x
        self.ll.y = v.y
        return
    end
    if a == "northeast" or a == "upperright" then
        self.size = v - self.ll
        return
    end
    if a == "east" or a == "right" then
        self.size.x = v.x - self.ll.x
        return
    end
    if a == "west" or a == "left" then
        self.size.x = self.size.x + self.ll.x - v.x
        self.ll.x = v.x
        return
    end
    if a == "north" or a == "top" then
        self.size.y = v.y - self.ll.y
        return
    end
    if a == "south" or a == "bottom" then
        self.size.y = self.size.y + self.ll.y - v.y
        self.ll.y = v.y
        return
    end
end

if _M then
    return Rectangle
else
    _G["Rectangle"] = Rectangle
end


