local Players=game:GetService("Players")
local RS=game:GetService("RunService")
local UIS=game:GetService("UserInputService")
local WS=game:GetService("Workspace")
local Light=game:GetService("Lighting")
local Tween=game:GetService("TweenService")
local CoreGui=game:GetService("CoreGui")
local Http=game:GetService("HttpService")
local VIM=game:GetService("VirtualInputManager")
local Cam=WS.CurrentCamera
local LP=Players.LocalPlayer

local S={
AimOn=false,AimKey=Enum.KeyCode.E,AimMode="Giữ",AimPart="Đầu",
AimSmooth=18,AimFOV=150,TeamCheck=false,WallCheck=true,
Predict=0,ShowFOV=true,FOVRainbow=false,AimHeld=false,
SnapShoot=true,SnapDur=12,SnapUntil=0,TargetPriority="Tâm Ngắm",
AutoShoot=false,TriggerBot=false,HitSound=false,
MagicRate=8,FireRateBoost=false,
EspOn=false,EspBox=true,EspBoxMode="Đầy Đủ",EspName=true,EspDist=true,EspHP=true,
EspTracer=false,EspSkel=false,EspChams=false,EspArrow=false,
EspPos="Trên",EspCol=Color3.fromRGB(0,200,255),EspRainbow=false,EspMax=1500,
SpeedOn=false,SpeedVal=32,SpeedMode="Velocity",
JumpOn=false,JumpVal=80,InfJump=false,Bunny=false,
FlyOn=false,FlySpd=80,FlyMode="CFrame",
Noclip=false,AntiVoid=false,
FOVChg=false,FOVVal=90,FullBright=false,NoFog=false,RainbowChar=false,
WMOn=true,Notify=true,CurTarget=nil,HookedMode=false,RainbowTheme=false,
Debug=false}
local CFG="oneshot_v15.json"
local conns={}

local T={
bg=Color3.fromRGB(10,12,18),
card=Color3.fromRGB(20,24,34),
cardHi=Color3.fromRGB(28,34,46),
border=Color3.fromRGB(0,170,255),
accent=Color3.fromRGB(0,200,255),
accent2=Color3.fromRGB(160,0,255),
text=Color3.fromRGB(240,240,245),
textSub=Color3.fromRGB(140,145,160),
toggleOff=Color3.fromRGB(40,44,55),
danger=Color3.fromRGB(255,60,60),
ok=Color3.fromRGB(0,255,140)}

local function notify(t,x,d)
    if not S.Notify then return end
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification",
        {Title=t,Text=x,Duration=d or 3})
    end)
end
local function getChar() return LP.Character or LP.CharacterAdded:Wait() end
local function getHum()
    local c=LP.Character
    return c and c:FindFirstChildOfClass("Humanoid")
end
local function isAlive(p)
    local c=p and p.Character
    if not c then return false end
    local h=c:FindFirstChildOfClass("Humanoid")
    return h and h.Health>0
end
local function isVis(part,targetChar)
    if not part then return false end
    local origin=Cam.CFrame.Position
    local dir=part.Position-origin
    if dir.Magnitude<0.1 then return true end
    local rp=RaycastParams.new()
    rp.FilterType=Enum.RaycastFilterType.Exclude
    rp.IgnoreWater=true
    local ex={}
    if LP.Character then table.insert(ex,LP.Character) end
    if targetChar then table.insert(ex,targetChar) end
    rp.FilterDescendantsInstances=ex
    local result=WS:Raycast(origin,dir,rp)
    if not result then return true end
    if targetChar and result.Instance:IsDescendantOf(targetChar) then
        return true
    end
    return false
end
local function rainbow(o) return Color3.fromHSV((tick()*0.4+(o or 0))%1,1,1) end
local function curAccent()
    if S.RainbowTheme then return rainbow() end
    return T.accent
end
local function w2s(pos)
    local sp,on=Cam:WorldToViewportPoint(pos)
    return Vector2.new(sp.X,sp.Y),on
