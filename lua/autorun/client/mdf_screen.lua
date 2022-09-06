AddCSLuaFile()

local CursorModes = {
    "Sticky",
    "Default"
}

local mdf_screen = {}
mdf_screen.__index = mdf_screen

function MaterialScreen( name, w, h )

    local material_name = "MDF_Screen_"..name
    local rt = GetRenderTarget( material_name, h, w )
    local mt = Matrix()
    mt:SetTranslation( Vector( 0, 0, 0 ) )
    mt:SetScale( Vector( 1, 1, 1 ) )
    return setmetatable({
        ScreenResolution = Vector( w, h ),
        MaterialName = material_name,
        RenderTarget = rt,
        ScreenMaterial = CreateMaterial( material_name , "VertexLitGeneric", {
                            ["$basetexture"] = rt:GetName(),
                            ["$model"] = 1,
                            ["$selfillum"] = 1
                        } ),
        ScreenMatrix = mt,
        ScreenStartPos = Vector( 0, 0 ),
        ScreenEndPos = Vector( w, h ),
        ScreenRealResolution = Vector( w, h ),
        Touch = false,
        Cursor = {
            Draw = true,
            Pos = Vector(),
            Mode = "Sticky",
            Selected = nil,
            Events = {
                [MOUSE_LEFT] = {},
                [MOUSE_MIDDLE] = {},
                [MOUSE_RIGHT] = {},
                [MOUSE_WHEEL_UP] = {},
                [MOUSE_WHEEL_DOWN] = {}
            },
            Offsets = {5,5,5,5}
        },
        Panels = {},
        Illum = 1
    }, mdf_screen )
end

do
--render

    function mdf_screen:Draw( w, h )

    end

    function mdf_screen:__Render()
        render.PushRenderTarget( self.RenderTarget)
            cam.Start2D()
                cam.PushModelMatrix( self.ScreenMatrix )
                    isfunction(self:Draw(self.ScreenRealResolution.x, self.ScreenRealResolution.y))
                cam.PopModelMatrix()
            cam.End2D()
        render.PopRenderTarget()
    end

    function mdf_screen:RenderUpdate()
        self:__Render()
        self:CursorUpdate()
        if self.ScreenMaterial == nil then return end
        self.ScreenMaterial:Recompute()
    end
end

do
    function mdf_screen:SetScreenPos(x1, y1)
        self.ScreenStartPos = Vector( x1, y1)
        self.ScreenMatrix:SetTranslation( Vector( self.ScreenStartPos.x, self.ScreenStartPos.y, 0 ) )
        self.ScreenRealResolution = Vector( self.ScreenResolution.x -  self.ScreenStartPos.x*2, self.ScreenResolution.y - self.ScreenStartPos.y*2 )
    end

    function mdf_screen:IsValid()
        return true
    end

    function mdf_screen:OnChangeSize()
        
    end

    function mdf_screen:ChangeSize()
        self:OnChangeSize()
        for key, panel in ipairs( self.Panels ) do
            panel:PerformLayout()
        end
    end

    function mdf_screen:OnRemove()
        
    end

    function mdf_screen:Remove()
        self:OnRemove()
        hook.Remove("PlayerButtonDown", "PlayerButtonDown"..self.MaterialName)
    end

end

do
--touch

    function mdf_screen:__ClickEvents()
        local active = self.Touch or false 
        local screen = self
        if active then
            hook.Add("PlayerButtonDown", "PlayerButtonDown"..self.MaterialName, function(ply, key)
                if IsValid(ply) and screen:IsValid() then
                    local events = self.Cursor.Events
                    if ply:Alive() then
                        if IsFirstTimePredicted() then
                            for key, func in ipairs( events[key] ) do
                                func()
                            end

                            if key == KEY_ESCAPE then
                                screen:SetTouchable( false )
                            end
                        end
                    end
                end
            end)
        else
            hook.Remove("PlayerButtonDown", "PlayerButtonDown"..self.MaterialName)
        end
    end

    function mdf_screen:TouchEvent( event, func )
        table.insert( self.Cursor.Events[event], func )
    end


    function mdf_screen:SetTouchable( bool )
        self.Touch = bool
        gui.EnableScreenClicker( self.Touch )
        self:__ClickEvents()
    end

    function mdf_screen:GetTouchable()
        return self.Touch
    end

    function mdf_screen:TouchableToggle()
        self:SetTouchable( !self:GetTouchable() )
    end

    function mdf_screen:SetDrawCursor( bool )
        self.Cursor.Draw = bool
    end

    function mdf_screen:GetDrawCursor()
        return self.Cursor.Draw
    end

    function mdf_screen:DrawCursorToggle()
        self.Cursor.Draw = !self.Cursor.Draw
    end

    function mdf_screen:SetCursorMode( mode )
        for key, value in ipairs( CursorModes ) do
            if value == mode then
                self.Cursor.Mode = mode
                break
            end
        end
    end

    function mdf_screen:GetCursorMode()
        return self.Cursor.Mode
    end

    function mdf_screen:VirtualCursorPosUpdate()
        local cx, cy = input.GetCursorPos()
        cx, cy = self.ScreenRealResolution.x / ScrW(), self.ScreenRealResolution.y / ScrH()
        self.Cursor.Pos = Vector(cx,cy)
    end

    function mdf_screen:SetCursorPos(x, y)
        input.SetCursorPos(x, y)
        self:VirtualCursorPosUpdate()
    end

    function mdf_screen:GetCursorPos()
        return self.Cursor.Pos
    end

    function mdf_screen:CursorIsAbovePanel(panel)
        local curpos = self:GetCursorPos()
        local panelpos = panel:GetGlobalPos()
        local panelsize = panel:GetSize()

        if (curpos.x >= panelpos.x and curpos.x <= panelpos.x + panelsize.x) and (curpos.y >= panelpos.y and curpos.y <= panelpos.y + panelsize.y) then
            return true
        end

        return false
    end

    function mdf_screen:CursorUpdate()
        if self:GetTouchable() then
            self:VirtualCursorPosUpdate()
        end

        for key, panel in ipairs( self.Panels ) do
            if panel:GetSelectable() then
                if self:CursorIsAbovePanel(panel) then
                    panel:SetHovered( true )
                    continue
                end
            end
            panel:SetHovered( false )
        end
    end
end

