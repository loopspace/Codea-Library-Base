-- Touch handler class
-- Author: Andrew Stacey
-- Website: http://www.math.ntnu.no/~stacey/HowDidIDoThat/iPad/Codea.html
-- Licence: CC0 http://wiki.creativecommons.org/CC0

--[[
The classes in this file are for handling touches.  The classes are:

Touches: this is the controller class which gathers touches, figures
out which object they belong to, and passes the information to those
objects in an orderly manner as a "gesture".

Gesture: a gesture is a collection of touches that are "alive" and
claimed by the same object.  A gesture is analysed before being passed
to an object to help provide some information as to what type of
gesture it is.

Touch: this represents a touch as a single object (from start to
finish) and is updated by the controller as new information comes in.
--]]

if _M then
    cimport "Coordinates"
end

local Touches = class()
local Gesture = class()
local Touch = class()

--[[
The controlling object has an array of touches, an array of handlers,
and an array of "active touches".

When a "touch" object is registered by Codea, the handler takes it and
tries to work out what to do with it.  When a touch begins, the
handler creates a "Touch" object surrounding it.  As new information
comes in, via new "touch" objects, this needs to be linked to the
correct "Touch" object.  The handler uses the "touch.id" to do this,
but this creates a problem: although the "touch.id" is guaranteed to
be unique in the lifetime of the touch, it might be reused afterwards.
For complicated gestures, it is useful to have "Touch" objects persist
beyond the liftetime of the actual touch.  So more than one Touch can
correspond to the same "touch.id".  To get round this, we maintain a
list of "active" touches: ie ones that have not officially ended.
These are the ones that accept new information.
--]]

function Touches:init()
    self.touches = {}
    self.handlers = {}
    self.numTouches = 0
    self.actives = {}
    local img = image(100,100)
    setContext(img)
    ellipseMode(RADIUS)
    fill(255, 223, 0, 21)
    strokeWidth(0)
    local r
    for i=0,90,5 do
        r = 10 + 40*math.sin(math.rad(i))
        ellipse(50,50,r)
    end
    self.img = img
    setContext()
end

--[[
This is where a touch is initially analysed.  If it is a new touch
then a Touch object is created.  Then each of the handlers in turn is
asked if it wants to "claim" the touch.  The first one to do so is
assigned the touch.  If none do, it is consigned to the bin.

There is a slight wrinkle in the above: it is possible for an object
to specify an "interrupt" which is given first priority in the
claimant queue.  Sometimes an object might want to take some action
"until the next touch", wherever that touch may be: this is to allow
for that.

If a touch is not new, its information is used to update the
corresponding active Touch object.
--]]

function Touches:addTouch(touch)
    local retval = false
    if touch.state == BEGAN then
        self.numTouches = self.numTouches + 1
        self.touches[self.numTouches] = Touch(touch)
        self.touches[self.numTouches].container = self
        self.touches[self.numTouches].id = self.numTouches
        self.actives[touch.id] = self.numTouches
        retval = true -- in case the interrupt gets it
        if
            not self.interrupt 
            or 
            not self.interrupt:interruption(
                    self.touches[self.actives[touch.id]]
                )
        then
            retval = false -- interrupt didn't
            retval = self:checkHandlers(touch,self.handlers)
            if not self.touches[self.actives[touch.id]].gesture then
                self.touches[self.actives[touch.id]] = nil
                self.actives[touch.id] = nil
                retval = false -- gesture rejected it for some reason
            end
        else
            -- Interrupt got it and used it, now we destroy it
            self.touches[self.actives[touch.id]]:destroy()
        end
    elseif touch.state == MOVING then
        if self.actives[touch.id] then
            self.touches[self.actives[touch.id]]:update(touch)
            retval = true
        end
    elseif touch.state == ENDED then
        if self.actives[touch.id] then
            self.touches[self.actives[touch.id]]:update(touch)
            retval = true
        end
    end
    return retval
end

--[[
Create a handler for adding to the relevant code.
--]]

function Touches:registerHandler(h)
    local g = Gesture(self)
    return {h,g}
end

--[[
This adds a new handler at the end of the list, creating a gesture to
contain its touches.
--]]

function Touches:pushHandler(h)
    local g = self:registerHandler(h)
    table.insert(self.handlers,g)
    return g[2]
end

--[[
This adds a new handler at the start of the list, creating a gesture to
contain its touches.
--]]

