AddCSLuaFile()

SWEP["PrintName"] = "Tablet"
SWEP["Category"]  = "MDF"

SWEP["Spawnable"]	= true
SWEP["UseHands"]	= true

SWEP["HoldType"]	= "slam"

SWEP["WorldModel"] = ""
SWEP["ViewModel"]  = "models/weapons/c_tablet_hand.mdl"

SWEP["Slot"] = 1
SWEP["SlotPos"] = 4

function SWEP:Play(anim, anim2, pre, after)
    local ply = self:GetOwner()
    if IsValid(ply) then
        local len = self:SequenceDuration(self:SelectWeightedSequence(anim))
        timer.Simple(len - 0.25, function()
            if IsValid(self) and IsValid(ply) then
                if isfunction(after) then after(ply) end
                self:SendWeaponAnim(anim2 or ACT_VM_IDLE)
            end
        end)

        self:SendWeaponAnim(anim)
        if isfunction(pre) then pre(ply, len) end
        self:SetNextPrimaryFire(CurTime() + len)
    end
end


function SWEP:Initialize()
    self:SetWeaponHoldType(self["HoldType"])
    if CLIENT then
        self.RenderTargetName = self:GetPrintName().."_RT"
        self.ScreenRenderTarget = GetRenderTarget( self.RenderTargetName, 2048, 2048 )
        self.ScreenMaterial = CreateMaterial( self.RenderTargetName , "VertexLitGeneric", {
            ["$basetexture"] = self.ScreenRenderTarget:GetName(),
            ["$model"] = 1,
            ["$selfillum"] = 1
        } )
        self.createdmaterial = true

        self:GetOwner():GetViewModel():SetSubMaterial( 1, "!" .. self.RenderTargetName )

    end
end

if CLIENT then


    if IsValid( TEST_PNL ) then
        TEST_PNL:Remove()
    end

    TEST_PNL = vgui.Create("DPanel")
    TEST_PNL:SetPaintedManually( true )
    TEST_PNL:SetSize( ScrW(), ScrH() )
    TEST_PNL:Center()
    local eng = 0
    local neweng = 0
    soundalz:BeatEvent( SND_SA_BASS, function()
        neweng = 200
    end)

    function SWEP:UpdateScreen()
        render.PushRenderTarget( self.ScreenRenderTarget)
            -- cam.Start3D2D()
            --     TEST_PNL:PaintManual()
            -- cam.End3D2D()

            cam.Start2D()
                    surface.SetDrawColor( Color(0,0,0,255) )
                    surface.DrawRect( 0, 0, 2048, 2048 )
                   -- surface.DrawCircle(512,312,20,0,255,255,255)
                    if IsValid(soundalz) then
                        eng = eng + (neweng - eng)/11.11111
                        neweng = 80
                        -- for i = 1 , 360 do
                        --     surface.DrawCircle(1024+math.sin(CurTime()+i)*eng,1024+math.cos(CurTime()+i)*eng,30,0,255,255,255)
                        -- end
                        for i = 1, 205 do
                            surface.SetDrawColor( color_white )
                            surface.DrawRect((i-1)*10, 315, 10, 1 + soundalz["FFT"][i]*2500  )
                        end
                    end
            cam.End2D()

        render.PopRenderTarget()

        self.ScreenMaterial:Recompute()
    end

    function SWEP:Think()
        if self.createdmaterial then
            self:UpdateScreen()
        end
    end

    function SWEP:DrawHUD()
        local vm = self:GetOwner():GetViewModel()
        local obj1 = vm:GetAttachment(vm:LookupAttachment( "left_up" ))
        local obj2 = vm:GetAttachment(vm:LookupAttachment( "right_up" ))
        local obj3 = vm:GetAttachment(vm:LookupAttachment( "left_down" ))
        local obj4 = vm:GetAttachment(vm:LookupAttachment( "right_down" ))
        local pos1 = obj1.Pos:ToScreen()
        local pos2 = obj2.Pos:ToScreen()
        local pos3 = obj3.Pos:ToScreen()
        local pos4 = obj4.Pos:ToScreen()
        surface.SetDrawColor( Color(255,0,0,255) )
        surface.DrawLine(pos1.x,pos1.y,pos2.x,pos2.y)
        surface.DrawLine(pos1.x,pos1.y,pos3.x,pos3.y)
        surface.DrawLine(pos4.x,pos4.y,pos2.x,pos2.y)
        surface.DrawLine(pos4.x,pos4.y,pos3.x,pos3.y)
    end
end



if SERVER then
    function SWEP:OnRemove()
    end

    function SWEP:OnDrop()
        self:Remove()
    end
end

function SWEP:Holster(wep)
    self:SendWeaponAnim(ACT_VM_DRAW)
    return true
end

function SWEP:Deploy()
    self:SendWeaponAnim(ACT_VM_HOLSTER)
    self:Play(ACT_VM_HOLSTER, ACT_VM_IDLE)
end

