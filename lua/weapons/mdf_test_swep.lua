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

    local PlayTable = {
        maxWide = 5,
        maxHeight = 4,
        count = 0,
        info = {},
        page = 1,
        pages = {},
        maxpage = 1,
        nowPlay = {0,0},
        select = 1,
        globalY = 0,
        newglobalY = 0,
        selectpage = 1,
        volume = 40,
        selectpagepos = 1,
        scrcl = true,
        cursor = {0,0,40,40},
        tocursor = {0,0,40,40},
        curfocused = false
    }

    RecentReleasesNCS(PlayTable.page,function(info)
        -- PrintTable(info)
        for k, v in ipairs(info.Tracks) do
            v.Material = Material(v.Cover, "smooth", function( mat )
                v.Material = mat
                v.Material:SetInt( "$flags", bit.bor( v.Material:GetInt( "$flags" ), 32768 ) )
                PlayTable.info = info
                PlayTable.maxpage = tonumber(info.LastPage)
                for i = 1 , PlayTable.maxpage do
                    PlayTable.pages[i] = i
                end
            end)
        end
        PlayTable.count = #info.Tracks
    end)

    function SWEP:Initialize()
        self.mdf = MaterialScreen( "tablet_screen",2048, 2048 )
        self.mdf:SetScreenPos(0, 315)
        local vm = self:GetOwner():GetViewModel()
        if LocalPlayer() == self:GetOwner() then
            vm:SetSubMaterial( 1, "!"..self.mdf.MaterialName )
        end
        hook.Add( "PlayerBindPress", "mdf_tablet", function( ply, bind, pressed )
            if (bind == "+left" or bind == "+right") then
                return true
            end
        end )

        local soundalz = SoundAnalyze()

        soundalz:BeatEvent( SND_SA_BASS, function()
            local Power = soundalz:GetSoundPower()
            PlayTable.tocursor[1],PlayTable.tocursor[2] = PlayTable.tocursor[1]-Power/2,PlayTable.tocursor[2]-Power/2
            PlayTable.tocursor[3],PlayTable.tocursor[4] = PlayTable.tocursor[3]+Power,PlayTable.tocursor[4]+Power
        end)

        hook.Add("PlayerButtonDown","mdf_tablet",function(ply,key)
            if IsFirstTimePredicted() then
                if key == 108 then
                    PlayTable.scrcl = false
                    gui.EnableScreenClicker( PlayTable.scrcl )
                end
                if key == 89 then
                    if PlayTable.select == -2 then
                        PlayTable.volume = math.max(1,PlayTable.volume-5)
                        if IsValid(PlayTable.sound) then
                            PlayTable.sound:SetVolume(PlayTable.volume/100)
                        end
                        return
                    end
                    if PlayTable.select == -1 then
                        if PlayTable.selectpage == 1 then
                            PlayTable.selectpage = PlayTable.maxpage
                            return
                        end
                        PlayTable.selectpage = math.max(1,PlayTable.selectpage-1)
                        return
                    end
                    PlayTable.select = math.max(1,PlayTable.select-1)
                end
                if key == 91 then
                    if PlayTable.select == -2 then
                        PlayTable.volume = math.min(100,PlayTable.volume+5)
                        if IsValid(PlayTable.sound) then
                            PlayTable.sound:SetVolume(PlayTable.volume/100)
                        end
                        return
                    end
                    if PlayTable.select == -1 then
                        if PlayTable.selectpage == PlayTable.maxpage then
                            PlayTable.selectpage = 1
                            return
                        end
                        PlayTable.selectpage = math.min(PlayTable.maxpage,PlayTable.selectpage+1)
                        return
                    end
                    PlayTable.select = math.min(PlayTable.count,PlayTable.select+1)
                end
                if key == 88 then
                    if PlayTable.select == -2 then
                        return
                    end

                    if PlayTable.select == 0 then
                        PlayTable.select = -2
                        PlayTable.newglobalY = 300
                        return
                    end
                    if PlayTable.select <= 5 and PlayTable.select > -1 then
                        PlayTable.select = 0
                        PlayTable.newglobalY = 150
                        return
                    end

                    if PlayTable.select == -1 then
                        PlayTable.newglobalY = - (2048/5+50)
                        PlayTable.select = PlayTable.count
                        return
                    end

                    if PlayTable.select > 5 and PlayTable.select <= 10 then
                        PlayTable.newglobalY = 0
                    end

                    PlayTable.select = math.max(1,PlayTable.select-5)

                end

                if key == 90 then

                    if PlayTable.select == -2 then
                        PlayTable.select = 0
                        PlayTable.newglobalY = 150
                        return
                    end

                    if PlayTable.select == 0 then
                        PlayTable.newglobalY = 0
                    end
                    if PlayTable.select == -1 then return end

                    if PlayTable.select > 10 and PlayTable.select <= 15 then
                        PlayTable.newglobalY = - (2048/5+50)
                    end

                    if (PlayTable.select > 15 or PlayTable.select == PlayTable.count) and #PlayTable.pages > 1 then
                        PlayTable.newglobalY = - (2048/5+200)
                        PlayTable.select = -1
                        return
                    end

                    PlayTable.select = math.min(PlayTable.count,PlayTable.select+5)
                end
                local i = 1
                if key == 107 then
                    local rx,ry = input.GetCursorPos()
                    local cx,cy = rx*(2048/1920),ry*(1418/1080)
                    for i = 1 , #PlayTable.pages do
                        if cx >= 2048/2 + 60*((i-1) - PlayTable.selectpagepos) and cx <= 2048/2 + 60*((i-1) - PlayTable.selectpagepos) + 50 and cy >= 50 + PlayTable.globalY + 1418 + (2048/5 + 50 ) and cy <= 50 + PlayTable.globalY + 1418 + (2048/5 + 50 ) + 50 then

                            PlayTable.page = i
                            RecentReleasesNCS(PlayTable.page,function(info)
                                -- PrintTable(info)
                                for k, v in ipairs(info.Tracks) do
                                    v.Material = Material(v.Cover, "smooth", function( mat )
                                        v.Material = mat
                                        v.Material:SetInt( "$flags", bit.bor( v.Material:GetInt( "$flags" ), 32768 ) )
                                        PlayTable.info = info
                                        PlayTable.maxpage = tonumber(info.LastPage)
                                    end)
                                end
                                PlayTable.count = #info.Tracks
                            end)
                        end
                    end

                    for y = 0, PlayTable.maxHeight - 1 do
                        for x = 0, PlayTable.maxWide - 1 do

                if cx >= 25 + x*(2048/5 - 5 ) and cx <= 25 + x*(2048/5 - 5 ) + 2048/5 - 50 and cy >= 25 + PlayTable.globalY + y*(2048/5 + 50 )  and cy <= 25 + PlayTable.globalY + y*(2048/5 + 50 ) + 2048/5 then
                    if !istable(PlayTable.info.Tracks[i]) then return end
                    if i == PlayTable.nowPlay[1]  and PlayTable.page == PlayTable.nowPlay[2] then
                        if IsValid(PlayTable.sound) then
                            if PlayTable.sound:GetState() == 1 then
                                PlayTable.sound:Pause()
                                return
                            elseif PlayTable.sound:GetState() == 2 then
                                PlayTable.sound:Play()
                                return
                            end
                        end
                    end

                    PlayTable.nowPlay = {i,PlayTable.page}
                        sound.PlayURL( PlayTable.info.Tracks[PlayTable.nowPlay[1]].URL, "noplay", function( station, errCode, errStr )
                            if ( IsValid( station ) ) then
                                station:Play()
                                local vol = 0
                                timer.Create("nsc_volume",0.001,0,function()
                                    vol = vol + 0.5
                                    station:SetVolume(vol/100)
                                    if IsValid(PlayTable.sound) then
                                        PlayTable.sound:SetVolume((PlayTable.volume-vol)/100)
                                    end
                                    if vol >= PlayTable.volume then
                                        if IsValid(PlayTable.sound) then
                                            PlayTable.sound:Stop()
                                        end
                                        PlayTable.sound = station
                                        soundalz:SetAudio( PlayTable.sound )
                                        PlayTable.sound:SetVolume(PlayTable.volume/100)
                                        timer.Remove("nsc_volume")
                                    end
                                end)


                            else
                                print( "Error playing sound!", errCode, errStr )
                            end
                        end )
                end
                        i = i + 1
                        end
                    end
                end

                if key == 112  then
                    local rx,ry = input.GetCursorPos()
                    local cx,cy = rx*(2048/1920),ry*(1418/1080)
                    if cx >= 30 and cx <= 2048-8 and cy >= 40 + PlayTable.globalY - 300 and cy <= 40 + PlayTable.globalY - 300 + 70 then
                        PlayTable.volume = math.max(0,PlayTable.volume-5)
                        if IsValid(PlayTable.sound) then
                            PlayTable.sound:SetVolume(PlayTable.volume/100)
                        end
                        return
                    end
                    PlayTable.newglobalY = math.min(300,PlayTable.newglobalY + 80)
                end

                if key == 113 then
                    local rx,ry = input.GetCursorPos()
                    local cx,cy = rx*(2048/1920),ry*(1418/1080)
                    if cx >= 30 and cx <= 2048-8 and cy >= 40 + PlayTable.globalY - 300 and cy <= 40 + PlayTable.globalY - 300 + 70 then
                        PlayTable.volume = math.min(100,PlayTable.volume+5)
                        if IsValid(PlayTable.sound) then
                            PlayTable.sound:SetVolume(PlayTable.volume/100)
                        end
                        return
                    end
                    PlayTable.newglobalY = math.max(- (2048/5+200),PlayTable.newglobalY - 80)
                end

                if key == 80 then

                    if PlayTable.select == 0 or PlayTable.select == -2 then
                        PlayTable.scrcl = !PlayTable.scrcl
                        gui.EnableScreenClicker( PlayTable.scrcl )
                        return
                    end

                    if PlayTable.select == -1 then
                        PlayTable.page = PlayTable.selectpage
                        RecentReleasesNCS(PlayTable.page,function(info)
                            -- PrintTable(info)
                            for k, v in ipairs(info.Tracks) do
                                v.Material = Material(v.Cover, "smooth", function( mat )
                                    v.Material = mat
                                    v.Material:SetInt( "$flags", bit.bor( v.Material:GetInt( "$flags" ), 32768 ) )
                                    PlayTable.info = info
                                    PlayTable.maxpage = tonumber(info.LastPage)
                                end)
                            end
                            PlayTable.count = #info.Tracks
                        end)
                        return
                    end

                    if PlayTable.select != 0 or PlayTable.select != -1 then
                        if PlayTable.select == PlayTable.nowPlay[1]  and PlayTable.page == PlayTable.nowPlay[2] then
                            if IsValid(PlayTable.sound) then
                                if PlayTable.sound:GetState() == 1 then
                                    PlayTable.sound:Pause()
                                    return
                                elseif PlayTable.sound:GetState() == 2 then
                                    PlayTable.sound:Play()
                                    return
                                end
                            end
                        end


                        PlayTable.nowPlay = {PlayTable.select,PlayTable.page}

                        sound.PlayURL( PlayTable.info.Tracks[PlayTable.nowPlay[1]].URL, "noplay", function( station, errCode, errStr )
                            if ( IsValid( station ) ) then
                                station:Play()
                                local vol = 0
                                timer.Create("nsc_volume",0.001,0,function()
                                    vol = vol + 0.5
                                    station:SetVolume(vol/100)
                                    if IsValid(PlayTable.sound) then
                                        PlayTable.sound:SetVolume((PlayTable.volume-vol)/100)
                                    end
                                    if vol >= PlayTable.volume then
                                        if IsValid(PlayTable.sound) then
                                            PlayTable.sound:Stop()
                                        end
                                        PlayTable.sound = station
                                        soundalz:SetAudio( PlayTable.sound )
                                        PlayTable.sound:SetVolume(PlayTable.volume/100)
                                        timer.Remove("nsc_volume")
                                    end
                                end)


                            else
                                print( "Error playing sound!", errCode, errStr )
                            end
                        end )
                    end

                end
            end
        end)
        local font = "Default"
        function self.mdf:Draw( w, h )
            surface.SetDrawColor( Color(0,0,0,255) )
            surface.DrawRect( -100, -100, w+200, h+200 )
            PlayTable.globalY = PlayTable.globalY + (PlayTable.newglobalY - PlayTable.globalY)/11.1111
            if IsValid(soundalz) then
                if !istable(soundalz["FFT"]) then return end
                if #soundalz["FFT"]<205 then return end
                if soundalz:GetSoundPower() != nil then
                    for i = 1, 204 do
                        draw.RoundedBox(20,(i-1)*10, 0, 10, 1 + soundalz["FFT"][i]*2500,HSVToColor(((CurTime()*20)+i)%360,1,1))
                    end
                end
            end

            local cx,cy = input.GetCursorPos()
            cx,cy = cx*(w/1920) - 20,cy*(h/1080) - 20
            for i = 1 , 4 do
                PlayTable.cursor[i] = PlayTable.cursor[i] + ( PlayTable.tocursor[i] - PlayTable.cursor[i])/11.1111
            end
            draw.RoundedBox(10,PlayTable.cursor[1],PlayTable.cursor[2],PlayTable.cursor[3],PlayTable.cursor[4],Color(136,136,136,155))

           -- HSVToColor(((CurTime()*20)+i)%360,1,1)
            draw.RoundedBox(10,30,40 + PlayTable.globalY - 150,w-80,70,Color(36,36,36,155))

            if cx >= 30 and cx <= w-8 and cy >= 40 + PlayTable.globalY - 150 and cy <= 40 + PlayTable.globalY - 150 + 70 then
                PlayTable.tocursor[1] = 25
                PlayTable.tocursor[2] = 35 + PlayTable.globalY - 150
                PlayTable.tocursor[3] = w-69
                PlayTable.tocursor[4] = 80
                PlayTable.curfocused = true
            end

            draw.RoundedBox(10,40,50 + PlayTable.globalY - 150,w-100,50,(PlayTable.select == 0 and Color(150,150,150,155))  or Color(50,50,50,155))

            draw.RoundedBox(10,30,40 + PlayTable.globalY - 300,w-80,70,Color(36,36,36,155))
            draw.RoundedBox(10,40,50 + PlayTable.globalY - 288,w-100,20,(PlayTable.select == -2 and Color(150,150,150,155))  or Color(50,50,50,155))
            draw.RoundedBox(10,30 + (w-100)/100*PlayTable.volume ,40 + PlayTable.globalY - 295,26,55,Color(236,236,236,255))

            if cx >= 30 and cx <= w-8 and cy >= 40 + PlayTable.globalY - 300 and cy <= 40 + PlayTable.globalY - 300 + 70 then
                PlayTable.tocursor[1] = 25
                PlayTable.tocursor[2] = 35 + PlayTable.globalY - 300
                PlayTable.tocursor[3] = w-69
                PlayTable.tocursor[4] = 80
                PlayTable.curfocused = true
            end

            local i = 1
            for y = 0, PlayTable.maxHeight - 1 do
                for x = 0, PlayTable.maxWide - 1 do
                    if PlayTable.info.Tracks then

                        track = PlayTable.info.Tracks[i]
                        if istable(track) then
                            if cx >= 25 + x*(2048/5 - 5 ) and cx <= 25 + x*(2048/5 - 5 ) + 2048/5 - 50 and cy >= 25 + PlayTable.globalY + y*(2048/5 + 50 ) and cy <= 25 + PlayTable.globalY + y*(2048/5 + 50 ) + 2048/5 then
                                PlayTable.tocursor[1] = 20 + x*(2048/5 - 5 )
                                PlayTable.tocursor[2] = 20 + PlayTable.globalY + y*(2048/5 + 50 )
                                PlayTable.tocursor[3] = 15 + 2048/5 - 50
                                PlayTable.tocursor[4] = 15  + 2048/5 
                                PlayTable.curfocused = true
                            end
                           -- surface.SetDrawColor( (i == PlayTable.nowPlay and i == PlayTable.select and Color(50,155,50,155)) or (i == PlayTable.nowPlay and Color(0,255,0,155)) or (i == PlayTable.select and Color(150,150,150,255)) or Color(50,50,50,155) )
                          --  surface.DrawRect( 25 + x*(2048/5 - 5 ), 25 + PlayTable.globalY + y*(2048/5 + 50 ), 2048/5 - 50, 2048/5)
                            draw.RoundedBox(10,25 + x*(2048/5 - 5 ), 25 + PlayTable.globalY + y*(2048/5 + 50 ), 2048/5 - 50, 2048/5,(i == PlayTable.nowPlay[1] and PlayTable.page == PlayTable.nowPlay[2] and i == PlayTable.select and Color(50,155,50,155)) or (i == PlayTable.nowPlay[1] and PlayTable.page == PlayTable.nowPlay[2] and Color(0,255,0,155)) or (i == PlayTable.select and Color(100,100,100,255)) or Color(50,50,50,155) )

                            surface.SetDrawColor( 255, 255, 255, 255 )
                            surface.SetMaterial( track.Material )
                            surface.DrawTexturedRect( 25 + x*(2048/5 - 5 ) + 25, 25 + PlayTable.globalY + y*(2048/5 + 50 ) + 10, 2048/5 - 100 , 2048/5 - 100)

                            surface.SetFont( "CloseCaption_Normal" )
                            surface.SetTextColor( color_white )
                            surface.SetTextPos( 50 + x*(2048/5 - 5 ) , 2048/5 - 55 + PlayTable.globalY + y*(2048/5 + 50 ) )
                            surface.DrawText( track.Name)
                            surface.SetFont( "DermaLarge" )
                            surface.SetTextPos( 50 + x*(2048/5 - 5 ) , 2048/5 - 30 + PlayTable.globalY + y*(2048/5 + 50 ) )
                            surface.DrawText( track.Artist )

                        end
                    end
                    i = i + 1
                end
            end

            PlayTable.selectpagepos = PlayTable.selectpagepos + (PlayTable.selectpage - PlayTable.selectpagepos)/11.1111
            for i = 1 , #PlayTable.pages do
                draw.RoundedBox(10,w/2 + 60*((i-1) - PlayTable.selectpagepos) ,50 + PlayTable.globalY + h + (2048/5 + 50 ),50,50, (PlayTable.nowPlay[2] == i and PlayTable.selectpage == i and Color(155,0,155,155)) or (PlayTable.page == i and PlayTable.selectpage == i and Color(50,155,50,155)) or (PlayTable.nowPlay[2] == i and Color(255,0,255,155)) or (PlayTable.page == i and Color(50,255,50,155)) or (PlayTable.selectpage == i and PlayTable.select == -1 and Color(150,150,150,155)) or Color(50,50,50,155))
                surface.SetFont( "DermaLarge" )
                surface.SetTextColor( color_white )
                surface.SetTextPos( w/2 +3+ 60*((i-1) - PlayTable.selectpagepos) ,53 + PlayTable.globalY + h + (2048/5 + 50 ) )
                surface.DrawText( i )
                if cx >= w/2 + 60*((i-1) - PlayTable.selectpagepos) and cx <= w/2 + 60*((i-1) - PlayTable.selectpagepos) + 50 and cy >= 50 + PlayTable.globalY + h + (2048/5 + 50 ) and cy <= 50 + PlayTable.globalY + h + (2048/5 + 50 ) + 50 then
                    PlayTable.tocursor[1] = w/2 + 60*((i-1) - PlayTable.selectpagepos)
                    PlayTable.tocursor[2] = 50 + PlayTable.globalY + h + (2048/5 + 50 )
                    PlayTable.tocursor[3] = 50
                    PlayTable.tocursor[4] = 50 
                    PlayTable.curfocused = true
                end
                if cx >= w/2 + 60*((i-1) - PlayTable.selectpagepos) and cx <= w/2 + 60*((i-1) - PlayTable.selectpagepos) + 50 and cy >= 100 + PlayTable.globalY + h + (2048/5 + 50 ) and cy <= 70 + PlayTable.globalY + h + (2048/5 + 50 ) + 50 then
                    PlayTable.selectpage = i
                end
            end
            if !PlayTable.curfocused then
                PlayTable.tocursor[1], PlayTable.tocursor[2] = cx,cy
                PlayTable.tocursor[3] = 40
                PlayTable.tocursor[4] = 40 
            end
            PlayTable.curfocused = false
        end
    end

    function SWEP:Reload()
        self:Initialize()
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
                    gui.EnableScreenClicker( false )
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
                    gui.EnableScreenClicker( false )
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
                        gui.EnableScreenClicker( true )
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
        self.scrcl = !self.scrcl
        gui.EnableScreenClicker( self.scrcl )
    end
end