function Touches:unshiftHandler(h)
    local g = self:registerHandler(h)
    table.insert(self.handlers,1,g)
    return g[2]
end

function Touches:removeHandler(h)
    for k,v in ipairs(self.handlers) do
        if v[1] == h then
            table.remove(self.handlers,k)
            break
        end
    end
end

--[[
This adds a new table of handlers at the end of the list.
--]]

function Touches:pushHandlers(t)
    local t = t or {}
    table.insert(self.handlers,{t})
    return t
end

--[[
This adds a new table of handlers at the start of the list.
--]]

function Touches:unshiftHandlers(t)
    local t = t or {}
    table.insert(self.handlers,1,{t})
    return t
end

--[[
Check the handlers to see who claims the touch
--]]

function Touches:checkHandlers(touch,t)
    for k,v in ipairs(t) do
        if v[2] then
            if v[1]:isTouchedBy(touch) then
                v[2]:addTouch(self.touches[self.actives[touch.id]])
                return true 
            end
        else
            if self:checkHandlers(touch,v[1]) then
                return true
            end
        end
    end
    return false
end

--[[
The draw function is used to process the touch information gathered in
the current cycle.  Gestures are analysed and then passed to the
corresponding handers.
--]]

function Touches:show()
    if self.showtouch then
        pushStyle()
        pushMatrix()
        resetMatrix()
        resetStyle()
        for k,v in pairs(self.touches) do
            v:draw(self.img)
        end
        popMatrix()
        popStyle()
    end
end

function Touches:showTouches(s)
    self.showtouch = s
end

function Touches:draw()
    self:processHandlers(self.handlers)
end

function Touches:processHandlers(t)
    if t then
        for k,v in pairs(t) do
            if v[2] then
                if v[2].num > 0 then
                    v[2]:analyse()
                    v[1]:processTouches(v[2])
                    if v[2].type.finished then
                        v[2]:reset()
                    end
                end
            else
                self:processHandlers(v[1])
            end
        end
    end
end

function Touches:getById(id)
    if self.actives[id] then
        return self.touches[self.actives[id]]
    end
end

function Touches:reset()
    for k,v in pairs(self.touches) do
        v:destroy()
    end
    self.touches = {}
    self.numTouches = 0
    self.actives = {}
end

function Touches:pause()
end

--[[
A gesture is a group of touches that are handled by the same object
and are "alive" at the same time.  A gesture is analysed before being
passed to its object and certain basic information is gathered that
can be analysed by the handling object.  Most of this information is
stored in the "type" array with two notable exceptions.  The main list
is as follows (there are some others which are used for implementation
reasons that can nonetheless be used, but the following contains all
the available information):

num: the number of touches in the gesture.

updated: has there been new information since the gesture was last
looked at?

type.tap: this is true if none of the touches have moved

type.long: this is true if all of the touches waited a significant
length of time (currently .5s) between starting and ending or moving.

type.short: this is true if all of the touches were of short duration
(less that .5s).  Note that "short" and "long" are not opposites.

type.ended: if all the touches have ended.

type.finished: if all the touches ended at least .5s ago.  The
distinction between "ended" and "finished" is to allow for things like
multiple taps to be registered as a single gesture.

type.pinch: if the gesture consists of multiple movements, the gesture
tries to see if they are moving towards each other or parallel.  It
does this by looking at the relative movement of the barycentre of the
touch compared to the average magnitude of the movements of the
individual touches.
--]]



--[[
Initialise our data.
--]]

function Gesture:init(t)
    self.touchHandler = t
    self.touches = {}
    self.touchesArr = {}
    self.num = 0
    self.updated = true
    self.updatedat = ElapsedTime
    self.type = {}
end

--[[
Add a touch to the list.
--]]

function Gesture:addTouch(touch)
    self.num = self.num + 1
    self.touches[touch.id] = touch
    table.insert(self.touchesArr,touch)
    touch.gesture = self
    self.updated = true
    self.updatedat = ElapsedTime
    return true
end

--[[
Remove a touch from the list.
--]]

function Gesture:removeTouch(touch)
    for k,v in ipairs(self.touchesArr) do
        if v.id == touch.id then
            table.remove(self.touchesArr,k)
            break
        end
    end
    self.touches[touch.id] = nil
    touch.gesture = nil
    self.num = self.num - 1
    self.updated = true
    self.updatedat = ElapsedTime
    self.type = {}
    return true
