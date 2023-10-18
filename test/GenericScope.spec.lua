--[[
TheNexusAvenger

Tests the GenericScope class.
--]]
--!strict
--$NexusUnitTestExtensions

local GenericScope = require(game:GetService("ReplicatedStorage").NexusScopedSettings.GenericScope)

return function()
    describe("A GenericScope instance", function()
        it("should create from no serialization data.", function()
            local Scope = GenericScope.new()
            expect(Scope:Get("Setting1")).to.equal(nil)
            expect(Scope:Get("Setting2")).to.equal(nil)
            expect(Scope:Serialize()).to.deepEqual({})

            Scope:Set("Setting1", "Value1")
            expect(Scope:Get("Setting1")).to.equal("Value1")
            expect(Scope:Get("Setting2")).to.equal(nil)
            expect(Scope:Serialize()).to.deepEqual({Setting1="Value1"})

            Scope:Set("Setting1", "Value2")
            expect(Scope:Get("Setting1")).to.equal("Value2")
            expect(Scope:Get("Setting2")).to.equal(nil)
            expect(Scope:Serialize()).to.deepEqual({Setting1="Value2"})

            Scope:Set("Setting2", "Value3")
            expect(Scope:Get("Setting1")).to.equal("Value2")
            expect(Scope:Get("Setting2")).to.equal("Value3")
            expect(Scope:Serialize()).to.deepEqual({Setting1="Value2", Setting2="Value3"})
        end)

        it("should create from serialization data.", function()
            local Scope = GenericScope.new({Setting1="Value1"})
            expect(Scope:Get("Setting1")).to.equal("Value1")
            expect(Scope:Get("Setting2")).to.equal(nil)
            expect(Scope:Serialize()).to.deepEqual({Setting1="Value1"})

            Scope:Set("Setting1", "Value2")
            expect(Scope:Get("Setting1")).to.equal("Value2")
            expect(Scope:Get("Setting2")).to.equal(nil)
            expect(Scope:Serialize()).to.deepEqual({Setting1="Value2"})

            Scope:Set("Setting2", "Value3")
            expect(Scope:Get("Setting1")).to.equal("Value2")
            expect(Scope:Get("Setting2")).to.equal("Value3")
            expect(Scope:Serialize()).to.deepEqual({Setting1="Value2", Setting2="Value3"})
        end)
    end)

    describe("A GenericScope instance with a parent", function()
        it("should fetch and override parent values.", function()
            local ParentScope = GenericScope.new({Setting="Value1"})
            local Scope = GenericScope.new(nil, ParentScope)
            expect(Scope:Get("Setting")).to.equal("Value1")

            Scope:Set("Setting", "Value2")
            expect(Scope:Get("Setting")).to.equal("Value2")
            expect(ParentScope:Serialize()).to.deepEqual({Setting="Value1"})
            expect(Scope:Serialize()).to.deepEqual({Setting="Value2"})
        end)
    end)
end