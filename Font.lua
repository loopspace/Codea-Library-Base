-- Bitmap font class
-- Author: Andrew Stacey
-- Website: http://www.math.ntnu.no/~stacey/HowDidIDoThat/iPad/Codea.html
-- Licence: CC0 http://wiki.creativecommons.org/CC0

--[[
The "Font", "Sentence", "Char", and "Textarea" classes are all
designed to aid getting text onto the screen.  Their purposes are as
follows:

"Font": This contains a list of characters which make up a "font".
The methods are to do with rendering these characters on the screen in
a reasonable way (ensuring that characters line up correctly, for
example).

"Sentence": This class holds a single line of text to be drawn in a
given font.  Its purpose is that it be used when a string is to be
rendered several time (for example, over the course of many draw
iterations) as it saves various pieces of information needed to render
it to the screen to avoid computing them every time.

"Char": This class contains the information about a single character.
The initial information is based on the BDF font format; the first
time a Char object is drawn then this is converted to a sprite which
is then used on subsequent occasions.  In particular, sprites are only
created for those characters that are actually used.

"Textarea": This is a box containing lines which can be added to to
present messages to the user.  It handles line wrapping and scrolling,
and can be moved or hidden (except for the title).

Strings passed to the objects defined using these classes are assumed
to be in utf8 format (using the "utf8" functionality from the
corresponding file).  However, to get the full use of this one should
use a font supporting all the necessary characters.
--]]

local UTF8 = UTF8
local Colour = Colour
if _M then
    UTF8 = cimport "utf8"
    Colour = cimport "Colour"
    cimport "RoundedRectangle"
    cimport "Lengths"
    cimport "Coordinates"
    cimport "ColourNames"
end

local Font = class()
local BitmapFont = class()
local InternalFont = class()

--[[
The "Fonts" table contains functions that define the fonts used (we
use functions so that fonts are only processed if they are actually
used).
--]]

local Fonts = {}

--[[
A "Font" is just a list of characters.
--]]

function Font:init(t)
    local mf
    if t then
        mf = InternalFont(t)
    else
        mf = BitmapFont()
    end
    for k,v in pairs(mf) do
        self[k] = v
    end
    local mt = getmetatable(mf)
    setmetatable(self,mt)
end

function BitmapFont:init()
    self.char = {}
end

function InternalFont:init(t)
    self.name = t.name
    self.size = t.size
    self.tint = t.tint
    pushStyle()
    font(t.name)
    fontSize(t.size)
    local fm = fontMetrics()
    local w,h = textSize("x")
    self.bbx = {w,h}
    self.descent = fm.descent
    popStyle()
end

function BitmapFont:clone()
    return self
end

function InternalFont:clone(t)
    t = t or {}
    t.name = t.name or self.name
    t.size = t.size or self.size
    t.tint = t.tint or self.tint
    return Font(t)
end

--[[
This returns the line height (bounding box height) of the font.
--]]

function BitmapFont:lineheight()
    return self.bbx[2]
end

function InternalFont:lineheight()
    return self.bbx[2]
end

--[[
This returns the default character width (individual characters may
override this).
--]]

function BitmapFont:charWidth(c)
    if c then
        c = tostring(c)
        c = UTF8(c):firstchar()
        if self.char[c] then
            return self.char[c].dwidth[1]
        end
    end
    return self.bbx[1]
end

function InternalFont:charWidth(c)
    if c then
        pushStyle()
        self:setstyle()
        local w,_ = textSize(c)
        popStyle()
        return w
    else
        return self.bbx[1]
    end
end

--[[
This sets the colour for the font.
--]]

function BitmapFont:setColour(c)
    self.tint = c
end

function InternalFont:setColour(c)
    self.tint = c
end

--[[
Builtin and rendered fonts have different methods of setting colours
--]]

function BitmapFont:colour(c)
    c = c or self.tint
    tint(c)
end

function InternalFont:colour(c)
    c = c or self.tint
    fill(c)
end

--[[
and of how to put a character on the screen
--]]

function BitmapFont:render_char(c,x,y)
    sprite(c,x,y)
end

function InternalFont:render_char(c,x,y)
    text(c,x,y)
end

--[[
and of what styles should apply
--]]

function BitmapFont:setstyle()
    resetStyle()
    noSmooth()
    spriteMode(CORNER)
end

function InternalFont:setstyle()
    resetStyle()
    textMode(CORNER)
    font(self.name)
    fontSize(self.size)
end

function BitmapFont:exh()
    return self.char[109].bbx[2]
end

function InternalFont:exh()
    pushStyle()
    self:setstyle()
    local fm = fontMetrics()
    popStyle()
    return fm.xHeight
end

