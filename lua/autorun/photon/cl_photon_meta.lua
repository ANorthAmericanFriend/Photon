AddCSLuaFile()

local PhotonColors = nil
if EMVU and EMVU.Colors then PhotonColors = EMVU.Colors end
hook.Add( "InitPostEntity", "Photon.LocalColorSet", function() PhotonColors = EMVU.Colors; end )

function Photon:SetupCar( ent, index )

	ent.VehicleName = index

	function ent:Photon_HeadlightsOn()
		if not IsValid( self ) then return false end
		return self:GetDTBool( CAR_HEADLIGHTS )
	end

	function ent:Photon_IsBraking()
		if not IsValid( self ) then return false end
		return self:GetDTBool( CAR_BRAKING )
	end

	function ent:Photon_IsReversing()
		if not IsValid( self ) then return false end
		return self:GetDTBool( CAR_REVERSING )
	end

	function ent:Photon_IsRunning()
		if not IsValid( self ) then return false end
		return self:GetDTBool( CAR_RUNNING )
	end

	function ent:Photon_BlinkState()
		if not IsValid( self ) then return 0 end
		return self:GetDTInt( CAR_BLINKER )
	end

	function ent:Photon_TurningLeft()
		if not IsValid( self ) then return false end
		return self:Photon_BlinkState() == CAR_TURNING_LEFT
	end

	function ent:Photon_TurningRight()
		if not IsValid( self ) then return false end
		return self:Photon_BlinkState() == CAR_TURNING_RIGHT
	end

	function ent:Photon_Hazards()
		if not IsValid( self ) then return false end
		return self:Photon_BlinkState() == CAR_HAZARD
	end

	function ent:Photon_SetupCarVisHandles()
		if not IsValid( self ) or not self.Photon_GetLightingPositions then return false end
		//if not self.GetLightingPositions() or not self:Photon_GetLightingPositions() then return end
		if not istable( self:Photon_GetLightingPositions() ) then return end
		for k,v in pairs( self:Photon_GetLightingPositions() ) do
			self.Lighting.Handles[k] = util.GetPixelVisibleHandle()
		end
	end

	function ent:Photon_GetLightingPositions()
		if not IsValid( self ) then return false end
		return Photon.Vehicles.Positions[self.VehicleName]
	end

	function ent:Photon_GetLightingMeta()
		if not IsValid( self ) then return false end
		return Photon.Vehicles.Meta[self.VehicleName]
	end

	function ent:Photon_DisconnectLight( index )

		if not IsValid( self ) then return false end
		//local disconnectTable = { true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true }
		if not table.HasValue( self.Lighting.Disconnected, index ) then
			table.insert( self.Lighting.Disconnected, index )
		end
	end

	function ent:Photon_GetLightingConfig()
		if not IsValid( self ) then return false end
		if Photon.Vehicles.Config[self.VehicleName] then
			return Photon.Vehicles.Config[self.VehicleName]
		end
		return false
	end

	function ent:Photon_GetBlinkRate()
		if not IsValid( self ) then return PHO_DEFAULT_BLINK end
		if self:Photon_GetLightingConfig() and isnumber(self:Photon_GetLightingConfig().BlinkRate) then 
			return self:Photon_GetLightingConfig().BlinkRate 
		else 
			return PHO_DEFAULT_BLINK 
		end 
	end

	function ent:Photon_BlinkOn()
		if not IsValid( self ) then return false end
		if not self.Lighting.LastBlink then self.Lighting.LastBlink = RealTime() end
		local driving = (LocalPlayer():GetVehicle() == self)
		local result = nil
		if (self.Lighting.LastBlink + self:Photon_GetBlinkRate()) <= RealTime() and RealTime() <= (self.Lighting.LastBlink + (self:Photon_GetBlinkRate() * 2)) then
			result = false
			if not self.Lighting.WasOff and driving then surface.PlaySound( EMVU.Sounds.Tick ) end 
			self.Lighting.WasOff = true
		elseif RealTime() > (self.Lighting.LastBlink + (self:Photon_GetBlinkRate() * 2)) then
			result = false
			self.Lighting.WasOff = true
			self.Lighting.LastBlink = RealTime()
		else
			if self.Lighting.WasOff and driving then surface.PlaySound( EMVU.Sounds.Tock ) end 
			result = true
			self.Lighting.WasOff = false
		end
		return result
	end

	function ent:Photon_ReconnectLights()
		if not IsValid( self ) then return false end
		self.Lighting.Disconnected = {}
	end

	function ent:Photon_LightDisconnected( index )
		if not IsValid( self ) then return false end
		if table.HasValue( self.Lighting.Disconnected, index ) then return true end
		return false
	end

	function ent:SetStateMaterial( index, value )
		//print(tostring(index))
		//PrintTable( Photon.Vehicles.StateMaterials[ self.VehicleName ] )
		local stateData = Photon.Vehicles.StateMaterials[ self.VehicleName ][ index ]
		local matNumber = stateData.Index
		local matValue = stateData.States[ value ]
		self:SetSubMaterial( matNumber, matValue )
		self.PhotonMaterials[ index ] = value
	end

	function ent:ResetStateMaterials()
		for k,v in pairs( self.PhotonMaterials ) do
			self:SetStateMaterial( k, 0 )
			self.PhotonMaterials[k] = nil
		end
	end

	function ent:Photon_RenderLights( headlights, running, reversing, braking, left, right, hazards, pdebug )
		if not IsValid( self ) then return false end
		self:ResetStateMaterials()
		if not self.LastPhotonRenderCache or self.LastPhotonRenderCache + .05 < RealTime() then self.PhotonRenderCache = nil end

		local RenderTable = { true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true }

		if istable( self.PhotonRenderCache ) then

			RenderTable = self.PhotonRenderCache

		else
			if headlights then
				if Photon.Vehicles.States.Headlights[self.VehicleName] or pdebug then
					for _,l in pairs(Photon.Vehicles.States.Headlights[self.VehicleName]) do
						RenderTable[l[1]] = l
					end
				end
			end

			if running or pdebug then
				if Photon.Vehicles.States.Running[self.VehicleName] then
					for _,l in pairs(Photon.Vehicles.States.Running[self.VehicleName]) do
						RenderTable[l[1]] = l
					end
				end
			end

			if reversing or pdebug then
				if Photon.Vehicles.States.Reverse[self.VehicleName] then
					for _,l in pairs(Photon.Vehicles.States.Reverse[self.VehicleName]) do
						RenderTable[l[1]] = l
					end
				end
			end

			if braking or pdebug then -- Braking is added later because it will override values of all other lights
				if Photon.Vehicles.States.Brakes[self.VehicleName] then
					for _,l in pairs(Photon.Vehicles.States.Brakes[self.VehicleName]) do
						RenderTable[l[1]] = l
					end
				end
			end

			if ((left and running) or hazards) and self:Photon_BlinkOn() or pdebug then
				if Photon.Vehicles.States.Blink_Left[self.VehicleName] then
					for _,l in pairs(Photon.Vehicles.States.Blink_Left[self.VehicleName]) do
						RenderTable[l[1]] = l
					end
				end
			end

			if ((right and running) or hazards) and self:Photon_BlinkOn() or pdebug then
				if Photon.Vehicles.States.Blink_Right[self.VehicleName] then
					for _,l in pairs(Photon.Vehicles.States.Blink_Right[self.VehicleName]) do
						RenderTable[l[1]] = l
					end
				end
			end

			self.PhotonRenderCache = RenderTable
			self.LastPhotonRenderCache = RealTime()

		end

		local handles = self.Lighting.Handles
		local meta = self:Photon_GetLightingMeta()
		local positions = self:Photon_GetLightingPositions()

		local setupVis = self.Photon_SetupCarVisHandles
		local lightDisconnect = self.Photon_LightDisconnected
		local drawLight = Photon.PrepareVehicleLight

		local light = false
		
		for i,light in pairs( RenderTable ) do
			if light != true then
				if string.StartWith(tostring(i), "_") then
					self:SetStateMaterial( string.sub( tostring(i), 2 ), light[2] )
				else
					if not handles[light[1]] then setupVis( self ) return end -- for debugging mostly
					local pos = positions[light[1]]
					if pos and handles[i] and not lightDisconnect( self, light[1] ) then
					local gpos = self:LocalToWorld(pos[1])
						drawLight(
							Photon,
							self,
							PhotonColors[light[2]], -- color
							pos[1], -- local pos
							gpos, -- worldpos
							pos[2], -- angle
							meta[pos[3]], -- meta data
							// handles[light[1]], -- handle
							util.PixelVisible( gpos, 1, handles[light[1]]), -- handle
							i, -- dynamic light number
							light[3] -- brightness
						)
					end
				end
			end
		end
	end

	ent.Lighting = {}
	ent.Lighting.Clock = RealTime()
	ent.Lighting.Handles = {}
	ent.Lighting.Disconnected = {}
	ent.Lighting.LastBlink = RealTime()
	ent.Lighting.Blink = false

	ent.PhotonMaterials = {}

	ent:Photon_SetupCarVisHandles()

	ent.DrawLight = Photon.DrawLight

end