end
local function partOf(char,which)
    if which=="Đầu" then return char:FindFirstChild("Head")
    elseif which=="Thân" then
        return char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
    elseif which=="Ngẫu Nhiên" then
        local t={char:FindFirstChild("Head"),
            char:FindFirstChild("UpperTorso"),
            char:FindFirstChild("LowerTorso")}
        local v={}
        for _,x in ipairs(t) do if x then table.insert(v,x) end end
        return v[math.random(1,#v)]
    elseif which=="Gần Nhất" then
        return char:FindFirstChild("HumanoidRootPart")
    else return char:FindFirstChild("Head") end
end
local function getAnyPart(char)
    return char:FindFirstChild("Head")
        or char:FindFirstChild("UpperTorso")
        or char:FindFirstChild("Torso")
        or char:FindFirstChild("HumanoidRootPart")
        or char:FindFirstChildWhichIsA("BasePart")
end

local WeaponManager=nil
local old_cast=nil
local OriginalConstants={}
local function getWeaponManager()
    if WeaponManager then return WeaponManager end
    pcall(function()
        local rs=game:GetService("ReplicatedStorage")
        local common=rs:FindFirstChild("Common")
        if not common then return end
        local managers=common:FindFirstChild("Managers")
        if not managers then return end
        local wm=managers:FindFirstChild("WeaponManager")
        if wm then
            WeaponManager=require(wm)
            if WeaponManager and WeaponManager.Constants then
                for k,v in pairs(WeaponManager.Constants) do
                    OriginalConstants[k]=v
                end
            end
        end
    end)
    return WeaponManager
end
local function hookCast()
    if S.HookedMode then return true end
    if not hookfunction then return false end
    local wm=getWeaponManager()
    if not wm or not wm.cast then return false end
    local ok=pcall(function()
        old_cast=hookfunction(wm.cast,function(origin,direction,bullet_speed,max_distance,...)
            if S.CurTarget and S.CurTarget.Parent and S.CurTarget.Parent:FindFirstChild("Humanoid") then
                local char=S.CurTarget.Parent
                local canFire=true
                if S.WallCheck and origin then
                    local rp=RaycastParams.new()
                    rp.FilterType=Enum.RaycastFilterType.Exclude
                    rp.FilterDescendantsInstances={LP.Character,char}
                    local result=WS:Raycast(origin,S.CurTarget.Position-origin,rp)
                    if result then canFire=false end
                end
                if canFire then
                    direction=(S.CurTarget.Position-origin).Unit
                    bullet_speed=9e9
                    max_distance=9e999
                end
            end
            return old_cast(origin,direction,bullet_speed,max_distance,...)
        end)
        if ok then S.HookedMode=true end
    end)
    return ok
end
local function unhookCast()
    if old_cast then
        pcall(function()
            local wm=getWeaponManager()
            if wm and wm.cast then hookfunction(wm.cast,old_cast) end
        end)
        old_cast=nil
    end
    S.HookedMode=false
end
local function applyWeaponMods(on)
    local wm=getWeaponManager()
    if not wm or not wm.Constants then return end
    if on then
        pcall(function()
            wm.Constants.DEFAULT_PISTOL_RELOAD_TIME=0
            wm.Constants.DEFAULT_PISTOL_FIRERATE=500
            wm.Constants.DEFAULT_RELOAD_TIME=0
            wm.Constants.DEFAULT_MAGAZINE=9e9
        end)
    else
        pcall(function()
            for k,v in pairs(OriginalConstants) do
                wm.Constants[k]=v
            end
        end)
    end
end
local Gui=Instance.new("ScreenGui")
Gui.Name="OneShotV15"
Gui.ResetOnSpawn=false
Gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
Gui.IgnoreGuiInset=true
pcall(function() Gui.Parent=CoreGui end)
if not Gui.Parent then Gui.Parent=LP:WaitForChild("PlayerGui") end
local blur=Instance.new("BlurEffect") blur.Size=0 blur.Parent=Light

local function isPress(i)
    return i.UserInputType==Enum.UserInputType.MouseButton1
        or i.UserInputType==Enum.UserInputType.Touch
end
local function isMove(i)
    return i.UserInputType==Enum.UserInputType.MouseMovement
        or i.UserInputType==Enum.UserInputType.Touch
end
local function tween(o,t,props)
    Tween:Create(o,TweenInfo.new(t,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),props):Play()
end

local Main=Instance.new("Frame")
Main.Size=UDim2.new(0,620,0,440)
Main.Position=UDim2.new(0.5,-310,0.5,-220)
Main.BackgroundColor3=T.bg
Main.BorderSizePixel=0
Main.Active=true
Main.Parent=Gui
Main.BackgroundTransparency=0.03
Instance.new("UICorner",Main).CornerRadius=UDim.new(0,14)
local MainStroke=Instance.new("UIStroke",Main)
MainStroke.Thickness=1.5
MainStroke.Color=T.accent
MainStroke.Transparency=0.3
local MainGrad=Instance.new("UIGradient",Main)
MainGrad.Rotation=45
MainGrad.Color=ColorSequence.new(T.accent,T.accent2)

local Header=Instance.new("Frame")
Header.Size=UDim2.new(1,0,0,44)
Header.BackgroundColor3=T.card
Header.BackgroundTransparency=0.2
Header.BorderSizePixel=0
Header.Active=true
Header.Parent=Main
Instance.new("UICorner",Header).CornerRadius=UDim.new(0,14)
local HeaderFix=Instance.new("Frame",Header)
HeaderFix.Size=UDim2.new(1,0,0,14)
HeaderFix.Position=UDim2.new(0,0,1,-14)
HeaderFix.BackgroundColor3=T.card
HeaderFix.BackgroundTransparency=0.2
HeaderFix.BorderSizePixel=0
local HeaderLine=Instance.new("Frame",Header)
HeaderLine.Size=UDim2.new(1,0,0,1)
HeaderLine.Position=UDim2.new(0,0,1,-1)
HeaderLine.BackgroundColor3=T.accent
HeaderLine.BackgroundTransparency=0.5
HeaderLine.BorderSizePixel=0

local Logo=Instance.new("TextLabel")
Logo.Size=UDim2.new(0,220,1,0)
Logo.Position=UDim2.new(0,16,0,0)
Logo.BackgroundTransparency=1
Logo.Text="ONE SHOT  v15"
Logo.TextColor3=T.text
Logo.Font=Enum.Font.GothamBold
Logo.TextSize=16
Logo.TextXAlignment=Enum.TextXAlignment.Left
Logo.Parent=Header

local Version=Instance.new("TextLabel")
Version.Size=UDim2.new(0,60,1,0)
Version.Position=UDim2.new(0,220,0,0)
Version.BackgroundTransparency=1
Version.Text="CYBER"
Version.TextColor3=T.accent
Version.Font=Enum.Font.GothamBold
Version.TextSize=11
Version.TextXAlignment=Enum.TextXAlignment.Left
Version.Parent=Header

local SearchFrame=Instance.new("Frame")
SearchFrame.Size=UDim2.new(0,150,0,26)
SearchFrame.Position=UDim2.new(1,-260,0.5,-13)
SearchFrame.BackgroundColor3=T.bg
SearchFrame.BorderSizePixel=0
SearchFrame.Parent=Header
Instance.new("UICorner",SearchFrame).CornerRadius=UDim.new(0,13)
local SearchStroke=Instance.new("UIStroke",SearchFrame)
SearchStroke.Color=T.accent SearchStroke.Thickness=1 SearchStroke.Transparency=0.6
local SearchBox=Instance.new("TextBox")
SearchBox.Size=UDim2.new(1,-16,1,0)
SearchBox.Position=UDim2.new(0,8,0,0)
SearchBox.BackgroundTransparency=1
SearchBox.Text=""
SearchBox.PlaceholderText="Tìm tính năng..."
SearchBox.PlaceholderColor3=T.textSub
SearchBox.TextColor3=T.text
SearchBox.Font=Enum.Font.Gotham
SearchBox.TextSize=12
SearchBox.TextXAlignment=Enum.TextXAlignment.Left
SearchBox.ClearTextOnFocus=false
SearchBox.Parent=SearchFrame

local function hBtn(txt,xOff,cb,col)
    local b=Instance.new("TextButton")
    b.Size=UDim2.new(0,26,0,26)
    b.Position=UDim2.new(1,xOff,0.5,-13)
    b.BackgroundColor3=T.cardHi
    b.Text=txt b.TextColor3=col or T.text
    b.Font=Enum.Font.GothamBold b.TextSize=14
    b.BorderSizePixel=0 b.Parent=Header
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,8)
    b.MouseEnter:Connect(function()
        tween(b,0.15,{BackgroundColor3=col or T.accent})
    end)
    b.MouseLeave:Connect(function()
        tween(b,0.15,{BackgroundColor3=T.cardHi})
    end)
    b.MouseButton1Click:Connect(cb)
    return b
end
hBtn("−",-66,function()
    Main.Visible=false Handle.Visible=true
    tween(blur,0.3,{Size=16})
end)
hBtn("×",-36,function() unload() end, T.danger)

local dragging=false local dStart,sPos
Header.InputBegan:Connect(function(i)
    if isPress(i) then
        dragging=true dStart=i.Position sPos=Main.Position
    end
end)
UIS.InputChanged:Connect(function(i)
    if dragging and isMove(i) then
        local d=i.Position-dStart
        Main.Position=UDim2.new(sPos.X.Scale,sPos.X.Offset+d.X,
            sPos.Y.Scale,sPos.Y.Offset+d.Y)
    end
end)
UIS.InputEnded:Connect(function(i)
    if isPress(i) then dragging=false end
end)

local Handle=Instance.new("Frame")
Handle.Size=UDim2.new(0,200,0,38)
Handle.Position=UDim2.new(0.5,-100,0,6)
Handle.BackgroundColor3=T.bg
Handle.BackgroundTransparency=0.05
Handle.BorderSizePixel=0
Handle.Active=true
Handle.Visible=false
Handle.Parent=Gui
Instance.new("UICorner",Handle).CornerRadius=UDim.new(0,10)
local HS=Instance.new("UIStroke",Handle)
HS.Color=T.accent HS.Thickness=1.5
local HG=Instance.new("UIGradient",Handle)
HG.Color=ColorSequence.new(T.accent,T.accent2)
local HLbl=Instance.new("TextLabel")
HLbl.Size=UDim2.new(1,0,1,0) HLbl.BackgroundTransparency=1
HLbl.Text="ONE SHOT v15  ▼" HLbl.TextColor3=T.text
HLbl.Font=Enum.Font.GothamBold HLbl.TextSize=13 HLbl.Parent=Handle

local hDrag=false local hStart,hPos,hMoved
Handle.InputBegan:Connect(function(i)
    if isPress(i) then
        hDrag=true hStart=i.Position hPos=Handle.Position hMoved=0
    end
end)
UIS.InputChanged:Connect(function(i)
    if hDrag and isMove(i) then
        local d=i.Position-hStart
        hMoved=d.Magnitude
        Handle.Position=UDim2.new(hPos.X.Scale,hPos.X.Offset+d.X,
            hPos.Y.Scale,hPos.Y.Offset+d.Y)
    end
end)
UIS.InputEnded:Connect(function(i)
    if isPress(i) and hDrag then
        hDrag=false
        if hMoved<8 then
            Main.Visible=true Handle.Visible=false
            tween(blur,0.3,{Size=0})
        end
    end
end)

local Sidebar=Instance.new("Frame")
Sidebar.Size=UDim2.new(0,140,1,-92)
Sidebar.Position=UDim2.new(0,0,0,44)
Sidebar.BackgroundColor3=T.card
Sidebar.BackgroundTransparency=0.3
Sidebar.BorderSizePixel=0
Sidebar.Parent=Main

local Content=Instance.new("Frame")
Content.Size=UDim2.new(1,-150,1,-100)
Content.Position=UDim2.new(0,144,0,50)
Content.BackgroundTransparency=1
Content.Parent=Main

local Footer=Instance.new("Frame")
Footer.Size=UDim2.new(1,0,0,22)
Footer.Position=UDim2.new(0,0,1,-22)
Footer.BackgroundColor3=T.card
Footer.BackgroundTransparency=0.3
Footer.BorderSizePixel=0
Footer.Parent=Main
Instance.new("UICorner",Footer).CornerRadius=UDim.new(0,14)
local FFooterFix=Instance.new("Frame",Footer)
FFooterFix.Size=UDim2.new(1,0,0,14)
FFooterFix.Position=UDim2.new(0,0,0,0)
FFooterFix.BackgroundColor3=T.card
FFooterFix.BackgroundTransparency=0.3
FFooterFix.BorderSizePixel=0
local FooterText=Instance.new("TextLabel")
FooterText.Size=UDim2.new(1,0,1,0)
FooterText.BackgroundTransparency=1
FooterText.Text="FPS: -- | Ping: -- | Hook: OFF | v15"
FooterText.TextColor3=T.textSub
FooterText.Font=Enum.Font.Gotham
FooterText.TextSize=11
FooterText.Parent=Footer

local Pages={}
local function newPage(n)
    local p=Instance.new("ScrollingFrame")
    p.Size=UDim2.new(1,0,1,0)
    p.BackgroundTransparency=1
    p.BorderSizePixel=0
    p.ScrollBarThickness=4
    p.ScrollBarImageColor3=T.accent
    p.CanvasSize=UDim2.new(0,0,0,0)
    p.AutomaticCanvasSize=Enum.AutomaticSize.Y
    p.Visible=false p.Parent=Content
    local lay=Instance.new("UIListLayout",p)
    lay.Padding=UDim.new(0,8)
    lay.SortOrder=Enum.SortOrder.LayoutOrder
    Pages[n]=p return p
end
local function selPage(n)
    for k,v in pairs(Pages) do v.Visible=(k==n) end
end
local tabs={}
local tabIcons={Ngắm="[A]",ESP="[E]",["Di Chuyển"]="[M]",
    ["Chiến Đấu"]="[C]",["Hiển Thị"]="[V]",["Cấu Hình"]="[S]"}
local function mkTab(n,o)
    local b=Instance.new("TextButton")
    b.Size=UDim2.new(1,-16,0,44)
    b.Position=UDim2.new(0,8,0,8+(o-1)*48)
    b.BackgroundColor3=T.cardHi
    b.BackgroundTransparency=1
    b.BorderSizePixel=0
    b.Text=""
    b.AutoButtonColor=false
    b.Parent=Sidebar
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,10)
    local glow=Instance.new("Frame",b)
    glow.Size=UDim2.new(0,3,0,0)
    glow.Position=UDim2.new(0,0,0.5,0)
    glow.AnchorPoint=Vector2.new(0,0.5)
    glow.BackgroundColor3=T.accent
    glow.BorderSizePixel=0
    Instance.new("UICorner",glow).CornerRadius=UDim.new(0,2)
    local ico=Instance.new("TextLabel",b)
    ico.Size=UDim2.new(0,30,1,0) ico.Position=UDim2.new(0,10,0,0)
    ico.BackgroundTransparency=1
    ico.Text=tabIcons[n] or "•"
    ico.TextColor3=T.text
    ico.Font=Enum.Font.GothamBold ico.TextSize=14
    ico.TextXAlignment=Enum.TextXAlignment.Left
    local lbl=Instance.new("TextLabel",b)
    lbl.Size=UDim2.new(1,-46,1,0) lbl.Position=UDim2.new(0,42,0,0)
    lbl.BackgroundTransparency=1
    lbl.Text=n
    lbl.TextColor3=T.textSub
    lbl.Font=Enum.Font.GothamBold lbl.TextSize=13
    lbl.TextXAlignment=Enum.TextXAlignment.Left
    local function setActive(on)
        if on then
            b.BackgroundTransparency=0
            b.BackgroundColor3=T.cardHi
            ico.TextColor3=T.accent
            lbl.TextColor3=T.text
            tween(glow,0.2,{Size=UDim2.new(0,3,0,28)})
        else
            b.BackgroundTransparency=1
            ico.TextColor3=T.textSub
            lbl.TextColor3=T.textSub
            tween(glow,0.2,{Size=UDim2.new(0,3,0,0)})
        end
    end
    b.MouseEnter:Connect(function()
        if not b:GetAttribute("active") then b.BackgroundTransparency=0.6 end
    end)
    b.MouseLeave:Connect(function()
        if not b:GetAttribute("active") then b.BackgroundTransparency=1 end
    end)
    b.MouseButton1Click:Connect(function()
        selPage(n)
        for _,x in ipairs(tabs) do
            x.bg:SetAttribute("active",false)
            x.setActive(false)
        end
        b:SetAttribute("active",true)
        setActive(true)
    end)
    table.insert(tabs,{bg=b,setActive=setActive})
    newPage(n)
    return b
