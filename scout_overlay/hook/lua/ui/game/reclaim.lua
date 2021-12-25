--local oldUpdateLabels = UpdateLabels

--function CreateScoutingLabel()
--end

--function UpdateLabels()
    --oldUpdateLabels()
--end

function CreateScoutLabel(view, path, squareSize)
    local label = WorldLabel(view, Vector(0, 0, 0))

    label.oldTickDiff = 0
    label.bitmap = Bitmap(label)
    label.bitmap:SetTexture(UIUtil.UIFile(path))
    LayoutHelpers.AtLeftIn(label.bitmap, label)
    LayoutHelpers.AtVerticalCenterIn(label.bitmap, label)
    LayoutHelpers.SetDimensions(label.bitmap, squareSize, squareSize)

    label.text = UIUtil.CreateText(label, "", 10, UIUtil.bodyFont)
    label.text:SetColor('ffb4b7c1')
    label.text:SetDropShadow(true)
    LayoutHelpers.AtLeftIn(label.text, label, 16)
    LayoutHelpers.AtVerticalCenterIn(label.text, label)

    label:DisableHitTest(true)
    label.OnHide = function(self, hidden)
        self:SetNeedsFrameUpdate(not hidden)
    end

    label.Update = function(self)
        local view = self.parent.view
        local proj = view:Project(self.position)
        LayoutHelpers.AtLeftTopIn(self, self.parent, (proj.x - self.Width() / 2) / LayoutHelpers.GetPixelScaleFactor(), (proj.y - self.Height() / 2 + 1) / LayoutHelpers.GetPixelScaleFactor())
        self.proj = {x=proj.x, y=proj.y }

    end

    label.DisplayScouted = function(self, r)
        if self:IsHidden() then
            self:Show()
        end
        self:SetPosition(r.position)
        if r.tickDiff ~= self.oldTickDiff then
            self.text:SetText(tostring(r.tickDiff))
            self.oldTickDiff = r.tickDiff
            self.bitmap:SetTexture(r.path)
        end
    end

    label:Update()

    return label
end