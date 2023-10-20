--[[
TheNexusAvenger

Tests the UnserializedScope class.
--]]
--!strict

local UnserializedScope = require(game:GetService("ReplicatedStorage").NexusScopedSettings.Scope.UnserializedScope)

return function()
    describe("An UnserializedScope instance", function()
        it("should create from no serialization data.", function()
            local Scope = UnserializedScope.new()
            expect(Scope:Get("Setting1")).to.equal(nil)
            expect(Scope:Get("Setting2")).to.equal(nil)
            expect(Scope:Serialize()).to.equal(nil)

            Scope:Set("Setting1", "Value1")
            expect(Scope:Get("Setting1")).to.equal("Value1")
            expect(Scope:Get("Setting2")).to.equal(nil)
            expect(Scope:Serialize()).to.equal(nil)

            Scope:Set("Setting1", "Value2")
            expect(Scope:Get("Setting1")).to.equal("Value2")
            expect(Scope:Get("Setting2")).to.equal(nil)
            expect(Scope:Serialize()).to.equal(nil)

            Scope:Set("Setting2", "Value3")
            expect(Scope:Get("Setting1")).to.equal("Value2")
            expect(Scope:Get("Setting2")).to.equal("Value3")
            expect(Scope:Serialize()).to.equal(nil)
        end)

        it("should create from serialization data.", function()
            local Scope = UnserializedScope.new({Setting1="Value1"})
            expect(Scope:Get("Setting1")).to.equal("Value1")
            expect(Scope:Get("Setting2")).to.equal(nil)
            expect(Scope:Serialize()).to.equal(nil)

            Scope:Set("Setting1", "Value2")
            expect(Scope:Get("Setting1")).to.equal("Value2")
            expect(Scope:Get("Setting2")).to.equal(nil)
            expect(Scope:Serialize()).to.equal(nil)

            Scope:Set("Setting2", "Value3")
            expect(Scope:Get("Setting1")).to.equal("Value2")
            expect(Scope:Get("Setting2")).to.equal("Value3")
            expect(Scope:Serialize()).to.equal(nil)
        end)
    end)
end