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


local function findInNCS( find, callback )
    if type(find) == "string" then
        find = find:Replace(" ","+")
    end
    http.Fetch( "https://ncs.io/music-search?q="..find.."&genre=&mood=",
        function(body, size, headers, code)

            local Tracks = {}

            for s in string.gmatch(body,"<a class=\"player.play\".-</i></a>") do
                table.insert(Tracks, {
                    URL = string.match(s, "data.url=\"(.-)\""),
                    Artist = string.match(s, "artist=\".->(.-)<"),
                    Name = string.match(s, "track=\"(.-)\""),
                    Cover = string.match(s, "cover=\"(.-)\"")
                })
            end

            if isfunction( callback ) then
                callback( Tracks )
            end

        end,
        function(code)
            print("error "..code)
        end,
    {} )
end

local function RecentReleasesNCS(page, callback)
    assert( isnumber(page), "Argument #1 must be a number!" )

    http.Fetch( "https://ncs.io/music?page=" .. page,
        function(body, size, headers, code)
            print( "req code:", code, "size: ", size )
            local info = {
                FeaturedRelease = {
                    URL = {},
                    Artist = {},
                    Name = {},
                    Cover = {},
                },
                Tracks = {},
                LastPage = 1
            }

            local FeaturedRelease_data = string.match(body, "<a class=\"btn white player.play\".-></i> Play</a>")
            info["FeaturedRelease"].URL = string.match(FeaturedRelease_data, "data.url=\"(.-)\"")
            info["FeaturedRelease"].Artist = string.match(FeaturedRelease_data, "artist=\".->(.-)<")
            info["FeaturedRelease"].Name = string.match(FeaturedRelease_data, "track=\"(.-)\"")
            info["FeaturedRelease"].Cover = string.match(FeaturedRelease_data, "cover=\"(.-)\"")

            for s in string.gmatch(body,"<a class=\"btn black player.play\".-></i> Play</a>") do
                if string.match(s, "data.url=\"(.-)\"") == "" then continue end
                table.insert(info["Tracks"], {
                    URL = string.match(s, "data.url=\"(.-)\""),
                    Artist = string.match(s, "artist=\".->(.-)<"),
                    Name = string.match(s, "track=\"(.-)\""),
                    Cover = string.match(s, "cover=\"(.-)\"")
                })
            end

            for s in string.gmatch(body, "<li class=\"page.item\"><a class=\"page.link\" href=\".-\">(.-)<") do
                info["LastPage"] = s
            end

            if isfunction( callback ) then
                callback( info )
            end

        end,
        function(code)
            print("error "..code)
        end,
    {} )
end

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
end


if CLIENT then

    function SWEP:Initialize()
        self.mdf = MaterialScreen( "tablet_screen", 2048, 2048 )
        self.mdf:SetScreenPos(0, 315)
        local vm = self:GetOwner():GetViewModel()
        if LocalPlayer() == self:GetOwner() then
            vm:SetSubMaterial( 1, "!"..self.mdf.MaterialName )
        end

        self.mdf:SetTouchable( true )
        -- hook.Add( "PlayerBindPress", "mdf_tablet", function( ply, bind, pressed )
        --     if (bind == "+left" or bind == "+right") then
        --         return true
        --     end
        -- end )

        local font = "Default"

        function self.mdf:Draw( w, h )
            surface.SetDrawColor( Color(0,0,0,255) )
            surface.DrawRect( -100, -100, w+200, h+200 )

            local cx, cy = self:GetCursorPos().x, self:GetCursorPos().y
            draw.RoundedBox(10,cx-10, cy-10,20,20,Color(136,136,136,155))

        end
    end

    function SWEP:Reload()
        if IsFirstTimePredicted() then
            self:Initialize()
        end
    end

    function SWEP:Think()
       self.mdf:RenderUpdate()
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
       -- surface.SetDrawColor( Color(255,0,0,255) )
      --  surface.DrawLine(pos1.x,pos1.y,pos2.x,pos2.y)
       -- surface.DrawLine(pos1.x,pos1.y,pos3.x,pos3.y)
       -- surface.DrawLine(pos4.x,pos4.y,pos2.x,pos2.y)
       -- surface.DrawLine(pos4.x,pos4.y,pos3.x,pos3.y)
    end

    function SWEP:OnRemove()
        local ply = self:GetOwner()
        if IsValid(ply) then
            if ply:IsPlayer() then
                local vm = ply:GetViewModel()
                if IsValid(vm) then
                    vm:SetSubMaterial( 1 )
                end
            end
        end
    end

end


function SWEP:Holster(wep)
    self:SendWeaponAnim(ACT_VM_DRAW)
    if CLIENT then
        local ply = self:GetOwner()
        if IsValid(ply) then
            if ply:IsPlayer() then
                local vm = ply:GetViewModel()
                if IsValid(vm) then
                    vm:SetSubMaterial( 1 )
                end
            end
        end
    end
    return true
end

function SWEP:OnDrop()
    if SERVER then
        self:Remove()
    end
end

function SWEP:Deploy()
    self:SendWeaponAnim(ACT_VM_HOLSTER)
        if CLIENT then
            local ply = self:GetOwner()
            if IsValid(ply) then
                if ply:IsPlayer() then
                    local vm = ply:GetViewModel()
                    if IsValid(vm) then
                        vm:SetSubMaterial( 1, "!"..self.mdf.MaterialName )
                    end
                end
            end
        end
    self:Play(ACT_VM_HOLSTER, ACT_VM_IDLE)
end

function SWEP:PrimaryAttack()

end

function SWEP:SecondaryAttack()
    if CLIENT then

    end
end