end
local function sec(pg,t)
    local f=Instance.new("Frame")
    f.Size=UDim2.new(1,0,0,34)
    f.BackgroundTransparency=1
    f.Parent=pg
    local l=Instance.new("TextLabel")
    l.Size=UDim2.new(1,0,1,0)
    l.BackgroundTransparency=1
    l.Text="▬  "..t
    l.TextColor3=T.accent
    l.Font=Enum.Font.GothamBold l.TextSize=13
    l.TextXAlignment=Enum.TextXAlignment.Left
    l.Parent=f
end

local function tgl(pg,t,d,cb)
    local card=Instance.new("Frame")
    card.Size=UDim2.new(1,-4,0,36)
    card.BackgroundColor3=T.card
    card.BorderSizePixel=0
    card.Parent=pg
    Instance.new("UICorner",card).CornerRadius=UDim.new(0,10)
    local stk=Instance.new("UIStroke",card)
    stk.Color=T.accent stk.Thickness=1 stk.Transparency=0.7
    local lbl=Instance.new("TextLabel",card)
    lbl.Size=UDim2.new(1,-70,1,0)
    lbl.Position=UDim2.new(0,12,0,0)
    lbl.BackgroundTransparency=1
    lbl.Text=t
    lbl.TextColor3=T.text
    lbl.Font=Enum.Font.Gotham
    lbl.TextSize=13
    lbl.TextXAlignment=Enum.TextXAlignment.Left
    local track=Instance.new("Frame",card)
    track.Size=UDim2.new(0,44,0,22)
    track.Position=UDim2.new(1,-56,0.5,-11)
    track.BackgroundColor3=d and T.accent or T.toggleOff
    track.BorderSizePixel=0
    Instance.new("UICorner",track).CornerRadius=UDim.new(0,11)
    local knob=Instance.new("Frame",track)
    knob.Size=UDim2.new(0,16,0,16)
    knob.Position=d and UDim2.new(1,-20,0.5,-8) or UDim2.new(0,3,0.5,-8)
    knob.BackgroundColor3=Color3.fromRGB(255,255,255)
    knob.BorderSizePixel=0
    Instance.new("UICorner",knob).CornerRadius=UDim.new(1,0)
    local btn=Instance.new("TextButton",card)
    btn.Size=UDim2.new(1,0,1,0)
    btn.BackgroundTransparency=1
    btn.Text=""
    btn.ZIndex=5
    local st=d
    btn.MouseButton1Click:Connect(function()
        st=not st
        if st then
            tween(track,0.15,{BackgroundColor3=T.accent})
            tween(knob,0.15,{Position=UDim2.new(1,-20,0.5,-8)})
            tween(card,0.2,{BackgroundColor3=T.cardHi})
            tween(stk,0.2,{Transparency=0.3})
        else
            tween(track,0.15,{BackgroundColor3=T.toggleOff})
            tween(knob,0.15,{Position=UDim2.new(0,3,0.5,-8)})
            tween(card,0.2,{BackgroundColor3=T.card})
            tween(stk,0.2,{Transparency=0.7})
        end
        cb(st)
    end)
    card.MouseEnter:Connect(function()
        tween(card,0.15,{BackgroundColor3=T.cardHi})
    end)
    card.MouseLeave:Connect(function()
        if not st then tween(card,0.15,{BackgroundColor3=T.card}) end
    end)
    return card
end

local function sld(pg,t,mn,mx,d,cb)
    local card=Instance.new("Frame")
    card.Size=UDim2.new(1,-4,0,52)
    card.BackgroundColor3=T.card
    card.BorderSizePixel=0
    card.Parent=pg
    Instance.new("UICorner",card).CornerRadius=UDim.new(0,10)
    local stk=Instance.new("UIStroke",card)
    stk.Color=T.accent stk.Thickness=1 stk.Transparency=0.7
    local lbl=Instance.new("TextLabel",card)
    lbl.Size=UDim2.new(1,-70,0,20)
    lbl.Position=UDim2.new(0,12,0,4)
    lbl.BackgroundTransparency=1
    lbl.Text=t
    lbl.TextColor3=T.text
    lbl.Font=Enum.Font.Gotham lbl.TextSize=13
    lbl.TextXAlignment=Enum.TextXAlignment.Left
    local val=Instance.new("TextLabel",card)
    val.Size=UDim2.new(0,60,0,20)
    val.Position=UDim2.new(1,-72,0,4)
    val.BackgroundTransparency=1
    val.Text=tostring(d)
    val.TextColor3=T.accent
    val.Font=Enum.Font.GothamBold val.TextSize=13
    val.TextXAlignment=Enum.TextXAlignment.Right
    local bar=Instance.new("Frame",card)
    bar.Size=UDim2.new(1,-24,0,10)
    bar.Position=UDim2.new(0,12,0,32)
    bar.BackgroundColor3=T.toggleOff
    bar.BorderSizePixel=0
    bar.Active=true
    Instance.new("UICorner",bar).CornerRadius=UDim.new(0,5)
    local fill=Instance.new("Frame",bar)
    fill.Size=UDim2.new((d-mn)/(mx-mn),0,1,0)
    fill.BackgroundColor3=T.accent
    fill.BorderSizePixel=0
    fill.Active=false
    Instance.new("UICorner",fill).CornerRadius=UDim.new(0,5)
    local fillGrad=Instance.new("UIGradient",fill)
    fillGrad.Color=ColorSequence.new(T.accent,T.accent2)
    local knob=Instance.new("Frame",fill)
    knob.Size=UDim2.new(0,14,0,14)
    knob.Position=UDim2.new(1,-7,0.5,-7)
    knob.BackgroundColor3=Color3.fromRGB(255,255,255)
    knob.BorderSizePixel=0
    Instance.new("UICorner",knob).CornerRadius=UDim.new(1,0)
    local drg=false
    local function upd(x)
        local r=math.clamp((x-bar.AbsolutePosition.X)/math.max(bar.AbsoluteSize.X,1),0,1)
        local v=math.floor(mn+r*(mx-mn)+0.5)
        fill.Size=UDim2.new(r,0,1,0)
        val.Text=tostring(v)
        cb(v)
    end
    bar.InputBegan:Connect(function(i)
        if isPress(i) then drg=true upd(i.Position.X) end
    end)
    UIS.InputChanged:Connect(function(i)
        if drg and isMove(i) then upd(i.Position.X) end
    end)
    UIS.InputEnded:Connect(function(i)
        if isPress(i) and drg then drg=false end
    end)
    return card
end

