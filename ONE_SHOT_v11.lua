--=============================================================
--  ONE SHOT v11 - Full Fixed Edition
--  Đã sửa: trùng lặp WeaponManager, applyWeaponMods, nút ×,
--  thứ tự unload, version đồng bộ
--=============================================================
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
SilentAim=false,SnapShoot=true,SnapDur=12,SnapUntil=0,
TargetPriority="Tâm Ngắm",AutoFireOnAim=false,TriggerBot=false,HitSound=false,
Magic=false,MagicRate=8,FireRateBoost=false,
EspOn=false,EspBox=false,EspName=true,EspDist=true,EspHP=true,
EspTracer=false,EspSkel=false,EspChams=false,EspArrow=false,
EspPos="Trên",EspCol=Color3.fromRGB(255,60,60),EspRainbow=false,EspMax=1500,
SpeedOn=false,SpeedVal=32,JumpOn=false,JumpVal=80,InfJump=false,Bunny=false,
FlyOn=false,FlySpd=80,Noclip=false,AntiVoid=false,
FOVChg=false,FOVVal=90,FullBright=false,NoFog=false,RainbowChar=false,
WMOn=true,Notify=true,CurTarget=nil}
local CFG="oneshot_v11.json"
local conns={}

--=============================================================
-- 1. HÀM PHỤ TRỢ
--=============================================================
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
local function isVis(part,ig2)
    if not part then return false end
    local o=Cam.CFrame.Position
    local ig={LP.Character}
    if ig2 then for _,v in ipairs(ig2) do table.insert(ig,v) end end
    local hit=WS:FindPartOnRayWithIgnoreList(Ray.new(o,part.Position-o),ig)
    return hit==part or (hit and hit:IsDescendantOf(part.Parent))
end
local function rainbow(o) return Color3.fromHSV((tick()*0.4+(o or 0))%1,1,1) end
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

--=============================================================
-- 2. WEAPON MANAGER + HOOK (định nghĩa 1 lần duy nhất)
--=============================================================
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
    if not hookfunction then return false end
    local wm=getWeaponManager()
    if not wm or not wm.cast then return false end
    if old_cast then return true end
    local ok=pcall(function()
        old_cast=hookfunction(wm.cast,function(...)
            local args={...}
            if S.Magic and S.CurTarget and S.CurTarget.Parent then
                local origin=args[1]
                local head=S.CurTarget
                local canFire=true
                if S.WallCheck and origin then
                    local ig={LP.Character}
                    local hit=WS:FindPartOnRayWithIgnoreList(
                        Ray.new(origin,head.Position-origin),ig)
                    if hit and not hit:IsDescendantOf(head.Parent) then
                        canFire=false
                    end
                end
                if canFire and origin then
                    args[2]=(head.Position-origin).Unit
                    args[3]=9e9
                    args[4]=9e999
                end
            end
            return old_cast(table.unpack(args))
        end)
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

--=============================================================
-- 3. GIAO DIỆN
--=============================================================
local Gui=Instance.new("ScreenGui")
Gui.Name="OneShotV11"
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

local Main=Instance.new("Frame")
Main.Size=UDim2.new(0,560,0,400)
Main.Position=UDim2.new(0.5,-280,0.5,-200)
Main.BackgroundColor3=Color3.fromRGB(18,18,22)
Main.BackgroundTransparency=0.05
Main.BorderSizePixel=0 Main.Active=true Main.Parent=Gui
Instance.new("UICorner",Main).CornerRadius=UDim.new(0,10)
local MS=Instance.new("UIStroke",Main)
MS.Thickness=1.5 MS.Color=Color3.fromRGB(0,170,255) MS.Transparency=0.2
local Grad=Instance.new("UIGradient",Main)
Grad.Rotation=45
Grad.Color=ColorSequence.new(Color3.fromRGB(0,170,255),Color3.fromRGB(200,0,255))

local TitleBar=Instance.new("Frame")
TitleBar.Size=UDim2.new(1,0,0,32)
TitleBar.BackgroundTransparency=1 TitleBar.Active=true TitleBar.Parent=Main
local tLbl=Instance.new("TextLabel")
tLbl.Size=UDim2.new(1,-100,1,0) tLbl.Position=UDim2.new(0,12,0,0)
tLbl.BackgroundTransparency=1 tLbl.Text="ONE SHOT v11"
tLbl.TextColor3=Color3.fromRGB(255,255,255) tLbl.Font=Enum.Font.GothamBold
tLbl.TextSize=15 tLbl.TextXAlignment=Enum.TextXAlignment.Left tLbl.Parent=TitleBar

local dragging=false local dStart,sPos
TitleBar.InputBegan:Connect(function(i)
    if isPress(i) then dragging=true dStart=i.Position sPos=Main.Position end
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

-- Thanh handle mini
local Handle=Instance.new("Frame")
Handle.Size=UDim2.new(0,180,0,34)
Handle.Position=UDim2.new(0.5,-90,0,4)
Handle.BackgroundColor3=Color3.fromRGB(18,18,22)
Handle.BackgroundTransparency=0.1
Handle.BorderSizePixel=0 Handle.Active=true
Handle.Visible=false Handle.Parent=Gui
Instance.new("UICorner",Handle).CornerRadius=UDim.new(0,8)
local HS=Instance.new("UIStroke",Handle)
HS.Color=Color3.fromRGB(0,170,255) HS.Thickness=1.5
local HLbl=Instance.new("TextLabel")
HLbl.Size=UDim2.new(1,0,1,0) HLbl.BackgroundTransparency=1
HLbl.Text="ONE SHOT  ▼" HLbl.TextColor3=Color3.fromRGB(0,170,255)
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
            Tween:Create(blur,TweenInfo.new(0.3),{Size=0}):Play()
        end
    end
end)

local Side=Instance.new("Frame")
Side.Size=UDim2.new(0,130,1,-42) Side.Position=UDim2.new(0,0,0,42)
Side.BackgroundColor3=Color3.fromRGB(25,25,30)
Side.BorderSizePixel=0 Side.Parent=Main
Instance.new("UICorner",Side).CornerRadius=UDim.new(0,10)
local Content=Instance.new("Frame")
Content.Size=UDim2.new(1,-140,1,-52)
Content.Position=UDim2.new(0,135,0,42)
Content.BackgroundTransparency=1 Content.Parent=Main

local Pages={}
local function newPage(n)
    local p=Instance.new("ScrollingFrame")
    p.Size=UDim2.new(1,0,1,0)
    p.BackgroundTransparency=1 p.BorderSizePixel=0
    p.ScrollBarThickness=4 p.ScrollBarImageColor3=Color3.fromRGB(0,170,255)
    p.CanvasSize=UDim2.new(0,0,0,0)
    p.AutomaticCanvasSize=Enum.AutomaticSize.Y
    p.ClipsDescendants=true p.Visible=false p.Parent=Content
    Instance.new("UIListLayout",p).Padding=UDim.new(0,6)
    Pages[n]=p return p
end
local function selPage(n)
    for k,v in pairs(Pages) do v.Visible=(k==n) end
end
local tabs={}
local function mkTab(n,o)
    local b=Instance.new("TextButton")
    b.Size=UDim2.new(1,-10,0,32)
    b.Position=UDim2.new(0,5,0,10+(o-1)*36)
    b.BackgroundColor3=Color3.fromRGB(35,35,42)
    b.BorderSizePixel=0 b.Text=n
    b.TextColor3=Color3.fromRGB(200,200,200)
    b.Font=Enum.Font.Gotham b.TextSize=14 b.Parent=Side
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,6)
    b.MouseButton1Click:Connect(function()
        selPage(n)
        for _,x in ipairs(tabs) do
            x.bg.BackgroundColor3=Color3.fromRGB(35,35,42)
            x.bg.TextColor3=Color3.fromRGB(200,200,200)
        end
        b.BackgroundColor3=Color3.fromRGB(0,170,255)
        b.TextColor3=Color3.fromRGB(255,255,255)
    end)
    table.insert(tabs,{bg=b}) newPage(n) return b
