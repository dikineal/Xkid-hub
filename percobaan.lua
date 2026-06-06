-- @XKID SCRIPT V2.1 (SMART EDITION)
-- by @WTF.XKID | Mobile/PC | All Executors
-- UPDATE: Smart Anti AFK 7min | Simple Custom FX | No DOF | Fixed Expand

repeat task.wait() until game:IsLoaded()

-- ================================ WINDUI LOADER ================================
local WindUI = (function() local s,r = pcall(function() return loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))() end) if s then return r else error("Failed to load WindUI") end end)()

-- ================================ EXECUTOR DETECTION ================================
local executor = {name="Unknown", has_writefile=false, has_readfile=false, has_listfiles=false, has_isfolder=false, has_makefolder=false, is_mobile_executor=false}
pcall(function() local e = identifyexecutor and identifyexecutor() or getexecutorname and getexecutorname() or "Unknown" executor.name = e executor.is_mobile_executor = (string.find(e, "Hydrogen") or string.find(e, "Arceus") or string.find(e, "Vega")) and true or false end)
executor.has_writefile = type(writefile)=="function" executor.has_readfile = type(readfile)=="function" executor.has_listfiles = type(listfiles)=="function" executor.has_isfolder = type(isfolder)=="function" executor.has_makefolder = type(makefolder)=="function"
if not executor.has_writefile then getgenv()._XKID_NO_SAVE = true warn("[XKID] Executor tidak support writefile") end

local function httpRequest(options)
    local rf = http_request or request or (syn and syn.request) or (fluxus and fluxus.request) or (http and http.request)
    if not rf then local hs = game:GetService("HttpService") return {StatusCode=200, Body=hs:GetAsync(options.Url,true), Success=true} end
    return rf(options)
end
getgenv()._XKID_REQUEST = httpRequest

-- ================================ FPS UNLOCKER ================================
local function setOptimalFPS(t) t=t or 120 pcall(function() if setfpscap then setfpscap(t) end end) pcall(function() local rs=settings():GetService("Rendering") if rs and rs.SetTargetFrameRate then rs:SetTargetFrameRate(t) end end) pcall(function() local ws=game:GetService("Workspace") if ws and ws.SetTargetFrameRate then ws:SetTargetFrameRate(t) end end) end
setOptimalFPS(120)

-- ================================ SERVICES ================================
local RS,HS,TS,PL,UI,VI,LT,TP,SS,CG,TCS,SG,RPS = game:GetService("RunService"), game:GetService("HttpService"), game:GetService("TweenService"), game:GetService("Players"), game:GetService("UserInputService"), game:GetService("VirtualUser"), game:GetService("Lighting"), game:GetService("TeleportService"), game:GetService("Stats"), game:GetService("CoreGui"), game:GetService("TextChatService"), game:GetService("StarterGui"), game:GetService("ReplicatedStorage")
local LP = PL.LocalPlayer
local Camera = workspace.CurrentCamera
local onMobile = not UI.KeyboardEnabled
getgenv()._XKID_UI_LOADING = true

-- ================================ ORIGINAL LIGHTING ================================
local origLight = {ClockTime=LT.ClockTime, Brightness=LT.Brightness, Ambient=LT.Ambient, OutdoorAmbient=LT.OutdoorAmbient, GlobalShadows=LT.GlobalShadows, ExposureCompensation=LT.ExposureCompensation}

-- ================================ CLEANUP ================================
if getgenv()._XKID_RUNNING then getgenv()._XKID_RUNNING=false; task.wait(0.5) end
if getgenv()._XKID_ESP_CACHE then for _,c in pairs(getgenv()._XKID_ESP_CACHE) do pcall(function() if c.texts then c.texts:Remove() end if c.tracer then c.tracer:Remove() end if c.boxLines then for _,l in ipairs(c.boxLines) do l:Remove() end end if c.hl then c.hl:Destroy() end end) end end
getgenv()._XKID_ESP_CACHE = {}
if getgenv()._XKID_LOADED then
    pcall(function() for _,v in pairs(CG:GetChildren()) do if v.Name=="WindUI" or v.Name=="XKID_FreecamUI" then v:Destroy() end end for _,v in pairs(LT:GetChildren()) do if v.Name=="_XKID_FILTER" then v:Destroy() end end if getgenv()._XKID_CONNS then for _,c in pairs(getgenv()._XKID_CONNS) do pcall(function() c:Disconnect() end) end end end)
    pcall(function() RS:UnbindFromRenderStep("XKIDFreecam") RS:UnbindFromRenderStep("XKIDFly") RS:UnbindFromRenderStep("XKIDSpec") RS:UnbindFromRenderStep("XKIDSelfSpec") RS:UnbindFromRenderStep("XKIDShiftLock") RS:UnbindFromRenderStep("XKIDAutoWalk") end)
end
getgenv()._XKID_LOADED=true getgenv()._XKID_RUNNING=true getgenv()._XKID_CONNS={}
local function TC(c) table.insert(getgenv()._XKID_CONNS,c); return c end
local function notify(t,c,d,i) local ok=pcall(function() WindUI:Notify({Title=t,Content=c,Duration=d or 2,Icon=i or "bell"}) end) if not ok then task.wait(0.03); pcall(function() WindUI:Notify({Title=t,Content=c,Duration=d or 2,Icon=i or "bell"}) end) end end

-- ================================ STATE ================================
local State = {
    Move={ws=16,jp=50,ncp=false,infJ=false,flyS=60,autoWalk=false,autoWalkSpeed=16},
    Fly={active=false,bv=nil,bg=nil,_keys={}},
    HardFling={active=false,power=10000,mode="Spin",currentPower=0,rampUpActive=false},
    Security={shiftLock=false,shiftLockGyro=nil,antiLag=false},
    Cinema={hideUI=false,cachedGuis={}},
    Avatar={isRefreshing=false},
    CustomFilter={r=255,g=255,b=255,sat=0,con=0,bri=0,exp=0,bloom=0,bloomSize=24,time=14},
    SelfSpec={active=false,mode="Manual",dist=8,height=3,orbitYaw=0,orbitPitch=20,fpYaw=0,fpPitch=0,origFov=70,radius=8,speed=1},
    ESP={active=false,cache=getgenv()._XKID_ESP_CACHE,tracerMode="Bottom",maxDist=300,highlight=false,boxN=Color3.fromRGB(0,255,150),boxS=Color3.fromRGB(220,20,60),boxG=Color3.fromRGB(255,165,0),traceN=Color3.fromRGB(0,200,255),traceS=Color3.fromRGB(220,20,60),traceG=Color3.fromRGB(255,165,0),nameC=Color3.fromRGB(255,255,255)},
}
local colorMap={Merah=Color3.fromRGB(255,0,0),Hijau=Color3.fromRGB(0,255,0),Biru=Color3.fromRGB(0,0,255),Kuning=Color3.fromRGB(255,255,0),Ungu=Color3.fromRGB(255,0,255),Cyan=Color3.fromRGB(0,255,255),Orange=Color3.fromRGB(255,165,0),Pink=Color3.fromRGB(255,105,180),Putih=Color3.fromRGB(255,255,255),Hitam=Color3.fromRGB(0,0,0),Crimson=Color3.fromRGB(220,20,60)}

-- ================================ HELPERS ================================
local function getRoot() return LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") end
local function getHum() return LP.Character and LP.Character:FindFirstChildOfClass("Humanoid") end
local function getCharRoot(c) if not c then return nil end return c:FindFirstChild("HumanoidRootPart") or c.PrimaryPart or c:FindFirstChild("Head") or c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso") or c:FindFirstChildWhichIsA("BasePart") end
local function getDisplayNames() local t={} for _,p in pairs(PL:GetPlayers()) do if p~=LP then table.insert(t,p.DisplayName) end end if #t==0 then table.insert(t,"N/A") end return t end
local function getDisplayNamesWithSelf() local t={"[Self]"} for _,p in pairs(PL:GetPlayers()) do if p~=LP then table.insert(t,p.DisplayName) end end if #t==1 then table.insert(t,"N/A") end return t end
local function findPlayerByDisplay(s) if s=="[Self]" then return LP end for _,p in pairs(PL:GetPlayers()) do if p.DisplayName==s or p.Name==s then return p end end return nil end
local function formatTime(s) local m=math.floor(s/60) local s2=s%60 return string.format("%02d:%02d",m,s2) end
local function makeBar(v,mx,l) local f=math.clamp(math.floor((v/mx)*l),0,l) return string.rep("█",f)..string.rep("░",l-f) end
local function isOnGround() local r=getRoot() if not r then return false end local p=RaycastParams.new() p.FilterType=Enum.RaycastFilterType.Exclude p.FilterDescendantsInstances={LP.Character} return workspace:Raycast(r.Position,Vector3.new(0,-5,0),p)~=nil end
local function getConfigList() local l={} if executor.has_isfolder and executor.has_listfiles then pcall(function() if isfolder and isfolder("XKID_HUB") then for _,f in ipairs(listfiles("XKID_HUB")) do if f:match("%.json$") then local n=f:match("([^/\\]+)%.json$") if n then table.insert(l,n) end end end end end) end if #l==0 then table.insert(l,"No config") end return l end

-- ================================ GLOBAL VARS ================================
local START_TIME=os.time()
local cachedMapName=nil local lastMapCheck=0 local sharedFPS=60 local sharedPing=0
TC(RS.RenderStepped:Connect(function(dt) if dt>0 then sharedFPS=math.floor(1/dt) end end))
task.spawn(function() while getgenv()._XKID_RUNNING do task.wait(0.5) pcall(function() local it=SS.Network.ServerStatsItem["Data Ping"] if it then sharedPing=math.floor(it:GetValue()) end end) end end)
task.spawn(function() while getgenv()._XKID_RUNNING do pcall(function() if tick()-lastMapCheck>30 or not cachedMapName then cachedMapName=game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name lastMapCheck=tick() end end) task.wait(5) end end)
task.spawn(function() while getgenv()._XKID_RUNNING do task.wait(120) collectgarbage("collect") end end)
task.spawn(function() while getgenv()._XKID_RUNNING do task.wait(30) setOptimalFPS(120) end end)
TC(LP.CharacterAdded:Connect(function() task.wait(0.5) setOptimalFPS(120) end))

-- ================================ SMART ANTI AFK (BEST - NO DISTURB + JUMP 7MIN) ================================
local VIM = pcall(function() return game:GetService("VirtualInputManager") end) and game:GetService("VirtualInputManager") or nil
local AFK = {active=false, thread=nil, lastActive=0, lastJump=0}
local JUMP_INT = 420 -- 7 menit (420 detik)
local CHECK_INT = 10

