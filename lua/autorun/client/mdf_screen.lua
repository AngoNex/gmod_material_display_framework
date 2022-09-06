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
    mt:Translate( Vector( 0, 0, 0 ) )
    mt:Scale( Vector( 1, 1, 1 ) )
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

        },
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
        if self.ScreenMaterial == nil then return end
        self.ScreenMaterial:Recompute()
    end
end

do
    function mdf_screen:SetScreenPos(x1, y1)
        ScreenStartPos = Vector( x1, y1)
        self.ScreenMatrix:SetTranslation( Vector( ScreenStartPos.x, ScreenStartPos.y, 0 ) )
        self.ScreenRealResolution = Vector( self.ScreenResolution.x -  ScreenStartPos.x*2, self.ScreenResolution.y - ScreenStartPos.y*2 )
    end

end

do
--touch
    function mdf_screen:SetTouchable( bool )
        self.Touch = bool
    end

    function mdf_screen:GetTouchable()
        return self.Touch
    end

    function mdf_screen:TouchableToggle()
        self.Touch = !self.Touch
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

end