--[[
This is the basic method for writing a string to the screen.  Its
inputs are a string (assumed to be utf8), the xy coordinates to start
at (being the start of the "writing line"), and the colour to use
(this is optional).

It parses the string, drawing each character in turn.  The "draw_char"
function returns the xy coordinate at which to position the next
characters.
--]]

function BitmapFont:write(s,x,y,col)
    x = math.floor(x + .5)
    y = math.floor(y + .5)
    s = tostring(s)
    local u = UTF8(s)
    pushStyle()
    self:setstyle()
    if col then
        tint(col)
    elseif self.tint then
        tint(self.tint)
    end
    for c in u:chars() do
        x,y = self:draw_char(c,x,y)
    end
    popStyle()
    return x,y
end

function InternalFont:write(s,x,y,col)
    x = math.floor(x + .5)
    y = math.floor(y + .5)
    s = tostring(s)
    pushStyle()
    self:setstyle()
    if col then
        fill(col)
    elseif self.tint then
        fill(self.tint)
    end
    local w,_ = textSize(s)
    text(s,x,y - self.descent)
    popStyle()
    return x + w,y
end

--[[
This is the same as the "write" method except that we assume that the
input is a list of (decimal) numbers specifying characters via the
utf8 encoding.  The input can either be a single number or a table.
--]]

function BitmapFont:write_utf8(s,x,y,col)
    x = math.floor(x + .5)
    y = math.floor(y + .5)
    pushStyle()
    self:setstyle()
    if col then
        tint(col)
    elseif self.tint then
        tint(self.tint)
    end
    if type(s) == "table" then
        for k,c in ipairs(s) do
            x,y = self:draw_char(c,x,y)
        end
    else
        x,y = self:draw_char(s,x,y)
    end
    popStyle()
    return x,y
end

function InternalFont:write_utf8(s,x,y,col)
    x = math.floor(x + .5)
    y = math.floor(y + .5)
    if type(s) == "table" then
        s = s:tostring()
    else
        s = utf8dec(s)
    end
    pushStyle()
    self:setstyle()
    if col then
        fill(col)
    elseif self.tint then
        fill(self.tint)
    end
    local w,_ = textSize(s)
    text(s,x,y - self.descent)
    popStyle()
    return x + w,y
end

--[[
Quick versions of the above: don't set the style
--]]

function BitmapFont:quick_write(s,x,y)
    s = tostring(s)
    local u = UTF8(s)
    for c in u:chars() do
        x,y = self:draw_char(c,x,y)
    end
    return x,y
end

function InternalFont:quick_write(s,x,y)
    local w,_ = textSize(s)
    text(s,x,y - self.descent)
    return x + w,y
end

--[[
This is the same as the "write" method except that we assume that the
input is a list of (decimal) numbers specifying characters via the
utf8 encoding.  The input can either be a single number or a table.
--]]

function BitmapFont:quick_write_utf8(s,x,y)
    if type(s) == "table" then
        for k,c in ipairs(s) do
            x,y = self:draw_char(c,x,y)
        end
    else
        x,y = self:draw_char(s,x,y)
    end
    return x,y
end

function InternalFont:quick_write_utf8(s,x,y)
    if type(s) == "table" then
        s = s:tostring()
    else
        s = utf8dec(s)
    end
    local w,_ = textSize(s)
    text(s,x,y - self.descent)
    return x + w,y
end

--[[
This function calls the "draw" function of a character at the
specified xy coordinate and works out the place to put the next
character from the bounding box of the current one.
--]]

function BitmapFont:draw_char(c,x,y)
    x = math.floor(x + .5)
    y = math.floor(y + .5)
    c = tonumber(c)
    if self.char[c] then
        local ch,cx,cy
        ch = self.char[c]
        cx = x + ch.bbx[3]
        cy = y + ch.bbx[4]
        ch:draw(cx,cy)
        x = x + ch.dwidth[1]
        y = y + ch.dwidth[2]
    end
    return x,y
end

function InternalFont:draw_char(c,x,y)
    x = math.floor(x + .5)
    y = math.floor(y + .5)
    c = tonumber(c)
    c = string.char(c)
    return self:write(c,x,y)
end

--[[
There are various places in the drawing method where information is
saved for use next time round.  This does all the processing involved
without actually drawing the characters.  It is useful for getting the
width of a string before rendering it to the screen.
--]]

function BitmapFont:prepare_char(c,x,y)
    x = math.floor(x + .5)
    y = math.floor(y + .5)
    c = tonumber(c)
    if self.char[c] then
        local ch,cx,cy,nx,ny
        ch = self.char[c]
        cx = ch.bbx[3]
        cy = ch.bbx[4]
        ch:prepare()
        nx = ch.dwidth[1]
        ny = ch.dwidth[2]
        return {ch.image,x,y,cx,cy,nx,ny},x + nx,y + ny
    else
        return {},x,y
    end