local function drp(pg,t,opts,d,cb)
    local card=Instance.new("Frame")
    card.Size=UDim2.new(1,-4,0,36)
    card.BackgroundColor3=T.card
    card.BorderSizePixel=0
    card.Parent=pg
    Instance.new("UICorner",card).CornerRadius=UDim.new(0,10)
    local stk=Instance.new("UIStroke",card)
    stk.Color=T.accent stk.Thickness=1 stk.Transparency=0.7
    local lbl=Instance.new("TextLabel",card)
    lbl.Size=UDim2.new(1,-100,1,0)
    lbl.Position=UDim2.new(0,12,0,0)
    lbl.BackgroundTransparency=1
    lbl.Text=t
    lbl.TextColor3=T.text
    lbl.Font=Enum.Font.Gotham lbl.TextSize=13
    lbl.TextXAlignment=Enum.TextXAlignment.Left
    local b=Instance.new("TextButton",card)
    b.Size=UDim2.new(0,90,1,0)
    b.Position=UDim2.new(1,-96,0,0)
    b.BackgroundTransparency=1
    b.Text=d.."  ▼"
    b.TextColor3=T.accent
    b.Font=Enum.Font.GothamBold b.TextSize=12
    b.TextXAlignment=Enum.TextXAlignment.Right
    local ls=Instance.new("Frame")
    ls.BackgroundColor3=T.cardHi
    ls.BorderSizePixel=0
    ls.Visible=false ls.ZIndex=9999 ls.Parent=Gui
    Instance.new("UICorner",ls).CornerRadius=UDim.new(0,10)
    local lstk=Instance.new("UIStroke",ls)
    lstk.Color=T.accent lstk.Thickness=1
    for i,o in ipairs(opts) do
        local ob=Instance.new("TextButton")
        ob.Size=UDim2.new(1,0,0,30)
        ob.Position=UDim2.new(0,0,0,(i-1)*30)
        ob.BackgroundTransparency=1
        ob.Text=(o==d and "✓  " or "     ")..o
        ob.TextColor3=o==d and T.accent or T.text
        ob.Font=Enum.Font.Gotham ob.TextSize=13
        ob.TextXAlignment=Enum.TextXAlignment.Left
        ob.ZIndex=10000 ob.Parent=ls
        Instance.new("UIPadding",ob).PaddingLeft=UDim.new(0,10)
        ob.MouseEnter:Connect(function()
            ob.BackgroundTransparency=0.7
            ob.BackgroundColor3=T.accent
        end)
        ob.MouseLeave:Connect(function()
            ob.BackgroundTransparency=1
        end)
        ob.MouseButton1Click:Connect(function()
            b.Text=o.."  ▼"
            ls.Visible=false
            cb(o)
        end)
    end
    b.MouseButton1Click:Connect(function()
        if ls.Visible then ls.Visible=false return end
        ls.Size=UDim2.new(0,card.AbsoluteSize.X,0,#opts*30)
        ls.Position=UDim2.new(0,card.AbsolutePosition.X,
            0,card.AbsolutePosition.Y+card.AbsoluteSize.Y+2)
        ls.Visible=true
    end)
    return card
end

local function kb(pg,t,d,cb)
    local card=Instance.new("Frame")
    card.Size=UDim2.new(1,-4,0,36)
    card.BackgroundColor3=T.card
    card.BorderSizePixel=0
    card.Parent=pg
    Instance.new("UICorner",card).CornerRadius=UDim.new(0,10)
    local stk=Instance.new("UIStroke",card)
    stk.Color=T.accent stk.Thickness=1 stk.Transparency=0.7
    local lbl=Instance.new("TextLabel",card)
    lbl.Size=UDim2.new(1,-100,1,0)
    lbl.Position=UDim2.new(0,12,0,0)
    lbl.BackgroundTransparency=1
    lbl.Text=t
    lbl.TextColor3=T.text
    lbl.Font=Enum.Font.Gotham lbl.TextSize=13
    lbl.TextXAlignment=Enum.TextXAlignment.Left
    local b=Instance.new("TextButton",card)
    b.Size=UDim2.new(0,70,0,24)
    b.Position=UDim2.new(1,-78,0.5,-12)
    b.BackgroundColor3=T.cardHi
    b.Text=d.Name
    b.TextColor3=T.accent
    b.Font=Enum.Font.GothamBold b.TextSize=12
    b.BorderSizePixel=0
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,6)
    local li=false
    b.MouseButton1Click:Connect(function()
        li=true b.Text="..."
    end)
    UIS.InputBegan:Connect(function(i,gp)
        if li and i.UserInputType==Enum.UserInputType.Keyboard then
            b.Text=i.KeyCode.Name
            li=false
            cb(i.KeyCode)
        end
    end)
    return card
end

local function mkBtn(pg,t,cb)
    local b=Instance.new("TextButton")
    b.Size=UDim2.new(1,-4,0,36)
    b.BackgroundColor3=T.accent
    b.Text=t
    b.TextColor3=Color3.fromRGB(255,255,255)
    b.Font=Enum.Font.GothamBold b.TextSize=13
    b.BorderSizePixel=0
    b.AutoButtonColor=false
    b.Parent=pg
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,10)
    local g=Instance.new("UIGradient",b)
    g.Color=ColorSequence.new(T.accent,T.accent2)
    b.MouseEnter:Connect(function()
        tween(b,0.15,{BackgroundColor3=T.accent2})
    end)
    b.MouseLeave:Connect(function()
        tween(b,0.15,{BackgroundColor3=T.accent})
    end)
    b.MouseButton1Click:Connect(cb)
    return b
end
local toastHolder=Instance.new("Frame")
toastHolder.Size=UDim2.new(0,300,1,0)
toastHolder.Position=UDim2.new(1,-320,0,20)
toastHolder.BackgroundTransparency=1
toastHolder.Parent=Gui
local toastList=Instance.new("UIListLayout",toastHolder)
toastList.Padding=UDim.new(0,8)
toastList.HorizontalAlignment=Enum.HorizontalAlignment.Right
toastList.VerticalAlignment=Enum.VerticalAlignment.Top

local function toast(title,text,kind)
    local c=kind=="err" and T.danger or kind=="warn" and Color3.fromRGB(255,180,0) or T.ok
    local f=Instance.new("Frame")
    f.Size=UDim2.new(1,0,0,52)
    f.BackgroundColor3=T.card
    f.BorderSizePixel=0
    f.Parent=toastHolder
    Instance.new("UICorner",f).CornerRadius=UDim.new(0,10)
    local s=Instance.new("UIStroke",f)
    s.Color=c s.Thickness=1.5
    local bar=Instance.new("Frame",f)
    bar.Size=UDim2.new(0,4,1,-12)
    bar.Position=UDim2.new(0,4,0,6)
    bar.BackgroundColor3=c
    bar.BorderSizePixel=0
    Instance.new("UICorner",bar).CornerRadius=UDim.new(1,0)
    local ico=Instance.new("TextLabel",f)
    ico.Size=UDim2.new(0,30,1,0) ico.Position=UDim2.new(0,14,0,0)
    ico.BackgroundTransparency=1
    ico.Text=kind=="err" and "✗" or kind=="warn" and "⚠" or "✓"
    ico.TextColor3=c
    ico.Font=Enum.Font.GothamBold ico.TextSize=18
    local tt=Instance.new("TextLabel",f)
    tt.Size=UDim2.new(1,-52,0,20)
    tt.Position=UDim2.new(0,46,0,6)
    tt.BackgroundTransparency=1
    tt.Text=title
    tt.TextColor3=T.text
    tt.Font=Enum.Font.GothamBold tt.TextSize=13
    tt.TextXAlignment=Enum.TextXAlignment.Left
    local tx=Instance.new("TextLabel",f)
    tx.Size=UDim2.new(1,-52,0,16)
    tx.Position=UDim2.new(0,46,0,26)
    tx.BackgroundTransparency=1
    tx.Text=text
    tx.TextColor3=T.textSub
    tx.Font=Enum.Font.Gotham tx.TextSize=11
    tx.TextXAlignment=Enum.TextXAlignment.Left
    f.Position=UDim2.new(1,0,0,0)
    tween(f,0.3,{Position=UDim2.new(0,0,0,0)})
    task.delay(2.5,function()
        tween(f,0.3,{Position=UDim2.new(1,0,0,0),BackgroundTransparency=1})
        task.wait(0.4)
        f:Destroy()
    end)
end

mkTab("Ngắm",1) mkTab("ESP",2) mkTab("Di Chuyển",3)
mkTab("Chiến Đấu",4) mkTab("Hiển Thị",5) mkTab("Cấu Hình",6)
selPage("Ngắm")
tabs[1].bg:SetAttribute("active",true)
tabs[1].setActive(true)

local AP=Pages["Ngắm"]
sec(AP,"NGẮM TỰ ĐỘNG")
tgl(AP,"Bật Ngắm",false,function(v) S.AimOn=v end)
kb(AP,"Phím Ngắm",Enum.KeyCode.E,function(k) S.AimKey=k end)
drp(AP,"Chế Độ",{"Giữ","Bật Tắt"},"Giữ",function(v) S.AimMode=v end)
drp(AP,"Bộ Phận",{"Đầu","Thân","Ngẫu Nhiên","Gần Nhất"},"Đầu",function(v) S.AimPart=v end)
drp(AP,"Ưu Tiên",{"Tâm Ngắm","Khoảng Cách","Máu"},"Tâm Ngắm",function(v) S.TargetPriority=v end)
sld(AP,"Độ Mượt x100",1,100,18,function(v) S.AimSmooth=v end)
sld(AP,"Phạm Vi Ngắm",20,600,150,function(v) S.AimFOV=v end)
tgl(AP,"Bỏ Qua Đồng Đội",false,function(v) S.TeamCheck=v end)
tgl(AP,"Kiểm Tra Tường",true,function(v) S.WallCheck=v end)
sld(AP,"Dự Đoán x100",0,50,0,function(v) S.Predict=v end)
sec(AP,"NÂNG CAO")
tgl(AP,"Khóa Khi Bắn",true,function(v) S.SnapShoot=v end)
sld(AP,"Thời Gian Khóa x10ms",5,50,12,function(v) S.SnapDur=v end)
tgl(AP,"Âm Trúng Đích",false,function(v) S.HitSound=v end)
sec(AP,"VÒNG NGẮM")
tgl(AP,"Hiện Vòng Ngắm",true,function(v) S.ShowFOV=v end)
tgl(AP,"Cầu Vồng",false,function(v) S.FOVRainbow=v end)

local Fov=Drawing.new("Circle")
Fov.Thickness=1.5 Fov.NumSides=64 Fov.Transparency=1
Fov.Filled=false Fov.Visible=false