end

local function sec(pg,t)
    local l=Instance.new("TextLabel")
    l.Size=UDim2.new(1,0,0,22) l.BackgroundTransparency=1
    l.Text="  "..t l.TextColor3=Color3.fromRGB(0,170,255)
    l.Font=Enum.Font.GothamBold l.TextSize=13
    l.TextXAlignment=Enum.TextXAlignment.Left l.Parent=pg
end
local function tgl(pg,t,d,cb)
    local f=Instance.new("Frame") f.Size=UDim2.new(1,-10,0,30)
    f.BackgroundColor3=Color3.fromRGB(28,28,34)
    f.BorderSizePixel=0 f.Parent=pg
    Instance.new("UICorner",f).CornerRadius=UDim.new(0,6)
    local lb=Instance.new("TextLabel")
    lb.Size=UDim2.new(1,-60,1,0) lb.Position=UDim2.new(0,10,0,0)
    lb.BackgroundTransparency=1 lb.Text=t
    lb.TextColor3=Color3.fromRGB(230,230,230)
    lb.Font=Enum.Font.Gotham lb.TextSize=13
    lb.TextXAlignment=Enum.TextXAlignment.Left lb.Parent=f
    local b=Instance.new("TextButton")
    b.Size=UDim2.new(0,44,0,20) b.Position=UDim2.new(1,-52,0.5,-10)
    b.BackgroundColor3=d and Color3.fromRGB(0,170,255) or Color3.fromRGB(50,50,58)
    b.Text=d and "BẬT" or "TẮT"
    b.TextColor3=Color3.fromRGB(255,255,255)
    b.Font=Enum.Font.GothamBold b.TextSize=11
    b.BorderSizePixel=0 b.Parent=f
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,4)
    local st=d
    b.MouseButton1Click:Connect(function()
        st=not st
        b.BackgroundColor3=st and Color3.fromRGB(0,170,255) or Color3.fromRGB(50,50,58)
        b.Text=st and "BẬT" or "TẮT"
        cb(st)
    end)
    return f