end

--[[
Remove touches according to a test, then reanalyses the gesture
--]]

function Gesture:removeTouches(f)
    local del = {}
    for k,v in ipairs(self.touchesArr) do
        if f(v) then
            table.insert(del,1,k)
        end
    end
    local t
    for k,v in ipairs(del) do
        t = table.remove(self.touchesArr,v)
        self.touches[t.id] = nil
        t.gesture = nil
        self.num = self.num - 1
    end
    if #del > 0 then
        self.updated = false
        self.updatedat = 0
        for k,v in ipairs(self.touchesArr) do
            self.updated = self.updated or v.updated
            self.updatedat = math.max(self.updatedat,v.updatedat)
        end
        self:analyse()
    end
end

--[[
Resets us to a "blank" state.  Called by the touch controller at the
end of the cycle if we are "finished" but can be called by our object
at an earlier stage.
--]]

function Gesture:reset()
    for k,v in pairs(self.touches) do
        v:destroy()
    end
    self.touches = {}
    self.touchesArr = {}
    self.num = 0
    self.updated = true
    self.updatedat = ElapsedTime
    self.type = {}
end

--[[
The "updated" field is so that the object knows that new information
has come in.  So it is for the object to say "I am done with this
information, wake me again when there is new stuff" by calling this
routine.
--]]

function Gesture:noted()
    self.updated = false
    for k,v in pairs(self.touches) do
        v.updated = false
        v.utouch = nil
    end
end

--[[
This is the analyser that works out the basic information about the
gesture.  Most of the information is of the "if all touches are X, so
are we" or "if at least one touch is X, so are we" (which are
equivalent via negation).  The exception is the "pinch".
--]]

function Gesture:analyse()
    local b = vec2(0,0)
    local d = 0
    local c
    self.actives = {}
    local na = 0
    self.type.ended = true
    self.type.notlong = false
    for k,v in ipairs(self.touchesArr) do
        if v.updated or v.touch.state ~= ENDED then
            table.insert(self.actives,v)
            na = na + 1
        end
        if v.moved then
            self.type.moved = true
        end
        if v.touch.state ~= ENDED  then
            self.type.ended = false
        end
        if not v:islong() then
            self.type.notlong = true
        end
        if not v:isshort() then
            self.type.notshort = true
        end
        c = vec2(v.touch.deltaX,v.touch.deltaY)
        b = b + c
        d = d + c:lenSqr()
    end
    self.numactives = na
    if not self.type.moved then
        -- some sort of tap
        self.type.tap = true
    else
        self.type.tap = false
    end
    if self.type.ended and (ElapsedTime - self.updatedat) > .5 then
        self.type.finished = true
    end
    self.type.long = not self.type.notlong
    self.type.short = not self.type.notshort
    if self.num > 1 and not self.type.tap then
        if d * self.num < 1.5 * b:lenSqr() then
            self.type.pinch = false
        else
            self.type.pinch = true
        end
    end
end

function Gesture:transformTouches(o)
    local f
    if type(o) == "function" then
        f = o
    else
        f = function(v)
            return TransformTouch(o,v)
        end
    end
    for _,t in pairs(self.touches) do
        if t.updated then
            t.utouch = t.utouch or t.touch
            t.touch = f(t.touch)
            if t.touch.state == BEGAN then
                t.ufirsttouch = t.ufirsttouch or t.firsttouch
                t.firsttouch = f(t.firsttouch)
            end
            t.velocities[t.ntouches][1] = t.touch.x
            t.velocities[t.ntouches][2] = t.touch.y
        end
    end
end

function Gesture:getById(id)
    return self.touchHandler:getById(id)
end

--[[
This is an extension of the "touch" class, providing a single object
that corresponds to what a user would call a "touch".  It also
provides more information than is contained in a single "touch"
object.
--]]

--[[
Initialiser function.
--]]

function Touch:init(touch)
    self.id = touch.id
    self.touch = touch
    self.firsttouch = touch
    self.updated = true
    self.updatedat = ElapsedTime
    self.createdat = ElapsedTime
    self.startedat = ElapsedTime
    self.deltatime = 0
    self.laststate = 0
    self.moved = false -- did we move?
    self.long = false  -- long time before we did anything?
    self.short = false -- active lifetime was short?
    self.keepalive = false
    self.velDelta = .5 -- for computing a more realistic velocity
    self.velocities = {{touch.x,touch.y,ElapsedTime}}
    self.ntouches = 1
