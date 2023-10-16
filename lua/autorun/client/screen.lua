AddCSLuaFile()

MDF_MOUSE_MOVE = 99

local mdf_screen = {}
mdf_screen.__index = mdf_screen

function MaterialScreen( name, w, h )
    local material_name = "MDF_Screen_" .. name
    local rt = GetRenderTarget( material_name, w, h )
    local mt = Matrix()
    mt:SetTranslation( Vector( 0, 0, 0 ) )
    mt:SetScale( Vector( 1, 1, 1 ) )

    meta = setmetatable({
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
        ButtonDown = {},
        KeyboardDown = {},
        Cursor = {
            Draw = false,
            Pos = Vector(),
            Selected = nil,
            Events = {
                [MOUSE_LEFT] = {},
                [MOUSE_MIDDLE] = {},
                [MOUSE_RIGHT] = {},
                [MOUSE_WHEEL_UP] = {},
                [MOUSE_WHEEL_DOWN] = {},
                [MDF_MOUSE_MOVE] = {}
            }
        },
        Panels = {},
        Illum = 1
    }, mdf_screen )

    return meta
end

do
--render

    function mdf_screen:Draw( w, h )

    end

    function mdf_screen:__Render()
        render.PushRenderTarget( self.RenderTarget )
            render.OverrideAlphaWriteEnable( true, true )
            render.ClearDepth()
            render.Clear( 0, 0, 0, 0 )
            cam.Start2D()
                cam.PushModelMatrix( self.ScreenMatrix )
                    render.SetScissorRect( self.ScreenStartPos.x, self.ScreenStartPos.y, self.ScreenRealResolution.x, self.ScreenRealResolution.y, true )
                    for num, panel in ipairs( self.Panels ) do
                        panel:__Render()
                    end
                    self:Draw( self.ScreenRealResolution.x, self.ScreenRealResolution.y )
                    render.SetScissorRect( 0, 0, 0, 0, false )
                cam.PopModelMatrix()
            cam.End2D()
            render.OverrideAlphaWriteEnable( false )
        render.PopRenderTarget()
    end

    function mdf_screen:RenderUpdate()
        self:__Render()
        if self.ScreenMaterial == nil then return end
    end

    function mdf_screen:Recompute()
        self.ScreenMaterial:Recompute()
    end

end

do
    function mdf_screen:SetScreenPos( x, y )
        self.ScreenStartPos = Vector( x, y )
        self.ScreenMatrix:SetTranslation( Vector( self.ScreenStartPos.x, self.ScreenStartPos.y, 0 ) )
        --self.ScreenRealResolution = Vector( self.ScreenResolution.x - self.ScreenStartPos.x * 2, self.ScreenResolution.y - self.ScreenStartPos.y * 2 )
    end

    function mdf_screen:SetScreenRealResolution( x, y )
        self.ScreenRealResolution = Vector( x, y )
    end

    function mdf_screen:IsValid()
        return true
    end

    function mdf_screen:OnChangeSize()

    end

    function mdf_screen:ChangeSize()
        self:OnChangeSize()
    end

    function mdf_screen:OnRemove()

    end

    function mdf_screen:Remove()
        self:OnRemove()
        hook.Remove( "PlayerButtonDown", "PlayerButtonDown" .. self.MaterialName )
        hook.Remove( "PlayerBindPress", "PlayerBindPress" .. self.MaterialName )
        hook.Remove( "Think", "Think" .. self.MaterialName )
    end

end

do
--touch

    function mdf_screen:__MouseLock()
        local active = self.Touch or false
        local screen = self
        if active then
            local events = self.Cursor.Events
            hook.Add( "InputMouseApply", "InputMouseApply" .. self.MaterialName, function( cmd,x, y, ang )
                cmd:SetMouseX( 0 )
                cmd:SetMouseY( 0 )
                screen:SetCursorPos( screen:GetCursorPos() + Vector(x / 2, y / 2) )
                if istable( events[MDF_MOUSE_MOVE] ) then
                    for key, func in ipairs( events[MDF_MOUSE_MOVE] ) do
                        func( screen:GetCursorPos() )
                    end
                end
                return true
            end )
        else
            hook.Remove("InputMouseApply", "InputMouseApply" .. self.MaterialName)
        end
    end

    function mdf_screen:__ClickEvents()
        local active = self.Touch or false
        local screen = self
        if active then
            local events = self.Cursor.Events
            local press = self.ButtonDown
            local keyboard = self.KeyboardDown
            hook.Add( "PlayerButtonDown", "PlayerButtonDown" .. self.MaterialName, function(ply, key)
                if IsValid( ply ) and screen:IsValid() and ply:Alive() and IsFirstTimePredicted() then
                    --print( language.GetPhrase( input.GetKeyName( key ) ) )
                    if key >= KEY_0 and key <= KEY_Z or key == KEY_BACKSPACE or key == KEY_ENTER or key == KEY_SPACE then
                        for _, func in ipairs( keyboard ) do
                            func( key )
                        end
                    end
                    if istable( press[key] ) then
                        for _, func in ipairs( press[key] ) do
                            func()
                        end
                    end
                    if istable( events[key] ) then
                        for _, func in ipairs( events[key] ) do
                            func( self.Cursor.Pos )
                        end
                    end
                    if key == KEY_ESCAPE then
                        screen:SetTouchable( false )
                    end
                end
            end)

            hook.Add( "PlayerBindPress", "PlayerBindPress" .. self.MaterialName, function( ply, bind, pressed )
                --if (bind == "+left" or bind == "+right") then
                return true
                --end
            end )
        else
            hook.Remove( "PlayerButtonDown", "PlayerButtonDown" .. self.MaterialName )
            hook.Remove( "PlayerBindPress", "PlayerBindPress" .. self.MaterialName )
        end
    end

    function mdf_screen:TouchEvent( event, func )
        table.insert( self.Cursor.Events[event], func )
    end

    function mdf_screen:PressEvent( event, func )
        if not istable( self.ButtonDown[event] ) then
            self.ButtonDown[event] = {}
        end
        table.insert( self.ButtonDown[event], func )
    end

    function mdf_screen:Keyboard( func )
        table.insert( self.KeyboardDown, func )
    end


    function mdf_screen:SetTouchable( bool )
        self.Touch = bool
        self:__ClickEvents()
        self:__MouseLock()
    end

    function mdf_screen:GetTouchable()
        return self.Touch
    end

    function mdf_screen:TouchableToggle()
        self:SetTouchable( not self:GetTouchable() )
    end

    function mdf_screen:SetDrawCursor( bool )
        self.Cursor.Draw = bool
    end

    function mdf_screen:GetDrawCursor()
        return self.Cursor.Draw
    end

    function mdf_screen:DrawCursorToggle()
        self.Cursor.Draw = not self.Cursor.Draw
    end

    function mdf_screen:SetCursorPos( input )
        local x, y = input.x, input.y

        local vec = Vector( math.Clamp( x, 0, self.ScreenRealResolution.x ), math.Clamp( y, 0, self.ScreenRealResolution.y ) )

        self.Cursor.Pos = vec
    end

    function mdf_screen:GetCursorPos()
        return self.Cursor.Pos
    end

end