local EP=Pages["ESP"]
sec(EP,"BẬT ESP")
tgl(EP,"Bật ESP",false,function(v) S.EspOn=v end)
tgl(EP,"Khung Box",true,function(v) S.EspBox=v end)
drp(EP,"Kiểu Box",{"Đầy Đủ","4 Góc"},"Đầy Đủ",function(v) S.EspBoxMode=v end)
tgl(EP,"Tên",true,function(v) S.EspName=v end)
tgl(EP,"Khoảng Cách",true,function(v) S.EspDist=v end)
tgl(EP,"Thanh Máu",true,function(v) S.EspHP=v end)
sec(EP,"CHI TIẾT")
tgl(EP,"Xương Skeleton",false,function(v) S.EspSkel=v end)
tgl(EP,"Đường Chỉ Tracer",false,function(v) S.EspTracer=v end)
tgl(EP,"Viền Sáng Chams",false,function(v) S.EspChams=v end)
tgl(EP,"Mũi Tên Off-screen",false,function(v) S.EspArrow=v end)
sec(EP,"KIỂU")
drp(EP,"Vị Trí Text",{"Trên","Giữa","Dưới"},"Trên",function(v) S.EspPos=v end)
tgl(EP,"Màu Cầu Vồng",false,function(v) S.EspRainbow=v end)
sld(EP,"Khoảng Cách Tối Đa",100,5000,1500,function(v) S.EspMax=v end)

local MP=Pages["Di Chuyển"]
sec(MP,"TỐC ĐỘ")
tgl(MP,"Bật Tốc Độ",false,function(v)
    S.SpeedOn=v
    if not v then
        local h=getHum() if h then h.WalkSpeed=16 end
        if speedLV then speedLV:Destroy() speedLV=nil end
        if speedAtt then speedAtt:Destroy() speedAtt=nil end
    end
end)
drp(MP,"Kiểu Speed",{"Velocity","WalkSpeed"},"Velocity",function(v) S.SpeedMode=v end)
sld(MP,"Giá Trị",16,300,32,function(v) S.SpeedVal=v end)
sec(MP,"NHẢY")
tgl(MP,"Lực Nhảy",false,function(v)
    S.JumpOn=v
    local h=getHum()
    if h then h.UseJumpPower=true h.JumpPower=v and S.JumpVal or 50 end
end)
sld(MP,"Giá Trị Nhảy",50,500,80,function(v) S.JumpVal=v end)
tgl(MP,"Nhảy Vô Hạn",false,function(v) S.InfJump=v end)
tgl(MP,"Nhảy Liên Tục",false,function(v) S.Bunny=v end)
sec(MP,"BAY")
tgl(MP,"Bật Bay",false,function(v) S.FlyOn=v end)
drp(MP,"Kiểu Bay",{"CFrame","Velocity"},"CFrame",function(v)
    S.FlyMode=v
    if S.FlyOn then stopFly() task.wait(0.1) startFly() end
end)
sld(MP,"Tốc Độ Bay",10,500,80,function(v) S.FlySpd=v end)
sec(MP,"KHÁC")
tgl(MP,"Xuyên Tường",false,function(v) S.Noclip=v end)
tgl(MP,"Chống Rớt Map",false,function(v) S.AntiVoid=v end)

local flyLV,flyAtt,flyConn,flyGyro
local speedLV,speedAtt
local FK={W=false,A=false,S=false,D=false,SP=false,CT=false}
local function stopFly()
    if flyConn then flyConn:Disconnect() flyConn=nil end
    if flyLV then flyLV:Destroy() flyLV=nil end
    if flyAtt then flyAtt:Destroy() flyAtt=nil end
    if flyGyro then flyGyro:Destroy() flyGyro=nil end
    local h=getHum()
    if h then h.PlatformStand=false h.WalkSpeed=16 end
end
local function getMoveVec()
    local cam=Cam.CFrame
    local mv=Vector3.zero
    if FK.W then mv=mv+cam.LookVector end
    if FK.S then mv=mv-cam.LookVector end
    if FK.A then mv=mv-cam.RightVector end
    if FK.D then mv=mv+cam.RightVector end
    if FK.SP then mv=mv+Vector3.new(0,1,0) end
    if FK.CT then mv=mv-Vector3.new(0,1,0) end
    if mv.Magnitude>0 then mv=mv.Unit end
    return mv
end
local function startFlyVelocity()
    local c=getChar()
    local hrp=c:WaitForChild("HumanoidRootPart",5)
    local hum=c:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end
    hum.PlatformStand=true
    flyAtt=Instance.new("Attachment") flyAtt.Parent=hrp
    flyLV=Instance.new("LinearVelocity")
    flyLV.Attachment0=flyAtt
    flyLV.MaxForce=math.huge
    flyLV.VectorVelocity=Vector3.zero
    flyLV.Parent=hrp
    flyGyro=Instance.new("AlignOrientation")
    flyGyro.Mode=Enum.OrientationAlignmentMode.OneAttachment
    flyGyro.Attachment0=flyAtt
    flyGyro.MaxTorque=math.huge
    flyGyro.Responsiveness=200
    flyGyro.Parent=hrp
    if flyConn then flyConn:Disconnect() end
    flyConn=RS.RenderStepped:Connect(function()
        if not S.FlyOn then return end
        local c2=LP.Character
        if not c2 then return end
        local hrp2=c2:FindFirstChild("HumanoidRootPart")
        if not hrp2 then return end
        if not flyLV or not flyLV.Parent then
            flyAtt=Instance.new("Attachment") flyAtt.Parent=hrp2
            flyLV=Instance.new("LinearVelocity")
            flyLV.Attachment0=flyAtt
            flyLV.MaxForce=math.huge
            flyLV.VectorVelocity=Vector3.zero
            flyLV.Parent=hrp2
        end
        local hum2=c2:FindFirstChildOfClass("Humanoid")
        if hum2 and not hum2.PlatformStand then hum2.PlatformStand=true end
        flyLV.VectorVelocity=getMoveVec()*S.FlySpd
        if flyGyro then flyGyro.CFrame=Cam.CFrame end
    end)
    toast("Bay","Velocity mode")
end
local function startFlyCFrame()
    local c=getChar()
    local hrp=c:WaitForChild("HumanoidRootPart",5)
    local hum=c:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end
    hum.PlatformStand=true
    if flyConn then flyConn:Disconnect() end
    flyConn=RS.RenderStepped:Connect(function(dt)
        if not S.FlyOn then return end
        local c2=LP.Character
        if not c2 then return end
        local hrp2=c2:FindFirstChild("HumanoidRootPart")
        local hum2=c2:FindFirstChildOfClass("Humanoid")
        if not hrp2 then return end
        if hum2 and not hum2.PlatformStand then hum2.PlatformStand=true end
        local mv=getMoveVec()
        if mv.Magnitude>0 then
            hrp2.CFrame=hrp2.CFrame+mv*(S.FlySpd*dt)
        end
    end)
    toast("Bay","CFrame mode")
end
local function startFly()
    if S.FlyMode=="CFrame" then startFlyCFrame()
    else startFlyVelocity() end
end

local CP=Pages["Chiến Đấu"]
sec(CP,"AUTO SHOOT")
tgl(CP,"Bật Auto Shoot",false,function(v)
    S.AutoShoot=v
    if v then
        local ok=hookCast()
        if ok then toast("Auto Shoot","Đã hook WeaponManager!")
        else toast("Auto Shoot","Không hook được, fallback aim camera","warn") end
    else
        unhookCast()
    end
end)
sld(CP,"Tốc Độ Bắn x10ms",3,50,8,function(v) S.MagicRate=v end)
tgl(CP,"Bắn Khi Thấy Tâm",false,function(v) S.TriggerBot=v end)
sec(CP,"MOD SÚNG")
tgl(CP,"Tăng Tốc Bắn + Vô Hạn Đạn",false,function(v)
    S.FireRateBoost=v
    applyWeaponMods(v)
    if v then toast("Mod Súng","Đã áp dụng") end
end)

local VP=Pages["Hiển Thị"]
sec(VP,"CAMERA")
tgl(VP,"Đổi FOV",false,function(v)
    S.FOVChg=v
    Cam.FieldOfView=v and S.FOVVal or 70
end)
sld(VP,"Giá Trị FOV",70,120,90,function(v)
    S.FOVVal=v
    if S.FOVChg then Cam.FieldOfView=v end
end)
sec(VP,"ÁNH SÁNG")
tgl(VP,"Sáng Toàn Map",false,function(v)
    S.FullBright=v
    if v then
        Light.Brightness=3 Light.ClockTime=14
        Light.Ambient=Color3.fromRGB(180,180,180)
        Light.OutdoorAmbient=Color3.fromRGB(180,180,180)
    else Light.Brightness=1 end
end)
tgl(VP,"Xóa Sương Mù",false,function(v)
    S.NoFog=v
    Light.FogEnd=v and 1e6 or 100000
end)
sec(VP,"NHÂN VẬT")
tgl(VP,"Nhân Vật Cầu Vồng",false,function(v) S.RainbowChar=v end)
sec(VP,"GIAO DIỆN")
tgl(VP,"Watermark",true,function(v) S.WMOn=v WM.Visible=v end)
tgl(VP,"Theme Rainbow",false,function(v) S.RainbowTheme=v end)
tgl(VP,"Thông Báo",true,function(v) S.Notify=v end)
sec(VP,"DEBUG")
tgl(VP,"Hiện Debug HUD",false,function(v) S.Debug=v end)

local CgP=Pages["Cấu Hình"]
sec(CgP,"LƯU / TẢI")
mkBtn(CgP,"Lưu Cấu Hình",function()
    local d={}
    for k,v in pairs(S) do
        if type(v)=="number" or type(v)=="boolean" or type(v)=="string" then
            d[k]=v
        end
    end
    if writefile then
        writefile(CFG,Http:JSONEncode(d))
        toast("Cấu Hình","Đã lưu!")
    end
end)
mkBtn(CgP,"Tải Cấu Hình",function()
    if isfile and isfile(CFG) and readfile then
        local ok,d=pcall(function() return Http:JSONDecode(readfile(CFG)) end)
        if ok then
            for k,v in pairs(d) do S[k]=v end
            toast("Cấu Hình","Đã tải! (cần bật lại toggle)")
        end
    end
end)
sec(CgP,"SCRIPT")
mkBtn(CgP,"Gỡ Script + Reset",function() unload() end)