end
local function sld(pg,t,mn,mx,d,cb)
    local f=Instance.new("Frame") f.Size=UDim2.new(1,-10,0,44)
    f.BackgroundColor3=Color3.fromRGB(28,28,34)
    f.BorderSizePixel=0 f.Parent=pg
    Instance.new("UICorner",f).CornerRadius=UDim.new(0,6)
    local lb=Instance.new("TextLabel")
    lb.Size=UDim2.new(1,-20,0,20) lb.Position=UDim2.new(0,10,0,2)
    lb.BackgroundTransparency=1 lb.Text=t..": "..d
    lb.TextColor3=Color3.fromRGB(230,230,230)
    lb.Font=Enum.Font.Gotham lb.TextSize=13
    lb.TextXAlignment=Enum.TextXAlignment.Left lb.Parent=f
    local bar=Instance.new("Frame")
    bar.Size=UDim2.new(1,-20,0,14) bar.Position=UDim2.new(0,10,0,25)
    bar.BackgroundColor3=Color3.fromRGB(50,50,58)
    bar.BorderSizePixel=0 bar.Active=true bar.Parent=f
    Instance.new("UICorner",bar).CornerRadius=UDim.new(0,7)
    local fill=Instance.new("Frame")
    fill.Size=UDim2.new((d-mn)/(mx-mn),0,1,0)
    fill.BackgroundColor3=Color3.fromRGB(0,170,255)
    fill.BorderSizePixel=0 fill.Active=false fill.Parent=bar
    Instance.new("UICorner",fill).CornerRadius=UDim.new(0,7)
    local drg=false
    local function upd(x)
        local r=math.clamp((x-bar.AbsolutePosition.X)/math.max(bar.AbsoluteSize.X,1),0,1)
        local v=math.floor(mn+r*(mx-mn)+0.5)
        fill.Size=UDim2.new(r,0,1,0) lb.Text=t..": "..v cb(v)
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
    return f
end
local function drp(pg,t,opts,d,cb)
    local f=Instance.new("Frame") f.Size=UDim2.new(1,-10,0,32)
    f.BackgroundColor3=Color3.fromRGB(28,28,34)
    f.BorderSizePixel=0 f.Parent=pg
    Instance.new("UICorner",f).CornerRadius=UDim.new(0,6)
    local b=Instance.new("TextButton")
    b.Size=UDim2.new(1,0,1,0) b.BackgroundTransparency=1
    b.Text=t..": "..d b.TextColor3=Color3.fromRGB(230,230,230)
    b.Font=Enum.Font.Gotham b.TextSize=13
    b.TextXAlignment=Enum.TextXAlignment.Left b.Parent=f
    Instance.new("UIPadding",b).PaddingLeft=UDim.new(0,10)
    local ls=Instance.new("Frame")
    ls.BackgroundColor3=Color3.fromRGB(22,22,28)
    ls.BorderSizePixel=0 ls.Visible=false ls.ZIndex=9999 ls.Parent=Gui
    Instance.new("UICorner",ls).CornerRadius=UDim.new(0,6)
    local st=Instance.new("UIStroke",ls)
    st.Color=Color3.fromRGB(0,170,255) st.Thickness=1
    for i,o in ipairs(opts) do
        local ob=Instance.new("TextButton")
        ob.Size=UDim2.new(1,0,0,28)
        ob.Position=UDim2.new(0,0,0,(i-1)*28)
        ob.BackgroundTransparency=1 ob.Text=o
        ob.TextColor3=Color3.fromRGB(220,220,220)
        ob.Font=Enum.Font.Gotham ob.TextSize=13
        ob.ZIndex=10000 ob.Parent=ls
        ob.MouseButton1Click:Connect(function()
            b.Text=t..": "..o ls.Visible=false cb(o)
        end)
    end
    b.MouseButton1Click:Connect(function()
        if ls.Visible then ls.Visible=false return end
        ls.Size=UDim2.new(0,f.AbsoluteSize.X,0,#opts*28)
        ls.Position=UDim2.new(0,f.AbsolutePosition.X,
            0,f.AbsolutePosition.Y+f.AbsoluteSize.Y+2)
        ls.Visible=true
    end)
    return f
end
local function btn(pg,t,cb)
    local b=Instance.new("TextButton")
    b.Size=UDim2.new(1,-10,0,32)
    b.BackgroundColor3=Color3.fromRGB(0,170,255) b.Text=t
    b.TextColor3=Color3.fromRGB(255,255,255)
    b.Font=Enum.Font.GothamBold b.TextSize=13
    b.BorderSizePixel=0 b.Parent=pg
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,6)
    b.MouseButton1Click:Connect(cb) return b
