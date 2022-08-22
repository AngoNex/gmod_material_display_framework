AddCSLuaFile()

local display_name = "music_tablet"
local renderTarget = GetRenderTarget( display_name, 1024, 1024 )
local material = CreateMaterial( display_name, "LightmappedGeneric", {
    ["$basetexture"] = renderTarget:GetName(),
    ["$model"] = 1,
    ["$translucent"] = 1,
    ["$vertexalpha"] = 1,
    ["$vertexcolor"] = 1
} )

local function Update()
    render.PushRenderTarget( renderTarget )
        cam.Start2D()
            surface.SetDrawColor( Color(0,255,0,255) )
            surface.DrawRect( 0, 0, 1024, 1024 )

        cam.End2D()
    render.PopRenderTarget()

    material:Recompute()
end


-- timer.Create(display_name .. " - Update", 0.025, 0, function()
--     Update()
-- end)

--timer.Remove(display_name .. " - Update")

-- for n, ent in ipairs(ents.FindByModel( "models/weapons/c_tablet_hand.mdl" )) do
--     ent:SetSubMaterial( 1, "!" .. display_name )
--   print(ent)
-- end

-- hook.Add( "HUDPaint", display_name .. " - Debug", function()
-- 	surface.SetDrawColor( color_white )
-- 	surface.SetMaterial( material )
-- 	surface.DrawTexturedRect( 25, 25, 128, 128 )
-- end )

