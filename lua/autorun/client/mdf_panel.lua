AddCSLuaFile()

local colors = {
    white = Color(255,255,255,255),
    light_grey = Color(150,150,150,255),
    grey = Color(100,100,100,255),
    dark_grey = Color(36,36,36,255),
    black = Color(0,0,0,255),
}

local mdf_panel = {}
mdf_panel.__index = mdf_panel

AccessorFunc( mdf_panel, "size", "Size", FORCE_VECTOR )
AccessorFunc( mdf_panel, "pos", "Pos", FORCE_VECTOR )
AccessorFunc( mdf_panel, "wide", "Wide", FORCE_NUMBER )
AccessorFunc( mdf_panel, "height", "Height", FORCE_NUMBER )
AccessorFunc( mdf_panel, "selectable", "Selectable", FORCE_BOOL )
AccessorFunc( mdf_panel, "text", "Text", FORCE_STRING )


function MDF_CreatePanel( screen )
    assert(screen:IsValid(),"screen InValid")
    local mt = Matrix()
    mt:SetTranslation( Vector( 0, 0, 0 ) )
    mt:SetScale( Vector( 1, 1, 1 ) )
    local meta = setmetatable({
        x = 0,
        y = 0,
        wide = 0,
        height = 0,
        theme = {
            render = "box",
            color1 = colors.black,
            color2 = colors.dark_grey,
            color3 = colors.grey,
            color_text = colors.color_white,
            color_text_shadow = colors.light_grey
        },
        isbutton = false,
        matrix = mt,
        realpos = Vector(0,0),
        parent = nil

    },mdf_panel)
    meta:Init()
    return meta
end

do

    function mdf_panel:Init()

    end

    function mdf_panel:IsButton()
        return isbutton
    end

    function mdf_panel:GetParent()
        return self.parent
    end

    function mdf_panel:SetParent( panel )
        self.parent = panel
    end

    function mdf_panel:Draw( w, h )
        if self.theme.render == "box" then
            draw.RoundedBox(0,0,0,w,h,self.theme.color1)
        end
    end

    function mdf_panel:Render()
        cam.PushModelMatrix( self.matrix )
            self:Draw( )
        cam.PopModelMatrix()
    end

    function mdf_panel:Update()
        self.realpos = self.
        self:SetWide(self:GetSize().x)
        self:SetHeight(self:GetSize().y)
        self.matrix:SetTranslation( Vector( realpos.x, realpos.y, 0 ) )
        self.matrix:SetScale( Vector( self:GetWide(), self:GetHeight()), 1 )
    end

end


-- RecentReleasesNCS(1,function(tbl)
--     PrintTable(tbl)
-- end)

-- findInNCS("Unknown Brain", function(tbl)
--     PrintTable( tbl )
-- end)