end
local function kb(pg,t,d,cb)
    local f=Instance.new("Frame") f.Size=UDim2.new(1,-10,0,30)
    f.BackgroundColor3=Color3.fromRGB(28,28,34)
    f.BorderSizePixel=0 f.Parent=pg
    Instance.new("UICorner",f).CornerRadius=UDim.new(0,6)
    local lb=Instance.new("TextLabel")
    lb.Size=UDim2.new(1,-90,1,0) lb.Position=UDim2.new(0,10,0,0)
    lb.BackgroundTransparency=1 lb.Text=t
    lb.TextColor3=Color3.fromRGB(230,230,230)
    lb.Font=Enum.Font.Gotham lb.TextSize=13
    lb.TextXAlignment=Enum.TextXAlignment.Left lb.Parent=f
    local b=Instance.new("TextButton")
    b.Size=UDim2.new(0,80,0,22) b.Position=UDim2.new(1,-88,0.5,-11)
    b.BackgroundColor3=Color3.fromRGB(50,50,58) b.Text=d.Name
    b.TextColor3=Color3.fromRGB(255,255,255)
    b.Font=Enum.Font.Gotham b.TextSize=12
    b.BorderSizePixel=0 b.Parent=f
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,4)
    local li=false
    b.MouseButton1Click:Connect(function() li=true b.Text="..." end)
    UIS.InputBegan:Connect(function(i,gp)
        if li and i.UserInputType==Enum.UserInputType.Keyboard then
            b.Text=i.KeyCode.Name li=false cb(i.KeyCode)
        end
    end)
    return f
end

--=============================================================
-- 4. TABS
--=============================================================
mkTab("Ngắm",1) mkTab("ESP",2) mkTab("Di Chuyển",3)
mkTab("Chiến Đấu",4) mkTab("Hiển Thị",5) mkTab("Cấu Hình",6)
selPage("Ngắm")
tabs[1].bg.BackgroundColor3=Color3.fromRGB(0,170,255)
tabs[1].bg.TextColor3=Color3.fromRGB(255,255,255)

-- TAB NGẮM
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
tgl(AP,"Ngắm Ngầm",false,function(v) S.SilentAim=v end)
tgl(AP,"Tự Bắn Khi Ngắm",false,function(v) S.AutoFireOnAim=v end)
tgl(AP,"Khóa Khi Bắn",true,function(v) S.SnapShoot=v end)
sld(AP,"Thời Gian Khóa x10ms",5,50,12,function(v) S.SnapDur=v end)
tgl(AP,"Âm Trúng Đích",false,function(v) S.HitSound=v end)
sec(AP,"VÒNG NGẮM")
tgl(AP,"Hiện Vòng Ngắm",true,function(v) S.ShowFOV=v end)
tgl(AP,"Cầu Vồng",false,function(v) S.FOVRainbow=v end)

local Fov=Drawing.new("Circle")
Fov.Thickness=1.5 Fov.NumSides=64 Fov.Transparency=1
Fov.Filled=false Fov.Visible=false

-- TAB ESP
local EP=Pages["ESP"]
sec(EP,"ESP")
tgl(EP,"Bật ESP",false,function(v) S.EspOn=v end)
tgl(EP,"Khung",false,function(v) S.EspBox=v end)
tgl(EP,"Tên",true,function(v) S.EspName=v end)
tgl(EP,"Khoảng Cách",true,function(v) S.EspDist=v end)
tgl(EP,"Thanh Máu",true,function(v) S.EspHP=v end)
tgl(EP,"Đường Chỉ",false,function(v) S.EspTracer=v end)
tgl(EP,"Xương",false,function(v) S.EspSkel=v end)
tgl(EP,"Viền Sáng",false,function(v) S.EspChams=v end)
tgl(EP,"Mũi Tên Chỉ Hướng",false,function(v) S.EspArrow=v end)
sec(EP,"KIỂU")
drp(EP,"Vị Trí",{"Trên","Giữa","Dưới"},"Trên",function(v) S.EspPos=v end)
tgl(EP,"Màu Cầu Vồng",false,function(v) S.EspRainbow=v end)
sld(EP,"Khoảng Cách Tối Đa",100,5000,1500,function(v) S.EspMax=v end)

-- TAB DI CHUYỂN
local MP=Pages["Di Chuyển"]
sec(MP,"TỐC ĐỘ")
tgl(MP,"Bật Tốc Độ",false,function(v)
    S.SpeedOn=v
    if not v then local h=getHum() if h then h.WalkSpeed=16 end end
end)
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
sld(MP,"Tốc Độ Bay",10,500,80,function(v) S.FlySpd=v end)
sec(MP,"KHÁC")
tgl(MP,"Xuyên Tường",false,function(v) S.Noclip=v end)
tgl(MP,"Chống Rớt Map",false,function(v) S.AntiVoid=v end)

-- FLY logic
local flyLV,flyAtt,flyConn
local FK={W=false,A=false,S=false,D=false,SP=false,CT=false}
function stopFly()
    if flyConn then flyConn:Disconnect() flyConn=nil end
    if flyLV then flyLV:Destroy() flyLV=nil end
    if flyAtt then flyAtt:Destroy() flyAtt=nil end
    local h=getHum() if h then h.PlatformStand=false end
