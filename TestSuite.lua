-- TestSuite code

testsuite = {}

testsuite.tests = {}
testsuite.testsdraw = {}
testsuite.test = "None"

testsuite.addTest = function (t)
    table.insert(testsuite.tests,t)
end

testsuite.addTest({
        name = "None",
        draw = function() end,
        setup = function() end
    })

testsuite.draw = function ()
    testsuite.testsdraw[testsuite.test]()
end

testsuite.initialise = function (t)
    local m = t.ui:addMenu({title = "Tests", attach = true})
    for k,v in ipairs(testsuite.tests) do
        m:addItem({
            title = v.name,
            action = function() testsuite.test = v.name v.setup() end,
            highlight = function()
                return testsuite.test == v.name
            end
        })
        testsuite.testsdraw[v.name] = v.draw
    end
end

if _M then
    cmodule.export { testsuite = testsuite }
else
    _G["testsuite"] = testsuite
end