end

function InternalFont:prepare_char(c,x,y)
    x = math.floor(x + .5)
    y = math.floor(y + .5)
    pushStyle()
    self:setstyle()
    c = utf8dec(c)
    local w,h = textSize(c)
    popStyle()
    return {c,x,y,0,- self.descent,w,0},x+w,y
end

--[[
A sentence is a string to be written to the screen in a specified
font.  The purpose of this class is to ensure that repeated
calculations are only carried out once and then their values saved.
--]]

local Sentence = class()

--[[
A sentence consists of a UTF8 object, a font, the characters making
up the string (drawn from the font) and some information about how
much space the sentence takes up on the screen.
--]]

function Sentence:init(f,s,t)
    self.font = f
    self.chars = {}
    self.width = 0
    self.lastx = 0
    self.lasty = 0
    if type(s) == "string" then
        self.utf8 = UTF8(s)
    elseif type(s) == "table" and s.is_a and s:is_a(UTF8) then
        self.utf8 = s:clone()
    elseif type(s) == "table" and s.is_a and s:is_a(Sentence) then
        self.utf8 = s.utf8:clone()
        if t then
            local fn = {}
            fn.name = s.font.name
            fn.size = s.font.size
            for _,v in pairs(t) do
                fn[v] = f[v]
            end
            self.font = Font(fn)
            self.prepared = false
        else
            self.font = s.font

            if s.prepared then
                self.length = s.length
                local c
                for k=1,s.length do
                    c = s.chars[k]
                    table.insert(self.chars,
                        {c[1],c[2],c[3],c[4],c[5],c[6],c[7]})
                end
            end
            self.prepared = s.prepared
            self.width = s.width
            self.lastx = s.lastx
            self.lasty = s.lasty
        end
        self.colour = s.colour
    elseif type(s) == "number" then
        self.utf8 = UTF8(tostring(s))
    else
        self.utf8 = UTF8("")
    end
end

--[[
This sets our string.  As this is probably new, we will need to parse
it afresh so we unset the "prepared" flag.
--]]

function Sentence:setString(s)
    if type(s) == "string" then
        self.utf8 = UTF8(s)
    elseif type(s) == "table" and s:is_a(UTF8) then
        self.utf8 = s
    elseif type(s) == "number" then
        self.utf8 = UTF8(tostring(s))
    else
        self.utf8 = UTF8("")
    end
    self.prepared = false
    self.chars = {}
    self.width = 0
    self.lastx = 0
    self.lasty = 0
    self.length = 0
end

--[[
This returns our current string.
--]]

function Sentence:getString()
    return self.utf8:tostring()
end

--[[
This returns our current string as a UTF8 object.
--]]

function Sentence:getUTF8()
    return self.utf8
end

function Sentence:toupper()
    self.utf8:toupper()
    self.prepared = false
end

--[[
This appends the given string to our stored string.  If we have
already processed our stored string we process the new string as well
(thus ensuring that we only process the new information).
--]]

function Sentence:appendString(u)
    if type(u) == "string" then
        u = UTF8(u)
    end
    self.utf8:append(u)
    if self.prepared then
        local t,x,y,n
        n = self.length
        x = self.lastx
        y = self.lasty
        for c in u:chars() do
            t,x,y = self.font:prepare_char(c,x,y)
            if t[1] then
                table.insert(self.chars,t)
                n = n + 1
            end
        end
        self.width = x
        self.lastx = x
        self.lasty = y
        self.length = n
    end
end

--[[
This is the same as "appendString" except that it prepends the string.
--]]

function Sentence:prependString(u)
    if type(u) == "string" then
        u = UTF8(u)
    end
    self.utf8:prepend(u)
    if self.prepared then
        local t,x,y,l
        x = 0
        y = 0
        l = 0
        for c in u:chars() do
            t,x,y = self.font:prepare_char(c,x,y)
            if t[1] then
                table.insert(self.chars,t,1)
                l = l + 1
            end
        end
        self.length = self.length + l
        for k = l+1,self.length do
            self.chars[2] = self.chars[2] + x
            self.chars[3] = self.chars[3] + y
        end
        self.width = self.width + x
        self.lastx = self.lastx + x
        self.lasty = self.lasty + y
    end
end

--[[
In this case, the argument is another instance of the Sentence class
and the new one is appended to the current one.
--]]

