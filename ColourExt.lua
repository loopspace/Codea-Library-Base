-- Colour manipulation
-- Author: Andrew Stacey
-- Website: http://www.math.ntnu.no/~stacey/HowDidIDoThat/iPad/Codea.html
-- Licence: CC0 (http://wiki.creativecommons.org/CC0)

--[[
This provides some functions for basic colour manipulation such as
colour blending.  This version works by extending the color userdata object.
--]]

local mt = getmetatable(color())
if not mt.__is_extended then
    mt.__is_extended = true
    -- Should we modify the alpha of our colours?
    mt.ModifyAlpha = false
    
    local __hsl,__hsv,__svg,__x11,__clone,__byName,__random
    __svg = {}
    __x11 = {}
    
    mt.new = function(c,...)
        local args = {...}
        local n = select("#",...)
        if n == 0 then
            return c
        end
        if type (args[1]) == "string" then
            local model = table.remove(args,1)
            if model == "hsl" then
                c = __hsl(unpack(args))
            elseif model == "hsv" then
                c = __hsv(unpack(args))
            elseif model == "svg" then
                c = __byName(__svg,args[1])
            elseif model == "x11" then
                c = __byName(__x11,args[1])
            elseif model == "random" then
                c = __random()
            elseif model == "transparent" then
                c = color(0,0,0,0)
            else
                c = __byName(__svg,model) or __byName(__x11,model) or c
            end
        elseif type(args[1]) == "number" then
            c = color(unpack(args))
        elseif type(args[1] == "userdata") then
            __clone(c,args[1])
        end
        return c
    end
    
    __clone = function(c,r,g,b,a)
        if type(r) == "userdata" then
            r,g,b,a = r.r,r.g,r.b,r.a
        end
        c.r = r
        c.g = g
        c.b = b
        c.a = a
        return c
    end
    
    __hsl = function (h,s,l,a)
        h = (h-math.floor(h))*6
        s = s or 1
        l = l or 1
        a = a or 255
        local c = (1-2*math.abs(2*l-1))*s*255
        local m = l*255 - c/2
        local x = c*(1 - math.abs(h%2 - 1))
        local r,g,b
        if h < 1 then
            r,g,b = c+m,x+m,m
        elseif h < 2 then
            r,g,b = x+m,c+m,m
        elseif h < 3 then
            r,g,b = m,c+m,x+m
        elseif h < 4 then
            r,g,b = m,x+m,c+m
        elseif h < 5 then
            r,g,b = x+m,m,c+m
        else
            r,g,b = c+m,m,x+m
        end
        return color(r,g,b,a)
    end
    
    mt["tohsl"] = function(c)
        local r,g,b,a = c.r,c.g,c.b,c.a
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
    
    mt["tohsv"] = function(c)
        local r,g,b,a = c.r,c.g,c.b,c.a
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
    
    __hsv = function (h,s,v,a)
        h = (h-math.floor(h))*6
        s = s or 1
        v = v or 1
        a = a or 255
        local m = (v - s*v)*255
        local c = s*v*255
        local x = c*(1 - math.abs(h%2 - 1))
        local r,g,b
        if h < 1 then
            r,g,b = c+m,x+m,m
        elseif h < 2 then
            r,g,b = x+m,c+m,m
        elseif h < 3 then
            r,g,b = m,c+m,x+m
        elseif h < 4 then
            r,g,b = m,x+m,c+m
        elseif h < 5 then
            r,g,b = x+m,m,c+m
        else
            r,g,b = c+m,m,x+m
        end
        return color(r,g,b,a)
    end
    
    --[[
    This blends the two specified colours according to the parameter given
    as the middle argument (the syntax is based on that of the "xcolor"
    LaTeX package) which is the percentage of the first colour.
    --]]
    
    mt["xblend"] = function (cc,t,c,m)
        local s,r,g,b,a
        m = m or mt.ModifyAlpha
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
    
    mt["tint"] = function(c,t,m)
        local s,r,g,b,a
        m = m or mt.ModifyAlpha
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
    
    mt["shade"] = function(c,t,m)
        local s,r,g,b,a
        m = m or mt.ModifyAlpha
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
    
    mt["tone"] = function(c,t,m)
        local s,r,g,b,a
        m = m or mt.ModifyAlpha
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
    
    mt["complement"] = function(c,m)
        local r,g,b,a
        m = m or mt.ModifyAlpha
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
    
    mt["posterise"] = function(c,t,m)
        local r,g,b,a
        m = m or mt.ModifyAlpha
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
    
    mt["opacity"] = function(c,t)
        return color(c.r,c.g,c.b,t*c.a/100)
    end
    
    mt["opaque"] = function(c)
        return color(c.r,c.g,c.b,255)
    end
    
    --[[
    This "pretty prints" the colour, converting it to a string.
    --]]
    
    mt["tostring"] = function(c)
        return "R:" .. c.r .. " G:" .. c.g .. " B:" .. c.b .. " A:" .. c.a
    end
    
    mt.__tostring = mt.tostring
    
    mt["fromstring"] = function(cl,c)
        local r,g,b,a
        r = string.match(c,"R:(%d+)")
        g = string.match(c,"G:(%d+)")
        b = string.match(c,"B:(%d+)")
        a = string.match(c,"A:(%d+)")
        cl.r,cl.g,cl.b,cl.a = r,g,b,a
    end
    
    mt["readData"] = function(cl,t,k,c)
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
            return cl:fromstring(col)
        else
            return c:clone(cl)
        end
    end
    
    mt["saveData"] = function(cl,t,k)
        local f
        if t == "global" then
            f = saveGlobalData
        elseif t == "project" then
            f = saveProjectData
        else
            f = saveLocalData
        end
        f(k,cl:tostring())
    end
    
    --[[
    This searches for a colour by name from a specified list (such as
    "svg" or "x11").  It looks for a match for the given string at the
    start of the name of the colour, without regard for case.
    --]]
    
    __byName = function(t,n)
        if t[n] then
            return t[n]
        end
        n = string.lower(n)
        n = string.gsub(n,"%s","")
        if n == "random" then
            return __random(t)
        end
        local ln,k,v,s,lk
        ln = "^" .. n
        for k,v in pairs(t) do
            lk = string.lower(k)
            s = string.find(lk,ln)
            if s then
                return v
            end
        end
        return false
    end
    
    --[[
    Get a random colour, either from a list or random.
    But not black.
    --]]
    
    local __colourlists
    
    function __random(s)
        if s then
            if __colourlists[s] then
                return __colourlists[s][math.random(#__colourlists[s])]
            else
                __colourlists[s] = {}
                for k,v in pairs(s) do
                    if k ~= "Black" then
                        table.insert(__colourlists[s],v)
                    end
                end
                return __colourlists[s][math.random(#__colourlists[s])]
            end
        end
        return __hsv(math.random())
    end
    
--[[
This file defines two arrays of colours one according to the SVG
definitions and one according to the x11 definitions.  The precise
numbers were taken from the definitions in the "xcolor" LaTeX package.

The xcolor package can be found at http://www.ctan.org/pkg/xcolor
--]]

__svg = {}
__svg.AliceBlue = color(239,247,255,255)
__svg.AntiqueWhite = color(249,234,215,255)
__svg.Aqua = color(0,255,255,255)
__svg.Aquamarine = color(126,255,211,255)
__svg.Azure = color(239,255,255,255)
__svg.Beige = color(244,244,220,255)
__svg.Bisque = color(255,227,196,255)
__svg.Black = color(0,0,0,255)
__svg.BlanchedAlmond = color(255,234,205,255)
__svg.Blue = color(0,0,255,255)
__svg.BlueViolet = color(137,43,226,255)
__svg.Brown = color(165,42,42,255)
__svg.BurlyWood = color(221,183,135,255)
__svg.CadetBlue = color(94,158,160,255)
__svg.Chartreuse = color(126,255,0,255)
__svg.Chocolate = color(210,104,29,255)
__svg.Coral = color(255,126,79,255)
__svg.CornflowerBlue = color(99,149,237,255)
__svg.Cornsilk = color(255,247,220,255)
__svg.Crimson = color(220,20,59,255)
__svg.Cyan = color(0,255,255,255)
__svg.DarkBlue = color(0,0,138,255)
__svg.DarkCyan = color(0,138,138,255)
__svg.DarkGoldenrod = color(183,133,11,255)
__svg.DarkGray = color(169,169,169,255)
__svg.DarkGreen = color(0,99,0,255)
__svg.DarkGrey = color(169,169,169,255)
__svg.DarkKhaki = color(188,182,107,255)
__svg.DarkMagenta = color(138,0,138,255)
__svg.DarkOliveGreen = color(84,107,47,255)
__svg.DarkOrange = color(255,140,0,255)
__svg.DarkOrchid = color(183,49,204,255)
__svg.DarkRed = color(138,0,0,255)
__svg.DarkSalmon = color(232,150,122,255)
__svg.DarkSeaGreen = color(142,187,142,255)
__svg.DarkSlateBlue = color(72,61,138,255)
__svg.DarkSlateGray = color(47,79,79,255)
__svg.DarkSlateGrey = color(47,79,79,255)
__svg.DarkTurquoise = color(0,206,209,255)
__svg.DarkViolet = color(147,0,211,255)
__svg.DeepPink = color(255,20,146,255)
__svg.DeepSkyBlue = color(0,191,255,255)
__svg.DimGray = color(104,104,104,255)
__svg.DimGrey = color(104,104,104,255)
__svg.DodgerBlue = color(29,144,255,255)
__svg.FireBrick = color(177,33,33,255)
__svg.FloralWhite = color(255,249,239,255)
__svg.ForestGreen = color(33,138,33,255)
__svg.Fuchsia = color(255,0,255,255)
__svg.Gainsboro = color(220,220,220,255)
__svg.GhostWhite = color(247,247,255,255)
__svg.Gold = color(255,215,0,255)
__svg.Goldenrod = color(218,165,31,255)
__svg.Gray = color(127,127,127,255)
__svg.Green = color(0,127,0,255)
__svg.GreenYellow = color(173,255,47,255)
__svg.Grey = color(127,127,127,255)
__svg.Honeydew = color(239,255,239,255)
__svg.HotPink = color(255,104,179,255)
__svg.IndianRed = color(205,91,91,255)
__svg.Indigo = color(74,0,130,255)
__svg.Ivory = color(255,255,239,255)
__svg.Khaki = color(239,229,140,255)
__svg.Lavender = color(229,229,249,255)
__svg.LavenderBlush = color(255,239,244,255)
__svg.LawnGreen = color(124,252,0,255)
__svg.LemonChiffon = color(255,249,205,255)
__svg.LightBlue = color(173,216,229,255)
__svg.LightCoral = color(239,127,127,255)
__svg.LightCyan = color(224,255,255,255)
__svg.LightGoldenrod = color(237,221,130,255)
__svg.LightGoldenrodYellow = color(249,249,210,255)
__svg.LightGray = color(211,211,211,255)
__svg.LightGreen = color(144,237,144,255)
__svg.LightGrey = color(211,211,211,255)
__svg.LightPink = color(255,181,192,255)
__svg.LightSalmon = color(255,160,122,255)
__svg.LightSeaGreen = color(31,177,170,255)
__svg.LightSkyBlue = color(135,206,249,255)
__svg.LightSlateBlue = color(132,112,255,255)
__svg.LightSlateGray = color(119,135,153,255)
__svg.LightSlateGrey = color(119,135,153,255)
__svg.LightSteelBlue = color(175,196,221,255)
__svg.LightYellow = color(255,255,224,255)
__svg.Lime = color(0,255,0,255)
__svg.LimeGreen = color(49,205,49,255)
__svg.Linen = color(249,239,229,255)
__svg.Magenta = color(255,0,255,255)
__svg.Maroon = color(127,0,0,255)
__svg.MediumAquamarine = color(102,205,170,255)
__svg.MediumBlue = color(0,0,205,255)
__svg.MediumOrchid = color(186,84,211,255)
__svg.MediumPurple = color(146,112,219,255)
__svg.MediumSeaGreen = color(59,178,113,255)
__svg.MediumSlateBlue = color(123,104,237,255)
__svg.MediumSpringGreen = color(0,249,154,255)
__svg.MediumTurquoise = color(72,209,204,255)
__svg.MediumVioletRed = color(198,21,132,255)
__svg.MidnightBlue = color(24,24,112,255)
__svg.MintCream = color(244,255,249,255)
__svg.MistyRose = color(255,227,225,255)
__svg.Moccasin = color(255,227,181,255)
__svg.NavajoWhite = color(255,221,173,255)
__svg.Navy = color(0,0,127,255)
__svg.NavyBlue = color(0,0,127,255)
__svg.OldLace = color(252,244,229,255)
__svg.Olive = color(127,127,0,255)
__svg.OliveDrab = color(107,141,34,255)
__svg.Orange = color(255,165,0,255)
__svg.OrangeRed = color(255,68,0,255)
__svg.Orchid = color(218,112,214,255)
__svg.PaleGoldenrod = color(237,232,170,255)
__svg.PaleGreen = color(151,251,151,255)
__svg.PaleTurquoise = color(175,237,237,255)
__svg.PaleVioletRed = color(219,112,146,255)
__svg.PapayaWhip = color(255,238,212,255)
__svg.PeachPuff = color(255,218,184,255)
__svg.Peru = color(205,132,63,255)
__svg.Pink = color(255,191,202,255)
__svg.Plum = color(221,160,221,255)
__svg.PowderBlue = color(175,224,229,255)
__svg.Purple = color(127,0,127,255)
__svg.Red = color(255,0,0,255)
__svg.RosyBrown = color(187,142,142,255)
__svg.RoyalBlue = color(65,104,225,255)
__svg.SaddleBrown = color(138,68,19,255)
__svg.Salmon = color(249,127,114,255)
__svg.SandyBrown = color(243,164,95,255)
__svg.SeaGreen = color(45,138,86,255)
__svg.Seashell = color(255,244,237,255)
__svg.Sienna = color(160,81,44,255)
__svg.Silver = color(191,191,191,255)
__svg.SkyBlue = color(135,206,234,255)
__svg.SlateBlue = color(105,89,205,255)
__svg.SlateGray = color(112,127,144,255)
__svg.SlateGrey = color(112,127,144,255)
__svg.Snow = color(255,249,249,255)
__svg.SpringGreen = color(0,255,126,255)
__svg.SteelBlue = color(70,130,179,255)
__svg.Tan = color(210,179,140,255)
__svg.Teal = color(0,127,127,255)
__svg.Thistle = color(216,191,216,255)
__svg.Tomato = color(255,99,71,255)
__svg.Turquoise = color(63,224,207,255)
__svg.Violet = color(237,130,237,255)
__svg.VioletRed = color(208,31,144,255)
__svg.Wheat = color(244,221,178,255)
__svg.White = color(255,255,255,255)
__svg.WhiteSmoke = color(244,244,244,255)
__svg.Yellow = color(255,255,0,255)
__svg.YellowGreen = color(154,205,49,255)

__x11 = {}
__x11.AntiqueWhite1 = color(255,238,219,255)
__x11.AntiqueWhite2 = color(237,223,204,255)
__x11.AntiqueWhite3 = color(205,191,175,255)
__x11.AntiqueWhite4 = color(138,130,119,255)
__x11.Aquamarine1 = color(126,255,211,255)
__x11.Aquamarine2 = color(118,237,197,255)
__x11.Aquamarine3 = color(102,205,170,255)
__x11.Aquamarine4 = color(68,138,116,255)
__x11.Azure1 = color(239,255,255,255)
__x11.Azure2 = color(224,237,237,255)
__x11.Azure3 = color(192,205,205,255)
__x11.Azure4 = color(130,138,138,255)
__x11.Bisque1 = color(255,227,196,255)
__x11.Bisque2 = color(237,212,182,255)
__x11.Bisque3 = color(205,182,158,255)
__x11.Bisque4 = color(138,124,107,255)
__x11.Blue1 = color(0,0,255,255)
__x11.Blue2 = color(0,0,237,255)
__x11.Blue3 = color(0,0,205,255)
__x11.Blue4 = color(0,0,138,255)
__x11.Brown1 = color(255,63,63,255)
__x11.Brown2 = color(237,58,58,255)
__x11.Brown3 = color(205,51,51,255)
__x11.Brown4 = color(138,34,34,255)
__x11.Burlywood1 = color(255,211,155,255)
__x11.Burlywood2 = color(237,196,145,255)
__x11.Burlywood3 = color(205,170,124,255)
__x11.Burlywood4 = color(138,114,84,255)
__x11.CadetBlue1 = color(151,244,255,255)
__x11.CadetBlue2 = color(141,228,237,255)
__x11.CadetBlue3 = color(122,196,205,255)
__x11.CadetBlue4 = color(82,133,138,255)
__x11.Chartreuse1 = color(126,255,0,255)
__x11.Chartreuse2 = color(118,237,0,255)
__x11.Chartreuse3 = color(102,205,0,255)
__x11.Chartreuse4 = color(68,138,0,255)
__x11.Chocolate1 = color(255,126,35,255)
__x11.Chocolate2 = color(237,118,33,255)
__x11.Chocolate3 = color(205,102,28,255)
__x11.Chocolate4 = color(138,68,19,255)
__x11.Coral1 = color(255,114,85,255)
__x11.Coral2 = color(237,105,79,255)
__x11.Coral3 = color(205,90,68,255)
__x11.Coral4 = color(138,62,47,255)
__x11.Cornsilk1 = color(255,247,220,255)
__x11.Cornsilk2 = color(237,232,205,255)
__x11.Cornsilk3 = color(205,200,176,255)
__x11.Cornsilk4 = color(138,135,119,255)
__x11.Cyan1 = color(0,255,255,255)
__x11.Cyan2 = color(0,237,237,255)
__x11.Cyan3 = color(0,205,205,255)
__x11.Cyan4 = color(0,138,138,255)
__x11.DarkGoldenrod1 = color(255,184,15,255)
__x11.DarkGoldenrod2 = color(237,173,14,255)
__x11.DarkGoldenrod3 = color(205,149,12,255)
__x11.DarkGoldenrod4 = color(138,100,7,255)
__x11.DarkOliveGreen1 = color(201,255,112,255)
__x11.DarkOliveGreen2 = color(187,237,104,255)
__x11.DarkOliveGreen3 = color(161,205,89,255)
__x11.DarkOliveGreen4 = color(109,138,61,255)
__x11.DarkOrange1 = color(255,126,0,255)
__x11.DarkOrange2 = color(237,118,0,255)
__x11.DarkOrange3 = color(205,102,0,255)
__x11.DarkOrange4 = color(138,68,0,255)
__x11.DarkOrchid1 = color(191,62,255,255)
__x11.DarkOrchid2 = color(177,58,237,255)
__x11.DarkOrchid3 = color(154,49,205,255)
__x11.DarkOrchid4 = color(104,33,138,255)
__x11.DarkSeaGreen1 = color(192,255,192,255)
__x11.DarkSeaGreen2 = color(179,237,179,255)
__x11.DarkSeaGreen3 = color(155,205,155,255)
__x11.DarkSeaGreen4 = color(104,138,104,255)
__x11.DarkSlateGray1 = color(150,255,255,255)
__x11.DarkSlateGray2 = color(140,237,237,255)
__x11.DarkSlateGray3 = color(121,205,205,255)
__x11.DarkSlateGray4 = color(81,138,138,255)
__x11.DeepPink1 = color(255,20,146,255)
__x11.DeepPink2 = color(237,17,136,255)
__x11.DeepPink3 = color(205,16,118,255)
__x11.DeepPink4 = color(138,10,79,255)
__x11.DeepSkyBlue1 = color(0,191,255,255)
__x11.DeepSkyBlue2 = color(0,177,237,255)
__x11.DeepSkyBlue3 = color(0,154,205,255)
__x11.DeepSkyBlue4 = color(0,104,138,255)
__x11.DodgerBlue1 = color(29,144,255,255)
__x11.DodgerBlue2 = color(28,133,237,255)
__x11.DodgerBlue3 = color(23,116,205,255)
__x11.DodgerBlue4 = color(16,77,138,255)
__x11.Firebrick1 = color(255,48,48,255)
__x11.Firebrick2 = color(237,43,43,255)
__x11.Firebrick3 = color(205,38,38,255)
__x11.Firebrick4 = color(138,25,25,255)
__x11.Gold1 = color(255,215,0,255)
__x11.Gold2 = color(237,201,0,255)
__x11.Gold3 = color(205,173,0,255)
__x11.Gold4 = color(138,117,0,255)
__x11.Goldenrod1 = color(255,192,36,255)
__x11.Goldenrod2 = color(237,179,33,255)
__x11.Goldenrod3 = color(205,155,28,255)
__x11.Goldenrod4 = color(138,104,20,255)
__x11.Green1 = color(0,255,0,255)
__x11.Green2 = color(0,237,0,255)
__x11.Green3 = color(0,205,0,255)
__x11.Green4 = color(0,138,0,255)
__x11.Honeydew1 = color(239,255,239,255)
__x11.Honeydew2 = color(224,237,224,255)
__x11.Honeydew3 = color(192,205,192,255)
__x11.Honeydew4 = color(130,138,130,255)
__x11.HotPink1 = color(255,109,179,255)
__x11.HotPink2 = color(237,105,167,255)
__x11.HotPink3 = color(205,95,144,255)
__x11.HotPink4 = color(138,58,98,255)
__x11.IndianRed1 = color(255,105,105,255)
__x11.IndianRed2 = color(237,99,99,255)
__x11.IndianRed3 = color(205,84,84,255)
__x11.IndianRed4 = color(138,58,58,255)
__x11.Ivory1 = color(255,255,239,255)
__x11.Ivory2 = color(237,237,224,255)
__x11.Ivory3 = color(205,205,192,255)
__x11.Ivory4 = color(138,138,130,255)
__x11.Khaki1 = color(255,246,142,255)
__x11.Khaki2 = color(237,229,132,255)
__x11.Khaki3 = color(205,197,114,255)
__x11.Khaki4 = color(138,133,77,255)
__x11.LavenderBlush1 = color(255,239,244,255)
__x11.LavenderBlush2 = color(237,224,228,255)
__x11.LavenderBlush3 = color(205,192,196,255)
__x11.LavenderBlush4 = color(138,130,133,255)
__x11.LemonChiffon1 = color(255,249,205,255)
__x11.LemonChiffon2 = color(237,232,191,255)
__x11.LemonChiffon3 = color(205,201,165,255)
__x11.LemonChiffon4 = color(138,136,112,255)
__x11.LightBlue1 = color(191,238,255,255)
__x11.LightBlue2 = color(177,223,237,255)
__x11.LightBlue3 = color(154,191,205,255)
__x11.LightBlue4 = color(104,130,138,255)
__x11.LightCyan1 = color(224,255,255,255)
__x11.LightCyan2 = color(209,237,237,255)
__x11.LightCyan3 = color(179,205,205,255)
__x11.LightCyan4 = color(122,138,138,255)
__x11.LightGoldenrod1 = color(255,235,138,255)
__x11.LightGoldenrod2 = color(237,220,130,255)
__x11.LightGoldenrod3 = color(205,189,112,255)
__x11.LightGoldenrod4 = color(138,128,75,255)
__x11.LightPink1 = color(255,174,184,255)
__x11.LightPink2 = color(237,161,173,255)
__x11.LightPink3 = color(205,140,149,255)
__x11.LightPink4 = color(138,94,100,255)
__x11.LightSalmon1 = color(255,160,122,255)
__x11.LightSalmon2 = color(237,149,114,255)
__x11.LightSalmon3 = color(205,128,98,255)
__x11.LightSalmon4 = color(138,86,66,255)
__x11.LightSkyBlue1 = color(175,226,255,255)
__x11.LightSkyBlue2 = color(164,211,237,255)
__x11.LightSkyBlue3 = color(140,181,205,255)
__x11.LightSkyBlue4 = color(95,123,138,255)
__x11.LightSteelBlue1 = color(201,225,255,255)
__x11.LightSteelBlue2 = color(187,210,237,255)
__x11.LightSteelBlue3 = color(161,181,205,255)
__x11.LightSteelBlue4 = color(109,123,138,255)
__x11.LightYellow1 = color(255,255,224,255)
__x11.LightYellow2 = color(237,237,209,255)
__x11.LightYellow3 = color(205,205,179,255)
__x11.LightYellow4 = color(138,138,122,255)
__x11.Magenta1 = color(255,0,255,255)
__x11.Magenta2 = color(237,0,237,255)
__x11.Magenta3 = color(205,0,205,255)
__x11.Magenta4 = color(138,0,138,255)
__x11.Maroon1 = color(255,52,178,255)
__x11.Maroon2 = color(237,48,167,255)
__x11.Maroon3 = color(205,40,144,255)
__x11.Maroon4 = color(138,28,98,255)
__x11.MediumOrchid1 = color(224,102,255,255)
__x11.MediumOrchid2 = color(209,94,237,255)
__x11.MediumOrchid3 = color(179,81,205,255)
__x11.MediumOrchid4 = color(122,54,138,255)
__x11.MediumPurple1 = color(170,130,255,255)
__x11.MediumPurple2 = color(159,121,237,255)
__x11.MediumPurple3 = color(136,104,205,255)
__x11.MediumPurple4 = color(93,71,138,255)
__x11.MistyRose1 = color(255,227,225,255)
__x11.MistyRose2 = color(237,212,210,255)
__x11.MistyRose3 = color(205,182,181,255)
__x11.MistyRose4 = color(138,124,123,255)
__x11.NavajoWhite1 = color(255,221,173,255)
__x11.NavajoWhite2 = color(237,206,160,255)
__x11.NavajoWhite3 = color(205,178,138,255)
__x11.NavajoWhite4 = color(138,121,94,255)
__x11.OliveDrab1 = color(191,255,62,255)
__x11.OliveDrab2 = color(178,237,58,255)
__x11.OliveDrab3 = color(154,205,49,255)
__x11.OliveDrab4 = color(104,138,33,255)
__x11.Orange1 = color(255,165,0,255)
__x11.Orange2 = color(237,154,0,255)
__x11.Orange3 = color(205,132,0,255)
__x11.Orange4 = color(138,89,0,255)
__x11.OrangeRed1 = color(255,68,0,255)
__x11.OrangeRed2 = color(237,63,0,255)
__x11.OrangeRed3 = color(205,54,0,255)
__x11.OrangeRed4 = color(138,36,0,255)
__x11.Orchid1 = color(255,130,249,255)
__x11.Orchid2 = color(237,122,232,255)
__x11.Orchid3 = color(205,104,201,255)
__x11.Orchid4 = color(138,71,136,255)
__x11.PaleGreen1 = color(154,255,154,255)
__x11.PaleGreen2 = color(144,237,144,255)
__x11.PaleGreen3 = color(124,205,124,255)
__x11.PaleGreen4 = color(84,138,84,255)
__x11.PaleTurquoise1 = color(186,255,255,255)
__x11.PaleTurquoise2 = color(174,237,237,255)
__x11.PaleTurquoise3 = color(150,205,205,255)
__x11.PaleTurquoise4 = color(102,138,138,255)
__x11.PaleVioletRed1 = color(255,130,170,255)
__x11.PaleVioletRed2 = color(237,121,159,255)
__x11.PaleVioletRed3 = color(205,104,136,255)
__x11.PaleVioletRed4 = color(138,71,93,255)
__x11.PeachPuff1 = color(255,218,184,255)
__x11.PeachPuff2 = color(237,202,173,255)
__x11.PeachPuff3 = color(205,175,149,255)
__x11.PeachPuff4 = color(138,119,100,255)
__x11.Pink1 = color(255,181,196,255)
__x11.Pink2 = color(237,169,183,255)
__x11.Pink3 = color(205,145,158,255)
__x11.Pink4 = color(138,99,108,255)
__x11.Plum1 = color(255,186,255,255)
__x11.Plum2 = color(237,174,237,255)
__x11.Plum3 = color(205,150,205,255)
__x11.Plum4 = color(138,102,138,255)
__x11.Purple1 = color(155,48,255,255)
__x11.Purple2 = color(145,43,237,255)
__x11.Purple3 = color(124,38,205,255)
__x11.Purple4 = color(84,25,138,255)
__x11.Red1 = color(255,0,0,255)
__x11.Red2 = color(237,0,0,255)
__x11.Red3 = color(205,0,0,255)
__x11.Red4 = color(138,0,0,255)
__x11.RosyBrown1 = color(255,192,192,255)
__x11.RosyBrown2 = color(237,179,179,255)
__x11.RosyBrown3 = color(205,155,155,255)
__x11.RosyBrown4 = color(138,104,104,255)
__x11.RoyalBlue1 = color(72,118,255,255)
__x11.RoyalBlue2 = color(67,109,237,255)
__x11.RoyalBlue3 = color(58,94,205,255)
__x11.RoyalBlue4 = color(38,63,138,255)
__x11.Salmon1 = color(255,140,104,255)
__x11.Salmon2 = color(237,130,98,255)
__x11.Salmon3 = color(205,112,84,255)
__x11.Salmon4 = color(138,75,57,255)
__x11.SeaGreen1 = color(84,255,159,255)
__x11.SeaGreen2 = color(77,237,147,255)
__x11.SeaGreen3 = color(67,205,127,255)
__x11.SeaGreen4 = color(45,138,86,255)
__x11.Seashell1 = color(255,244,237,255)
__x11.Seashell2 = color(237,228,221,255)
__x11.Seashell3 = color(205,196,191,255)
__x11.Seashell4 = color(138,133,130,255)
__x11.Sienna1 = color(255,130,71,255)
__x11.Sienna2 = color(237,121,66,255)
__x11.Sienna3 = color(205,104,57,255)
__x11.Sienna4 = color(138,71,38,255)
__x11.SkyBlue1 = color(135,206,255,255)
__x11.SkyBlue2 = color(125,191,237,255)
__x11.SkyBlue3 = color(108,165,205,255)
__x11.SkyBlue4 = color(73,112,138,255)
__x11.SlateBlue1 = color(130,110,255,255)
__x11.SlateBlue2 = color(122,103,237,255)
__x11.SlateBlue3 = color(104,89,205,255)
__x11.SlateBlue4 = color(71,59,138,255)
__x11.SlateGray1 = color(197,226,255,255)
__x11.SlateGray2 = color(184,211,237,255)
__x11.SlateGray3 = color(159,181,205,255)
__x11.SlateGray4 = color(108,123,138,255)
__x11.Snow1 = color(255,249,249,255)
__x11.Snow2 = color(237,232,232,255)
__x11.Snow3 = color(205,201,201,255)
__x11.Snow4 = color(138,136,136,255)
__x11.SpringGreen1 = color(0,255,126,255)
__x11.SpringGreen2 = color(0,237,118,255)
__x11.SpringGreen3 = color(0,205,102,255)
__x11.SpringGreen4 = color(0,138,68,255)
__x11.SteelBlue1 = color(99,183,255,255)
__x11.SteelBlue2 = color(91,172,237,255)
__x11.SteelBlue3 = color(79,147,205,255)
__x11.SteelBlue4 = color(53,99,138,255)
__x11.Tan1 = color(255,165,79,255)
__x11.Tan2 = color(237,154,73,255)
__x11.Tan3 = color(205,132,63,255)
__x11.Tan4 = color(138,89,43,255)
__x11.Thistle1 = color(255,225,255,255)
__x11.Thistle2 = color(237,210,237,255)
__x11.Thistle3 = color(205,181,205,255)
__x11.Thistle4 = color(138,123,138,255)
__x11.Tomato1 = color(255,99,71,255)
__x11.Tomato2 = color(237,91,66,255)
__x11.Tomato3 = color(205,79,57,255)
__x11.Tomato4 = color(138,53,38,255)
__x11.Turquoise1 = color(0,244,255,255)
__x11.Turquoise2 = color(0,228,237,255)
__x11.Turquoise3 = color(0,196,205,255)
__x11.Turquoise4 = color(0,133,138,255)
__x11.VioletRed1 = color(255,62,150,255)
__x11.VioletRed2 = color(237,58,140,255)
__x11.VioletRed3 = color(205,49,119,255)
__x11.VioletRed4 = color(138,33,81,255)
__x11.Wheat1 = color(255,230,186,255)
__x11.Wheat2 = color(237,216,174,255)
__x11.Wheat3 = color(205,186,150,255)
__x11.Wheat4 = color(138,125,102,255)
__x11.Yellow1 = color(255,255,0,255)
__x11.Yellow2 = color(237,237,0,255)
__x11.Yellow3 = color(205,205,0,255)
__x11.Yellow4 = color(138,138,0,255)
__x11.Gray0 = color(189,189,189,255)
__x11.Green0 = color(0,255,0,255)
__x11.Grey0 = color(189,189,189,255)
__x11.Maroon0 = color(175,48,95,255)
__x11.Purple0 = color(160,31,239,255)


    
end


