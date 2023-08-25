AddCSLuaFile()

local colors = {
    white = Color(255,255,255,255),
    light_grey = Color(150,150,150,255),
    grey = Color(100,100,100,255),
    dark_grey = Color(36,36,36,255),
    black = Color(0,0,0,255),
}

local rendertypes = {
    "box",
    "roundbox",
    "circle",
    "custom"
}

local mdf_panel = {}
mdf_panel.__index = mdf_panel

AccessorFunc( mdf_panel, "size", "Size", FORCE_VECTOR )
AccessorFunc( mdf_panel, "pos", "Pos", FORCE_VECTOR )
AccessorFunc( mdf_panel, "wide", "Wide", FORCE_NUMBER )
AccessorFunc( mdf_panel, "height", "Height", FORCE_NUMBER )
AccessorFunc( mdf_panel, "selectable", "Selectable", FORCE_BOOL )
AccessorFunc( mdf_panel, "hovered", "Hovered", FORCE_BOOL )
AccessorFunc( mdf_panel, "text", "Text", FORCE_STRING )


function MDF_CreatePanel( screen )
    assert(screen:IsValid(),"screen InValid")
    local mt = Matrix()
    mt:SetTranslation( Vector( 0, 0, 0 ) )
    mt:SetScale( Vector( 1, 1, 1 ) )
    local meta = setmetatable({
        screen = screen,
        pos = Vector(),
        wide = 0,
        height = 0,
        theme = {
            render = {"box"},
            color1 = colors.black,
            color2 = colors.dark_grey,
            color3 = colors.grey,
            color_text = colors.color_white,
            color_text_shadow = colors.light_grey
        },
        matrix = mt,
        parent = nil,
        childs = {}

    },mdf_panel)
    meta:Init()
    meta:PerformLayout()
    return meta
end

do

    function mdf_panel:Init()
        
    end

    function mdf_panel:PerformLayout()
        self:SetWide(self:GetSize().x)
        self:SetHeight(self:GetSize().y)
        for num, child in ipairs(childs) do
            child:PerformLayout()
        end
    end

    function mdf_panel:GetParent()
        return self.parent
    end

    function mdf_panel:SetParent( panel )
        self.parent = panel
    end

    function mdf_panel:Draw( w, h )

    end

    function mdf_panel:__RenderChild()
        for num, child in ipairs(childs) do
            child:__Render()
        end
    end

    function mdf_panel:__Render()
        cam.PushModelMatrix( self.matrix )
            self:Draw(self:GetWide(), self:GetHeight())
            --тут может быть условие стенсила
            self:__RenderChild()
        cam.PopModelMatrix()
    end

    function mdf_panel:Update()
    end


    function mdf_panel:OnClick()

    end
    


end