local function isUserActive()
    if UI:IsKeyDown(Enum.KeyCode.W) or UI:IsKeyDown(Enum.KeyCode.A) or UI:IsKeyDown(Enum.KeyCode.S) or UI:IsKeyDown(Enum.KeyCode.D) or UI:IsKeyDown(Enum.KeyCode.Space) or UI:IsKeyDown(Enum.KeyCode.LeftShift) or UI:IsKeyDown(Enum.KeyCode.MouseButton1) then return true end
    if onMobile then if #UI:GetTouchPositions()>0 then return true end end
    local hrp,hum=getRoot(),getHum()
    if hrp and hum and hum.MoveDirection.Magnitude>0.1 then return true end
    return false
end

local function sendSilentAFK()
    if VI and VI.ClickButton2 then pcall(function() local vp=Camera.ViewportSize VI:ClickButton2(Vector2.new(vp.X-5,vp.Y-5)) end) return true end
    pcall(function() local r=RPS:FindFirstChild("Remotes") if r then local sr=r:FindFirstChild("Ping") or r:FindFirstChild("Heartbeat") if sr and sr.FireServer then sr:FireServer() return true end end end)
    local hum=getHum() if hum then pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end) return true end
    pcall(function() local cf=Camera.CFrame Camera.CFrame=cf*CFrame.Angles(0,math.rad(0.5),0) task.wait(0.05) Camera.CFrame=cf end)
    return true
end

local function startAFK()
    if AFK.active then return end
    AFK.active=true State.Security.afkActive=true
    AFK.lastActive=tick() AFK.lastJump=tick()
    AFK.thread=task.spawn(function() while AFK.active do task.wait(CHECK_INT) local now=tick() if isUserActive() then AFK.lastActive=now elseif now-AFK.lastActive>=JUMP_INT and now-AFK.lastJump>=JUMP_INT then sendSilentAFK() AFK.lastJump=now end end end)
    notify("Anti AFK","ON (Jump 7min | Silent)",1.5,"shield-check")
end
local function stopAFK() AFK.active=false State.Security.afkActive=false if AFK.thread then task.cancel(AFK.thread) AFK.thread=nil end notify("Anti AFK","OFF",1.5,"shield-check") end
function ToggleAntiAFK() if AFK.active then stopAFK() else startAFK() end end

-- ================================ SHIFT LOCK ================================
TC(LP.CharacterAdded:Connect(function(char) task.wait(0.5) local hum=char:FindFirstChildOfClass("Humanoid") if hum then if State.Move.ws~=16 then hum.WalkSpeed=State.Move.ws end if State.Move.jp~=50 then hum.UseJumpPower=true hum.JumpPower=State.Move.jp end end if State.Security.shiftLock then task.wait(0.2) local hrp=getRoot() if hrp then if State.Security.shiftLockGyro then State.Security.shiftLockGyro:Destroy() end State.Security.shiftLockGyro=Instance.new("BodyGyro",hrp) State.Security.shiftLockGyro.MaxTorque=Vector3.new(9e9,9e9,9e9) State.Security.shiftLockGyro.P=50000 State.Security.shiftLockGyro.D=1000 end end end))
local function toggleShiftLock(v) State.Security.shiftLock=v if v then local hrp=getRoot() if hrp then if State.Security.shiftLockGyro then State.Security.shiftLockGyro:Destroy() end State.Security.shiftLockGyro=Instance.new("BodyGyro",hrp) State.Security.shiftLockGyro.MaxTorque=Vector3.new(9e9,9e9,9e9) State.Security.shiftLockGyro.P=50000 State.Security.shiftLockGyro.D=1000 end RS:BindToRenderStep("XKIDShiftLock",Enum.RenderPriority.Camera.Value+2,function() if not State.Security.shiftLock then return end local hrp2,gyro=getRoot(),State.Security.shiftLockGyro if hrp2 and gyro and gyro.Parent==hrp2 then local flatLook=Vector3.new(Camera.CFrame.LookVector.X,0,Camera.CFrame.LookVector.Z) if flatLook.Magnitude>0.01 then gyro.CFrame=CFrame.new(hrp2.Position,hrp2.Position+flatLook) end end end) notify("Shift Lock","ON",1.5,"lock") else RS:UnbindFromRenderStep("XKIDShiftLock") if State.Security.shiftLockGyro then State.Security.shiftLockGyro:Destroy() State.Security.shiftLockGyro=nil end notify("Shift Lock","OFF",1.5,"unlock") end end

-- ================================ REFRESH CHARACTER ================================
local refCF,refWS,refJP,refZoom=nil,16,50,400
local function refreshCharacter()
    if State.Avatar.isRefreshing then return end
    local char,hrp=LP.Character,getRoot()
    if not char or not hrp then notify("Error","Character not found",2,"circle-alert") return end
    State.Avatar.isRefreshing=true refCF=hrp.CFrame refWS=State.Move.ws refJP=State.Move.jp refZoom=LP.CameraMaxZoomDistance
    notify("Refresh","Reloading...",1.5,"refresh-cw") pcall(function() char:BreakJoints() end)
    local w=0 repeat task.wait(0.1) w=w+0.1 until not LP.Character or w>2
    if LP.Character then pcall(function() LP.Character:Destroy() end) task.wait(0.3) end
    if not LP.Character then pcall(function() LP:LoadCharacter() end) end
    task.delay(12,function() if State.Avatar.isRefreshing then State.Avatar.isRefreshing=false refCF=nil notify("Error","Refresh timeout",3,"circle-alert") end end)
end
TC(LP.CharacterAdded:Connect(function(newChar) if not State.Avatar.isRefreshing or not refCF then return end task.wait(0.3) local newHrp=newChar:FindFirstChild("HumanoidRootPart") or newChar:WaitForChild("HumanoidRootPart",8) local newHum=newChar:FindFirstChildOfClass("Humanoid") or newChar:WaitForChild("Humanoid",8) if newHrp and newHum then repeat task.wait() until newHum.Health>0 and newHrp:IsDescendantOf(workspace) newHrp.CFrame=refCF+Vector3.new(0,4,0) newHrp.AssemblyLinearVelocity=Vector3.zero newHrp.AssemblyAngularVelocity=Vector3.zero newHum.WalkSpeed=refWS newHum.UseJumpPower=true newHum.JumpPower=refJP Camera.CameraSubject=newHum Camera.CameraType=Enum.CameraType.Custom pcall(function() LP.CameraMaxZoomDistance=refZoom end) notify("Refresh","Done",2,"check-circle") end State.Avatar.isRefreshing=false refCF=nil end))

-- ================================ SMART TP ================================
local TPtool={clickConn=nil,clickActive=false,toolActive=false,tool=nil}
local function execTP() local hrp=getRoot() if not hrp then return end local m=LP:GetMouse() if m.Hit then hrp.CFrame=CFrame.new(m.Hit.Position+Vector3.new(0,3.5,0)) hrp.AssemblyLinearVelocity=Vector3.zero end end
local function toggleSmartTP(v) TPtool.clickActive=v if v then pcall(function() local t=Instance.new("Tool") t.Name="TP Tool" t.RequiresHandle=false t.Parent=LP.Backpack TPtool.tool=t TPtool.toolActive=false t.Activated:Connect(function() TPtool.toolActive=not TPtool.toolActive end) end) TPtool.clickConn=TC(UI.InputBegan:Connect(function(inp,gp) if gp then return end if inp.UserInputType==Enum.UserInputType.Touch or inp.UserInputType==Enum.UserInputType.MouseButton1 then if TPtool.toolActive then execTP() TPtool.toolActive=false end end end)) notify("Smart TP","ON",2,"map-pin") else if TPtool.clickConn then TPtool.clickConn:Disconnect() TPtool.clickConn=nil end pcall(function() if TPtool.tool then TPtool.tool:Destroy() TPtool.tool=nil end end) TPtool.toolActive=false notify("Smart TP","OFF",1.5,"map-pin") end end

-- ================================ AUTO WALK ================================
local function startAutoWalk() RS:UnbindFromRenderStep("XKIDAutoWalk") State.Move.autoWalk=true local hum=getHum() if hum then hum.WalkSpeed=State.Move.autoWalkSpeed end RS:BindToRenderStep("XKIDAutoWalk",Enum.RenderPriority.Character.Value+1,function() if not State.Move.autoWalk then return end local hrp,hum=getRoot(),getHum() if not hrp or not hum then return end if hum.MoveDirection.Magnitude>0.1 then return end local camDir=Camera.CFrame.LookVector local moveDir=Vector3.new(camDir.X,0,camDir.Z).Unit hrp.CFrame=hrp.CFrame+moveDir*(State.Move.autoWalkSpeed/60) end) notify("Auto Walk","ON",1.5,"play") end
local function stopAutoWalk() RS:UnbindFromRenderStep("XKIDAutoWalk") State.Move.autoWalk=false local hum=getHum() if hum then hum.WalkSpeed=State.Move.ws end notify("Auto Walk","OFF",1.5,"play") end

