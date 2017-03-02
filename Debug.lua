-- Debug

local Debug = class()

if _M then
    Colour = cimport "Colour"
    Font,_,Textarea = unpack(cimport "Font",nil)
    cimport "Menu"
    cimport "ColourNames"
end

function Debug:init(t)
    t = t or {}
    -- you can accept and set parameters here
    self.textarea = Textarea({
        font = Font({name = "Courier", size = 32}),
        width = WIDTH,
        height = HEIGHT,
        colour = Colour.opacity(Colour.svg.Black,25),
        textColour = Colour.opacity(Colour.svg.White,25),
        --pos = Screen["centre"],
        title = "Debug",
        --anchor = "centre"
    })
    self.messages = {}
    self.fps = {}
    self.fpsn = 100
    for i=1,self.fpsn do
       self.fps[i] = 60
    end
    self.fpsi = 1
    self:log({
        name = "IFPS",
        message = function() return math.floor(1/DeltaTime*10)/10 end
        })
    self:log({
        name = "AFPS",
        message = function()
        self.fps[self.fpsi] = 1/DeltaTime
        local tfps = 0
        for i=1,self.fpsn do
            tfps = tfps + self.fps[i]
        end
        self.fpsi = self.fpsi%self.fpsn + 1
        return math.floor(tfps/self.fpsn*10)/10 end
    })
    if t.ui then
        local m = t.ui:addMenu({
            title = "Debug",
            attach = true,
            atEnd = true
        })
        m:addItem({
            title = "Debugging",
            action = function()
                if self.active then
                    self:deactivate()
                else
                    self:activate()
                end
                return true
                end,
            highlight = function() return self.active end
        })
    end
end

function Debug:draw()
    if self.active then
        pushStyle()
        pushMatrix()
        resetStyle()
        resetMatrix()
        self.textarea:setLines(self:processMessages())
        self.textarea:draw()
        popMatrix()
        popStyle()
    end
end

function Debug:log(t)
    local m = {}
    m.name = t.name or t[1] or "Log"
    m.message = t.message or t[2] or os.date()
    table.insert(self.messages,m)
end

function Debug:processMessages()
    local t = {}
    for k,v in ipairs(self.messages) do
        if type(v.message) == "function" then
            table.insert(t, v.name .. ": " .. v.message())
        else
            table.insert(t, v.name .. ": " .. v.message)
        end
    end
    if displayMode() == FULLSCREEN then
        table.insert(t," ")
    end
    return unpack(t)
end

function Debug:activate()
    self.active = true
    self.textarea:activate()
end

function Debug:deactivate()
    self.active = false
    self.textarea:deactivate()
end

function Debug:orientationChanged(o)
    self.textarea:setSize({width = WIDTH, height = HEIGHT})
end

function Debug:hide()
    self.pstate = self.active
    if self.active then
        self:deactivate()
    end
end

function Debug:unhide()
    if self.pstate then
        self:activate()
    end
   end

if _M then
    return Debug
else
    _G["Debug"] = Debug
end


