AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include('shared.lua')

--Was 15, reduced by popular request.
local Energy_Increment = 8

function ENT:Initialize()
    self.BaseClass.Initialize(self)
    self.damaged = 0
    if not (WireAddon == nil) then
        self.WireDebugName = self.PrintName
        self.Outputs = Wire_CreateOutputs(self, { "Out" })
    end
end

function ENT:TurnOn()
    if (self.Active == 0) then
        self.Active = 1
        self:SetOOO(1)
    end
end

function ENT:TurnOff()
    if (self.Active == 1) then
        self.Active = 0
        self:SetOOO(0)
        if not (WireAddon == nil) then Wire_TriggerOutput(self, "Out", 0) end
    end
end

function ENT:SetActive() --disable use, lol
end

function ENT:Damage()
    if (self.damaged == 0) then self.damaged = 1 end
end

function ENT:Repair()
    self.BaseClass.Repair(self)
    self:SetColor(Color(255, 255, 255, 255))
    self.damaged = 0
end

function ENT:Destruct()
    if CAF and CAF.GetAddon("Life Support") then
        CAF.GetAddon("Life Support").Destruct(self, true)
    end
end

function ENT:Extract_Energy(mul)
    mul = mul or 0;
    if mul == 0 then
        return
    end
    local inc = 0
    local SB = CAF.GetAddon("Spacebuild")
	local env = 0
	if self.environment ~= nil then
		env = self.environment:GetAtmosphere()
	end
	inc = math.ceil(Energy_Increment / (env + 1))
    if (self.damaged == 1) then inc = math.ceil(inc / 2) end
    if (inc > 0) then
        inc = math.ceil(inc * self:GetMultiplier() * mul)
        self:SupplyResource("energy", inc)
    end
    if not (WireAddon == nil) then Wire_TriggerOutput(self, "Out", inc) end
end


function ENT:GenEnergy()
    local waterlevel = 0
    if CAF then
        waterlevel = self:WaterLevel2()
    else
        waterlevel = self:WaterLevel()
    end
    if (waterlevel > 1) then
        self:TurnOff()
    else
        local entpos = self:GetPos()
        --local SunAngle
        if TrueSun and table.Count(TrueSun) > 0 then
            local output = 0
            for k, SUN_POS in pairs(TrueSun) do
                --[[SunAngle = (entpos - v)
                    SunAngle:Normalize()
                    local startpos = (entpos - (SunAngle * 4096))
                    trace.start = startpos
                    trace.endpos = entpos --+ Vector(0,0,30)
                    local tr = util.TraceLine( trace )
                    if (tr.Hit) then
                        if (tr.Entity == self) then
                            self:TurnOn()
                            self:Extract_Energy()
                            return
                        end
                    else
                        self:TurnOn()
                        self:Extract_Energy()
                        return
                    end]]
                local trace = util.QuickTrace(SUN_POS, entpos - SUN_POS, nil)
                if trace.Hit then
                    if trace.Entity == self then
                        local v = self:GetUp() + trace.HitNormal
                        local n = v.x * v.y * v.z
                        if n > 0 then
                            output = output + n
                            --solar panel produces energy
                        end
                    end
                end
                if output >= 1 then
                    break
                end
            end
            if output > 1 then
                output = 1
            end
            if output > 0 then
                self:TurnOn()
                self:Extract_Energy(output)
                return
            end
		else
			local SunAngle2 = SunAngle or Vector(0, 0, 1)
			local SUN_POS = (entpos - (SunAngle2 * 4096))
			--[[trace.start = startpos
			  trace.endpos = entpos --+ Vector(0,0,30)
			  local tr = util.TraceLine( trace )
			  if (tr.Hit) then
				  if (tr.Entity == self) then
					  self:TurnOn()
					  self:Extract_Energy(1)
					  return
				  end
			  else
				  self:TurnOn()
				  self:Extract_Energy()
				  return
			  end]]
			local trace = util.QuickTrace(SUN_POS, entpos - SUN_POS, nil)
			if trace.Hit then
				if trace.Entity == self then
					local v = self:GetUp() + trace.HitNormal
					local n = v.x * v.y * v.z
					if n > 0 then
						self:TurnOn()
						self:Extract_Energy(n)
						return
					end
				end
			end
			self:TurnOff() --No Sunbeams in sight so turn Off
		end
    end
end

function ENT:Think()
    self.BaseClass.Think(self)
    self:GenEnergy()
    self:NextThink(CurTime() + 1)
    return true
end