function Sentence:append(s)
    if self.prepared and s.prepared then
        for k,v in ipairs(s.chars) do
            v[2] = v[2] + self.lastx
            v[3] = v[3] + self.lasty
            table.insert(self.chars,v)
        end
        self.utf8:append(s.utf8)
        self.width = self.width + s.width
        self.lastx = self.lastx + s.lastx
        self.lasty = self.lasty + s.lasty
        self.length = self.length + s.length
        return
    elseif self.prepared then
        self:appendString(s.utf8)
        return
    else
        self.utf8:append(s.utf8)
    end
end

--[[
Same as "append" except with prepending.
--]]

function Sentence:prepend(s)
    if self.prepared and s.prepared then
        for k,v in ipairs(self.chars) do
            v[2] = v[2] + s.lastx
            v[3] = v[3] + s.lasty
        end
        for k,v in ipairs(s.chars) do
            table.insert(self.chars,k,v)
        end
        self.utf8:prepend(s.utf8)
        self.width = self.width + s.width
        self.lastx = self.lastx + s.lastx
        self.lasty = self.lasty + s.lasty
        self.length = self.length + s.length
        return
    elseif self.prepared then
        self:prependString(s.utf8)
        return
    else
        self.utf8:prepend(s.utf8)
    end
end

--[[
The "push", "unshift", "pop", and "shift" functions are for removing
and inserting characters at the start and end of the Sentence.  The
input for "push" and "unshift" is precisely that returned by "pop" and
"shift".  If you need to know the exact make-up of this input then you
are probably using the wrong function and should use something like
"append" or "appendString" instead.  The idea is that if one Sentence
has worked out the information required for a particular character
then there is no need for the other Sentence to work it out for
itself, so all of that information is passed with the character.
--]]

function Sentence:push(t)
    if self.prepared then
        if t[2] then
            t[2][2] = t[2][2] + self.lastx
            t[2][3] = t[2][3] + self.lasty
            table.insert(self.chars,t[2])
            self.width = self.width + t[2][6]
            self.lastx = self.lastx + t[2][6]
            self.lasty = self.lasty + t[2][7]
            self.length = self.length + 1
        end
    end
    if t[1] then
        self.utf8:append(t[1])
    end
end

function Sentence:unshift(t)
    if self.prepared then
        if t[2] then
            if self.chars[1] then
                t[2][2] = self.chars[1][2] - t[2][6]
                t[2][3] = self.chars[1][3] - t[2][7]
            end
            table.insert(self.chars,1,t[2])
            self.width = self.width + t[2][6]
            self.lastx = self.lastx + t[2][6]
            self.lasty = self.lasty + t[2][7]
            self.length = self.length + 1
        end
    end
    if t[1] then
        self.utf8:prepend(t[1])
    end
end

--[[
This sets our colour.
--]]

function Sentence:setColour(c)
    self.colour = c
end

--[[
This sets our anchor
--]]

function Sentence:setAnchor(a)
    self.anchor = a
end

--[[
This prepares the Sentence for rendering, stepping along the sentence
and working out what characters will be required and their relative
positions.
--]]

function Sentence:prepare()
    if not self.prepared then
        local t,x,y,n
        n = 0
        x = 0
        y = 0
        self.chars = {}
        for c in self.utf8:chars() do
            t,x,y = self.font:prepare_char(c,x,y)
            if t[1] then
                table.insert(self.chars,t)
                n = n + 1
            end
        end
        self.prepared = true
        self.width = x
        self.lastx = x
        self.lasty = y
        self.length = n
    end
end

--[[
This is the function that actually draws the Sentence (or rather,
which calls the "draw" function of each of the characters).  The
Sentence is meant to be anchored at (0,0) (so that when actually drawn
it is anchored at the given xy coordinate) but this might not be the
case due to some "shift" and "unshift" operations.  To avoid
recalculating the offset each time, we allow for it here and measure
the relative offset of the first character, adjusting all other
characters accordingly.
--]]

function Sentence:draw(x,y,c,A)
    local lx,ly
    lx = 0
    ly = 0
    c = c or self.colour
    pushStyle()
    self.font:setstyle()
    if c then
        self.font:setColour(c)
    end
    self:prepare()
    if self.anchor then
        x,y =TextAnchorAt(
            x,y,
            self.width,
            self.font:lineheight(),
            self.anchor,
            self.font:exh()/2,
            A
            )
    end
    if self.chars[1] then
        lx = self.chars[1][2]
        ly = self.chars[1][3]
        if lx ~= 0 or ly ~= 0 then
            for k,v in ipairs(self.chars) do
                v[2] = v[2] - lx
                v[3] = v[3] - ly
            end
        end
    end
    pushMatrix()
    translate(x,y)
    if A then
        rotate(A)
    end
    self.font:write_utf8(self.utf8,0,0)
    popMatrix()
    --[[
    for k,v in ipairs(self.chars) do
        v[2] = v[2] - lx
        v[3] = v[3] - ly
        self.font:render_char(v[1],v[2] + v[4] + x,v[3] + v[5] + y)
    end
    --]]
    popStyle()
    return self.lastx + x, self.lasty + y
