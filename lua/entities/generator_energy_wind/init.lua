AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include('shared.lua')

local Energy_Increment = 40

function ENT:Initialize()
    self.BaseClass.Initialize(self)
    self.Active = 0
    self.damaged = 0
    self.sequence = -1
    self.thinkcount = 0
    if not (WireAddon == nil) then
        self.WireDebugName = self.PrintName
        self.Outputs = Wire_CreateOutputs(self, { "Out" })
    end
end

function ENT:TurnOn()
    if (self.Active == 0) then
        self.Active = 1
        self:SetOOO(1)
        self.sequence = self:LookupSequence("rotate")
        if self.sequence and self.sequence ~= -1 then
            self:SetSequence(self.sequence)
            self:ResetSequence(self.sequence)
            --self:SetPlaybackRate(1)
        end
    end
end

function ENT:TurnOff()
    if (self.Active == 1) then
        self.Active = 0
        self:SetOOO(0)
        self.sequence = self:LookupSequence("idle")
        if self.sequence and self.sequence ~= -1 then
            self:SetSequence(self.sequence)
            self:ResetSequence(self.sequence)
            self:SetPlaybackRate(1)
        end
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

function ENT:Extract_Energy()
    local inc = 0
    if (self.damaged == 0) then --or (math.random(1, 10) < 6)
        if self.environment and (self.environment:IsStar() or self.environment:IsPlanet()) then
			inc = Energy_Increment * self.environment:GetAtmosphere()
        end
        if (inc > 0) then
            local einc = math.ceil(inc * self:GetMultiplier())
            self:SupplyResource("energy", einc)
            if not (WireAddon == nil) then Wire_TriggerOutput(self, "Out", einc) end
        else
            if not (WireAddon == nil) then Wire_TriggerOutput(self, "Out", 0) end
        end
    end
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
        self:Destruct()
    else
        self:Extract_Energy()
    end
end

function ENT:Think()
    self.BaseClass.Think(self)
    if self.sequence and self.sequence ~= -1 then
        self:ResetSequence(self.sequence)
        --self:SetPlaybackRate(1)
    end
    self.thinkcount = self.thinkcount + 1
    if self.thinkcount == 10 then
        local SB = CAF.GetAddon("Spacebuild")
        if SB and SB.GetStatus() then
            if self.environment then
                local planet = self.environment:IsOnPlanet()
				local atmos = 0
				if IsValid(planet) then atmos = planet:GetAtmosphere() end
                if (atmos > 0) then
                    self:TurnOn()
					if atmos > 10 then self:Destruct() end
					self:SetPlaybackRate(atmos)
                else
                    self:TurnOff()
                end
            end
        else
            self:TurnOn()
        end
        if (self.Active == 1) then
            self:GenEnergy()
        end
        self.thinkcount = 0
    end
    self:NextThink(CurTime() + 0.1)
    return true
end