end

--[[
Updates new information from a "touch" object.
--]]

function Touch:update(touch)
        -- save previous state
        self.laststate = touch.state
        self.deltatime = ElapsedTime - self.updatedat
        self.updatedat = ElapsedTime
        table.insert(self.velocities,{touch.x,touch.y,ElapsedTime})
        self.ntouches = self.ntouches + 1
        -- Update the touch
        self.touch = touch
        -- Regard ourselves as "refreshed"
        self.updated = true
        if self.gesture then
            self.gesture.updated = true
            self.gesture.updatedat = ElapsedTime
        end
        if self.laststate == BEGAN then
            self.startedat = ElapsedTime
        end
        -- record whether we've moved
        if touch.state == MOVING then
            self.moved = true
        end
        -- if it was a long time since we began, we're long
        if self.laststate == BEGAN and self.deltatime > 1 then
            self.long = true
        end
        if touch.state == ENDED then
            -- If we've ended and it's less than a second since we 
            -- actually did something, we're short
            if (ElapsedTime - self.startedat) < 1 then
                self.short = true
            end
        end
        return true
end

--[[
Regard ourselves as "dealt with" until new information comes in.
--]]

function Touch:handled()
    self.updated = false
end

--[[
Do our level best to get rid of ourselves, removing ourself from the
gesture and touch controller.
--]]

function Touch:destroy()
    if self.gesture then
        self.gesture:removeTouch(self)
    end
    if self.container then
        if self.container.actives[self.touch.id] == self.id then
            self.container.actives[self.touch.id] = nil
        end
        self.container.touches[self.id] = nil
    end
end

--[[
Test to find out if we are "long"
--]]

function Touch:islong()
    if self.long then
        return self.long
    elseif self.touch.state == BEGAN and (ElapsedTime - self.createdat) > 1 then
        self.long = true
        return true
    else
        return false
    end
end

--[[
Test to find out if we are "short"
--]]

function Touch:isshort()
    if self.short then
        return self.short
    elseif (ElapsedTime - self.startedat) < 1 then
        return true
    else
        return false
    end
end

function Touch:instVelocity()
    if self.deltatime > 0 then
        return vec2(
            self.touch.deltaX/self.deltatime,
            self.touch.deltaY/self.deltatime
            )
    else
        return vec2(0,0)
    end
end

function Touch:meanVelocity()
    if self.updatedat > self.createdat then
        return vec2(
            self.touch.x - self.firsttouch.x,
            self.touch.y - self.firsttouch.y
            )/(self.updatedat - self.createdat)
    else
        return vec2(0,0)
    end
end

function Touch:velocity()
    local dt = 0
    local dx = 0
    local dy = 0
    local i
    local n = 0
    local rec = false
    local vel = self.velocities
    for k,v in ipairs(vel) do
        n = n + 1
        if v[3] > ElapsedTime - 2*self.velDelta then
            rec = true
        end
        if i and v[3] > ElapsedTime - self.velDelta then
            rec = false
        end
        if rec then
            i = k
        end
    end
    if i == 0 then
        i = 1
    end
    dt = ElapsedTime - vel[i][3]
    if dt == 0 then
        return vec2(0,0)
    end
    dx = vel[n][1] - vel[i][1]
    dy = vel[n][2] - vel[i][2]
    return vec2(dx/dt,dy/dt)
end

function Touch:draw(img)
    sprite(img,self.touch.x,self.touch.y)
end

--[[
Make a touch act a bit like a vec2 where possible
--]]

local mt = getmetatable(CurrentTouch)
mt.tovec2 = function(t)
    return vec2(t.x,t.y)
end

function Touch:tovec2()
    return self.touch:tovec2()
end

function Touch:dist(v)
    local u = self:tovec2()
    if v.tovec2 then
        v = v:tovec2()
    end
    return u:dist(v)
end

function Touch:distSqr(v)
    local u = self:tovec2()
    if v.tovec2 then
        v = v:tovec2()
    end
    return u:distSqr(v)
end

function Touch:len()
    return self:vec2():len()
end

function Touch:lenSqr()
    return self:vec2():lenSqr()
end

if _M then
    return Touches
else
    _G["Touches"] = Touches
end

