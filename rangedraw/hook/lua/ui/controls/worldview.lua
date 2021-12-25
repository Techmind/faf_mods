local acs_modpath = "/mods/rangedraw/"
local CM = import('/lua/ui/game/commandmode.lua')
local Decal = import('/lua/user/userdecal.lua').UserDecal

local ACSdata = {
    isPreviewAlive = false,
    rings = {
        attackrange = {},
		buildrange = {},
    },
}

function createRangeRingPreviews(units)
	for __, w in {100,90,70,50,30} do
		local radius = w;
		if not ACSdata.rings.attackrange[radius] then
			local texture = acs_modpath..'textures/direct_ring.dds'
			if texture ~= nil then 
				createRing(ACSdata.rings.attackrange,texture, radius, 0, 0, 0, 0)
			end
		end
    end
	for __, w in {15} do
		local radius = w;
		if not ACSdata.rings.buildrange[radius] then
			local texture = acs_modpath..'textures/green_ring.dds'
			if texture ~= nil then 
				createRing(ACSdata.rings.buildrange,texture, radius, 0, 0, 0, 0)
			end
		end
    end
	for __, w in {10} do
		local radius = w;
		if not ACSdata.rings.buildrange[radius] then
			local texture = acs_modpath..'textures/range_ring.dds'
			if texture ~= nil then 
				createRing(ACSdata.rings.buildrange,texture, radius, 0, 0, 0, 0)
			end
		end
    end
    ACSdata.isPreviewAlive = true
end

function createRing(group, texture, radius, x1, x2, y1, y2)
    if not group[radius] then
        local ring = Decal(GetFrame(0))
        ring:SetTexture(texture)
        ring:SetScale({math.floor(2.03*(radius + x1) + x2), 0, math.floor(2.03*(radius + y1)) + y2})
        ring:SetPosition(GetMouseWorldPos())
        group[radius] = ring
    end
end


function createPreviewOfCurrentSelection()
    createRangeRingPreviews(GetSelectedUnits() or {})
end

function updatePreview()
    if (not ACSdata.isPreviewAlive) then
        createPreviewOfCurrentSelection()
    end
    for _, group in ACSdata.rings do
        for __, ring in group do
            ring:SetPosition(GetMouseWorldPos())
        end
    end
end

function removePreview()
    if (not ACSdata.isPreviewAlive) then
        return
    end
    for n, group in ACSdata.rings do
        for n2, ring in group do
            ring:Destroy()
            ACSdata.rings[n][n2] = nil
        end
    end
    ACSdata.isPreviewAlive = false
end


local oldWorldView = WorldView 
WorldView = Class(oldWorldView, Control) {

    isZoom = true,
    isPreviewBuildrange = false,
    isPreviewAttackrange = false,
    previewKey = "CONTROL",

    HandleEvent = function(self, event)
        if (not self.isZoom) and (event.Type == 'WheelRotation') then
            return true
        end
        return oldWorldView.HandleEvent(self, event)
    end,

    OnUpdateCursor = function(self)
		if IsKeyDown(self.previewKey) then
			updatePreview()
		else
			removePreview()
		end
        return oldWorldView.OnUpdateCursor(self)
    end,

    SetAllowZoom = function(self, bool)
        self.isZoom = bool
    end,
}