end

--[[
This resets us to a "blank slate".
--]]

function Sentence:clear()
    self.utf8 = UTF8("")
    self.chars = {}
    self.width = 0
    self.lastx = 0
    self.lasty = 0
    self.length = 0
end

--[[
See the comments before the "push" and "unshift" functions.
--]]

function Sentence:pop()
    local a,b
    a = table.remove(self.chars)
    if a then
        self.width = self.width - a[6]
        self.lastx = self.lastx - a[6]
        self.lasty = self.lasty - a[7]
        b = self.utf8:sub(-1,-1)
        self.utf8 = self.utf8:sub(1,-2)
        self.length = self.length - 1
    else
        self.width = 0
        self.lastx = 0
        self.lasty = 0
        self.length = 0
        self.utf8 = UTF8("")
    end
    return {b,a}
end

function Sentence:shift()
    local a
    a = table.remove(self.chars,1)
    if a then
        self.width = self.width - a[6]
        self.lastx = self.lastx - a[6]
        self.lasty = self.lasty - a[7]
        b = self.utf8:sub(1,1)
        self.utf8 = self.utf8:sub(2,-1)
        self.length = self.length - 1
    else
        self.width = 0
        self.lastx = 0
        self.lasty = 0
        self.length = 0
        self.utf8 = UTF8("")
    end
    return {b,a}
end

function Sentence:splitBy(w)
    self:prepare()
    local i = 1
    local l = self.length
    return function()
        if i > l then
            return nil
        end
        local p,q,j,ex,br,ps
        ex = self.chars[i][2] + w
        for k=i,l do
            if self.utf8:char(k) == 10 then
                p = k - 1
                q = k + 1
                br = true
                break
            end
            if self.chars[k][2] > ex then
                br = true
                if q then
                    break
                end
            end
            if self.utf8:char(k) == 32 then
                q = k + 1
                p = ps or i + 1
                if k == l then
                    p = p + 1
                end
                if br then
                    break
                end
            else
                ps = k
            end

        end
        if not br or not q then
            q = l + 1
            p = l
        end
        j = i
        i = q
        return self:sub(j,p)
    end
end

function Sentence:sub(i,j)
    self:prepare()
    local l = self.length
    i = i or 1
    j = j or l
    if i < 0 then
        i = i + l + 1
    end
    if j < 0 then
        j = j + l + 1
    end
    if i == 0 then
        i = 1
    end
    local s = Sentence(self.font)
    if i <= j then
        s.length = j - i + 1
        s.utf8 = self.utf8:sub(i,j)
        local t = self.chars[i]
        local x,y = t[2],t[3]
        local c
        for k=i,j do
            t = self.chars[k]
            if t then
            table.insert(s.chars,
                {t[1],t[2]-x,t[3]-y,t[4],t[5],t[6],t[7]})
            end
        end
        if t then
        s.prepared = true
        s.width = t[2] - x + t[6]
        s.lastx = t[2] - x + t[6]
        s.lasty = t[3] - y + t[7]
        end
        s.colour = self.colour
    end
    return s
end

--[[
A "Textarea" is a list of lines which are drawn on the screen in a box
with an optional title.  The lines are scrolled so that, by default,
the last lines are displayed.  The lines are wrapped to the width of
the area.  The Textarea reacts to touches in the following way.  It
can be moved by dragging the title, so long as the title stays on the
screen; a single tap moves it so that it is wholly on the screen; a
double tap either hides or shows the actual text (other than the
title); a moving touch in the main text area scrolls the text in the
opposite direction (this may change - I am not sure how intuitive this
is as yet).
--]]

local Textarea = class()

--[[
Line breaks can be hard or soft.
--]]

local HARDLINE = 1
local SOFTLINE = 2

--[[
Our initial information is a table defining a font, an xy coordinate,
our width and height in characters, an anchor, and a title.

The anchor is used to interpret the xy coordinate as a position on the
boundary of the area so that it can be positioned without needing to
compute beforehand its actual height and width (particularly as these
will depend on the font).

The width and height can be specified in terms of pixels or characters.
No units means characters (and lines).  "pt", "px", "pcx" mean pixels
(the idea being to add support for physical dimensions).
We can also specify maximum values so that the box can adjust to fit
its contents.
--]]

