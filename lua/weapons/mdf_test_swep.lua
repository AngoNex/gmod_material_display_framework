AddCSLuaFile()

SWEP["PrintName"] = "Tablet"
SWEP["Category"]  = "MDF"

SWEP["Spawnable"]	= true
SWEP["UseHands"]	= true

SWEP["HoldType"]	= "normal"

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
        self.ScreenRenderTarget = GetRenderTarget( self.RenderTargetName, 1024, 1024 )
        self.ScreenMaterial = CreateMaterial( self.RenderTargetName , "VertexLitGeneric", {
            ["$basetexture"] = self.ScreenRenderTarget:GetName(),
            ["$model"] = 1,
            ["$translucent"] = 1,
            ["$vertexalpha"] = 1,
            ["$vertexcolor"] = 1
        } )

        self.createdmaterial = true

        self:SetSubMaterial( 1, "!" .. self.RenderTargetName )

    end
end

if CLIENT then

    function SWEP:UpdateScreen()
        render.PushRenderTarget( self.ScreenRenderTarget)
            cam.Start2D()
                surface.SetDrawColor( Color(0,255,0,255) )
                surface.DrawRect( 0, 0, 1024, 1024 )

            cam.End2D()
        render.PopRenderTarget()

        self.ScreenMaterial:Recompute()
    end

    function SWEP:Think()
        if self.createdmaterial then
            self:UpdateScreen()
        end
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

