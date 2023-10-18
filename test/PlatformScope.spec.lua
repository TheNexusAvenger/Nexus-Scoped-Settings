--[[
TheNexusAvenger

Tests the PlatformScope class.
--]]
--!strict
--$NexusUnitTestExtensions

local PlatformScope = require(game:GetService("ReplicatedStorage").NexusScopedSettings.PlatformScope)

return function()
    describe("The PlatformScope ParseHardwareKey helper method", function()
        it("should throw an error for an empty string.", function()
            expect(function() PlatformScope.ParseHardwareKey(nil) end).to.throw("Hardware key is empty.")
            expect(function() PlatformScope.ParseHardwareKey("") end).to.throw("Hardware key is empty.")
        end)

        it("should throw an error for an odd-length string.", function()
            expect(function() PlatformScope.ParseHardwareKey("odd") end).to.throw("Hardware key is not an even length: odd")
        end)

        it("should throw an error for an unknown indicator.", function()
            expect(function() PlatformScope.ParseHardwareKey("TYUY") end).to.throw("Unknown indicator: U in TYUY")
        end)

        it("should throw an error for an unknown flag.", function()
            expect(function() PlatformScope.ParseHardwareKey("TYCU") end).to.throw("Unknown flag: U for C in TYCU")
        end)

        it("should parse full keys.", function()
            expect(PlatformScope.ParseHardwareKey("TYVNCN")).to.deepEqual({Touch = true, VR = false, Console = false})
            expect(PlatformScope.ParseHardwareKey("CNTYVN")).to.deepEqual({Touch = true, VR = false, Console = false})
        end)

        it("should parse partial keys.", function()
            expect(PlatformScope.ParseHardwareKey("TYVN")).to.deepEqual({Touch = true, VR = false})
            expect(PlatformScope.ParseHardwareKey("CNTY")).to.deepEqual({Touch = true, Console = false})
        end)
    end)

    describe("The PlatformScope CreateHardwareKey helper method", function()
        it("should create keys.", function()
            expect(PlatformScope.CreateHardwareKey({Touch = true, Console = false, Unknown = true})).to.equal("TYCN")
            expect(PlatformScope.CreateHardwareKey({Touch = false, Console = true, VR = true})).to.equal("TNVYCY")
        end)
    end)

    describe("A PlatformScope instance with serialization data", function()
        local ObjectUnderTest = nil
        beforeEach(function()
            ObjectUnderTest = PlatformScope.new({
                TYVNCN = {
                    Setting = "Value1",
                },
                TNVN = {
                    Setting = "Value2",
                },
            }, {
                Get = function() return "Default" end,
            } :: any)
        end)

        it("should match hardware keys that match exactly.", function()
            expect(ObjectUnderTest:GetClosestHardwareKey("TYVNCN")).to.equal("TYVNCN")
            expect(ObjectUnderTest:GetClosestHardwareKey("TNVN")).to.equal("TNVN")
        end)

        it("should match with different orders.", function()
            expect(ObjectUnderTest:GetClosestHardwareKey("VNCNTY")).to.equal("TYVNCN")
            expect(ObjectUnderTest:GetClosestHardwareKey("VNTN")).to.equal("TNVN")
        end)

        it("should match shorter keys.", function()
            expect(ObjectUnderTest:GetClosestHardwareKey("VNTNCN")).to.equal("TNVN")
            expect(ObjectUnderTest:GetClosestHardwareKey("VNTNCY")).to.equal("TNVN")
        end)

        it("should not match other keys.", function()
            expect(ObjectUnderTest:GetClosestHardwareKey("TYVYCN")).to.equal(nil)
            expect(ObjectUnderTest:GetClosestHardwareKey("TYVNCY")).to.equal(nil)
            expect(ObjectUnderTest:GetClosestHardwareKey("TNVY")).to.equal(nil)
        end)

        it("should return values for the hardware key.", function()
            expect(ObjectUnderTest:Get("Setting", "TYVNCN")).to.equal("Value1")
            expect(ObjectUnderTest:Get("Setting", "TNVN")).to.equal("Value2")
            expect(ObjectUnderTest:Get("Setting", "TNVNCY")).to.equal("Value2")
        end)

        it("should pass values from the parent.", function()
            expect(ObjectUnderTest:Get("Setting2", "TYVNCN")).to.equal("Default")
            expect(ObjectUnderTest:Get("Setting2", "TNVN")).to.equal("Default")
            expect(ObjectUnderTest:Get("Setting", "TNVYCY")).to.equal("Default")
        end)

        it("should update values with existing hardware keys.", function()
            ObjectUnderTest:Set("Setting", "Value3", "TYVNCN")
            expect(ObjectUnderTest:Get("Setting", "TYVNCN")).to.equal("Value3")
            expect(ObjectUnderTest:Serialize()).to.deepEqual({
                TYVNCN = {
                    Setting = "Value3",
                },
                TNVN = {
                    Setting = "Value2",
                },
            })
        end)

        it("should migrate extended hardware keys.", function()
            ObjectUnderTest:Set("Setting", "Value3", "TNVNCN")
            expect(ObjectUnderTest:Get("Setting", "TNVNCN")).to.equal("Value3")
            expect(ObjectUnderTest:Serialize()).to.deepEqual({
                TYVNCN = {
                    Setting = "Value1",
                },
                TNVNCN = {
                    Setting = "Value3",
                },
            })
        end)

        it("should not migrate reordered hardware keys.", function()
            ObjectUnderTest:Set("Setting", "Value3", "TYCNVN")
            expect(ObjectUnderTest:Get("Setting", "TYCNVN")).to.equal("Value3")
            expect(ObjectUnderTest:Serialize()).to.deepEqual({
                TYVNCN = {
                    Setting = "Value3",
                },
                TNVN = {
                    Setting = "Value2",
                },
            })
        end)

        it("should ad new hardware keys.", function()
            ObjectUnderTest:Set("Setting", "Value3", "TYVYCY")
            expect(ObjectUnderTest:Get("Setting", "TYVYCY")).to.equal("Value3")
            expect(ObjectUnderTest:Serialize()).to.deepEqual({
                TYVNCN = {
                    Setting = "Value1",
                },
                TNVN = {
                    Setting = "Value2",
                },
                TYVYCY = {
                    Setting = "Value3",
                },
            })
        end)
    end)
end