-- ================================ FLY ENGINE ================================
local fmT,fmS,fmJ,flyConns,flyVel=nil,nil,Vector2.zero,{},Vector3.zero
local function startFlyCap() local keys={} table.insert(flyConns,UI.InputBegan:Connect(function(inp,gp) if gp then return end local k=inp.KeyCode if k==Enum.KeyCode.W or k==Enum.KeyCode.A or k==Enum.KeyCode.S or k==Enum.KeyCode.D or k==Enum.KeyCode.E or k==Enum.KeyCode.Q then keys[k]=true end end)) table.insert(flyConns,UI.InputEnded:Connect(function(inp) keys[inp.KeyCode]=nil end)) table.insert(flyConns,UI.InputBegan:Connect(function(inp,gp) if gp or inp.UserInputType~=Enum.UserInputType.Touch then return end if inp.Position.X<=Camera.ViewportSize.X/2 then if not fmT then fmT=inp fmS=inp.Position end end end)) table.insert(flyConns,UI.TouchMoved:Connect(function(inp) if inp==fmT and fmS then local dx=inp.Position.X-fmS.X local dy=inp.Position.Y-fmS.Y local function ad(v,d,m) if math.abs(v)<d then return 0 end return math.clamp((v-math.sign(v)*d)/(m-d),-1,1) end fmJ=Vector2.new(ad(dx,25,80),ad(dy,20,80)) end end)) table.insert(flyConns,UI.InputEnded:Connect(function(inp) if inp.UserInputType~=Enum.UserInputType.Touch then return end if inp==fmT then fmT=nil fmS=nil fmJ=Vector2.zero end end)) State.Fly._keys=keys end
local function stopFlyCap() for _,c in ipairs(flyConns) do c:Disconnect() end flyConns={} fmT=nil fmS=nil fmJ=Vector2.zero State.Fly._keys={} end
local function toggleFly(v) if not v then State.Fly.active=false stopFlyCap() RS:UnbindFromRenderStep("XKIDFly") pcall(function() if State.Fly.bv then State.Fly.bv:Destroy() end end) pcall(function() if State.Fly.bg then State.Fly.bg:Destroy() end end) State.Fly.bv=nil State.Fly.bg=nil flyVel=Vector3.zero local hum=getHum() if hum then hum.PlatformStand=false hum:ChangeState(Enum.HumanoidStateType.GettingUp) hum.WalkSpeed=State.Move.ws hum.UseJumpPower=true hum.JumpPower=State.Move.jp end notify("Fly","OFF",1.5,"bird") return end local hrp,hum=getRoot(),getHum() if not hrp or not hum then return end State.Fly.active=true hum.PlatformStand=true flyVel=Vector3.zero State.Fly.bv=Instance.new("BodyVelocity",hrp) State.Fly.bv.MaxForce=Vector3.new(9e9,9e9,9e9) State.Fly.bg=Instance.new("BodyGyro",hrp) State.Fly.bg.MaxTorque=Vector3.new(9e9,9e9,9e9) State.Fly.bg.P=50000 startFlyCap() notify("Fly","ON",2,"bird") RS:BindToRenderStep("XKIDFly",Enum.RenderPriority.Camera.Value+1,function() if not State.Fly.active then return end local r=getRoot() if not r then return end local cf=Camera.CFrame local spd=State.Move.flyS local move=Vector3.zero local keys=State.Fly._keys or {} if onMobile then move=cf.LookVector*(-fmJ.Y)+cf.RightVector*fmJ.X else if keys[Enum.KeyCode.W] then move=move+cf.LookVector end if keys[Enum.KeyCode.S] then move=move-cf.LookVector end if keys[Enum.KeyCode.D] then move=move+cf.RightVector end if keys[Enum.KeyCode.A] then move=move-cf.RightVector end if keys[Enum.KeyCode.E] then move=move+Vector3.new(0,1,0) end if keys[Enum.KeyCode.Q] then move=move-Vector3.new(0,1,0) end end if move.Magnitude>0 then flyVel=flyVel:Lerp(move.Unit*spd,0.15) else flyVel=flyVel:Lerp(isOnGround() and Vector3.zero or Vector3.new(0,-0.8,0),0.08) end if State.Fly.bv and State.Fly.bv.Parent then State.Fly.bv.Velocity=flyVel end if State.Fly.bg and State.Fly.bg.Parent then State.Fly.bg.CFrame=CFrame.new(r.Position,r.Position+cf.LookVector) end end) end

-- ================================ FREECAM (DENGAN HIDE UI) ================================
local FC={active=false,pos=Vector3.zero,pitch=0,yaw=0,roll=0,speed=3,sens=0.25,origFov=70,savedWS=16,savedJP=50,wasAnchored=false}
local cVel,yVel,pVel,rVel,hVel=Vector3.zero,0,0,0,0
local fcMT,fcMS,fcJ,fcRT,fcRL,fcKH,fcCs=nil,nil,Vector2.zero,nil,nil,{},{}
local FC_UI_Btns={up=false,down=false,rollL=false,rollR=false,zoomIn=false,zoomOut=false}
local FC_UI_Hidden=false local fcBtns={}
local FCUI=Instance.new("ScreenGui") FCUI.Name="XKID_FreecamUI" FCUI.ResetOnSpawn=false FCUI.ZIndexBehavior=Enum.ZIndexBehavior.Global FCUI.Enabled=false FCUI.Parent=CG getgenv()._XKID_FCUI=FCUI
local function makeFCBtn(n,t,p,a) local b=Instance.new("TextButton",FCUI) b.Name=n b.Size=UDim2.new(0,44,0,44) b.Position=p b.BackgroundColor3=Color3.fromRGB(15,15,15) b.BackgroundTransparency=0.4 b.Text=t b.TextColor3=Color3.fromRGB(255,255,255) b.TextSize=18 b.Font=Enum.Font.GothamBold b.AutoButtonColor=false Instance.new("UICorner",b).CornerRadius=UDim.new(0,10) local us=Instance.new("UIStroke",b) us.Color=Color3.fromRGB(220,20,60) us.Thickness=2 us.Transparency=0.3 local ind=Instance.new("Frame",b) ind.Name="Indicator" ind.Size=UDim2.new(0,6,0,6) ind.Position=UDim2.new(0,4,0,4) ind.BackgroundColor3=Color3.fromRGB(60,60,60) Instance.new("UICorner",ind).CornerRadius=UDim.new(1,0) local function pr(d) FC_UI_Btns[a]=d b.BackgroundTransparency=d and 0.05 or 0.4 ind.BackgroundColor3=d and Color3.fromRGB(255,60,60) or Color3.fromRGB(60,60,60) end b.InputBegan:Connect(function(inp) if inp.UserInputType==Enum.UserInputType.Touch or inp.UserInputType==Enum.UserInputType.MouseButton1 then pr(true) end end) b.InputEnded:Connect(function(inp) if inp.UserInputType==Enum.UserInputType.Touch or inp.UserInputType==Enum.UserInputType.MouseButton1 then pr(false) end end) b.MouseLeave:Connect(function() pr(false) end) table.insert(fcBtns,b) return b end
makeFCBtn("BtnRollL","L",UDim2.new(1,-156,0.5,-66),"rollL") makeFCBtn("BtnRollR","R",UDim2.new(1,-58,0.5,-66),"rollR") makeFCBtn("BtnUp","↑",UDim2.new(1,-107,0.5,-110),"up") makeFCBtn("BtnDown","↓",UDim2.new(1,-107,0.5,-22),"down") makeFCBtn("BtnZIn","+",UDim2.new(1,-156,0.5,-22),"zoomIn") makeFCBtn("BtnZOut","-",UDim2.new(1,-58,0.5,-22),"zoomOut")
local eyeBtn=Instance.new("TextButton",FCUI) eyeBtn.Name="BtnEye" eyeBtn.Size=UDim2.new(0,44,0,44) eyeBtn.Position=UDim2.new(1,-107,0.5,-66) eyeBtn.BackgroundColor3=Color3.fromRGB(15,15,15) eyeBtn.BackgroundTransparency=0.6 eyeBtn.Text="👁" eyeBtn.TextColor3=Color3.fromRGB(255,255,255) eyeBtn.TextSize=18 eyeBtn.Font=Enum.Font.GothamBold eyeBtn.AutoButtonColor=false Instance.new("UICorner",eyeBtn).CornerRadius=UDim.new(0,10) Instance.new("UIStroke",eyeBtn)
local function toggleFCEye() FC_UI_Hidden=not FC_UI_Hidden eyeBtn.Text=FC_UI_Hidden and "👁‍🗨" or "👁" for _,b in ipairs(fcBtns) do b.Visible=not FC_UI_Hidden end end
eyeBtn.MouseButton1Click:Connect(toggleFCEye) eyeBtn.InputBegan:Connect(function(inp) if inp.UserInputType==Enum.UserInputType.Touch then toggleFCEye() end end)
local function startFCCap() fcKH={} table.insert(fcCs,UI.InputBegan:Connect(function(inp,gp) if gp then return end fcKH[inp.KeyCode]=true if inp.UserInputType==Enum.UserInputType.MouseButton2 then FC._mouseRot=true UI.MouseBehavior=Enum.MouseBehavior.LockCurrentPosition end end)) table.insert(fcCs,UI.InputEnded:Connect(function(inp) fcKH[inp.KeyCode]=false if inp.UserInputType==Enum.UserInputType.MouseButton2 then FC._mouseRot=false UI.MouseBehavior=Enum.MouseBehavior.Default end end)) table.insert(fcCs,UI.InputChanged:Connect(function(inp) if inp.UserInputType==Enum.UserInputType.MouseMovement and FC._mouseRot then yVel=yVel-inp.Delta.X*FC.sens*120 pVel=pVel-inp.Delta.Y*FC.sens*120 end end)) table.insert(fcCs,UI.InputBegan:Connect(function(inp,gp) if gp or inp.UserInputType~=Enum.UserInputType.Touch then return end if inp.Position.X>Camera.ViewportSize.X/2 then if not fcRT then fcRT=inp fcRL=inp.Position end else if not fcMT then fcMT=inp fcMS=inp.Position fcJ=Vector2.zero end end end)) table.insert(fcCs,UI.TouchMoved:Connect(function(inp) if inp==fcRT and fcRL then local dx=inp.Position.X-fcRL.X local dy=inp.Position.Y-fcRL.Y fcRL=inp.Position yVel=yVel-dx*FC.sens*80 pVel=pVel-dy*FC.sens*80 end if inp==fcMT and fcMS then local dx=inp.Position.X-fcMS.X local dy=inp.Position.Y-fcMS.Y local function ad(v,d,m) if math.abs(v)<d then return 0 end return math.clamp((v-math.sign(v)*d)/(m-d),-1,1) end fcJ=Vector2.new(ad(dx,15,70),ad(dy,15,70)) end end)) table.insert(fcCs,UI.InputEnded:Connect(function(inp) if inp.UserInputType~=Enum.UserInputType.Touch then return end if inp==fcRT then fcRT=nil fcRL=nil end if inp==fcMT then fcMT=nil fcMS=nil fcJ=Vector2.zero end end)) end
local function stopFCCap() for _,c in ipairs(fcCs) do c:Disconnect() end fcCs={} fcKH={} FC._mouseRot=false UI.MouseBehavior=Enum.MouseBehavior.Default end
local function startFCLoop() RS:BindToRenderStep("XKIDFreecam",Enum.RenderPriority.Camera.Value+1,function(dt) if not FC.active then return end Camera.CameraType=Enum.CameraType.Scriptable local sdt=math.clamp(dt,0.001,0.05) yVel=yVel*math.max(0,1-sdt*14) pVel=pVel*math.max(0,1-sdt*14) FC.yaw=FC.yaw+yVel*sdt FC.pitch=math.clamp(FC.pitch+pVel*sdt,-80,80) local rT=0 if FC_UI_Btns.rollL then rT=-100 elseif FC_UI_Btns.rollR then rT=100 end rVel=rVel+(rT-rVel)*math.clamp(sdt*5,0,1) FC.roll=math.clamp(FC.roll+rVel*sdt,-100,100) local cf=CFrame.new(FC.pos)*CFrame.Angles(0,math.rad(FC.yaw),0)*CFrame.Angles(math.rad(FC.pitch),0,0) local jx,jy=fcJ.X,fcJ.Y if not onMobile then if fcKH[Enum.KeyCode.W] then jy=jy-1 end if fcKH[Enum.KeyCode.S] then jy=jy+1 end if fcKH[Enum.KeyCode.D] then jx=jx+1 end if fcKH[Enum.KeyCode.A] then jx=jx-1 end end local rm=Vector2.new(jx,jy) if rm.Magnitude>1 then rm=rm.Unit end cVel=cVel:Lerp((cf.LookVector*(-rm.Y)+cf.RightVector*rm.X)*(FC.speed*60),math.clamp(sdt*3.5,0,1)) local hT=0 if fcKH[Enum.KeyCode.E] or FC_UI_Btns.up then hT=FC.speed*60 end if fcKH[Enum.KeyCode.Q] or FC_UI_Btns.down then hT=-FC.speed*60 end if hT==0 then hVel=hVel*math.max(0,1-sdt*10) else hVel=hVel+(hT-hVel)*math.clamp(sdt*3,0,1) end if FC_UI_Btns.zoomIn then Camera.FieldOfView=math.clamp(Camera.FieldOfView-1.2,10,120) end if FC_UI_Btns.zoomOut then Camera.FieldOfView=math.clamp(Camera.FieldOfView+1.2,10,120) end FC.pos=FC.pos+(cVel+Vector3.new(0,hVel,0))*sdt Camera.CFrame=CFrame.new(FC.pos)*CFrame.Angles(0,math.rad(FC.yaw),0)*CFrame.Angles(math.rad(FC.pitch),0,0)*CFrame.Angles(0,0,math.rad(FC.roll)) end) end
local function stopFCLoop() RS:UnbindFromRenderStep("XKIDFreecam") end
local function fullCleanupFC() stopFCLoop() stopFCCap() local hum,hrp=getHum(),getRoot() if hum then hum.WalkSpeed=FC.savedWS hum.UseJumpPower=true hum.JumpPower=FC.savedJP end if FC.wasAnchored and hrp then hrp.Anchored=false FC.wasAnchored=false end Camera.CameraType=Enum.CameraType.Custom Camera.FieldOfView=FC.origFov if getgenv()._XKID_FCUI then getgenv()._XKID_FCUI.Enabled=false end for k in pairs(FC_UI_Btns) do FC_UI_Btns[k]=false end FC_UI_Hidden=false eyeBtn.Text="👁" for _,b in ipairs(fcBtns) do b.Visible=true end end