local WM=Instance.new("TextLabel")
WM.Size=UDim2.new(0,340,0,26) WM.Position=UDim2.new(0,12,0,12)
WM.BackgroundColor3=T.bg
WM.BackgroundTransparency=0.2
WM.TextColor3=T.accent
WM.Font=Enum.Font.GothamBold WM.TextSize=13
WM.Text="ONE SHOT v15" WM.Parent=Gui
Instance.new("UICorner",WM).CornerRadius=UDim.new(0,8)
local WMS=Instance.new("UIStroke",WM)
WMS.Color=T.accent WMS.Thickness=1 WMS.Transparency=0.3
local EspData={}
local function newEsp(plr)
    local d={}
    d.name=Drawing.new("Text")
    d.name.Size=14 d.name.Center=true d.name.Outline=true
    d.name.OutlineColor=Color3.new(0,0,0) d.name.Visible=false
    d.name.Font=2
    d.dist=Drawing.new("Text")
    d.dist.Size=12 d.dist.Center=true d.dist.Outline=true
    d.dist.OutlineColor=Color3.new(0,0,0) d.dist.Visible=false
    d.dist.Font=2
    d.bT=Drawing.new("Line") d.bT.Thickness=1.2 d.bT.Visible=false
    d.bB=Drawing.new("Line") d.bB.Thickness=1.2 d.bB.Visible=false
    d.bL=Drawing.new("Line") d.bL.Thickness=1.2 d.bL.Visible=false
    d.bR=Drawing.new("Line") d.bR.Thickness=1.2 d.bR.Visible=false
    d.c1=Drawing.new("Line") d.c1.Thickness=1.5 d.c1.Visible=false
    d.c2=Drawing.new("Line") d.c2.Thickness=1.5 d.c2.Visible=false
    d.c3=Drawing.new("Line") d.c3.Thickness=1.5 d.c3.Visible=false
    d.c4=Drawing.new("Line") d.c4.Thickness=1.5 d.c4.Visible=false
    d.c5=Drawing.new("Line") d.c5.Thickness=1.5 d.c5.Visible=false
    d.c6=Drawing.new("Line") d.c6.Thickness=1.5 d.c5.Visible=false
    d.c7=Drawing.new("Line") d.c7.Thickness=1.5 d.c7.Visible=false
    d.c8=Drawing.new("Line") d.c8.Thickness=1.5 d.c8.Visible=false
    d.tracer=Drawing.new("Line")
    d.tracer.Thickness=1 d.tracer.Transparency=0.85 d.tracer.Visible=false
    d.arrow=Drawing.new("Triangle")
    d.arrow.Filled=true d.arrow.Thickness=1 d.arrow.Visible=false
    d.hpBg=Drawing.new("Line") d.hpBg.Thickness=4 d.hpBg.Visible=false
    d.hpFill=Drawing.new("Line") d.hpFill.Thickness=4 d.hpFill.Visible=false
    d.skel={}
    for i=1,15 do
        local l=Drawing.new("Line")
        l.Thickness=1.5 l.Visible=false
        d.skel[i]=l
    end
    local ch=Instance.new("Highlight")
    ch.FillTransparency=1 ch.OutlineTransparency=1
    ch.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
    if plr.Character then ch.Parent=plr.Character
    else
        local c=plr.CharacterAdded:Connect(function(c2) ch.Parent=c2 end)
        table.insert(conns,c)
    end
    d.ch=ch
    EspData[plr]=d
end
local function delEsp(plr)
    local d=EspData[plr]
    if d then
        for _,k in ipairs({"name","dist","bT","bB","bL","bR",
            "c1","c2","c3","c4","c5","c6","c7","c8",
            "tracer","arrow","hpBg","hpFill"}) do
            if d[k] then pcall(function() d[k]:Remove() end) end
        end
        for _,l in ipairs(d.skel) do pcall(function() l:Remove() end) end
        if d.ch then d.ch:Destroy() end
        EspData[plr]=nil
    end
end
for _,p in ipairs(Players:GetPlayers()) do
    if p~=LP then pcall(newEsp,p) end
end
table.insert(conns,Players.PlayerAdded:Connect(function(p)
    if p~=LP then pcall(newEsp,p) end
end))
table.insert(conns,Players.PlayerRemoving:Connect(delEsp))
function unload()
    unhookCast()
    applyWeaponMods(false)
    local h=getHum()
    if h then
        h.WalkSpeed=16 h.UseJumpPower=false h.JumpPower=50 h.PlatformStand=false
    end
    Cam.FieldOfView=70
    Light.Brightness=1 Light.FogEnd=100000 Light.ClockTime=14
    Light.Ambient=Color3.fromRGB(70,70,70)
    Light.OutdoorAmbient=Color3.fromRGB(128,128,128)
    if flyConn then flyConn:Disconnect() flyConn=nil end
    if flyLV then flyLV:Destroy() flyLV=nil end
    if flyAtt then flyAtt:Destroy() flyAtt=nil end
    if flyGyro then flyGyro:Destroy() flyGyro=nil end
    if speedLV then speedLV:Destroy() speedLV=nil end
    if speedAtt then speedAtt:Destroy() speedAtt=nil end
    for plr,d in pairs(EspData) do
        for _,k in ipairs({"name","dist","bT","bB","bL","bR",
            "c1","c2","c3","c4","c5","c6","c7","c8",
            "tracer","arrow","hpBg","hpFill"}) do
            if d[k] then pcall(function() d[k]:Remove() end) end
        end
        for _,l in ipairs(d.skel) do pcall(function() l:Remove() end) end
        if d.ch then d.ch:Destroy() end
    end
    EspData={}
    if Fov then Fov:Remove() end
    for _,c in ipairs(conns) do
        pcall(function() c:Disconnect() end)
    end
    conns={}
    if Gui then Gui:Destroy() end
    if blur then blur:Destroy() end
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification",
        {Title="One Shot v15",Text="Đã gỡ script",Duration=3})
    end)
end

local Dbg=Instance.new("TextLabel")
Dbg.Size=UDim2.new(0,240,0,80)
Dbg.Position=UDim2.new(0,12,0,44)
Dbg.BackgroundColor3=Color3.fromRGB(0,0,0)
Dbg.BackgroundTransparency=0.3
Dbg.TextColor3=Color3.fromRGB(0,255,140)
Dbg.Font=Enum.Font.Code
Dbg.TextSize=12
Dbg.TextXAlignment=Enum.TextXAlignment.Left
Dbg.TextYAlignment=Enum.TextYAlignment.Top
Dbg.Visible=false
Dbg.Text=""
Dbg.Parent=Gui
Instance.new("UICorner",Dbg).CornerRadius=UDim.new(0,6)
local DbgPad=Instance.new("UIPadding",Dbg)
DbgPad.PaddingLeft=UDim.new(0,8) DbgPad.PaddingTop=UDim.new(0,6)