function Textarea:init(t)
    self.font = t.font
    self.colour = t.colour or Colour.svg.DarkSlateBlue
    self.textColour = t.textColour or Colour.svg.White
    self.opos = t.pos or function() return 0,0 end
    self.anchor = t.anchor
    self.angle = t.angle
    self.fade = t.fadeTime or 0
    self.sep = 10
    self.active = false
    self.lh = self.font:lineheight()
    self.lines = {}
    self.numlines = 0
    self.offset = 0
    self.txtwidth = 0
    self.vfill = t.vfill
    self.valign = t.valign
    self.fit = t.fit
    if t.title then
        self.title = Sentence(self.font,t.title)
        self.title:prepare()
        self.title:setColour(self.textColour)
    end
    self:setSize({
        width = t.width, 
        height = t.height,
        maxWidth = t.maxWidth or t.width,
        maxHeight = t.maxHeight or t.height,
        })
end

function Textarea:orientationChanged()
    self:resetAnchor()
end

function Textarea:resetAnchor()
    local x,y = self.opos()
    if self.anchor then
        self.x, self.y = RectAnchorAt(
            x,y,self.width,self.height,self.anchor,self.angle)
    else
        self.x = x
        self.y = y
    end
end

function Textarea:setSize(t)
    local w,h,mw,mh = t.width,t.height,
        t.maxWidth or WIDTH,t.maxHeight or HEIGHT
    pushStyle()
    self.font:setstyle()
    w = evalLength(w)
    h = evalLength(h)
    mw = evalLength(mw)
    mh = evalLength(mh)
    w = math.max(0,w)
    h = math.max(0,h)
    mw = math.max(0,mw)
    mh = math.max(0,mh)
    popStyle()
    if w > mw then
        w = mw
    end
    local adj = true
    if h < self.lh + self.sep then
        adj = false
        h = self.lh + self.sep
    end
    if self.title then
        h = h + self.lh
        self.twidth = self.title.width + 2*self.sep
    else
        self.twidth = 0
    end
    if adj and h > mh then
        h = mh
    end
    self.totlines = math.floor((h - self.sep)/self.lh)
    if self.title then
        self.totlines = self.totlines - 1
    end
    self.totlines = math.max(1,self.totlines)
    self.height = h
    self.width = w
    self.mheight = mh
    self.mwidth = mw
    self:reflow()
    self:resetAnchor()
end

--[[
This is our "draw" method which puts our information on the screen
assuming that we are "active".  Exactly what is drawn depends on
whether or not we have a title and whether or not the main area has
been "hidden" so that only the title shows.  If all is shown then we
figure out which lines to show and print only those.  This depends on
the total number of lines, the number of lines that we can show, and
the "offset", which is usually specified by a touch.
--]]

function Textarea:draw()
    if not self.active then
        return
    end
    local col, tcol
    if self.deactivationTime then
        local dt = ElapsedTime - self.deactivationTime
        if dt > self.fade then
            self.active = false
            return
        else
            --[[
            local t = (1-dt/self.fade)*200
            if t > 100 then
                t = t - 100
                col = Colour.shade(self.colour,t)
                tcol = Colour.shade(self.textColour,t)
            else
                col = Colour.opacity(Colour.svg.Black,t)
                tcol = Colour.transparent
            end
            --]]
            local t = (1-dt/self.fade)*100
            col = Colour.opacity(self.colour,t)
            tcol = Colour.opacity(self.textColour,t)
        end
    end
    if self.activationTime then
        local dt = ElapsedTime - self.activationTime
        if dt > self.fade then
            self.activationTime = nil
        else
            --[[
            local t = (dt/self.fade)*200
            if t > 100 then
                t = t - 100
                col = Colour.shade(self.colour,t)
                tcol = Colour.shade(self.textColour,t)
            else
                col = Colour.opacity(Colour.svg.Black,t)
                tcol = Colour.transparent
            end
            --]]
            local t = (dt/self.fade)*100
            col = Colour.opacity(self.colour,t)
            tcol = Colour.opacity(self.textColour,t)
        end
    end
    col = col or self.colour
    tcol = tcol or self.textColour
    pushStyle()
    local m,n,y,lh,x,v,A,sv
    lh = self.lh
    A = self.angle or 0
    A = math.rad(A)
    v = vec2(self.sep,self.sep):rotate(A) 
    x = self.x + v.x
    y = self.y + v.y
    v = vec2(0,lh):rotate(A)
    sv = vec2(1,0):rotate(A)
    n = self.numlines - self.offset
    if n < 0 then
        n = self.totlines
    end
    m = n - self.totlines + 1
    if m < 1 then
        if self.vfill and not self.fit then
            y = y - (m - 1) * v.y
            x = x - (m - 1) * v.x
        elseif self.valign and not self.fit then
            if self.valign == "top" then
                y = y - (m - 1) * v.y
                x = x - (m - 1) * v.x
            elseif self.valign == "middle" then
                y = y - (m - 2) * v.y/2
                x = x - (m - 2) * v.x/2
            end
        end
        m = 1
    end
    
    fill(col)
    if self.onlyTitle then
        if self.title then
        RoundedRectangle(self.x,
        self.y + self.height - self.lh - self.sep,
        self.twidth,
        self.lh + self.sep,
        self.sep,
        0,
        self.angle)
        else
            self.active = false
        end
    else
        RoundedRectangle(
            self.x,self.y,self.width,self.height,
            self.sep,0,self.angle)
        for k = n,m,-1 do
        if self.lines[k] then
            self.lines[k][1]:draw(x,y,tcol,self.angle)
            if self.lines[k][2] then
                y = y + v.y
                x = x + v.x
            else
                y = y + sv.y*self.lines[k][1].width
                x = x + sv.x*self.lines[k][1].width
            end
        end
        end
    end
    if self.title then
        v = vec2(0,self.height - self.lh):rotate(A)
        x,y = self.x + v.x,self.y + v.y
        self.title:draw(x,y,tcol,self.angle)
    end