-- ================================ SELF-SPECTATE ================================
local SSs=State.SelfSpec
local stm,spin,spinD,span,scns=nil,{},nil,Vector2.zero,{}
local function startSSG() scns={} table.insert(scns,UI.InputBegan:Connect(function(inp,gp) if gp or not SSs.active or inp.UserInputType~=Enum.UserInputType.Touch then return end table.insert(spin,inp) stm=#spin==1 and inp or nil end)) table.insert(scns,UI.InputChanged:Connect(function(inp) if not SSs.active or inp.UserInputType~=Enum.UserInputType.Touch then return end if #spin==1 and inp==stm then span=span+Vector2.new(inp.Delta.X,inp.Delta.Y) elseif #spin>=2 then local d=(spin[1].Position-spin[2].Position).Magnitude if spinD then local diff=d-spinD Camera.FieldOfView=math.clamp(Camera.FieldOfView-diff*0.15,10,120) SSs.radius=math.clamp(SSs.radius-diff*0.03,3,30) end spinD=d end end)) table.insert(scns,UI.InputEnded:Connect(function(inp) if inp.UserInputType~=Enum.UserInputType.Touch then return end for i,v in ipairs(spin) do if v==inp then table.remove(spin,i) break end end spinD=nil stm=#spin==1 and spin[1] or nil end)) end
local function stopSSG() for _,c in ipairs(scns) do c:Disconnect() end scns={} stm=nil spin={} spinD=nil span=Vector2.zero end
local function startSSL() RS:UnbindFromRenderStep("XKIDSelfSpec") RS:BindToRenderStep("XKIDSelfSpec",Enum.RenderPriority.Camera.Value+1,function() if not SSs.active then return end pcall(function() local tChar=LP.Character local tHrp=getCharRoot(tChar) if not tHrp then return end Camera.CameraType=Enum.CameraType.Scriptable local pan,sens=span,onMobile and 0.2 or 0.3 span=Vector2.zero if SSs.mode=="First Person" then local head=tChar:FindFirstChild("Head") local org=head and head.Position or tHrp.Position+Vector3.new(0,1.5,0) SSs.fpYaw=SSs.fpYaw-pan.X*sens SSs.fpPitch=math.clamp(SSs.fpPitch-pan.Y*sens,-85,85) Camera.CFrame=CFrame.new(org)*CFrame.Angles(0,math.rad(SSs.fpYaw),0)*CFrame.Angles(math.rad(SSs.fpPitch),0,0) else if #spin==0 and pan.Magnitude<0.01 then local dt=0.016 if SSs.mode=="Slow Orbit" then SSs.orbitYaw=SSs.orbitYaw+dt*25*SSs.speed elseif SSs.mode=="Vertical Swing" then SSs.orbitPitch=20+math.sin(tick()*SSs.speed*1.5)*40 SSs.orbitYaw=SSs.orbitYaw+dt*10*SSs.speed elseif SSs.mode=="Figure 8" then SSs.orbitYaw=math.sin(tick()*SSs.speed*0.8)*80 SSs.orbitPitch=20+math.sin(tick()*SSs.speed*1.2)*35 elseif SSs.mode=="Cinematic Drift" then SSs.orbitYaw=SSs.orbitYaw+dt*15*SSs.speed SSs.orbitPitch=20+math.sin(tick()*SSs.speed*0.7)*15 elseif SSs.mode=="Top Down" then SSs.orbitPitch=-75 SSs.orbitYaw=SSs.orbitYaw+dt*8*SSs.speed end end SSs.orbitYaw=SSs.orbitYaw+pan.X*sens SSs.orbitPitch=math.clamp(SSs.orbitPitch+pan.Y*sens,-75,75) local h=(SSs.mode=="Top Down") and 15 or (SSs.height or 3) Camera.CFrame=CFrame.new((CFrame.new(tHrp.Position+Vector3.new(0,h,0))*CFrame.Angles(0,math.rad(-SSs.orbitYaw),0)*CFrame.Angles(math.rad(-SSs.orbitPitch),0,0)*CFrame.new(0,0,SSs.radius)).Position,tHrp.Position+Vector3.new(0,h,0)) end end) end) end
local function stopSSL() RS:UnbindFromRenderStep("XKIDSelfSpec") Camera.CameraType=Enum.CameraType.Custom Camera.FieldOfView=SSs.origFov SSs.active=false SSs.orbitYaw=0 SSs.orbitPitch=20 SSs.fpYaw=0 SSs.fpPitch=0 SSs.radius=8 SSs.height=3 span=Vector2.zero end
local function toggleSelfSpec(v) if v then if FC.active then fullCleanupFC() end if State.Fly.active then stopFlyCap() end if Spec and Spec.active then stopSpecCap() end if TPtool.clickConn then TPtool.clickConn:Disconnect() TPtool.clickConn=nil end SSs.active=true SSs.origFov=Camera.FieldOfView SSs.orbitYaw=0 SSs.orbitPitch=20 SSs.fpYaw=0 SSs.fpPitch=0 SSs.radius=SSs.radius or 8 SSs.height=SSs.height or 3 startSSG() startSSL() notify("Self-Spectate","ON — "..(SSs.mode or "Manual"),2,"camera") else SSs.active=false stopSSG() stopSSL() notify("Self-Spectate","OFF",1.5,"camera") end end

-- ================================ SPECTATE ================================
local Spec={active=false,target=nil,mode="third",dist=8,origFov=70,orbitYaw=0,orbitPitch=0,fpYaw=0,fpPitch=0,isSelf=false}
local stm2,spin2,spinD2,span2,scns2=nil,{},nil,Vector2.zero,{}
local function startSpecCap() table.insert(scns2,UI.InputBegan:Connect(function(inp,gp) if gp or not Spec.active or inp.UserInputType~=Enum.UserInputType.Touch then return end table.insert(spin2,inp) stm2=#spin2==1 and inp or nil end)) table.insert(scns2,UI.InputChanged:Connect(function(inp) if not Spec.active or inp.UserInputType~=Enum.UserInputType.Touch then return end if #spin2==1 and inp==stm2 then span2=span2+Vector2.new(inp.Delta.X,inp.Delta.Y) elseif #spin2>=2 then local d=(spin2[1].Position-spin2[2].Position).Magnitude if spinD2 then local diff=d-spinD2 Camera.FieldOfView=math.clamp(Camera.FieldOfView-diff*0.15,10,120) if Spec.mode=="third" then Spec.dist=math.clamp(Spec.dist-diff*0.03,3,30) end end spinD2=d end end)) table.insert(scns2,UI.InputEnded:Connect(function(inp) if inp.UserInputType~=Enum.UserInputType.Touch then return end for i,v in ipairs(spin2) do if v==inp then table.remove(spin2,i) break end end spinD2=nil stm2=#spin2==1 and spin2[1] or nil end)) end
local function stopSpecCap() for _,c in ipairs(scns2) do c:Disconnect() end scns2={} stm2=nil spin2={} spinD2=nil span2=Vector2.zero end
local function startSpecLoop() RS:BindToRenderStep("XKIDSpec",Enum.RenderPriority.Camera.Value+1,function() if not Spec.active then return end pcall(function() local tChar,tHrp if Spec.isSelf then tChar=LP.Character tHrp=getCharRoot(tChar) else if not Spec.target or not Spec.target.Character then Spec.active=false stopSpecLoop() stopSpecCap() Camera.CameraType=Enum.CameraType.Custom Camera.FieldOfView=Spec.origFov return end tChar=Spec.target.Character tHrp=tChar:FindFirstChild("HumanoidRootPart") end if not tHrp then if not Spec.isSelf then Spec.active=false stopSpecLoop() stopSpecCap() Camera.CameraType=Enum.CameraType.Custom Camera.FieldOfView=Spec.origFov end return end Camera.CameraType=Enum.CameraType.Scriptable local pan,sens=span2,0.3 span2=Vector2.zero if Spec.mode=="third" then Spec.orbitYaw=Spec.orbitYaw+pan.X*sens Spec.orbitPitch=math.clamp(Spec.orbitPitch+pan.Y*sens,-75,75) Camera.CFrame=CFrame.new((CFrame.new(tHrp.Position)*CFrame.Angles(0,math.rad(-Spec.orbitYaw),0)*CFrame.Angles(math.rad(-Spec.orbitPitch),0,0)*CFrame.new(0,0,Spec.dist)).Position,tHrp.Position+Vector3.new(0,1,0)) else local head=tChar:FindFirstChild("Head") local org=head and head.Position or tHrp.Position+Vector3.new(0,1.5,0) Spec.fpYaw=Spec.fpYaw-pan.X*sens Spec.fpPitch=math.clamp(Spec.fpPitch-pan.Y*sens,-85,85) Camera.CFrame=CFrame.new(org)*CFrame.Angles(0,math.rad(Spec.fpYaw),0)*CFrame.Angles(math.rad(Spec.fpPitch),0,0) end end) end) end
local function stopSpecLoop() RS:UnbindFromRenderStep("XKIDSpec") end

-- ================================ HARD FLING ================================
local hfConn,hfRampConn,hfBAV=nil,nil,nil
local function startHardFling()
    if State.HardFling.active then return end
    State.HardFling.active=true State.Move.ncp=true State.HardFling.currentPower=0 State.HardFling.rampUpActive=true
    local hrp=getRoot() if hrp then hfBAV=Instance.new("BodyAngularVelocity",hrp) hfBAV.MaxTorque=Vector3.new(9e9,9e9,9e9) hfBAV.P=100000 end
    local rStart=tick() hfRampConn=TC(RS.Heartbeat:Connect(function() if not State.HardFling.rampUpActive then return end local t=math.clamp((tick()-rStart)/2,0,1) State.HardFling.currentPower=State.HardFling.power*t if t>=1 then State.HardFling.currentPower=State.HardFling.power State.HardFling.rampUpActive=false end end))
    hfConn=TC(RS.Heartbeat:Connect(function() if not State.HardFling.active then return end local r=getRoot() if not r then return end if State.HardFling.mode=="Spin" then if hfBAV and hfBAV.Parent then hfBAV.AngularVelocity=Vector3.new(0,State.HardFling.currentPower,0) end elseif State.HardFling.mode=="Shake" then if hfBAV and hfBAV.Parent then local sx=(math.random()-0.5)*State.HardFling.currentPower*0.5 local sy=(math.random()-0.5)*State.HardFling.currentPower*0.3 local sz=(math.random()-0.5)*State.HardFling.currentPower*0.5 hfBAV.AngularVelocity=Vector3.new(sx,sy,sz) end end if LP.Character then for _,p in pairs(LP.Character:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=false end end end end))
    notify("Hard Fling","ON — "..State.HardFling.mode,2,"zap")
end
local function stopHardFling()
    State.HardFling.active=false State.HardFling.rampUpActive=false State.HardFling.currentPower=0
    if hfConn then hfConn:Disconnect() hfConn=nil end
    if hfRampConn then hfRampConn:Disconnect() hfRampConn=nil end
    if hfBAV then hfBAV:Destroy() hfBAV=nil end
    local r=getRoot() if r then pcall(function() r.AssemblyAngularVelocity=Vector3.zero r.AssemblyLinearVelocity=Vector3.zero end) end
    if LP.Character then for _,p in pairs(LP.Character:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=true end end end
    notify("Hard Fling","OFF",1.5,"zap")
end

-- ================================ SIMPLE CUSTOM FX (NO DOF) ================================
local function resetFilter() for _,v in pairs(LT:GetChildren()) do if v.Name=="_XKID_FILTER" then v:Destroy() end end end
local function applyCustomFilter()
    resetFilter()
    LT.Brightness=origLight.Brightness LT.Ambient=origLight.Ambient LT.OutdoorAmbient=origLight.OutdoorAmbient LT.GlobalShadows=origLight.GlobalShadows LT.ExposureCompensation=State.CustomFilter.exp
    local cc=Instance.new("ColorCorrectionEffect",LT) cc.Name="_XKID_FILTER" cc.TintColor=Color3.fromRGB(State.CustomFilter.r,State.CustomFilter.g,State.CustomFilter.b) cc.Saturation=State.CustomFilter.sat cc.Contrast=State.CustomFilter.con cc.Brightness=State.CustomFilter.bri
    local bloom=Instance.new("BloomEffect",LT) bloom.Name="_XKID_FILTER" bloom.Intensity=State.CustomFilter.bloom bloom.Size=State.CustomFilter.bloomSize
    LT.ClockTime=State.CustomFilter.time
end
local FILTER_PRESETS={
    Default={r=255,g=255,b=255,sat=0,con=0,bri=0,exp=0,bloom=0,bloomS=24,time=14},
    Mendung={r=180,g=185,b=200,sat=-0.3,con=0.1,bri=-0.15,exp=0,bloom=0.05,bloomS=24,time=10},
    CoolBlue={r=180,g=200,b=255,sat=0.1,con=0.15,bri=0.05,exp=0,bloom=0.2,bloomS=24,time=12},
    SoftFade={r=255,g=240,b=235,sat=-0.1,con=-0.05,bri=0.1,exp=0,bloom=0.4,bloomS=35,time=15},
    FullBright={r=255,g=255,b=255,sat=0,con=0,bri=0,exp=0,bloom=0,bloomS=24,time=12,lightB=3,shadow=false},
    Night={r=200,g=200,b=255,sat=0.1,con=0.2,bri=0,exp=0,bloom=0.15,bloomS=24,time=1},
    Senja={r=255,g=180,b=120,sat=0.2,con=0.1,bri=0.05,exp=0,bloom=0.5,bloomS=40,time=17.5},
    Golden={r=255,g=200,b=100,sat=0.1,con=0.15,bri=0.1,exp=0,bloom=0.4,bloomS=35,time=17.5},
}
local function applyFilter(name)
    resetFilter() LT.ClockTime=origLight.ClockTime LT.Brightness=origLight.Brightness LT.Ambient=origLight.Ambient LT.OutdoorAmbient=origLight.OutdoorAmbient LT.GlobalShadows=origLight.GlobalShadows LT.ExposureCompensation=origLight.ExposureCompensation
    if name=="Default" then State.CustomFilter={r=255,g=255,b=255,sat=0,con=0,bri=0,exp=0,bloom=0,bloomSize=24,time=14} notify("Visuals","Default",1.5,"palette") return end
    if name=="Custom" then applyCustomFilter() notify("Visuals","Custom FX",1.5,"palette") return end
    local p=FILTER_PRESETS[name:gsub(" ","")]
    if p then LT.ClockTime=p.time or 14 LT.Brightness=p.lightB or 1 LT.ExposureCompensation=p.exp or 0 LT.GlobalShadows=p.shadow~=false local cc=Instance.new("ColorCorrectionEffect",LT) cc.Name="_XKID_FILTER" cc.TintColor=Color3.fromRGB(p.r,p.g,p.b) cc.Saturation=p.sat or 0 cc.Contrast=p.con or 0 cc.Brightness=p.bri or 0 local bl=Instance.new("BloomEffect",LT) bl.Name="_XKID_FILTER" bl.Intensity=p.bloom or 0 bl.Size=p.bloomS or 24 for k,v in pairs(p) do if State.CustomFilter[k]~=nil then State.CustomFilter[k]=v end end notify("Visuals",name,2,"palette") else notify("Visuals","Filter not found",2,"circle-alert") end
end

-- ================================ ESP ENGINE (THROTTLED) ================================
local espList={}
local function initESP(p) if State.ESP.cache[p] then return end local c={texts=nil,tracer=nil,boxLines={},hl=nil,isSus=false,isGlitch=false,reason=""} pcall(function() c.texts=Drawing.new("Text") if c.texts then c.texts.Center=true c.texts.Outline=true c.texts.Font=2 c.texts.Size=13 c.texts.ZIndex=2 end c.tracer=Drawing.new("Line") if c.tracer then c.tracer.Thickness=1.5 c.tracer.ZIndex=1 end for i=1,4 do local l=Drawing.new("Line") if l then l.Thickness=1.5 l.ZIndex=1 c.boxLines[i]=l end end end) State.ESP.cache[p]=c end
local function clearESP(p) local c=State.ESP.cache[p] if not c then return end pcall(function() if c.texts then c.texts:Remove() end end) pcall(function() if c.tracer then c.tracer:Remove() end end) for _,l in ipairs(c.boxLines) do pcall(function() if l then l:Remove() end end) end pcall(function() if c.hl then c.hl:Destroy() end end) State.ESP.cache[p]=nil end
TC(PL.PlayerRemoving:Connect(clearESP))
task.spawn(function() while getgenv()._XKID_RUNNING do if State.ESP.active then local tmp={} local myHrp=getCharRoot(LP.Character) for _,p in pairs(PL:GetPlayers()) do if p~=LP and p.Character then local isSus,isGlitch,reason=false,false,"" for _,v in pairs(p.Character:GetChildren()) do if v:IsA("BasePart") and (v.Size.X>30 or v.Size.Y>30 or v.Size.Z>30) then isSus=true reason="Map Blocker" break elseif v:IsA("Accessory") then local h=v:FindFirstChild("Handle") if h and h:IsA("BasePart") then if h.Size.Magnitude>20 then isSus=true reason="Huge Hat" break elseif h.Size.Magnitude>10 or (h.Transparency<0.1 and h.Material==Enum.Material.Neon) then isGlitch=true reason="Glitch Acc" end end end end if not isSus and not isGlitch then local hum=p.Character:FindFirstChildOfClass("Humanoid") if hum then local bws=hum:FindFirstChild("BodyWidthScale") local bhs=hum:FindFirstChild("BodyHeightScale") if (bws and bws.Value>2) or (bhs and bhs.Value>2) then isSus=true reason="Glitch Avatar" end end end initESP(p) if State.ESP.cache[p] then State.ESP.cache[p].isSuspect=isSus State.ESP.cache[p].isGlitch=isGlitch State.ESP.cache[p].reason=reason end if myHrp then local hrp=getCharRoot(p.Character) local hum=p.Character:FindFirstChildOfClass("Humanoid") if hrp and hum and hum.Health>0 then local dist=(hrp.Position-myHrp.Position).Magnitude if dist<=State.ESP.maxDist then table.insert(tmp,{p=p,hrp=hrp,dist=dist,char=p.Character}) end end end end end table.sort(tmp,function(a,b) return a.dist<b.dist end) espList=tmp end task.wait(0.3) end end)
TC(RS.RenderStepped:Connect(function() if not State.ESP.active then return end local myHrp=getCharRoot(LP.Character) if not myHrp then return end local vp=Camera.ViewportSize local ct=Vector2.new(vp.X/2,vp.Y/2) for _,c in pairs(State.ESP.cache) do pcall(function() if c.texts then c.texts.Visible=false end if c.tracer then c.tracer.Visible=false end for _,l in ipairs(c.boxLines) do if l then l.Visible=false end end if c.hl then c.hl.Enabled=false end end) end local hlC=0 for _,d in ipairs(espList) do local p,char,hrp,dist=d.p,d.char,d.hrp,d.dist local c=State.ESP.cache[p] if not c then continue end local pos,vis=Camera:WorldToViewportPoint(hrp.Position) if not vis then continue end local sus,glitch=c.isSuspect,c.isGlitch local useHl=sus or glitch or State.ESP.highlight local txt=string.format("%s\n[%dm]",p.DisplayName,math.floor(dist)) if sus or glitch then txt=txt.."\n⚠ "..c.reason end local cCol=sus and State.ESP.boxS or (glitch and State.ESP.boxG or State.ESP.nameC) local tCol=sus and State.ESP.traceS or (glitch and State.ESP.traceG or State.ESP.traceN) local bCol=sus and State.ESP.boxS or (glitch and State.ESP.boxG or State.ESP.boxN) pcall(function() if c.texts then c.texts.Text=txt c.texts.Color=cCol c.texts.Position=Vector2.new(pos.X,pos.Y-45) c.texts.Visible=true end if State.ESP.tracerMode~="OFF" and c.tracer then local org=Vector2.new(vp.X/2,vp.Y) if State.ESP.tracerMode=="Center" then org=ct elseif State.ESP.tracerMode=="Mouse" then local m=UI:GetMouseLocation() org=Vector2.new(m.X,m.Y) end c.tracer.From=org c.tracer.To=Vector2.new(pos.X,pos.Y) c.tracer.Color=tCol c.tracer.Visible=true end end) if useHl and hlC<30 then hlC=hlC+1 pcall(function() local top,topVis=Camera:WorldToViewportPoint(hrp.Position+Vector3.new(0,3,0)) local bot,botVis=Camera:WorldToViewportPoint(hrp.Position-Vector3.new(0,3.5,0)) if topVis and botVis and #c.boxLines==4 then local bh=math.abs(top.Y-bot.Y) local bw=bh*0.6 c.boxLines[1].From=Vector2.new(pos.X-bw/2,top.Y) c.boxLines[1].To=Vector2.new(pos.X+bw/2,top.Y) c.boxLines[2].From=Vector2.new(pos.X+bw/2,top.Y) c.boxLines[2].To=Vector2.new(pos.X+bw/2,bot.Y) c.boxLines[3].From=Vector2.new(pos.X+bw/2,bot.Y) c.boxLines[3].To=Vector2.new(pos.X-bw/2,bot.Y) c.boxLines[4].From=Vector2.new(pos.X-bw/2,bot.Y) c.boxLines[4].To=Vector2.new(pos.X-bw/2,top.Y) for i=1,4 do c.boxLines[i].Color=bCol c.boxLines[i].Visible=true end end end) pcall(function() if not c.hl or c.hl.Parent~=char then if c.hl then c.hl:Destroy() end c.hl=Instance.new("Highlight",char) c.hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop end if c.hl then c.hl.FillColor=bCol c.hl.OutlineColor=Color3.new(1,1,1) c.hl.Enabled=true end end) end end end))

-- ================================ MAIN WINDOW UI ================================
local Win = WindUI:CreateWindow({Title="XKID HUB V2.1",Icon="bluetooth",Author="@WTF.XKID",Folder="XKIDHub",Size=UDim2.fromOffset(360,320),Transparent=true,Theme="Crimson",SideBarWidth=160,User={Enabled=true,Anonymous=false},Topbar={Height=40,ButtonsType="Default"}})
pcall(function() WindUI:SetFont("rbxassetid://12187376357") WindUI:SetNotificationLower(true) Win.User:SetDisplayName(LP.DisplayName) Win.User:SetUsername("@"..LP.Name) end)
Win:EditOpenButton({Title="XKID V2.1",Icon="github",CornerRadius=UDim.new(1,0),StrokeThickness=2,StrokeColor=Color3.fromRGB(255,70,120),Enabled=true,Draggable=true,Scale=0.72})
local fpsTag=Win:Tag({Title="FPS: -- | Ping: --",Color=Color3.fromRGB(255,215,0),Icon="github"})
task.spawn(function() while getgenv()._XKID_RUNNING do task.wait(1) if fpsTag and fpsTag.SetTitle then fpsTag:SetTitle("FPS: "..sharedFPS.." | Ping: "..sharedPing.."ms") end end end)

-- TAB: INFORMASI
local tabInfo=Win:Tab({Title="Informasi",Icon="activity"})
local function getExec() pcall(function() local e=identifyexecutor() if e and e~="" then return e end end) pcall(function() local e=getexecutorname() if e and e~="" then return e end end) return executor.name end
local execN=getExec() local accAge=LP.AccountAge.." days" local avatarImg="rbxthumb://type=AvatarHeadShot&id="..LP.UserId.."&w=420&h=420"
local afkP=tabInfo:Paragraph({Title="YooWssp!!, "..LP.DisplayName,Desc="Executor: "..execN.."\nAccount Age: "..accAge.."\nUserID: "..LP.UserId.."\nStatus: "..(LP.MembershipType==Enum.MembershipType.Premium and "Premium" or "Normal").."\nAnti AFK: ON ✅",Image=avatarImg,ImageSize=80})
task.spawn(function() while getgenv()._XKID_RUNNING do task.wait(1) pcall(function() afkP:SetDesc("Executor: "..execN.."\nAccount Age: "..accAge.."\nUserID: "..LP.UserId.."\nStatus: "..(LP.MembershipType==Enum.MembershipType.Premium and "Premium" or "Normal").."\nAnti AFK: "..(AFK.active and "ON ✅" or "OFF ❌")) end) end end)
local infoP=tabInfo:Paragraph({Title="💀 "..LP.DisplayName.."\n⚡ "..makeBar(sharedFPS,120,10).." "..sharedFPS.." FPS\n📡 "..makeBar(math.max(1,200-sharedPing),200,10).." "..sharedPing.."ms\n🕐 "..makeBar(os.difftime(os.time(),START_TIME)%3600,3600,10).." "..formatTime(os.difftime(os.time(),START_TIME)),Desc="👤 "..LP.DisplayName.."\n📱 "..(onMobile and "Mobile" or "PC").." | 🚀 "..execN.."\n\n🎮 "..(cachedMapName or "Loading...").."\n👥 "..makeBar(#PL:GetPlayers(),PL.MaxPlayers,10).." "..#PL:GetPlayers().."/"..PL.MaxPlayers.." Players\n\n🌐 discord.gg/bzumc2u96"})
task.spawn(function() while getgenv()._XKID_RUNNING do task.wait(1) pcall(function() infoP:SetTitle("💀 "..LP.DisplayName.."\n⚡ "..makeBar(sharedFPS,120,10).." "..sharedFPS.." FPS\n📡 "..makeBar(math.max(1,200-sharedPing),200,10).." "..sharedPing.."ms\n🕐 "..makeBar(os.difftime(os.time(),START_TIME)%3600,3600,10).." "..formatTime(os.difftime(os.time(),START_TIME))) end) end end)
tabInfo:Section({Title="🔗 Discord",Icon="message-circle",Box=true}):Button({Title="Copy Discord Link",Desc="discord.gg/bzumc2u96",Callback=function() pcall(function() setclipboard("https://discord.gg/bzumc2u96") end) notify("System","Link copied",2,"copy") end})

-- TAB: CHARACTER
local tabChar=Win:Tab({Title="Character",Icon="fingerprint"})
tabChar:Button({Title="Refresh Character 🔄",Desc="Reload character like /re",Callback=refreshCharacter})
local secMov=tabChar:Section({Title="Movement",Icon="activity",Box=true})
secMov:Slider({Title="Walk Speed",Step=1,Value={Min=16,Max=500,Default=16},Callback=function(v) State.Move.ws=v if getHum() then getHum().WalkSpeed=v end end})
secMov:Slider({Title="Jump Power",Step=1,Value={Min=50,Max=500,Default=50},Callback=function(v) State.Move.jp=v local h=getHum() if h then h.UseJumpPower=true h.JumpPower=v end end})
secMov:Toggle({Title="Infinite Jump",Default=false,Callback=function(v) if v then State.Move.infJ=TC(UI.JumpRequest:Connect(function() if getHum() then getHum():ChangeState(Enum.HumanoidStateType.Jumping) end end)) else if State.Move.infJ then State.Move.infJ:Disconnect() State.Move.infJ=nil end end notify("Infinite Jump",v and "ON" or "OFF",1.5,"arrow-big-up") end})
local secAW=tabChar:Section({Title="Auto Walk",Icon="play",Box=true})
secAW:Toggle({Title="Auto Walk",Default=false,Callback=function(v) if v then startAutoWalk() else stopAutoWalk() end end})
secAW:Slider({Title="Walk Speed",Step=1,Value={Min=1,Max=100,Default=16},Callback=function(v) State.Move.autoWalkSpeed=v if State.Move.autoWalk then local h=getHum() if h then h.WalkSpeed=v end end end})
secAW:Paragraph({Title="Info",Desc="Character walks forward automatically\nMove manually to override"})
local secAbi=tabChar:Section({Title="Abilities",Icon="zap",Box=true})
secAbi:Toggle({Title="Fly",Default=false,Callback=function(v) toggleFly(v) end})
secAbi:Slider({Title="Fly Speed",Step=1,Value={Min=10,Max=300,Default=60},Callback=function(v) State.Move.flyS=v end})
local ncConn=nil
secAbi:Toggle({Title="NoClip",Default=false,Callback=function(v) State.Move.ncp=v if v then if not ncConn then ncConn=TC(RS.Heartbeat:Connect(function() if not State.Move.ncp then return end if LP.Character then for _,p in pairs(LP.Character:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=false end end end end)) end else if ncConn then ncConn:Disconnect() ncConn=nil end if LP.Character then for _,p in pairs(LP.Character:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=true end end end end notify("NoClip",v and "ON" or "OFF",1.5,"ghost") end})
local secFling=tabChar:Section({Title="Hard Fling (Safe)",Icon="rotate-cw",Box=true})
secFling:Toggle({Title="Hard Fling",Default=false,Callback=function(v) if v then startHardFling() else stopHardFling() end end})
secFling:Dropdown({Title="Fling Mode",Values={"Spin","Shake"},Default="Spin",Callback=function(v) State.HardFling.mode=v notify("Fling Mode",v,1.5,"rotate-cw") end})
secFling:Slider({Title="Fling Power",Step=500,Value={Min=1000,Max=50000,Default=10000},Callback=function(v) State.HardFling.power=v end})

-- TAB: TELEPORT
local tabTP=Win:Tab({Title="Teleport",Icon="map-pin-x-inside"})
local secDirTP=tabTP:Section({Title="Direct Teleport",Icon="map-pin",Box=true})
secDirTP:Toggle({Title="Smart TP",Desc="Equip tool → tap to toggle mode → tap to TP",Default=false,Callback=toggleSmartTP})
local secTargetTP=tabTP:Section({Title="Target Teleport",Icon="crosshair",Box=true})
local tpTarget=""
secTargetTP:Input({Title="Search Player",Placeholder="Type name...",Callback=function(v) tpTarget=v end})
secTargetTP:Button({Title="Execute TP",Desc="Teleport to target",Callback=function() pcall(function() if tpTarget=="" then notify("Teleport","Input target!",2,"circle-alert") return end local target=nil for _,p in pairs(PL:GetPlayers()) do if p~=LP and (string.find(string.lower(p.Name),string.lower(tpTarget)) or string.find(string.lower(p.DisplayName),string.lower(tpTarget))) then target=p break end end if not target or not target.Parent or not target.Character then notify("Teleport","Invalid Target",2,"circle-alert") return end local tHrp=getCharRoot(target.Character) local myHrp=getRoot() if not tHrp or not myHrp then return end myHrp.CFrame=tHrp.CFrame*CFrame.new(0,0,3)+Vector3.new(0,2,0) notify("Teleport",target.DisplayName,2,"map-pin") end) end})
secTargetTP:Dropdown({Title="Player List",Values=getDisplayNames(),Callback=function(v) tpTarget=tostring(v) end})
secTargetTP:Button({Title="Refresh List",Callback=function() notify("Teleport","List refreshed",1.5,"map-pin") end})
local secCache=tabTP:Section({Title="Coordinates Cache",Icon="save",Box=true})
local SavedLocs={}
for i=1,3 do local idx=i local hc=secCache:HStack({Columns=2}) hc:Button({Title="💾 Save "..idx,Callback=function() local r=getRoot() if not r then return end SavedLocs[idx]=r.CFrame notify("Slot "..idx,"Saved",1.5,"save") end}) hc:Button({Title="📍 Load "..idx,Callback=function() if not SavedLocs[idx] then notify("Slot "..idx,"Empty",1.5,"save") return end local r=getRoot() if not r then return end r.CFrame=SavedLocs[idx] notify("Slot "..idx,"Loaded",1.5,"map-pin") end}) end

-- TAB: SPECTATOR
local tabSpec=Win:Tab({Title="Spectator",Icon="cctv"})
local secZoom=tabSpec:Section({Title="Zoom Override",Icon="zoom-in",Box=true})
secZoom:Toggle({Title="Max Zoom Out",Default=false,Callback=function(v) pcall(function() LP.CameraMaxZoomDistance=v and 100000 or 400 end) notify("Zoom",v and "Max" or "Default",1.5,"zoom-in") end})
local secSP=tabSpec:Section({Title="Spectator Mode",Icon="eye",Box=true})
secSP:Dropdown({Title="Select Target",Values=getDisplayNamesWithSelf(),Callback=function(v) local s=tostring(v) if s=="[Self]" then Spec.target=LP Spec.isSelf=true Spec.orbitYaw=0 Spec.orbitPitch=20 Spec.fpYaw=0 notify("Spectator","Self",1.5,"eye") else local p=findPlayerByDisplay(s) if p then Spec.target=p Spec.isSelf=false if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then local _,ry,_=p.Character.HumanoidRootPart.CFrame:ToEulerAnglesYXZ() Spec.orbitYaw=math.deg(ry) Spec.orbitPitch=20 Spec.fpYaw=math.deg(ry) end notify("Spectator",p.DisplayName,1.5,"eye") end end end})
secSP:Button({Title="Refresh Target List",Callback=function() notify("Spectator","List refreshed",1.5,"eye") end})
secSP:Toggle({Title="Enable Spectate",Default=false,Callback=function(v) if SSs.active then toggleSelfSpec(false) end Spec.active=v if v then if not Spec.target or not Spec.target.Character then if Spec.isSelf and LP.Character then else Spec.active=false notify("Error","No target",2,"circle-alert") return end end Spec.origFov=Camera.FieldOfView startSpecCap() startSpecLoop() notify("Spectator","ON",2,"eye") else stopSpecLoop() stopSpecCap() Camera.CameraType=Enum.CameraType.Custom Camera.FieldOfView=Spec.origFov notify("Spectator","OFF",1.5,"eye") end end})
secSP:Toggle({Title="First Person View",Default=false,Callback=function(v) Spec.mode=v and "first" or "third" notify("Spectator",v and "First Person" or "Third Person",1.5,"eye") end})
secSP:Slider({Title="Distance",Step=1,Value={Min=3,Max=30,Default=8},Callback=function(v) Spec.dist=v end})

-- TAB: CINEMATIC
local tabCine=Win:Tab({Title="Cinematic",Icon="aperture"})
local secSS=tabCine:Section({Title="🎥 Self-Spectate",Icon="camera",Box=true})
secSS:Toggle({Title="Enable Self-Spectate",Desc="1-finger orbit | 2-finger zoom | Mouse right-drag",Default=false,Callback=toggleSelfSpec})
secSS:Dropdown({Title="Preset Mode",Values={"Manual","Slow Orbit","Vertical Swing","Figure 8","Cinematic Drift","Top Down","First Person"},Default="Manual",Callback=function(v) SSs.mode=v notify("Self-Spec","Mode: "..v,1.5,"camera") end})
secSS:Slider({Title="Distance / Radius",Step=0.5,Value={Min=3,Max=30,Default=8},Callback=function(v) SSs.radius=v SSs.dist=v end})
secSS:Slider({Title="Height",Step=0.5,Value={Min=-10,Max=20,Default=3},Callback=function(v) SSs.height=v end})
secSS:Slider({Title="Speed",Step=0.1,Value={Min=0.1,Max=5,Default=1},Callback=function(v) SSs.speed=v end})
local secFC=tabCine:Section({Title="Drone Engine + Hide UI",Icon="video",Box=true})
secFC:Toggle({Title="Enable Freecam",Default=false,Callback=function(v) if v and SSs.active then toggleSelfSpec(false) end FC.active=v if v then local cf=Camera.CFrame FC.pos=cf.Position FC.pitch=0 FC.yaw=0 FC.roll=0 cVel=Vector3.zero yVel=0 pVel=0 rVel=0 hVel=0 fcJ=Vector2.zero local hum,hrp=getHum(),getRoot() if hum then FC.savedWS=hum.WalkSpeed FC.savedJP=hum.JumpPower hum.WalkSpeed=0 hum.JumpPower=0 end if hrp then hrp.Anchored=true FC.wasAnchored=true end FC.origFov=Camera.FieldOfView startFCCap() startFCLoop() if getgenv()._XKID_FCUI then getgenv()._XKID_FCUI.Enabled=true end FC_UI_Hidden=false eyeBtn.Text="👁" for _,b in ipairs(fcBtns) do b.Visible=true end notify("Freecam","ON",2,"video") else fullCleanupFC() notify("Freecam","OFF",1.5,"video") end end})
secFC:Slider({Title="Camera Speed",Step=0.5,Value={Min=1,Max=20,Default=3},Callback=function(v) FC.speed=v end})
secFC:Slider({Title="Sensitivity",Step=0.05,Value={Min=0.1,Max=1.0,Default=0.25},Callback=function(v) FC.sens=v end})
secFC:Toggle({Title="Hide All UI (Cinematic)",Default=false,Callback=function(v) if getgenv()._XKID_UI_LOADING then return end if v then State.Cinema.hideUI=true State.Cinema.cachedGuis={} for _,gui in pairs(LP.PlayerGui:GetChildren()) do if gui:IsA("ScreenGui") and gui.Enabled then table.insert(State.Cinema.cachedGuis,gui) gui.Enabled=false end end pcall(function() SG:SetCoreGuiEnabled(Enum.CoreGuiType.All,false) end) else State.Cinema.hideUI=false for _,gui in pairs(State.Cinema.cachedGuis) do if gui and gui.Parent then gui.Enabled=true end end State.Cinema.cachedGuis={} pcall(function() SG:SetCoreGuiEnabled(Enum.CoreGuiType.All,true) end) end notify("Cinematic",v and "UI Hidden" or "UI Shown",1.5,"film") end})

-- TAB: VISUALS
local tabVis=Win:Tab({Title="Visuals",Icon="moon-star"})
local secPresets=tabVis:Section({Title="Presets",Icon="palette",Box=true})
secPresets:Dropdown({Title="Select Filter",Values={"Default","Custom","Mendung","CoolBlue","SoftFade","FullBright","Night","Senja","Golden"},Default="Default",Callback=applyFilter})
local secFX=tabVis:Section({Title="Simple Custom FX",Icon="sliders",Box=true})
secFX:Slider({Title="Red",Step=1,Value={Min=0,Max=255,Default=255},Callback=function(v) State.CustomFilter.r=v applyCustomFilter() end})
secFX:Slider({Title="Green",Step=1,Value={Min=0,Max=255,Default=255},Callback=function(v) State.CustomFilter.g=v applyCustomFilter() end})
secFX:Slider({Title="Blue",Step=1,Value={Min=0,Max=255,Default=255},Callback=function(v) State.CustomFilter.b=v applyCustomFilter() end})
secFX:Slider({Title="Saturation",Step=0.05,Value={Min=-1,Max=1,Default=0},Callback=function(v) State.CustomFilter.sat=v applyCustomFilter() end})
secFX:Slider({Title="Contrast",Step=0.05,Value={Min=-1,Max=1,Default=0},Callback=function(v) State.CustomFilter.con=v applyCustomFilter() end})
secFX:Slider({Title="Brightness",Step=0.05,Value={Min=-1,Max=1,Default=0},Callback=function(v) State.CustomFilter.bri=v applyCustomFilter() end})
secFX:Slider({Title="Exposure",Step=0.1,Value={Min=-5,Max=5,Default=0},Callback=function(v) State.CustomFilter.exp=v applyCustomFilter() end})
secFX:Slider({Title="Bloom",Step=0.1,Value={Min=0,Max=2,Default=0},Callback=function(v) State.CustomFilter.bloom=v applyCustomFilter() end})
secFX:Slider({Title="Bloom Size",Step=1,Value={Min=0,Max=100,Default=24},Callback=function(v) State.CustomFilter.bloomSize=v applyCustomFilter() end})
secFX:Slider({Title="Time",Step=0.5,Value={Min=0,Max=24,Default=14},Callback=function(v) State.CustomFilter.time=v applyCustomFilter() end})
secFX:Button({Title="Reset FX",Callback=function() State.CustomFilter={r=255,g=255,b=255,sat=0,con=0,bri=0,exp=0,bloom=0,bloomSize=24,time=14} applyCustomFilter() notify("Visuals","FX Reset",2,"rotate-ccw") end})

-- TAB: ESP
local tabESP=Win:Tab({Title="ESP",Icon="scan-search"})
local secDetect=tabESP:Section({Title="Detection System",Icon="radar",Box=true})
secDetect:Toggle({Title="Enable Radar",Default=false,Callback=function(v) State.ESP.active=v if not v and State.ESP.cache then for _,c in pairs(State.ESP.cache) do pcall(function() if c.texts then c.texts.Visible=false end if c.tracer then c.tracer.Visible=false end for _,l in ipairs(c.boxLines) do if l then l.Visible=false end end if c.hl then c.hl.Enabled=false end end) end end notify("ESP",v and "ON" or "OFF",1.5,"radar") end})
secDetect:Dropdown({Title="Tracer Origin",Values={"Bottom","Center","Mouse","OFF"},Default="Bottom",Callback=function(v) State.ESP.tracerMode=v notify("ESP","Tracer: "..v,1.5,"radar") end})
secDetect:Toggle({Title="Highlight Entity",Default=false,Callback=function(v) State.ESP.highlight=v notify("ESP","Highlight "..(v and "ON" or "OFF"),1.5,"radar") end})
secDetect:Slider({Title="Scan Distance",Step=10,Value={Min=50,Max=500,Default=300},Callback=function(v) State.ESP.maxDist=v end})
local secCol=tabESP:Section({Title="Color Config",Icon="palette",Box=true})
secCol:Dropdown({Title="Normal",Values={"Hijau","Merah","Biru","Kuning","Ungu","Cyan","Orange","Pink","Putih","Hitam"},Default="Hijau",Callback=function(v) if colorMap[v] then State.ESP.traceN=colorMap[v] State.ESP.boxN=colorMap[v] end notify("ESP","Normal: "..v,1.5,"palette") end})
secCol:Dropdown({Title="Suspect",Values={"Merah","Crimson","Hijau","Biru","Kuning","Ungu","Cyan","Orange","Pink","Putih","Hitam"},Default="Crimson",Callback=function(v) if colorMap[v] then State.ESP.traceS=colorMap[v] State.ESP.boxS=colorMap[v] end notify("ESP","Suspect: "..v,1.5,"palette") end})
secCol:Dropdown({Title="Glitch",Values={"Orange","Merah","Hijau","Biru","Kuning","Ungu","Cyan","Pink","Putih","Hitam"},Default="Orange",Callback=function(v) if colorMap[v] then State.ESP.traceG=colorMap[v] State.ESP.boxG=colorMap[v] end notify("ESP","Glitch: "..v,1.5,"palette") end})

-- TAB: PROTECTION
local tabProt=Win:Tab({Title="Protection",Icon="shield-half"})
local secProt=tabProt:Section({Title="Protection Protocols",Icon="shield-check",Box=true})
secProt:Toggle({Title="Anti AFK (Smart)",Default=false,Callback=function(v) if v then startAFK() else stopAFK() end end})
secProt:Button({Title="Stuck Fix",Desc="Get unstuck from walls/ground",Callback=function() local hrp,hum=getRoot(),getHum() if hrp then hrp.Anchored=false hrp.CFrame=hrp.CFrame+Vector3.new(0,3,0) end if hum then hum.Sit=false hum:ChangeState(Enum.HumanoidStateType.Jumping) end notify("Protection","Stuck fix applied",2,"wrench") end})
local secSrv=tabProt:Section({Title="Server Control",Icon="server",Box=true})
secSrv:Button({Title="Force Rejoin",Desc="Rejoin current server",Callback=function() pcall(function() TP:TeleportToPlaceInstance(game.PlaceId,game.JobId,LP) end) notify("Server","Rejoining...",2,"log-in") end})
secSrv:Button({Title="Server Hop",Desc="Find a new server",Callback=function() pcall(function() local req=getgenv()._XKID_REQUEST or httpRequest if not req then notify("Error","HTTP not supported",2,"circle-alert") return end local res=req({Url="https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Desc&limit=100",Method="GET"}) if res.StatusCode==200 then local body=HS:JSONDecode(res.Body) if body and body.data then for _,v in ipairs(body.data) do if v.playing>0 and v.playing<v.maxPlayers and v.id~=game.JobId then TP:TeleportToPlaceInstance(game.PlaceId,v.id,LP) notify("Server","Hopping...",2,"shuffle") return end end end end end) end})
local secPerf=tabProt:Section({Title="Performance",Icon="gauge",Box=true})
local gfxMap={[1]="Level01",[2]="Level02",[3]="Level03",[4]="Level04",[5]="Level05",[6]="Level06",[7]="Level07",[8]="Level08",[9]="Level09",[10]="Level10"}
secPerf:Slider({Title="Quality Level",Step=1,Value={Min=1,Max=10,Default=2},Callback=function(v) if gfxMap[v] then pcall(function() settings().Rendering.QualityLevel=Enum.QualityLevel[gfxMap[v]] end) end notify("Graphics",gfxMap[v],1.5,"gauge") end})
secPerf:Dropdown({Title="FPS Cap",Values={"30","60","120","144","240","Unlimited"},Default="120",Callback=function(v) if v=="Unlimited" then setOptimalFPS(9999) else setOptimalFPS(tonumber(v)) end notify("Graphics",v.." FPS",1.5,"gauge") end})
local advCache={level=nil,shadows=true,brightness=5,clockTime=14,fogEnd=100000,mats={},texs={}}
secPerf:Toggle({Title="FPS Boost",Default=false,Callback=function(v) State.Security.antiLag=v if v then pcall(function() advCache.level=settings().Rendering.QualityLevel end) advCache.shadows=LT.GlobalShadows advCache.brightness=LT.Brightness advCache.clockTime=LT.ClockTime advCache.fogEnd=LT.FogEnd pcall(function() settings().Rendering.QualityLevel=1 end) LT.GlobalShadows=false LT.Brightness=1 LT.FogEnd=100000 for _,obj in pairs(workspace:GetDescendants()) do if obj:IsA("BasePart") then advCache.mats[obj]=obj.Material obj.Material=Enum.Material.SmoothPlastic elseif obj:IsA("Decal") or obj:IsA("Texture") or obj:IsA("ParticleEmitter") or obj:IsA("Trail") then advCache.texs[obj]=obj.Enabled obj.Enabled=false end end notify("Performance","FPS Boost ON",2,"zap") else pcall(function() if advCache.level then settings().Rendering.QualityLevel=advCache.level end end) LT.GlobalShadows=advCache.shadows LT.Brightness=advCache.brightness LT.ClockTime=advCache.clockTime LT.FogEnd=advCache.fogEnd for obj,mat in pairs(advCache.mats) do if obj and obj.Parent then obj.Material=mat end end for obj,enb in pairs(advCache.texs) do if obj and obj.Parent then obj.Enabled=enb end end advCache.mats={} advCache.texs={} notify("Performance","Graphics restored",2,"zap") end end})
local secCam=tabProt:Section({Title="Camera Lock",Icon="lock",Box=true})
secCam:Toggle({Title="Force Shift Lock",Default=false,Callback=function(v) toggleShiftLock(v) end})

-- TAB: SETTINGS
local tabSet=Win:Tab({Title="Settings",Icon="panels-top-left"})
local secTheme=tabSet:Section({Title="🎨 Theme",Icon="palette",Box=true})
secTheme:Dropdown({Title="UI Theme",Values={"Dark","Light","Rose","Sky","Emerald","Violet","Red","Amber","Indigo","Midnight","Crimson"},Default="Crimson",Callback=function(v) WindUI:SetTheme(v) end})
local secFile=tabSet:Section({Title="File Management",Icon="folder",Box=true})
local cfgName="XKID_Config_V2" local curCfg="No config"
secFile:Input({Title="Config Name",Value="XKID_Config_V2",Callback=function(v) cfgName=v end})
local function saveCfg() if executor.has_writefile then pcall(function() if not isfolder("XKID_HUB") then makefolder("XKID_HUB") end local data={Move={ws=State.Move.ws,jp=State.Move.jp,flyS=State.Move.flyS,aws=State.Move.autoWalkSpeed},ESP={tm=State.ESP.tracerMode,maxD=State.ESP.maxDist,hl=State.ESP.highlight},Security={sl=State.Security.shiftLock,al=State.Security.antiLag},HardFling={p=State.HardFling.power,m=State.HardFling.mode},SelfSpec={m=SSs.mode,r=SSs.radius,h=SSs.height,s=SSs.speed},CustomFilter={r=State.CustomFilter.r,g=State.CustomFilter.g,b=State.CustomFilter.b,sat=State.CustomFilter.sat,con=State.CustomFilter.con,bri=State.CustomFilter.bri,exp=State.CustomFilter.exp,bloom=State.CustomFilter.bloom,bloomS=State.CustomFilter.bloomSize,time=State.CustomFilter.time}} writefile("XKID_HUB/"..cfgName..".json",HS:JSONEncode(data)) notify("Config","Saved: "..cfgName,2,"save") end) else notify("Config","Executor tidak support save",2,"circle-alert") end end
local function loadCfg(s) if s=="No config" then return end pcall(function() if executor.has_readfile and isfile and isfile("XKID_HUB/"..s..".json") then local d=HS:JSONDecode(readfile("XKID_HUB/"..s..".json")) if d then if d.Move then State.Move.ws=d.Move.ws or 16 State.Move.jp=d.Move.jp or 50 State.Move.flyS=d.Move.flyS or 60 State.Move.autoWalkSpeed=d.Move.aws or 16 local h=getHum() if h then h.WalkSpeed=State.Move.ws h.UseJumpPower=true h.JumpPower=State.Move.jp end end if d.ESP then State.ESP.tracerMode=d.ESP.tm or "Bottom" State.ESP.maxDist=d.ESP.maxD or 300 State.ESP.highlight=d.ESP.hl or false end if d.Security and d.Security.sl~=State.Security.shiftLock then toggleShiftLock(d.Security.sl) end if d.HardFling then State.HardFling.power=d.HardFling.p or 10000 State.HardFling.mode=d.HardFling.m or "Spin" end if d.SelfSpec then SSs.mode=d.SelfSpec.m or "Manual" SSs.radius=d.SelfSpec.r or 8 SSs.height=d.SelfSpec.h or 3 SSs.speed=d.SelfSpec.s or 1 end if d.CustomFilter then for k,v in pairs(d.CustomFilter) do State.CustomFilter[k]=v end applyCustomFilter() end notify("Config","Loaded: "..s,2,"folder-open") end end end) end
secFile:Button({Title="Save Config",Callback=saveCfg})
local cfgDrop=secFile:Dropdown({Title="Load Config",Values=getConfigList(),Callback=function(s) curCfg=s loadCfg(s) end})
secFile:Button({Title="Delete Config",Callback=function() if curCfg~="No config" and curCfg~="" and executor.has_listfiles then pcall(function() if isfile and delfile and isfile("XKID_HUB/"..curCfg..".json") then delfile("XKID_HUB/"..curCfg..".json") pcall(function() cfgDrop:Refresh(getConfigList(),true) end) curCfg="No config" notify("Config","Deleted",2,"trash-2") end end) end end})
secFile:Button({Title="Refresh Files",Callback=function() pcall(function() cfgDrop:Refresh(getConfigList(),true) end) notify("Config","Files refreshed",1.5,"folder") end})

-- ================================ AUTO EXPAND (FIXED) & AUTO START ================================
task.delay(0.8, function() pcall(function() for _,t in pairs(Win.Tabs) do if t.Sections then for _,s in ipairs(t.Sections) do if s.Expand and type(s.Expand)=="function" then pcall(function() s:Expand() end) end end end end end) end)
pcall(function() settings().Rendering.QualityLevel=Enum.QualityLevel.Level02 end)
setOptimalFPS(120)
task.spawn(function() task.wait(0.5) startAFK() task.wait(2) getgenv()._XKID_UI_LOADING=false notify("System","XKID V2.1 AKTIF — Ready",3,"rocket") notify("Anti AFK","AUTO ACTIVATED (7min Jump)",2,"shield-check") end)