task.spawn(function()
    while Gui.Parent do
        if S.Debug then
            Dbg.Visible=true
            local c=LP.Character
            local h=c and c:FindFirstChildOfClass("Humanoid")
            local hrp=c and c:FindFirstChild("HumanoidRootPart")
            local vel=hrp and hrp.AssemblyLinearVelocity or Vector3.zero
            Dbg.Text=string.format(
                "Speed: %s | Mode: %s\nWalkSpeed: %.1f\nPlatformStand: %s\nVel: %.1f,%.1f,%.1f\nFlyConn: %s",
                S.SpeedOn and "ON" or "OFF",
                S.SpeedMode,
                h and h.WalkSpeed or 0,
                h and tostring(h.PlatformStand) or "?",
                vel.X,vel.Y,vel.Z,
                flyConn and "OK" or "—")
        else
            Dbg.Visible=false
        end
        task.wait(0.2)
    end
end)
local R15={{"Head","UpperTorso"},{"UpperTorso","LowerTorso"},
{"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},
{"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},
{"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},
{"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"}}
local R6={{"Head","Torso"},{"Torso","Left Arm"},{"Torso","Right Arm"},
{"Torso","Left Leg"},{"Torso","Right Leg"}}

table.insert(conns,UIS.InputBegan:Connect(function(i,gp)
    if gp then return end
    if i.KeyCode==S.AimKey then
        if S.AimMode=="Giữ" then S.AimHeld=true
        else S.AimHeld=not S.AimHeld end
    end
    if (i.UserInputType==Enum.UserInputType.MouseButton1
        or i.UserInputType==Enum.UserInputType.Touch)
        and S.SnapShoot then
        S.SnapUntil=tick()+S.SnapDur/100
    end
end))
table.insert(conns,UIS.InputEnded:Connect(function(i)
    if i.KeyCode==S.AimKey and S.AimMode=="Giữ" then S.AimHeld=false end
end))

table.insert(conns,UIS.InputBegan:Connect(function(i,gp)
    if gp then return end
    local k=i.KeyCode
    if k==Enum.KeyCode.W then FK.W=true end
    if k==Enum.KeyCode.A then FK.A=true end
    if k==Enum.KeyCode.S then FK.S=true end
    if k==Enum.KeyCode.D then FK.D=true end
    if k==Enum.KeyCode.Space then FK.SP=true end
    if k==Enum.KeyCode.LeftControl then FK.CT=true end
end))
table.insert(conns,UIS.InputEnded:Connect(function(i)
    local k=i.KeyCode
    if k==Enum.KeyCode.W then FK.W=false end
    if k==Enum.KeyCode.A then FK.A=false end
    if k==Enum.KeyCode.S then FK.S=false end
    if k==Enum.KeyCode.D then FK.D=false end
    if k==Enum.KeyCode.Space then FK.SP=false end
    if k==Enum.KeyCode.LeftControl then FK.CT=false end
end))

table.insert(conns,UIS.JumpRequest:Connect(function()
    if S.InfJump or S.Bunny then
        local h=getHum()
        if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end))

table.insert(conns,UIS.InputBegan:Connect(function(i,gp)
    if gp then return end
    if i.KeyCode==Enum.KeyCode.RightShift then
        if Main.Visible then
            Main.Visible=false Handle.Visible=true
            tween(blur,0.3,{Size=16})
        else
            Main.Visible=true Handle.Visible=false
            tween(blur,0.3,{Size=0})
        end
    end
end))

local function getTool()
    local c=LP.Character
    if not c then return nil end
    return c:FindFirstChildOfClass("Tool")
end
local function fireTool()
    local t=getTool()
    if t then pcall(function() t:Activate() end) end
end
local function sendM1()
    pcall(function()
        VIM:SendMouseButtonEvent(0,0,1,true,game,1)
        task.wait(0.03)
        VIM:SendMouseButtonEvent(0,0,1,false,game,1)
    end)
end

local hitSnd=Instance.new("Sound")
hitSnd.SoundId="rbxassetid://5656678979"
hitSnd.Volume=1 hitSnd.Parent=Gui
local function getTarget()
    local best,bestScore=nil,math.huge
    local camPos=Cam.CFrame.Position
    local center=Vector2.new(Cam.ViewportSize.X/2,Cam.ViewportSize.Y/2)
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LP and isAlive(p) then
            if S.TeamCheck and p.Team==LP.Team then continue end
            local char=p.Character
            if not char then continue end
            local hum=char:FindFirstChildOfClass("Humanoid")
            if not hum or hum.Health<=0 then continue end
            local part=partOf(char,S.AimPart) or getAnyPart(char)
            if not part then continue end
            local sp,on=Cam:WorldToViewportPoint(part.Position)
            local dCross
            if on then
                dCross=(Vector2.new(sp.X,sp.Y)-center).Magnitude
            else
                dCross=99999
            end
            if on and dCross>S.AimFOV then continue end
            if not on and dCross>S.AimFOV*2 then continue end
            if S.WallCheck and not isVis(part,char) then continue end
            local score
            if S.TargetPriority=="Tâm Ngắm" then score=dCross
            elseif S.TargetPriority=="Khoảng Cách" then
                score=(camPos-part.Position).Magnitude
            else score=hum.Health end
            if score<bestScore then
                best=part bestScore=score
            end
        end
    end
    return best
end

local lastAutoShoot=0
local lastWM=0

table.insert(conns,RS.RenderStepped:Connect(function(dt)
    -- FOV
    if S.ShowFOV and S.AimOn then
        Fov.Visible=true
        Fov.Position=Vector2.new(Cam.ViewportSize.X/2,Cam.ViewportSize.Y/2)
        Fov.Radius=S.AimFOV
        if S.FOVRainbow then Fov.Color=rainbow()
        else Fov.Color=curAccent() end
    else Fov.Visible=false end

    local target=getTarget()
    S.CurTarget=target
    local aiming=S.AimOn and (S.AimHeld or S.AimMode=="Bật Tắt")
    local snapping=tick()<S.SnapUntil

    -- AIM
    if target and (aiming or snapping) then
        local aimPos=target.Position
        if S.Predict>0 then
            local v=target.AssemblyLinearVelocity or Vector3.zero
            aimPos=aimPos+v*(S.Predict/100)
        end
        local alpha=1-math.exp(-(100/math.max(S.AimSmooth,1))*dt)
        Cam.CFrame=Cam.CFrame:Lerp(CFrame.new(Cam.CFrame.Position,aimPos),alpha)
    end

    -- AUTO SHOOT
    if S.AutoShoot and target then
        local now=tick()
        if now-lastAutoShoot>(S.MagicRate/100) then
            lastAutoShoot=now
            if S.HookedMode then fireTool()
            else
                local origin=Cam.CFrame.Position
                Cam.CFrame=CFrame.new(origin,target.Position)
                fireTool()
            end
        end
    end

    --===== ESP RENDER =====
    local camCenter=Vector2.new(Cam.ViewportSize.X/2,Cam.ViewportSize.Y/2)
    for plr,d in pairs(EspData) do
        local hide=false
        if not S.EspOn or not plr.Parent or not plr.Character then hide=true end
        local char=plr.Character
        local head,hrp,hum
        if char then
            head=char:FindFirstChild("Head")
            hrp=char:FindFirstChild("HumanoidRootPart")
            hum=char:FindFirstChildOfClass("Humanoid")
        end
        if not char or not head or not hum or hum.Health<=0 then hide=true end
        if hide then
            d.name.Visible=false d.dist.Visible=false
            d.bT.Visible=false d.bB.Visible=false
            d.bL.Visible=false d.bR.Visible=false
            d.c1.Visible=false d.c2.Visible=false
            d.c3.Visible=false d.c4.Visible=false
            d.c5.Visible=false d.c6.Visible=false
            d.c7.Visible=false d.c8.Visible=false
            d.tracer.Visible=false d.arrow.Visible=false
            d.hpBg.Visible=false d.hpFill.Visible=false
            for _,l in ipairs(d.skel) do l.Visible=false end
            if d.ch then
                d.ch.FillTransparency=1 d.ch.OutlineTransparency=1
            end
        else
            local headPos=head.Position
            local hrpPos=hrp and hrp.Position or (headPos-Vector3.new(0,2.5,0))
            local dist=(Cam.CFrame.Position-headPos).Magnitude
            if dist>S.EspMax then
                d.name.Visible=false d.dist.Visible=false
                d.bT.Visible=false d.bB.Visible=false
                d.bL.Visible=false d.bR.Visible=false
                d.c1.Visible=false d.c2.Visible=false
                d.c3.Visible=false d.c4.Visible=false
                d.c5.Visible=false d.c6.Visible=false
                d.c7.Visible=false d.c8.Visible=false
                d.tracer.Visible=false d.arrow.Visible=false
                d.hpBg.Visible=false d.hpFill.Visible=false
                for _,l in ipairs(d.skel) do l.Visible=false end
                if d.ch then
                    d.ch.FillTransparency=1 d.ch.OutlineTransparency=1
                end
            else
                local col=S.EspRainbow and rainbow() or S.EspCol
                local headSP,headOn=Cam:WorldToViewportPoint(headPos)
                local footSP,footOn=Cam:WorldToViewportPoint(
                    hrpPos-Vector3.new(0,2.5,0))
                local hV=Vector2.new(headSP.X,headSP.Y)
                local fV=Vector2.new(footSP.X,footSP.Y)
                local boxTop=Vector2.new(hV.X,hV.Y-8)
                local boxBot=Vector2.new(fV.X,fV.Y+8)
                local boxH=math.abs(boxBot.Y-boxTop.Y)
                local boxW=boxH*0.5
                local boxL=boxTop.X-boxW/2
                local boxR=boxTop.X+boxW/2

                if headOn then
                    -- Box
                    if S.EspBox then
                        if S.EspBoxMode=="4 Góc" then
                            d.bT.Visible=false d.bB.Visible=false
                            d.bL.Visible=false d.bR.Visible=false
                            local cH=boxH*0.2
                            local cW=boxW*0.3
                            -- 8 line tạo 4 góc L
                            d.c1.From=Vector2.new(boxL,boxTop.Y)
                            d.c1.To=Vector2.new(boxL+cW,boxTop.Y)
                            d.c1.Color=col d.c1.Visible=true
                            d.c2.From=Vector2.new(boxL,boxTop.Y)
                            d.c2.To=Vector2.new(boxL,boxTop.Y+cH)
                            d.c2.Color=col d.c2.Visible=true
                            d.c3.From=Vector2.new(boxR-cW,boxTop.Y)
                            d.c3.To=Vector2.new(boxR,boxTop.Y)
                            d.c3.Color=col d.c3.Visible=true
                            d.c4.From=Vector2.new(boxR,boxTop.Y)
                            d.c4.To=Vector2.new(boxR,boxTop.Y+cH)
                            d.c4.Color=col d.c4.Visible=true
                            d.c5.From=Vector2.new(boxL,boxBot.Y-cH)
                            d.c5.To=Vector2.new(boxL,boxBot.Y)
                            d.c5.Color=col d.c5.Visible=true
                            d.c6.From=Vector2.new(boxL,boxBot.Y)
                            d.c6.To=Vector2.new(boxL+cW,boxBot.Y)
                            d.c6.Color=col d.c6.Visible=true
                            d.c7.From=Vector2.new(boxR,boxBot.Y-cH)
                            d.c7.To=Vector2.new(boxR,boxBot.Y)
                            d.c7.Color=col d.c7.Visible=true
                            d.c8.From=Vector2.new(boxR-cW,boxBot.Y)
                            d.c8.To=Vector2.new(boxR,boxBot.Y)
                            d.c8.Color=col d.c8.Visible=true
                        else
                            d.c1.Visible=false d.c2.Visible=false
                            d.c3.Visible=false d.c4.Visible=false
                            d.c5.Visible=false d.c6.Visible=false
                            d.c7.Visible=false d.c8.Visible=false
                            d.bT.From=Vector2.new(boxL,boxTop.Y)
                            d.bT.To=Vector2.new(boxR,boxTop.Y)
                            d.bT.Color=col d.bT.Visible=true
                            d.bB.From=Vector2.new(boxL,boxBot.Y)
                            d.bB.To=Vector2.new(boxR,boxBot.Y)
                            d.bB.Color=col d.bB.Visible=true
                            d.bL.From=Vector2.new(boxL,boxTop.Y)
                            d.bL.To=Vector2.new(boxL,boxBot.Y)
                            d.bL.Color=col d.bL.Visible=true
                            d.bR.From=Vector2.new(boxR,boxTop.Y)
                            d.bR.To=Vector2.new(boxR,boxBot.Y)
                            d.bR.Color=col d.bR.Visible=true
                        end
                    else
                        d.bT.Visible=false d.bB.Visible=false
                        d.bL.Visible=false d.bR.Visible=false
                        d.c1.Visible=false d.c2.Visible=false
                        d.c3.Visible=false d.c4.Visible=false
                        d.c5.Visible=false d.c6.Visible=false
                        d.c7.Visible=false d.c8.Visible=false
                    end

                    -- ===== FIX: Vị trí text theo EspPos =====
                    local centerY=(boxTop.Y+boxBot.Y)/2
                    local textYName, textYDist
                    if S.EspPos=="Trên" then
                        textYName=boxTop.Y-28
                        textYDist=boxTop.Y-15
                    elseif S.EspPos=="Giữa" then
                        textYName=centerY-14
                        textYDist=centerY+2
                    else -- Dưới
                        textYName=boxBot.Y+4
                        textYDist=boxBot.Y+18
                    end

                    if S.EspName then
                        d.name.Text=plr.Name
                        d.name.Position=Vector2.new(boxTop.X,textYName)
                        d.name.Color=col d.name.Visible=true
                    else d.name.Visible=false end

                    if S.EspDist then
                        d.dist.Text=string.format("[%d m]",math.floor(dist))
                        d.dist.Position=Vector2.new(boxTop.X,textYDist)
                        d.dist.Color=col d.dist.Visible=true
                    else d.dist.Visible=false end

                    -- HP bar
                    if S.EspHP then
                        local r=math.clamp(hum.Health/math.max(hum.MaxHealth,1),0,1)
                        d.hpBg.From=Vector2.new(boxL-6,boxTop.Y)
                        d.hpBg.To=Vector2.new(boxL-6,boxBot.Y)
                        d.hpBg.Color=Color3.fromRGB(30,30,30)
                        d.hpBg.Visible=true
                        d.hpFill.From=Vector2.new(boxL-6,boxBot.Y-(boxBot.Y-boxTop.Y)*r)
                        d.hpFill.To=Vector2.new(boxL-6,boxBot.Y)
                        d.hpFill.Color=Color3.fromRGB(255*(1-r),255*r,0)
                        d.hpFill.Visible=true
                    else
                        d.hpBg.Visible=false d.hpFill.Visible=false
                    end
                else
                    d.bT.Visible=false d.bB.Visible=false
                    d.bL.Visible=false d.bR.Visible=false
                    d.c1.Visible=false d.c2.Visible=false
                    d.c3.Visible=false d.c4.Visible=false
                    d.c5.Visible=false d.c6.Visible=false
                    d.c7.Visible=false d.c8.Visible=false
                    d.name.Visible=false d.dist.Visible=false
                    d.hpBg.Visible=false d.hpFill.Visible=false
                end

                -- Tracer
                if S.EspTracer then
                    d.tracer.From=Vector2.new(Cam.ViewportSize.X/2,Cam.ViewportSize.Y)
                    d.tracer.To=Vector2.new(headSP.X,headSP.Y)
                    d.tracer.Color=col d.tracer.Visible=true
                else d.tracer.Visible=false end

                -- Arrow
                if S.EspArrow and not headOn then
                    local dir=Vector2.new(headSP.X,headSP.Y)-camCenter
                    if dir.Magnitude>0 then
                        dir=dir.Unit
                        local pos=camCenter+dir*math.min(
                            Cam.ViewportSize.X,Cam.ViewportSize.Y)*0.42
                        local perp=Vector2.new(-dir.Y,dir.X)
                        d.arrow.PointA=pos+dir*12
                        d.arrow.PointB=pos-dir*6+perp*7
                        d.arrow.PointC=pos-dir*6-perp*7
                        d.arrow.Color=col d.arrow.Visible=true
                    end
                else d.arrow.Visible=false end

                -- Skeleton
                if S.EspSkel then
                    for _,l in ipairs(d.skel) do l.Visible=false end
                    local pairs2=nil
                    if char:FindFirstChild("UpperTorso") then pairs2=R15
                    elseif char:FindFirstChild("Torso") then pairs2=R6 end
                    if pairs2 then
                        local idx=1
                        for _,pair in ipairs(pairs2) do
                            local a=char:FindFirstChild(pair[1])
                            local b=char:FindFirstChild(pair[2])
                            if a and b and d.skel[idx] then
                                local ap,aon=Cam:WorldToViewportPoint(a.Position)
                                local bp,bon=Cam:WorldToViewportPoint(b.Position)
                                if aon and bon then
                                    d.skel[idx].From=Vector2.new(ap.X,ap.Y)
                                    d.skel[idx].To=Vector2.new(bp.X,bp.Y)
                                    d.skel[idx].Color=col
                                    d.skel[idx].Visible=true
                                end
                                idx=idx+1
                            end
                        end
                    end
                end

                -- Chams
                if d.ch then
                    if S.EspChams then
                        d.ch.FillColor=col d.ch.OutlineColor=col
                        d.ch.FillTransparency=0.55
                        d.ch.OutlineTransparency=0
                    else
                        d.ch.FillTransparency=1
                        d.ch.OutlineTransparency=1
                    end
                end
            end
        end
    end

    -- Hit sound
    if S.HitSound and target then
        local sp,on=w2s(target.Position)
        if on and (sp-camCenter).Magnitude<15 then
            if not hitSnd.IsPlaying then hitSnd:Play() end
        end
    end
    -- Speed
    if S.SpeedOn then
        local c=LP.Character
        local h=getHum()
        if h and c then
            if h.WalkSpeed~=S.SpeedVal then h.WalkSpeed=S.SpeedVal end
            if S.SpeedMode=="Velocity" then
                local hrp=c:FindFirstChild("HumanoidRootPart")
                if hrp then
                    if not speedLV or not speedLV.Parent then
                        if speedAtt then speedAtt:Destroy() end
                        speedAtt=Instance.new("Attachment") speedAtt.Parent=hrp
                        speedLV=Instance.new("LinearVelocity")
                        speedLV.Attachment0=speedAtt
                        speedLV.MaxForce=math.huge
                        speedLV.VectorVelocity=Vector3.zero
                        speedLV.Parent=hrp
                    end
                    local md=h.MoveDirection
                    if md.Magnitude>0 then
                        speedLV.VectorVelocity=md*S.SpeedVal
                    else
                        speedLV.VectorVelocity=Vector3.zero
                    end
                end
            elseif speedLV then
                speedLV:Destroy() speedLV=nil
                if speedAtt then speedAtt:Destroy() speedAtt=nil end
            end
        end
    else
        if speedLV then speedLV:Destroy() speedLV=nil end
        if speedAtt then speedAtt:Destroy() speedAtt=nil end
    end
    -- Jump
    if S.JumpOn then
        local h=getHum()
        if h and h.JumpPower~=S.JumpVal then
            h.UseJumpPower=true h.JumpPower=S.JumpVal
        end
    end
    -- Noclip
    if S.Noclip then
        local c=LP.Character
        if c then
            for _,p in ipairs(c:GetDescendants()) do
                if p:IsA("BasePart") and p.CanCollide then p.CanCollide=false end
            end
        end
    end
    -- Fly
    if S.FlyOn and not flyConn then startFly() end
    if not S.FlyOn and flyConn then stopFly() end
    -- Trigger
    if S.TriggerBot and target then
        local sp=w2s(target.Position)
        if (sp-camCenter).Magnitude<12 then sendM1() end
    end
    -- Rainbow char
    if S.RainbowChar then
        local c=LP.Character
        if c then
            for _,p in ipairs(c:GetDescendants()) do
                if p:IsA("BasePart") then
                    pcall(function() p.Color=rainbow(0.1) end)
                end
            end
        end
    end
    -- Watermark
    if S.WMOn then
        local fps=math.floor(1/math.max(dt,1e-4))
        WM.Text=string.format("ONE SHOT v15 | %d FPS | %s",
            fps,target and "✓" or "—")
        if S.RainbowTheme then
            WM.TextColor3=rainbow()
            WMS.Color=rainbow(0.2)
        else
            WM.TextColor3=T.accent
            WMS.Color=T.accent
        end
    end
    -- Footer
    if tick()-lastWM>0.5 then
        lastWM=tick()
        local fps=math.floor(1/math.max(dt,1e-4))
        local ping=math.floor(LP:GetNetworkPing()*1000)
        FooterText.Text=string.format(
            "FPS: %d  |  Ping: %dms  |  Hook: %s  |  v15",
            fps,ping,S.HookedMode and "ON" or "OFF")
        FooterText.TextColor3=S.HookedMode and T.ok or T.textSub
    end
end))

table.insert(conns,RS.Heartbeat:Connect(function()
    if S.AntiVoid then
        local c=LP.Character
        local hrp=c and c:FindFirstChild("HumanoidRootPart")
        if hrp and hrp.Position.Y<-100 then
            hrp.CFrame=CFrame.new(0,50,0)
        end
    end
end))

task.spawn(function()
    task.wait(1)
    if getWeaponManager() then
        toast("One Shot v15","Đã tìm thấy WeaponManager!")
    else
        toast("One Shot v15","Không có WeaponManager (fallback)","warn")
    end
end)

toast("One Shot v15","Đã load! RightShift = ẩn/hiện.")