end
function startFly()
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
    if flyConn then flyConn:Disconnect() end
    flyConn=RS.RenderStepped:Connect(function()
        if not S.FlyOn or not flyLV or not flyLV.Parent then return end
        local cam=Cam.CFrame local mv=Vector3.zero
        if FK.W then mv=mv+cam.LookVector end
        if FK.S then mv=mv-cam.LookVector end
        if FK.A then mv=mv-cam.RightVector end
        if FK.D then mv=mv+cam.RightVector end
        if FK.SP then mv=mv+Vector3.new(0,1,0) end
        if FK.CT then mv=mv-Vector3.new(0,1,0) end
        if mv.Magnitude>0 then mv=mv.Unit*S.FlySpd end
        flyLV.VectorVelocity=mv
    end)
    notify("Bay","WASD di chuyển, Space lên, Ctrl xuống")
end

-- TAB CHIẾN ĐẤU
local CP=Pages["Chiến Đấu"]
sec(CP,"TỰ ĐỘNG")
tgl(CP,"Bắn Khi Thấy Tâm",false,function(v) S.TriggerBot=v end)
sec(CP,"ĐẠN MA THUẬT (SILENT AIM)")
tgl(CP,"Bật Đạn Ma Thuật",false,function(v)
    S.Magic=v
    if v then
        local ok=hookCast()
        if ok then
            notify("Đạn Ma Thuật","Đã hook WeaponManager thành công!")
        else
            notify("Đạn Ma Thuật","Không hook được (executor không hỗ trợ hoặc không tìm thấy WM)")
        end
    else
        unhookCast()
    end
end)
sld(CP,"Tốc Độ Bắn x10ms",3,50,8,function(v) S.MagicRate=v end)
sec(CP,"MOD SÚNG")
tgl(CP,"Tăng Tốc Bắn + Vô Hạn Đạn",false,function(v)
    S.FireRateBoost=v
    applyWeaponMods(v)
    if v then notify("Mod Súng","Đã áp dụng (nếu game hỗ trợ)") end
end)

-- TAB HIỂN THỊ
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
    else
        Light.Brightness=1
    end
end)
tgl(VP,"Xóa Sương Mù",false,function(v)
    S.NoFog=v
    Light.FogEnd=v and 1e6 or 100000
end)
sec(VP,"NHÂN VẬT")
tgl(VP,"Nhân Vật Cầu Vồng",false,function(v) S.RainbowChar=v end)
sec(VP,"GIAO DIỆN")
tgl(VP,"Watermark",true,function(v) S.WMOn=v WM.Visible=v end)
tgl(VP,"Thông Báo",true,function(v) S.Notify=v end)

--=============================================================
-- 5. ESP STORAGE
--=============================================================
local EspData={}
local function newEsp(plr)
    local bg=Instance.new("BillboardGui")
    bg.Size=UDim2.new(0,200,0,60) bg.AlwaysOnTop=true
    bg.StudsOffsetWorldSpace=Vector3.new(0,3,0) bg.Parent=Gui
    local nameL=Instance.new("TextLabel",bg)
    nameL.Size=UDim2.new(1,0,0,16) nameL.Position=UDim2.new(0,0,0,0)
    nameL.BackgroundTransparency=1
    nameL.TextColor3=Color3.fromRGB(255,255,255)
    nameL.Font=Enum.Font.GothamBold nameL.TextSize=13
    nameL.TextStrokeTransparency=0
    local distL=Instance.new("TextLabel",bg)
    distL.Size=UDim2.new(1,0,0,14) distL.Position=UDim2.new(0,0,0,16)
    distL.BackgroundTransparency=1
    distL.TextColor3=Color3.fromRGB(255,255,255)
    distL.Font=Enum.Font.Gotham distL.TextSize=11
    distL.TextStrokeTransparency=0
    local hpBG=Instance.new("Frame",bg)
    hpBG.Size=UDim2.new(0,60,0,5) hpBG.Position=UDim2.new(0.5,-30,0,32)
    hpBG.BackgroundColor3=Color3.fromRGB(30,30,30) hpBG.BorderSizePixel=0
    Instance.new("UICorner",hpBG).CornerRadius=UDim.new(0,2)
    local hpFill=Instance.new("Frame",hpBG)
    hpFill.Size=UDim2.new(1,0,1,0)
    hpFill.BackgroundColor3=Color3.fromRGB(0,255,0)
    hpFill.BorderSizePixel=0
    Instance.new("UICorner",hpFill).CornerRadius=UDim.new(0,2)
    local ch=Instance.new("Highlight")
    ch.FillTransparency=1 ch.OutlineTransparency=1
    ch.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
    if plr.Character then ch.Parent=plr.Character
    else plr.CharacterAdded:Connect(function(c) ch.Parent=c end) end
    local tracer=Drawing.new("Line")
    tracer.Thickness=1 tracer.Transparency=0.85 tracer.Visible=false
    local arrow=Drawing.new("Triangle")
    arrow.Filled=true arrow.Thickness=1 arrow.Visible=false
    local skel={}
    for i=1,15 do
        local l=Drawing.new("Line")
        l.Thickness=1.5 l.Color=Color3.fromRGB(255,255,255) l.Visible=false
        skel[i]=l
    end
    EspData[plr]={bg=bg,name=nameL,dist=distL,hp=hpFill,hpBG=hpBG,
        ch=ch,tracer=tracer,arrow=arrow,skel=skel}
