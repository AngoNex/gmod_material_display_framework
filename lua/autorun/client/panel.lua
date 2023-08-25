AddCSLuaFile()

local colors = {
    white = Color( 255, 255, 255, 255 ),
    light_grey = Color( 150, 150, 150, 255 ),
    grey = Color( 100, 100, 100, 255 ),
    dark_grey = Color( 36, 36, 36, 255 ),
    black = Color( 0, 0, 0, 255 )
}

local mdf_panel = {}
mdf_panel.__index = mdf_panel

AccessorFunc( mdf_panel, "selectable", "Selectable", FORCE_BOOL )
AccessorFunc( mdf_panel, "hovered", "Hovered", FORCE_BOOL )
AccessorFunc( mdf_panel, "text", "Text", FORCE_STRING )
AccessorFunc( mdf_panel, "update", "Update", FORCE_BOOL )
AccessorFunc( mdf_panel, "cliping", "Cliping", FORCE_BOOL )

function MDF_CreatePanel( screen, parent )
    assert( screen:IsValid(), "screen InValid" )
    local mt = Matrix()
    local meta = setmetatable({
        screen = screen,
        size = Vector( 50, 50 ),
        matrix = mt,
        parent = parent,
        childs = {},
        events = {},
        color = colors.white,
        material = nil
    },mdf_panel)
    meta:Init()

    if parent then
        table.insert( parent.childs, meta )
    else
        table.insert( screen.Panels, meta )
    end

    return meta
end

do

    function mdf_panel:IsValid()
        return true
    end

    function mdf_panel:Init()

    end

    function mdf_panel:Think()

    end

    function mdf_panel:PerformLayout()
        if self:GetUpdate() then
            self.screen:RenderUpdate()
        end
    end

    function mdf_panel:GetSize()
        return self.size
    end

    function mdf_panel:SetSize( x, y )
        self.size = Vector( x, y )
        self:PerformLayout()
    end

    function mdf_panel:GetPos()
        return self.matrix:GetTranslation()
    end

    function mdf_panel:SetPos( x, y )
        self.matrix:SetTranslation( Vector( x, y ) )
        self:PerformLayout()
    end

    function mdf_panel:GetColor()
        return self.color
    end

    function mdf_panel:SetColor( col )
        if not IsColor( col ) then return end
        self.color = col
        self.screen:RenderUpdate()
    end

    function mdf_panel:GetMaterial()
        return self.material
    end

    function mdf_panel:SetMaterial( mat )
        if type( mat ) ~= "IMaterial" then return end
        self.material = mat
        self.screen:RenderUpdate()
    end

    function mdf_panel:GetParent()
        return self.parent
    end

    function mdf_panel:SetParent( panel )
        self.parent = panel
    end

    function mdf_panel:SetDraw( func )
        self.Draw = func
        self.screen:RenderUpdate()
    end

    function mdf_panel:Draw( w, h )

    end

    function mdf_panel:__RenderChild()
        for num, child in ipairs( self.childs ) do
            child:__Render()
        end
    end

    function mdf_panel:__Render()
        cam.PushModelMatrix( self.matrix, true )
            local size = self:GetSize()
            local w, h = size.x, size.y

            if self:GetCliping() then render.SetScissorRect( 0, 0, w, h, true ) end
                self:Draw( w, h )
                self:__RenderChild()
            render.SetScissorRect( 0, 0, w, h, true )

        cam.PopModelMatrix()
    end

    function mdf_panel:OnEvent( event, func )
        self.screen:TouchEvent( event, func )
        table.insert( self.events, { event = event, func = func } )
    end

    function mdf_panel:OnRemove()
    end

    function mdf_panel:Remove()
        self:OnRemove()
        for num, tbl in ipairs( self.events ) do
            table.RemoveByValue( self.screen.Cursor.Events[tbl.event], func )
        end
        table.RemoveByValue( self.screen.Panels, self )
        for num, child in ipairs( self.childs ) do
            child:Remove()
        end
        self = nil
    end

end

