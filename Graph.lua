local Graph = class()

function Graph:init()
    self.nodes = {}
    self.nodeNames = {}
    self.num = 0
end

function Graph:addNode(t)
    t = t or {}
    self.num = self.num + 1
    local name = t.name or "Node" .. self.num
    local n = {
        name = name,
        index = self.num,
        edges = {}
    }
    table.insert(self.nodes,n)
    self.nodeNames[name] = self.num
    if t.edges then
        for k,v in ipairs(t.edges) do
            self:addEdge(n,v)
        end
    end
    return n
end

function Graph:addEdge(a,b)
    a = self:getNode(a)
    b = self:getNode(b)
    if not a or not b then
        return
    end
    table.insert(a.edges,b)
end

function Graph:getNode(a)
    if type(a) == "number" then
        a = self.nodes[a]
    elseif type(a) == "string" then
        a = self.nodes[self.nodeNames[a]]
    end
    return a
end

local visit,visitAll

function visit(n,f)
    if n.mark then
        return true
    end
    if n.tmark then
        return false
    end
    n.tmark = true
    for k,v in ipairs(n.edges) do
        if not visit(v,f) then
            return false
        end
    end
    n.tmark = false
    n.mark = true
    f(n)
    return true
end

function visitAll(n,f)
    if n.mark then
        return true
    end
    n.mark = true
    for k,v in ipairs(n.edges) do
        visitAll(v,f)
    end
    f(n)
    return true
end

function Graph:depthSearch(f)
    self:clearMarks()
    local dag = true
    for k,v in ipairs(self.nodes) do
        if not visit(v,f) then
            dag = false
            break
        end
    end
    return dag
end

function Graph:isAcyclic()
    return self:depthSearch(function() end)
end

function Graph:clearMarks()
    for k,v in ipairs(self.nodes) do
        v.mark = false
        v.tmark = false
    end
end

function Graph:sort()
    local rs = {}
    if self:depthSearch(function(n) table.insert(rs,n) end) then
        local s = {}
        for k=1,self.num do
            s[k] = rs[self.num-k+1]
        end
        return s
    else
        return false
    end
end

function Graph:decompose()
    local components = {}
    for k,v in ipairs(self.nodes) do
        self:clearMarks()
        components[k] = {}
        f = function(n) table.insert(components[k],n) end
        visitAll(v,f)
    end
    for k,v in ipairs(components) do
        table.sort(v,function(a,b) if a.index < b.index then return true else return false end end)
    end
    table.sort(components, function(a,b) if a[1].index < b[1].index then return true else return false end end)
    local rm = {}
    for k=2,#components do
        if components[k][1].index == components[k-1][1].index then
            table.insert(rm,1,k)
        end
    end
    for k,v in ipairs(rm) do
        table.remove(components,v)
    end
    return components
end

if _M then
    return Graph
else
    _G["Graph"] = Graph
end