end
local function delEsp(plr)
    local d=EspData[plr]
    if d then
        if d.bg then d.bg:Destroy() end
        if d.ch then d.ch:Destroy() end
        if d.tracer then d.tracer:Remove() end
        if d.arrow then d.arrow:Remove() end
        if d.skel then for _,l in ipairs(d.skel) do l:Remove() end end
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

--=============================================================
-- 6. UNLOAD (định nghĩa TRƯỚC khi tạo nút ×)
--=============================================================
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
    for plr,d in pairs(EspData) do
        if d.bg then d.bg:Destroy() end
        if d.ch then d.ch:Destroy() end
        if d.tracer then d.tracer:Remove() end
        if d.arrow then d.arrow:Remove() end
        if d.skel then for _,l in ipairs(d.skel) do l:Remove() end end
    end
    EspData={}
    if Fov then Fov:Remove() end
    for _,c in ipairs(conns) do
        pcall(function() c:Disconnect() end)
    end
    conns={}
    if Gui then Gui:Destroy() end
    if blur then blur:Destroy() end
    notify("One Shot v11","Đã gỡ script và khôi phục mặc định")
end

-- Nút − và × (chỉ tạo 1 lần)
local function cBtn(t,x,cb)
    local b=Instance.new("TextButton")
    b.Size=UDim2.new(0,24,0,24) b.Position=UDim2.new(1,x,0,4)
    b.BackgroundColor3=Color3.fromRGB(40,40,48)
    b.Text=t b.TextColor3=Color3.fromRGB(255,255,255)
    b.Font=Enum.Font.GothamBold b.TextSize=14
    b.BorderSizePixel=0 b.Parent=TitleBar
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,6)
    b.MouseEnter:Connect(function()
        b.BackgroundColor3=Color3.fromRGB(60,60,70)
    end)
    b.MouseLeave:Connect(function()
        b.BackgroundColor3=Color3.fromRGB(40,40,48)
    end)
    b.MouseButton1Click:Connect(cb)
    return b
end
cBtn("−",-60,function()
    Main.Visible=false Handle.Visible=true
    Tween:Create(blur,TweenInfo.new(0.3),{Size=16}):Play()
end)
cBtn("×",-32,function() unload() end)

--=============================================================
-- 7. TAB CẤU HÌNH (sau khi đã có unload)
--=============================================================
local CgP=Pages["Cấu Hình"]
sec(CgP,"LƯU / TẢI")
btn(CgP,"Lưu Cấu Hình",function()
    local d={}
    for k,v in pairs(S) do
        if type(v)=="number" or type(v)=="boolean" or type(v)=="string" then
            d[k]=v
        end
    end
    if writefile then
        writefile(CFG,Http:JSONEncode(d))
        notify("Cấu Hình","Đã lưu!")
    end
end)
btn(CgP,"Tải Cấu Hình",function()
    if isfile and isfile(CFG) and readfile then
        local ok,d=pcall(function() return Http:JSONDecode(readfile(CFG)) end)
        if ok then
            for k,v in pairs(d) do S[k]=v end
            notify("Cấu Hình","Đã tải! (cần bật lại toggle)")
        end
    end
end)
btn(CgP,"Gỡ Script",function() unload() end)

-- Watermark
local WM=Instance.new("TextLabel")
WM.Size=UDim2.new(0,280,0,26) WM.Position=UDim2.new(0,12,0,12)
WM.BackgroundColor3=Color3.fromRGB(15,15,20)
WM.BackgroundTransparency=0.3
WM.TextColor3=Color3.fromRGB(0,170,255)
WM.Font=Enum.Font.GothamBold WM.TextSize=13
WM.Text="ONE SHOT v11" WM.Parent=Gui
Instance.new("UICorner",WM).CornerRadius=UDim.new(0,6)
local WMS=Instance.new("UIStroke",WM)
WMS.Color=Color3.fromRGB(0,170,255) WMS.Transparency=0.3

--=============================================================
-- 8. VÒNG LẶP CHÍNH
--=============================================================
local function getTarget()
    local best,bestScore=nil,math.huge
    local camPos=Cam.CFrame.Position
    local center=Vector2.new(Cam.ViewportSize.X/2,Cam.ViewportSize.Y/2)
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LP and isAlive(p)
        and not (S.TeamCheck and p.Team==LP.Team) then
            local char=p.Character
            local hum=char:FindFirstChildOfClass("Humanoid")
            if hum then
                local part=partOf(char,S.AimPart)
                if part then
                    local sp,on=Cam:WorldToViewportPoint(part.Position)
                    if on then
                        local dCross=(Vector2.new(sp.X,sp.Y)-center).Magnitude
                        if dCross<S.AimFOV then
                            local score
                            if S.TargetPriority=="Tâm Ngắm" then score=dCross
                            elseif S.TargetPriority=="Khoảng Cách" then
                                score=(camPos-part.Position).Magnitude
                            else score=hum.Health end
                            if score<bestScore then
                                local ok=true
                                if S.WallCheck and not isVis(part,{char}) then
                                    ok=false
                                end
                                if ok then best=part bestScore=score end
                            end
                        end
                    end
                end
            end
        end
    end
    return best