end

--[[
This adds a line or lines to the stack.  The lines are wrapped (using
code based on contributions to the lua-users wiki) to the Textarea
width with breaks inserted at spaces (if possible).
--]]

function Textarea:addLine(...)
    local arg = {...}
    local w,u,sw
    w = self.mwidth - 2*self.sep
    if self.numlines > 0 then
        sw = self.width - 2*self.sep
    else
        sw = 0
    end
    for k,v in ipairs(arg) do
        u = Sentence(self.font,v)
        u:setColour(self.textColour)
        u:prepare()
        for s in u:splitBy(w) do
            sw = math.max(sw,s.width)
            table.insert(self.lines,{s,SOFTLINE})
            self.numlines = self.numlines + 1
        end
        if u.utf8:lastchar() == 32 then
            self.lines[self.numlines][2] = HARDLINE
        end
    end
    if self.fit then
        self.width = sw + 2*self.sep
        local h = math.min(self.mheight,
                self.numlines * self.lh + self.sep)
        local adj = true
        if h < self.lh + self.sep then
            adj = false
            h = self.lh + self.sep
        end
        if self.title then
            h = h + self.lh
        end
        if adj and h > self.mheight then
            h = self.mheight
        end
        self.totlines = math.floor((h - self.sep)/self.lh)
        if self.title then
            self.totlines = self.totlines - 1
        end
        self.totlines = math.max(1,self.totlines)
        self.height = h
        self:resetAnchor()
    end
end

function Textarea:setLines(...)
    self.lines = {}
    self.numlines = 0
    self:addLine(...)
end

function Textarea:clear()
    self.lines = {}
    self.numlines = 0
end

function Textarea:addChar(c)
    local s
    if self.numlines > 0 then
        s = self.lines[self.numlines][1]:getUTF8()
        s:append(UTF8(c))
        self.lines[self.numlines] = nil
        self.numlines = self.numlines - 1
    else
        s = UTF8(c)
    end
    self:addLine(s)
end

function Textarea:delChar()
    if self.numlines > 0 then
    local a = self.lines[self.numlines][1]:pop()
    if not a[2] then
        self.lines[self.numlines] = nil
        self.numlines = self.numlines - 1
    end
    end
end

function Textarea:reflow()
    if self.numlines > 0 then
    local s,l
    s = UTF8()
    for i=1,self.numlines do
        l = self.lines[i][1]:getUTF8()
        if self.lines[i][2] == SOFTLINE then
            l:chomp()
            l:append(UTF8(" "))
        elseif self.lines[i][2] == HARDLINE then
            l:chomp()
            l:append(UTF8("\n"))
        end
        s:append(l)
    end
    self:setLines(s)
    end
end

--[[
This figures out if the touch was inside our "bounding box" and claims
it if it was.
--]]

function Textarea:isTouchedBy(t)
    if not self.active or self.touchdisabled then
        return false
    end
    t = vec2(t.x,t.y) - vec2(self.x,self.y)
    if self.angle then
        t = t:rotate(-math.rad(self.angle))
    end
    if t.x < 0 then
        return false
    end
    if t.x > self.width then
        return false
    end
    if self.onlyTitle then
        if t.y < self.height - self.lh - self.sep then
            return false
        end
    else
    if t.y < 0 then
        return false
    end
    end
    if t.y > self.height then
        return false
    end
    return true
end

function Textarea:disableTouches()
    self.touchdisabled = true
end

--[[
This is our touch processor that figures out what action to take
according to the touch information available.  The currently
understood gestures are:

Single tap: move so that the whole area is visible.

Double tap: toggle display of the main area (title is always shown).

Move on title: moves the text area around the screen, ensuring that
the title is always visible.

Move on main: scrolls the text.
--]]

function Textarea:processTouches(g)
    local t = g.touchesArr[1]
    local ty = t.touch.y
    local y = self.y
    local h = self.height
    local lh = self.lh
    if t.touch.state == BEGAN and self.title then
        if ty > y + h - lh then
            g.type.onTitle = true
        end
    end
    if g.type.tap then
        if g.type.finished then
        if g.num == 1 then
            self:makeVisible()
        elseif g.num == 2 then
            if self.onlyTitle then
                self.onlyTitle = false
                self.width = self.txtwidth
            else
                if self.title then
                    self.onlyTitle = true
                    self.txtwidth = self.width
                    self.width = self.twidth
                else
                    self:deactivate()
                end
            end
        end
        end
    elseif g.updated then
                if g.type.onTitle then
                    local y = t.touch.deltaY
                    local x = t.touch.deltaX
                    self:ensureTitleVisible(x,y)
                else
                    local tfy = t.firsttouch.y
                    local o = math.floor((ty - tfy)/lh)
                    self.offset = math.max(0,math.min(self.totlines,o))
                end
                
    end
    g:noted()
    if g.type.finished then
        g:reset()
        self.offset = 0
    end
end

--[[
This function adjusts the xy coordinate to ensure that the whole
Textarea is visible.
--]]

function Textarea:makeVisible()
    local x = self.x
    local y = self.y
    local w = self.width
    local h = self.height
    x = math.max(0,math.min(WIDTH - w,x))
    y = math.max(0,math.min(HEIGHT - h,y))
    self.x = x
    self.y = y
end

--[[
This function adjusts the xy coordinate to ensure that the title
of the Textarea is visible.
--]]

function Textarea:ensureTitleVisible(x,y)
    local w = self.width
    local h = self.height
    local lh = self.lh + self.sep
    x = x + self.x
    y = y + self.y
    x = math.max(0,math.min(WIDTH - w,x))
    y = math.max(lh - h,math.min(HEIGHT - h,y))
    self.x = x
    self.y = y
end

--[[
Our activation and deactivation routines
--]]

function Textarea:activate()
    self.active = true
    self.deactivationTime = nil
    self.activationTime = ElapsedTime
end

function Textarea:deactivate()
    self.activationTime = nil
    self.deactivationTime = ElapsedTime
end

function Textarea:setColour(c)
    self.colour = c
end

function Textarea:setTextColour(c)
    self.textColour = c
    for i=1,self.numlines do
        self.lines[i]:setColour(c)
    end
end

function Textarea:setFont(f,c)
    if c then
        self.textColour = c
    end
    self.font = f
    self:reflow()
end

Textarea.help = "Text areas are used to display text.  If a text area has a title then it can be moved by dragging the title.  Double-tapping the box hides the body (if it has a title, that is left showing and can be double-tapped to bring the body of the text back again).  Dragging inside the box scrolls the text (most of the time)."

--[[
This is a character in a font.  The information is to be initially
constructed from a BDF font file.  At present, this information is
specified by accessing the actual attributes.  Later versions may be
able to read this information directly from the font file; at present,
the conversion is carried out by a Perl scrip.

Characters are rendered as sprites so the first time that a character
is drawn (or otherwise processed) then it converts the raw information
into a sprite which is then used on subsequent calls.
--]]

local Char = class()

function Char:init()
    self.bitmap = {}
    self.bbx = {}
    self.dwidth = {}
end

--[[
This is a wrapper around the preparation function for the character so
that we only call that once.
--]]

function Char:prepare()
    if not self.prepared then
        self:mkImage()
    end
    self.prepared = true
end

--[[
This is the function that renders the BDF information to a sprite.
--]]

function Char:mkImage()
    self.image = image(self.font.bbx[1], self.font.bbx[2])
    local i,j,b
    j = self.bbx[2]
    for k,v in pairs(self.bitmap) do
        i = 1
        b = Hex2Bin(v)
        for l in string.gmatch(b, ".") do
            
            if l == "1" then
                self.image:set(i,j,255,255,255)
            end
            i = i + 1
        end
        j = j - 1
    end
end

--[[
This draws the character at the specified coordinate.
--]]

function Char:draw(x,y)
    self:prepare()
    sprite(self.image,x,y)
end

if _M then
    return {Font, Sentence, Textarea, Char}
else
    _G["Font"] = Font
    _G["Sentence"] = Sentence
    _G["Textarea"] = Textarea
    _G["Char"] = Char
end


--]==]