end

-- Input
table.insert(conns,UIS.InputBegan:Connect(function(i,gp)
    if gp then return end
    if i.KeyCode==S.AimKey then
        if S.AimMode=="Giữ" then S.AimHeld=true
        else S.AimHeld=not S.AimHeld end
    end
    if i.UserInputType==Enum.UserInputType.MouseButton1 and S.SnapShoot then
        S.SnapUntil=tick()+S.SnapDur/100
    end
end))
table.insert(conns,UIS.InputEnded:Connect(function(i)
    if i.KeyCode==S.AimKey and S.AimMode=="Giữ" then S.AimHeld=false end
end))

-- Phím W/A/S/D cho fly
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

local R15={{"Head","UpperTorso"},{"UpperTorso","LowerTorso"},
{"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},
{"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},
{"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},
{"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightUpperLeg","RightFoot"}}
local R6={{"Head","Torso"},{"Torso","Left Arm"},{"Torso","Right Arm"},
{"Torso","Left Leg"},{"Torso","Right Leg"}}

local lastMagic=0
table.insert(conns,RS.RenderStepped:Connect(function(dt)
    -- Vòng ngắm
    if S.ShowFOV and S.AimOn then
        Fov.Visible=true
        Fov.Position=Vector2.new(Cam.ViewportSize.X/2,Cam.ViewportSize.Y/2)
        Fov.Radius=S.AimFOV
        if S.FOVRainbow then Fov.Color=rainbow()
        else Fov.Color=Color3.fromRGB(0,170,255) end
    else Fov.Visible=false end

    local target=getTarget()
    S.CurTarget=target
    local aiming=S.AimOn and (S.AimHeld or S.AimMode=="Bật Tắt")
    local snapping=tick()<S.SnapUntil

    -- Aim thường
    if target and (aiming or snapping) and not S.Magic then
        local aimPos=target.Position
        if S.Predict>0 then
            local v=target.AssemblyLinearVelocity or Vector3.zero
            aimPos=aimPos+v*(S.Predict/100)
        end
        if not S.SilentAim then
            local alpha=1-math.exp(-(100/math.max(S.AimSmooth,1))*dt)
            Cam.CFrame=Cam.CFrame:Lerp(CFrame.new(Cam.CFrame.Position,aimPos),alpha)
        end
        if S.AutoFireOnAim and aiming then fireTool() end
    end

    -- Đạn ma thuật: hook đã cài, chỉ cần fire liên tục
    if S.Magic and target and tick()-lastMagic>(S.MagicRate/100) then
        lastMagic=tick()
        fireTool()
    end

    -- ESP
    local camCenter=Vector2.new(Cam.ViewportSize.X/2,Cam.ViewportSize.Y/2)
    for plr,d in pairs(EspData) do
        local hide=not plr.Parent or not plr.Character
            or not isAlive(plr) or not S.EspOn
        if hide then
            d.bg.Enabled=false
            if d.ch then
                d.ch.FillTransparency=1 d.ch.OutlineTransparency=1
            end
            d.tracer.Visible=false d.arrow.Visible=false
            for _,l in ipairs(d.skel) do l.Visible=false end
        else
            local char=plr.Character
            local head=char:FindFirstChild("Head")
            local hrp=char:FindFirstChild("HumanoidRootPart")
            local hum=char:FindFirstChildOfClass("Humanoid")
            if not head or not hrp or not hum then
                d.bg.Enabled=false
            else
                local dist=(Cam.CFrame.Position-head.Position).Magnitude
                if dist>S.EspMax then
                    d.bg.Enabled=false
                    d.tracer.Visible=false d.arrow.Visible=false
                    for _,l in ipairs(d.skel) do l.Visible=false end
                else
                    d.bg.Enabled=true
                    local col=S.EspRainbow and rainbow() or S.EspCol
                    d.name.Visible=S.EspName
                    d.name.Text=plr.Name d.name.TextColor3=col
                    d.dist.Visible=S.EspDist
                    d.dist.Text=string.format("[%d m]",math.floor(dist))
                    d.dist.TextColor3=col
                    d.hpBG.Visible=S.EspHP
                    local r=math.clamp(hum.Health/math.max(hum.MaxHealth,1),0,1)
                    d.hp.Size=UDim2.new(r,0,1,0)
                    d.hp.BackgroundColor3=Color3.fromRGB(255*(1-r),255*r,0)
                    if S.EspPos=="Trên" then
                        d.bg.StudsOffsetWorldSpace=Vector3.new(0,3.2,0)
                    elseif S.EspPos=="Giữa" then
                        d.bg.StudsOffsetWorldSpace=Vector3.new(0,1.5,0)
                    else
                        d.bg.StudsOffsetWorldSpace=Vector3.new(0,0,0)
                    end
                    if S.EspChams then
                        d.ch.FillColor=col d.ch.OutlineColor=col
                        d.ch.FillTransparency=0.55 d.ch.OutlineTransparency=0
                    else
                        d.ch.FillTransparency=1 d.ch.OutlineTransparency=1
                    end
                    if S.EspTracer then
                        local hp2=w2s(head.Position)
                        d.tracer.Color=col d.tracer.Visible=true
                        d.tracer.From=Vector2.new(Cam.ViewportSize.X/2,
                            Cam.ViewportSize.Y)
                        d.tracer.To=hp2
                    else d.tracer.Visible=false end
                    local sp,on=w2s(head.Position)
                    if S.EspArrow and not on then
                        local dir=sp-camCenter
                        if dir.Magnitude>0 then
                            dir=dir.Unit
                            local pos=camCenter+dir
                                *math.min(Cam.ViewportSize.X,
                                    Cam.ViewportSize.Y)*0.42
                            local perp=Vector2.new(-dir.Y,dir.X)
                            d.arrow.PointA=pos+dir*12
                            d.arrow.PointB=pos-dir*6+perp*7
                            d.arrow.PointC=pos-dir*6-perp*7
                            d.arrow.Color=col d.arrow.Visible=true
                        end
                    else d.arrow.Visible=false end
                    if S.EspSkel then
                        for _,l in ipairs(d.skel) do l.Visible=false end
                        local pairs2=nil
                        if char:FindFirstChild("UpperTorso") then pairs2=R15
                        elseif char:FindFirstChild("Torso") then pairs2=R6 end
                        if pairs2 then
                            for i,pair in ipairs(pairs2) do
                                local a=char:FindFirstChild(pair[1])
                                local b=char:FindFirstChild(pair[2])
                                if a and b and d.skel[i] then
                                    local ap,aon=w2s(a.Position)
                                    local bp,bon=w2s(b.Position)
                                    if aon and bon then
                                        d.skel[i].From=ap
                                        d.skel[i].To=bp
                                        d.skel[i].Color=col
                                        d.skel[i].Visible=true
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    -- Âm trúng đích
    if S.HitSound and target then
        local sp,on=w2s(target.Position)
        if on and (sp-camCenter).Magnitude<15 then
            if not hitSnd.IsPlaying then hitSnd:Play() end
        end
    end

    -- Tốc độ
    if S.SpeedOn then
        local h=getHum()
        if h and h.WalkSpeed~=S.SpeedVal then h.WalkSpeed=S.SpeedVal end
    end
    -- Nhảy
    if S.JumpOn then
        local h=getHum()
        if h and h.JumpPower~=S.JumpVal then
            h.UseJumpPower=true h.JumpPower=S.JumpVal
        end
    end
    -- Xuyên tường
    if S.Noclip then
        local c=LP.Character
        if c then
            for _,p in ipairs(c:GetDescendants()) do
                if p:IsA("BasePart") and p.CanCollide then
                    p.CanCollide=false
                end
            end
        end
    end
    -- Bay
    if S.FlyOn and not flyLV then startFly() end
    if not S.FlyOn and flyLV then stopFly() end
    -- Trigger bot
    if S.TriggerBot and target then
        local sp=w2s(target.Position)
        if (sp-camCenter).Magnitude<12 then sendM1() end
    end
    -- Nhân vật cầu vồng
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
        WM.Text=string.format("ONE SHOT v11 | %d FPS | Mục Tiêu: %s",
            fps,target and "✓" or "—")
    end
end))

-- Chống rớt map
table.insert(conns,RS.Heartbeat:Connect(function()
    if S.AntiVoid then
        local c=LP.Character
        local hrp=c and c:FindFirstChild("HumanoidRootPart")
        if hrp and hrp.Position.Y<-100 then
            hrp.CFrame=CFrame.new(0,50,0)
        end
    end
end))

-- Nhảy vô hạn / bunny
table.insert(conns,UIS.JumpRequest:Connect(function()
    if S.InfJump or S.Bunny then
        local h=getHum()
        if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end))

-- Phím tắt RightShift
table.insert(conns,UIS.InputBegan:Connect(function(i,gp)
    if gp then return end
    if i.KeyCode==Enum.KeyCode.RightShift then
        if Main.Visible then
            Main.Visible=false Handle.Visible=true
            Tween:Create(blur,TweenInfo.new(0.3),{Size=16}):Play()
        else
            Main.Visible=true Handle.Visible=false
            Tween:Create(blur,TweenInfo.new(0.3),{Size=0}):Play()
        end
    end
end))

-- Auto tìm WeaponManager
task.spawn(function()
    task.wait(1)
    if getWeaponManager() then
        notify("One Shot v11","Đã tìm thấy WeaponManager!")
    else
        notify("One Shot v11","Không tìm thấy WeaponManager (chỉ ảnh hưởng Đạn Ma Thuật)")
    end
end)

notify("One Shot v11","Đã load! RightShift = ẩn/hiện. Nhấn × để gỡ và reset.")
