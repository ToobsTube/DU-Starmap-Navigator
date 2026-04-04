-- ================================================================
-- NAVIGATOR SHIP - NO SCREEN VERSION v2.0.0
-- Dual Universe Navigation System
--
-- SLOT CONNECTIONS (connect in this order):
--   Slot 0: databank   (Databank)
--   Slot 1: receiver   (Receiver)
--   Slot 2: emitter    (Emitter)
--
-- Output via Lua chat. AR marker via system.setWaypoint().
-- Alt+Up/Down = browse menu  |  Alt+Right = activate  |  Alt+Shift+Ins = toggle HUD
-- ================================================================

--[[@
slot=-5
event=onStart()
args=
]]
function FormatDist(m)
  if not m then return "---" end
  if m>=2e7  then return string.format("%.2f su",m/200000)
  elseif m>=1e6  then return string.format("%.1f Mm",m/1e6)
  elseif m>=1000 then return string.format("%.1f km",m/1000)
  else return string.format("%.0f m",m) end
end
function FormatTime(s)
  if not s or s<0 then return "---" end
  if s>=86400 then
    local d=math.floor(s/86400); local h=math.floor((s%86400)/3600)
    return string.format("%dd %dh",d,h)
  elseif s>=3600 then
    local h=math.floor(s/3600); local m=math.floor((s%3600)/60)
    return string.format("%dh %02dm",h,m)
  else
    local m=math.floor(s/60); local sc=math.floor(s%60)
    return string.format("%dm %02ds",m,sc)
  end
end
function CalcTravelTime(dist)
  if not dist or dist<=0 then return nil end
  local V=(CalcSpeed or 30000)/3.6   -- km/h → m/s
  local A=CalcAccel or 5
  if A<=0 then return dist/math.max(V,1) end
  local d_accel=V*V/(2*A)            -- distance to reach cruise speed
  if 2*d_accel>=dist then
    -- can't reach cruise speed — triangle profile
    return 2*math.sqrt(dist/A)
  else
    local t_accel=V/A                -- time to accel (= time to decel)
    local d_cruise=dist-2*d_accel
    local t_cruise=d_cruise/V
    return 2*t_accel+t_cruise
  end
end
function ParsePos(s)
  if not s or s=="" then return nil end
  local w,b,x,y,z=s:match("::pos{(%d+),(%d+),([-%.%d]+),([-%.%d]+),([-%.%d]+)}")
  if not x then return nil end
  w,b,x,y,z=tonumber(w),tonumber(b),tonumber(x),tonumber(y),tonumber(z)
  -- world coords (body=0) — already XYZ
  if b==0 then return {x=x,y=y,z=z} end
  -- planet-relative — convert via atlas
  if Atlas then
    for _,body in pairs(Atlas[0]) do
      if body.id==b then
        local deg=math.pi/180
        local lat,lon,alt=x*deg,y*deg,z
        local r=body.radius+alt
        local cx=r*math.cos(lat)*math.cos(lon)
        local cy=r*math.cos(lat)*math.sin(lon)
        local cz=r*math.sin(lat)
        local c=body.center
        return {x=c[1]+cx,y=c[2]+cy,z=c[3]+cz}
      end
    end
  end
  -- atlas missing for this body — return nil so distance shows ---
  return nil
end
function CalcDist(p1,p2)
  if not p1 or not p2 then return nil end
  local dx,dy,dz=p1.x-p2.x,p1.y-p2.y,p1.z-p2.z
  return math.sqrt(dx*dx+dy*dy+dz*dz)
end
function Trim(s) return (s or ""):match("^%s*(.-)%s*$") end
function OrgKey(n) return "org_"..n:gsub("[^%w]","_") end
function AutoName(prefix,list)
  local i=1
  while true do
    local c=prefix.."-"..i; local taken=false
    for _,v in ipairs(list) do if v.n:lower()==c:lower() then taken=true;break end end
    if not taken then return c end; i=i+1
  end
end
function BuildShipID()
  local name=construct and construct.getName() or "Ship"
  local cid=construct and tostring(construct.getId()) or ""
  if cid~="" then return name.."#"..cid:sub(-6) end
  return name
end
function SetStatus(msg,dur)
  system.print("[NAV] "..msg)
  StatusMsg=msg; StatusExpiry=system.getArkTime()+(dur or 5)
end


--[[@
slot=-1
event=onStart()
args=
]]

local VERSION="v2.0.0"
CustomAtlas  ="atlas"  --export: Atlas file to load (default=atlas, set to custom filename in autoconf/custom/)
BaseChannel ="NavBase" --export: Personal base channel
AutopilotCmd=""        --export: Autopilot command prefix e.g. /goto or / (blank = disabled)
CalcSpeed   =30000    --export: Time Calc cruise speed in km/h (e.g. 30000)
CalcAccel   =5        --export: Time Calc ship acceleration in m/s2 (e.g. 5)
AccentR=0    --export: HUD accent color Red 0-255 (default 0)
AccentG=200  --export: HUD accent color Green 0-255 (default 200)
AccentB=255  --export: HUD accent color Blue 0-255 (default 255)
HudX=13     --export: HUD left position in % from screen edge (default 13)
HudY=15     --export: HUD top position in % from screen edge (default 15)

PersonalWPs    = {}
PersonalRoutes = {}
OrgNames       = {}
OrgData        = {}
NavTarget      = nil
ShipID         = ""
SyncReceived   = 0
SyncOrgName    = ""
ActiveContext  = "personal"  -- "personal" or org name
ActiveOrg      = nil         -- which org is open in the ORG section (level 3)
SyncContext    = "personal"  -- routing target during a base sync ("personal" or org name)
SyncingChannel = ""          -- channel open for duration of active org sync
SectionIdx     = 1           -- left-panel category index
SubIdx         = 0           -- 0=left panel focused, 1+=right panel item
AtlasSearch    = ""
L_ALT          = false
HUD_VISIBLE    = true
StatusMsg      = ""
StatusExpiry   = 0
PushQueue    = {}
PushQueueCh  = ""
PushQueueIdx = 1
PushSending  = false
HudPX        = 13    -- runtime HUD X% (set from databank or HudX export)
HudPY        = 15    -- runtime HUD Y% (set from databank or HudY export)

-- ── Databank ──────────────────────────────────────────────────
function LoadData()
  if not databank then PersonalWPs={};PersonalRoutes={};return end
  local function jd(k) local v=databank.getStringValue(k); return (v and v~="") and json.decode(v) or nil end
  PersonalWPs    = jd("personal_wps")    or {}
  PersonalRoutes = jd("personal_routes") or {}
  OrgNames       = jd("org_names")       or {}
  OrgData={}
  for _,org in ipairs(OrgNames) do
    local k=OrgKey(org)
    OrgData[org]={wps=jd(k.."_wps") or {},routes=jd(k.."_routes") or {},channel=databank.getStringValue(k.."_ch") or ""}
  end
  NavTarget=jd("nav_target")
  ShipID=BuildShipID()
  local hx=tonumber(databank.getStringValue("hud_x"))
  local hy=tonumber(databank.getStringValue("hud_y"))
  HudPX=hx or HudX; HudPY=hy or HudY
end

function SaveData()
  if not databank then return end
  databank.setStringValue("personal_wps",    json.encode(PersonalWPs))
  databank.setStringValue("personal_routes", json.encode(PersonalRoutes))
  databank.setStringValue("org_names",       json.encode(OrgNames))
  for _,org in ipairs(OrgNames) do
    local k=OrgKey(org)
    databank.setStringValue(k.."_wps",    json.encode(OrgData[org].wps))
    databank.setStringValue(k.."_routes", json.encode(OrgData[org].routes))
    databank.setStringValue(k.."_ch",     OrgData[org].channel or "")
  end
  databank.setStringValue("nav_target", NavTarget and json.encode(NavTarget) or "")
  databank.setStringValue("hud_x", tostring(HudPX))
  databank.setStringValue("hud_y", tostring(HudPY))
end

-- ── Context helpers ───────────────────────────────────────────
function ContextWPs()
  if ActiveContext=="personal" then return PersonalWPs end
  return OrgData[ActiveContext] and OrgData[ActiveContext].wps or {}
end
function ContextRoutes()
  if ActiveContext=="personal" then return PersonalRoutes end
  return OrgData[ActiveContext] and OrgData[ActiveContext].routes or {}
end
function ContextTabIdx()
  if ActiveContext=="personal" then return 0 end
  for i,o in ipairs(OrgNames) do if o==ActiveContext then return i end end
  return 0
end

-- ── WP / Route management ─────────────────────────────────────
function AddWP(name,posStr)
  local list=ContextWPs()
  for _,wp in ipairs(list) do
    if wp.n:lower()==name:lower() then wp.c=posStr; SaveData(); SetStatus("Updated: "..name); return true end
  end
  table.insert(list,{n=name,c=posStr})
  table.sort(list,function(a,b) return a.n:lower()<b.n:lower() end)
  SaveData(); SetStatus("Saved WP: "..name); return true
end

function DelWP(name)
  local list=ContextWPs()
  for i,wp in ipairs(list) do
    if wp.n:lower()==name:lower() then
      table.remove(list,i)
      if NavTarget and NavTarget.t=="wp" and NavTarget.n:lower()==name:lower() then NavTarget=nil end
      SaveData(); SetStatus("Deleted: "..name); return true
    end
  end
  SetStatus("Not found: "..name); return false
end

function AddRoute(name)
  local list=ContextRoutes()
  for _,r in ipairs(list) do if r.n:lower()==name:lower() then SetStatus("Route exists: "..name) return false end end
  table.insert(list,{n=name,pts={}})
  table.sort(list,function(a,b) return a.n:lower()<b.n:lower() end)
  SaveData(); SetStatus("Route created: "..name); return true
end

function DelRoute(name)
  local list=ContextRoutes()
  for i,r in ipairs(list) do
    if r.n:lower()==name:lower() then
      table.remove(list,i)
      if NavTarget and NavTarget.t=="route" and NavTarget.n:lower()==name:lower() then NavTarget=nil end
      SaveData(); SetStatus("Route deleted: "..name); return true
    end
  end
  SetStatus("Route not found: "..name); return false
end

function AddStop(routeName,arg)
  local routes=ContextRoutes(); local wps=ContextWPs()
  for _,r in ipairs(routes) do
    if r.n:lower()==routeName:lower() then
      local c,lbl=arg,arg
      if not ParsePos(arg) then
        local found=false
        for _,wp in ipairs(wps) do
          if wp.n:lower()==arg:lower() then c=wp.c;lbl=wp.n;found=true;break end
        end
        if not found then SetStatus("Not a WP name or ::pos{}") return end
      end
      table.insert(r.pts,{c=c,label=lbl})
      SaveData(); SetStatus("Stop added ("..#r.pts.." total)"); return
    end
  end
  SetStatus("Route not found: "..routeName)
end

function DelStop(routeName,idx)
  local routes=ContextRoutes()
  for _,r in ipairs(routes) do
    if r.n:lower()==routeName:lower() then
      if idx<1 or idx>#r.pts then SetStatus("Stop index out of range") return end
      table.remove(r.pts,idx)
      SaveData(); SetStatus("Stop "..idx.." removed"); return
    end
  end
end

-- ── Navigation ───────────────────────────────────────────────
function GetCurrentPos()
  local p=construct.getWorldPosition(); if p then return {x=p[1],y=p[2],z=p[3]} end
  return nil
end
function GetCurrentPosStr()
  local p=GetCurrentPos(); if not p then return nil end
  return string.format("::pos{0,0,%.4f,%.4f,%.4f}",p.x,p.y,p.z)
end
function UpdateWaypoint()
  if NavTarget and NavTarget.c and NavTarget.c~="" then
    system.setWaypoint(NavTarget.c)
  end
end
function ClearWaypoint()
  NavTarget=nil; system.setWaypoint(""); SaveData()
end

function SendAutopilot(coords)
  if AutopilotCmd~="" and coords and coords~="" then
    system.print(AutopilotCmd.." "..coords)
  end
end

function SetNavWP(name)
  for _,wp in ipairs(ContextWPs()) do
    if wp.n:lower()==name:lower() then
      NavTarget={t="wp",n=wp.n,c=wp.c,tab=ContextTabIdx()}
      SaveData(); UpdateWaypoint()
      SendAutopilot(wp.c)
      if AutopilotCmd=="" then SetStatus("Navigating: "..wp.n) end
      return true
    end
  end
  SetStatus("WP not found: "..name); return false
end

function SetNavRoute(name,startStop)
  for _,r in ipairs(ContextRoutes()) do
    if r.n:lower()==name:lower() then
      if #r.pts==0 then SetStatus("Route has no stops") return false end
      local idx=startStop or 1
      NavTarget={t="route",n=r.n,c=r.pts[idx].c,tab=ContextTabIdx(),stopIdx=idx,stopTotal=#r.pts}
      SaveData(); UpdateWaypoint()
      SendAutopilot(r.pts[idx].c)
      if AutopilotCmd=="" then SetStatus("Route: "..r.n.."  stop "..idx.."/"..#r.pts) end
      return true
    end
  end
  SetStatus("Route not found: "..name); return false
end

function NextStop()
  if not NavTarget or NavTarget.t~="route" then SetStatus("Not navigating a route") return end
  local tab=NavTarget.tab
  local routes=(tab==0) and PersonalRoutes or (OrgData[OrgNames[tab]] and OrgData[OrgNames[tab]].routes) or {}
  for _,r in ipairs(routes) do
    if r.n:lower()==NavTarget.n:lower() then
      local idx=NavTarget.stopIdx+1
      if idx>#r.pts then SetStatus("Already at last stop") return end
      NavTarget.stopIdx=idx; NavTarget.c=r.pts[idx].c; NavTarget.stopTotal=#r.pts
      SaveData(); UpdateWaypoint()
      SetStatus("Stop "..idx.."/"..#r.pts.."  "..(r.pts[idx].label or r.pts[idx].c:sub(1,30))); return
    end
  end
end

function PrevStop()
  if not NavTarget or NavTarget.t~="route" then return end
  local tab=NavTarget.tab
  local routes=(tab==0) and PersonalRoutes or (OrgData[OrgNames[tab]] and OrgData[OrgNames[tab]].routes) or {}
  for _,r in ipairs(routes) do
    if r.n:lower()==NavTarget.n:lower() then
      local idx=NavTarget.stopIdx-1
      if idx<1 then SetStatus("Already at first stop") return end
      NavTarget.stopIdx=idx; NavTarget.c=r.pts[idx].c; NavTarget.stopTotal=#r.pts
      SaveData(); UpdateWaypoint()
      SetStatus("Stop "..idx.."/"..#r.pts.."  "..(r.pts[idx].label or r.pts[idx].c:sub(1,30))); return
    end
  end
end

-- ── Sync / Push ──────────────────────────────────────────────
function GetPlayerID()
  local pid=player and tostring(player.getId()) or "0"
  return pid
end
function GetPlayerName()
  return (player and player.getName()) or "Unknown"
end

function UpdateChannels()
  if not receiver then return end
  local chs={BaseChannel}
  if SyncingChannel~="" then table.insert(chs,SyncingChannel) end
  receiver.setChannelList(chs)
end


function RequestSync(ch)
  if not emitter then SetStatus("No emitter") return end
  SyncingChannel=ch; UpdateChannels()
  emitter.send(ch,"<RequestSync>"..ShipID.."|pid:"..GetPlayerID())
  SetStatus("Sync requested on "..ch)
end

function PushToChannel(ch,wps,routes)
  if not emitter then SetStatus("No emitter") return end
  PushQueue={}
  for _,wp in ipairs(wps) do
    table.insert(PushQueue,{type="wp",  data={n=wp.n,c=wp.c}})
  end
  for _,r in ipairs(routes) do
    table.insert(PushQueue,{type="route",data={n=r.n,pts=r.pts}})
  end
  if #PushQueue==0 then SetStatus("Nothing to push") return end
  PushQueueCh=ch; PushQueueIdx=1; PushSending=true
  emitter.send(ch,"<PushAuth>"..ShipID.."|pid:"..GetPlayerID().."|pname:"..GetPlayerName().."|count:"..#PushQueue)
  SetStatus("Pushing "..#PushQueue.." items to "..ch.."...")
  unit.setTimer("push_tick",0.25)
end

function EnsureOrg(name, ch)
  if ch and ch~="" then
    for i,v in ipairs(OrgNames) do
      if OrgData[v] and OrgData[v].channel==ch and v~=name then
        -- Another entry owns this channel — check if real name already exists
        local nameExists=false
        for _,e in ipairs(OrgNames) do if e==name then nameExists=true; break end end
        if nameExists then
          -- Real entry exists; just remove the stale placeholder and fix channel
          if OrgData[name] then OrgData[name].channel=ch end
          OrgData[v]=nil; table.remove(OrgNames,i)
        else
          OrgData[name]=OrgData[v]; OrgData[v]=nil; OrgNames[i]=name
        end
        SaveData(); return
      end
    end
  end
  for _,v in ipairs(OrgNames) do if v==name then
    -- Already exists — just ensure channel is stored
    if ch and ch~="" and OrgData[v] and OrgData[v].channel=="" then OrgData[v].channel=ch; SaveData() end
    return
  end end
  table.insert(OrgNames,name); OrgData[name]={wps={},routes={},channel=ch or ""}; SaveData()
end

function OrgChannelForContext()
  if ActiveContext~="personal" and OrgData[ActiveContext] then
    local ch=OrgData[ActiveContext].channel
    if ch and ch~="" then return ch end
  end
  return nil
end

-- ── Two-panel Aviator-style menu ──────────────────────────────
SECTIONS={"WP","ORG","ROUTES","SETTINGS","ATLAS","TIME CALC"}

function GetSubItems()
  local items={}
  local cp=GetCurrentPos()
  local sec=SECTIONS[SectionIdx]

  if sec=="WP" then
    for _,wp in ipairs(PersonalWPs) do
      local tp=ParsePos(wp.c)
      local d=(cp and tp) and FormatDist(CalcDist(cp,tp)) or "---"
      table.insert(items,{type="wp",n=wp.n,c=wp.c,dist=d,ctx="personal"})
    end
    if #items==0 then table.insert(items,{type="info",label="No waypoints  —  type: add NAME"}) end

  elseif sec=="ORG" then
    if ActiveOrg then
      -- Level 3: contents of the selected org
      table.insert(items,{type="sync_org", label="Sync from Org",  org=ActiveOrg})
      table.insert(items,{type="push_org", label="Push to Org",    org=ActiveOrg})
      table.insert(items,{type="mark_wp",  label="Mark WP Here"})
      local owps=(OrgData[ActiveOrg] and OrgData[ActiveOrg].wps) or {}
      local orts=(OrgData[ActiveOrg] and OrgData[ActiveOrg].routes) or {}
      if #owps>0 then
        table.insert(items,{type="hdr",label="WPs"})
        for _,wp in ipairs(owps) do
          local tp=ParsePos(wp.c)
          local d=(cp and tp) and FormatDist(CalcDist(cp,tp)) or "---"
          table.insert(items,{type="wp",n=wp.n,c=wp.c,dist=d,ctx=ActiveOrg})
        end
      end
      if #orts>0 then
        table.insert(items,{type="hdr",label="ROUTES"})
        for _,r in ipairs(orts) do
          table.insert(items,{type="route",n=r.n,stops=#r.pts,ctx=ActiveOrg})
        end
      end
      if #owps==0 and #orts==0 then
        table.insert(items,{type="info",label="No data — Sync, or: add NAME"})
      end
    else
      -- Level 2: list of orgs
      if #OrgNames==0 then
        table.insert(items,{type="info",label="No orgs configured"})
      else
        for _,org in ipairs(OrgNames) do
          local owps=(OrgData[org] and OrgData[org].wps) or {}
          local orts=(OrgData[org] and OrgData[org].routes) or {}
          table.insert(items,{type="org_entry",label=org,n=org,sub=#owps.." WPs  "..#orts.." Routes"})
        end
      end
    end

  elseif sec=="ROUTES" then
    for _,r in ipairs(PersonalRoutes) do
      table.insert(items,{type="route",n=r.n,stops=#r.pts,ctx="personal"})
    end
    if #items==0 then table.insert(items,{type="info",label="No routes  —  type: newroute NAME"}) end

  elseif sec=="SETTINGS" then
    table.insert(items,{type="mark_wp",  label="Mark WP Here"})
    table.insert(items,{type="next_stop",label="Next Stop"})
    table.insert(items,{type="prev_stop",label="Prev Stop"})
    table.insert(items,{type="clear_nav",label="Clear Navigation"})
    table.insert(items,{type="hdr",      label="BASE"})
    table.insert(items,{type="sync_base",label="Sync from Base"})
    table.insert(items,{type="push_base",label="Push to Base"})
    table.insert(items,{type="hdr",      label="ORG"})
    table.insert(items,{type="sync_org", label="Sync from Org"})
    table.insert(items,{type="push_org", label="Push to Org"})

  elseif sec=="ATLAS" then
    if Atlas then
      local bodies={}
      for _,sys in pairs(Atlas) do
        for _,body in pairs(sys) do
          local nm=type(body.name)=="table" and body.name[1] or body.name
          if type(nm)=="string" and nm~="" and body.center then
            local c=body.center
            local pos=string.format("::pos{0,0,%.4f,%.4f,%.4f}",c[1],c[2],c[3])
            table.insert(bodies,{n=nm,pos=pos})
          end
        end
      end
      table.sort(bodies,function(a,b) return a.n:lower()<b.n:lower() end)
      local q=AtlasSearch~="" and AtlasSearch:lower() or nil
      for _,b in ipairs(bodies) do
        if not q or b.n:lower():find(q,1,true) then
          table.insert(items,{type="atlas",n=b.n,c=b.pos})
        end
      end
      if q and #items==0 then
        table.insert(items,{type="info",label="No match: "..AtlasSearch})
      end
    else
      table.insert(items,{type="info",label="Atlas not loaded"})
    end

  else -- TIME CALC
    local V=(CalcSpeed or 30000)/3.6
    local A=CalcAccel or 5
    table.insert(items,{type="info",label=string.format("Speed: %g km/h  |  Accel: %g m/s\xc2\xb2",(CalcSpeed or 30000),(CalcAccel or 5))})
    -- Current target
    if NavTarget and NavTarget.c then
      local tp=ParsePos(NavTarget.c); local cp=GetCurrentPos()
      local dist=tp and cp and CalcDist(cp,tp) or nil
      local t=dist and CalcTravelTime(dist) or nil
      local row=string.format("TARGET: %s  →  %s", NavTarget.n:sub(1,16), t and FormatTime(t) or "---")
      table.insert(items,{type="info",label=row,highlight=true})
    else
      table.insert(items,{type="info",label="No nav target set"})
    end
    table.insert(items,{type="hdr",label="PERSONAL WPs"})
    local cp=GetCurrentPos()
    for _,wp in ipairs(PersonalWPs) do
      local tp=ParsePos(wp.c)
      local dist=tp and cp and CalcDist(cp,tp) or nil
      local t=dist and CalcTravelTime(dist) or nil
      table.insert(items,{type="time",n=wp.n,dist=dist,t=t})
    end
    if #PersonalWPs==0 then table.insert(items,{type="info",label="No waypoints"}) end
  end

  return items
end

function GetSelectable(items)
  local sel={}
  for i,v in ipairs(items) do
    if v.type~="hdr" and v.type~="info" then table.insert(sel,{i=i,v=v}) end
  end
  return sel
end

function DrawHUD()
  if not HUD_VISIBLE then system.showScreen(0) return end
  local W=system.getScreenWidth(); local H=system.getScreenHeight()
  local sc=H/1080
  local lw=math.floor(185*sc)
  local rw=math.floor(290*sc)
  local gap=math.floor(5*sc)
  local px=math.floor(W*(HudPX/100)); local py=math.floor(H*(HudPY/100))
  local fs=math.floor(13*sc); local fsS=math.floor(11*sc); local fsH=math.floor(12*sc)
  local rh=math.floor(30*sc)

  local items=GetSubItems()
  local sel=GetSelectable(items)
  local clampedSub=math.min(SubIdx,#sel)

  -- build selectable index map: items[i] → which # in sel list
  local selIdxMap={}
  local si=0
  for i,v in ipairs(items) do
    if v.type~="hdr" and v.type~="info" then si=si+1; selIdxMap[i]=si end
  end

  -- ── Accent colors ─────────────────────────────────────────────
  local ar,ag,ab = AccentR/255, AccentG/255, AccentB/255
  local mx=math.max(ar,ag,ab,0.001)
  local nr,ng,nb = ar/mx,ag/mx,ab/mx
  local function rgba(r,g,b,a) return string.format("rgba(%d,%d,%d,%.2f)",math.floor(r*255),math.floor(g*255),math.floor(b*255),a) end
  local cA  = string.format("rgb(%d,%d,%d)",math.floor(ar*255),math.floor(ag*255),math.floor(ab*255))
  local cBg = rgba(nr*0.01,       ng*0.01+0.002,  nb*0.04+0.007,  0.93)
  local cBd = rgba(nr*0.47,       ng*0.47,         nb*0.47,         0.45)
  local cPH = rgba(nr*0.20,       ng*0.20,         nb*0.47,         0.60)
  local cSl = rgba(ar,            ag,              ab,              0.35)
  local cDv = rgba(nr*0.24,       ng*0.24,         nb*0.55,         0.25)
  local cNB = rgba(nr*0.12,       ng*0.12,         nb*0.31,         0.60)
  local cFt = string.format("rgb(%d,%d,%d)",math.floor(nr*55+25),math.floor(ng*55+30),math.floor(nb*55+50))
  local cRi = string.format("rgb(%d,%d,%d)",math.floor(nr*55+30),math.floor(ng*55+45),math.floor(nb*55+70))
  local ls15=math.floor(15*sc)

  local h={}
  h[#h+1]=string.format([[<style>
*{box-sizing:border-box;margin:0;padding:0;}body{overflow:hidden;}
.lp,.rp{position:absolute;top:%dpx;background:%s;border:1px solid %s;border-radius:4px;overflow:hidden;}
.lp{left:%dpx;width:%dpx;}
.rp{left:%dpx;width:%dpx;}
.ph{font-family:Arial;font-size:%dpx;color:%s;text-align:center;padding:4px 6px;background:%s;border-bottom:1px solid %s;}
.lr{font-family:Arial;font-size:%dpx;color:rgb(140,170,215);display:flex;align-items:center;justify-content:space-between;padding:0 12px;height:%dpx;border-bottom:1px solid %s;}
.lsel{background:%s;color:white;}
.la{color:%s;font-size:%dpx;}
.sep{font-family:Arial;font-size:%dpx;color:%s;text-align:center;padding:2px 8px;border-bottom:1px solid %s;font-style:italic;}
.rr{font-family:Arial;font-size:%dpx;display:flex;align-items:center;justify-content:space-between;padding:0 10px;height:%dpx;border-bottom:1px solid %s;white-space:nowrap;overflow:hidden;}
.ri{font-family:Arial;font-size:%dpx;color:%s;padding:3px 10px;border-bottom:1px solid %s;font-style:italic;}
.rw{color:%s;}.rrt{color:rgb(80,215,130);}
.ra{color:rgb(255,180,60);}
.rsel{background:%s;color:white;}
.num{color:rgb(80,110,150);margin-right:6px;}
.arr{color:%s;margin-left:6px;font-size:%dpx;}
.nav{font-family:Arial;font-size:%dpx;color:%s;padding:3px 8px;background:%s;border-bottom:1px solid %s;white-space:nowrap;overflow:hidden;}
.ft{font-family:Arial;font-size:%dpx;color:%s;text-align:center;padding:2px 4px;border-top:1px solid %s;}
.st{color:rgb(255,178,50);}
</style>]],
    py,cBg,cBd,
    px,lw,
    px+lw+gap,rw,
    fsH,cA,cPH,cBd,
    fs,rh,cDv,
    cSl,cA,ls15,
    fsS,cFt,cDv,
    fs,rh,cDv,
    fsS,cRi,cDv,
    cA,
    cSl,
    cA,ls15,
    fsH,cA,cNB,cBd,
    fsS,cFt,cDv)

  -- ── LEFT PANEL ───────────────────────────────────────────────
  h[#h+1]='<div class="lp">'
  h[#h+1]=string.format('<div class="ph">&#9670; %s &#9670;</div>', ShipID:sub(1,18))
  for i,lbl in ipairs(SECTIONS) do
    local isSel=(i==SectionIdx)
    local cls="lr"..(isSel and " lsel" or "")
    h[#h+1]=string.format('<div class="%s"><span>%s</span><span class="la">&#62;</span></div>', cls, lbl)
  end
  if StatusMsg~="" then
    h[#h+1]=string.format('<div class="ft st">%s</div>', StatusMsg:sub(1,26))
  else
    h[#h+1]='<div class="ft">&#8593;&#8595; Alt &#8593;&#8595; &nbsp;|&nbsp; &#9658; Alt &#8594;</div>'
  end
  h[#h+1]='</div>'

  -- ── RIGHT PANEL ──────────────────────────────────────────────
  h[#h+1]='<div class="rp">'
  -- Current nav target
  if NavTarget then
    local tp=ParsePos(NavTarget.c); local cp2=GetCurrentPos()
    local dist=(tp and cp2) and FormatDist(CalcDist(cp2,tp)) or "---"
    local lbl=(NavTarget.t=="route") and "ROUTE" or "WP"
    local si2=(NavTarget.t=="route") and string.format(" [%d/%d]",NavTarget.stopIdx,NavTarget.stopTotal) or ""
    h[#h+1]=string.format('<div class="nav">&#9658; %s: %s%s &nbsp; %s</div>', lbl, NavTarget.n:sub(1,20), si2, dist)
  else
    h[#h+1]='<div class="nav" style="color:rgb(65,85,115);">&#9658; No target</div>'
  end
  -- AP hint
  if AutopilotCmd~="" and NavTarget and NavTarget.c then
    h[#h+1]=string.format('<div class="nav" style="color:rgb(255,200,50);font-size:%dpx;">%s</div>',
      fsS, (AutopilotCmd.." "..NavTarget.c):sub(1,40))
  end
  local secLabel=SECTIONS[SectionIdx]
  if secLabel=="ATLAS" and AtlasSearch~="" then secLabel="ATLAS  /"..AtlasSearch end
  if secLabel=="ORG" and ActiveOrg then secLabel="ORG  &#8250;  "..ActiveOrg end
  h[#h+1]=string.format('<div class="ph">&#8592; %s</div>', secLabel)

  -- scroll window
  local vis=9
  local winStart=1
  if clampedSub>0 then
    winStart=math.max(1,clampedSub-math.floor(vis/2))
    winStart=math.min(winStart,math.max(1,#items-vis+1))
  end
  local winEnd=math.min(#items,winStart+vis-1)

  for i=winStart,winEnd do
    local item=items[i]
    local sIdx=selIdxMap[i] or 0
    local isSel=(SubIdx>0 and sIdx==clampedSub and sIdx>0)
    if item.type=="hdr" then
      h[#h+1]=string.format('<div class="sep">%s</div>', item.label)
    elseif item.type=="info" then
      local style=item.highlight and ' style="color:rgb(0,200,180);"' or ""
      h[#h+1]=string.format('<div class="ri"%s>%s</div>', style, item.label)
    elseif item.type=="wp" then
      local cls="rr rw"..(isSel and " rsel" or "")
      h[#h+1]=string.format('<div class="%s"><span><span class="num">%d</span>%s</span><span><span style="opacity:0.65">%s</span><span class="arr">&#62;</span></span></div>',
        cls, sIdx, item.n:sub(1,18), item.dist or "---")
    elseif item.type=="route" then
      local cls="rr rrt"..(isSel and " rsel" or "")
      h[#h+1]=string.format('<div class="%s"><span><span class="num">%d</span>%s</span><span><span style="opacity:0.65">%d stops</span><span class="arr">&#62;</span></span></div>',
        cls, sIdx, item.n:sub(1,18), item.stops or 0)
    elseif item.type=="atlas" then
      local cls="rr rw"..(isSel and " rsel" or "")
      local cp2=GetCurrentPos(); local tp=ParsePos(item.c)
      local d=(cp2 and tp) and FormatDist(CalcDist(cp2,tp)) or "---"
      h[#h+1]=string.format('<div class="%s"><span><span class="num">%d</span>%s</span><span><span style="opacity:0.65">%s</span><span class="arr">&#62;</span></span></div>',
        cls, sIdx, item.n:sub(1,18), d)
    elseif item.type=="time" then
      local cls="rr rw"
      h[#h+1]=string.format('<div class="%s"><span>%s</span><span style="opacity:0.75">%s</span></div>',
        cls, item.n:sub(1,18), item.t and FormatTime(item.t) or "---")
    elseif item.type=="org_entry" then
      local cls="rr ra"..(isSel and " rsel" or "")
      h[#h+1]=string.format('<div class="%s"><span><span class="num">%d</span>%s</span><span><span style="opacity:0.55">%s</span><span class="arr">&#62;</span></span></div>',
        cls, sIdx, item.label:sub(1,14), item.sub or "")
    else
      local cls="rr ra"..(isSel and " rsel" or "")
      h[#h+1]=string.format('<div class="%s"><span><span class="num">%d</span>%s</span><span class="arr">&#62;</span></div>',
        cls, sIdx, item.label or item.type)
    end
  end

  -- footer
  if #sel==0 then
    h[#h+1]='<div class="ft">Alt &#8592; to go back</div>'
  elseif SubIdx==0 then
    h[#h+1]='<div class="ft">Alt &#8594; to enter &nbsp;|&nbsp; Alt &#8592; = back</div>'
  else
    h[#h+1]=string.format('<div class="ft">%d / %d &nbsp;|&nbsp; Alt &#8592; = back</div>', clampedSub, #sel)
  end
  h[#h+1]='</div>'

  system.setScreen(table.concat(h))
  system.showScreen(1)
end

function ActivateMenuItem()
  if SubIdx==0 then
    -- Enter the right panel
    local items=GetSubItems(); local sel=GetSelectable(items)
    if #sel>0 then SubIdx=1 end
    DrawHUD(); return
  end
  local items=GetSubItems(); local sel=GetSelectable(items)
  local clampedSub=math.min(SubIdx,#sel)
  if clampedSub<1 then DrawHUD(); return end
  local item=sel[clampedSub].v
  if item.type=="atlas" then
    NavTarget={t="wp",n=item.n,c=item.c}
    SaveData(); UpdateWaypoint()
    SendAutopilot(item.c)
    SetStatus("Navigating: "..item.n)
  elseif item.type=="wp" then
    ActiveContext=item.ctx; SetNavWP(item.n)
  elseif item.type=="route" then
    ActiveContext=item.ctx; SetNavRoute(item.n,1)
  elseif item.type=="mark_wp" then
    local p=GetCurrentPosStr()
    if p then AddWP(AutoName("WP",ContextWPs()),p) else SetStatus("No position") end
  elseif item.type=="next_stop"  then NextStop()
  elseif item.type=="prev_stop"  then PrevStop()
  elseif item.type=="clear_nav"  then ClearWaypoint(); SetStatus("Nav cleared")
  elseif item.type=="org_entry"  then
    ActiveOrg=item.n; ActiveContext=item.n; SubIdx=1
  elseif item.type=="sync_base"  then RequestSync(BaseChannel)
  elseif item.type=="sync_org"   then
    local ch=(OrgData[item.org] and OrgData[item.org].channel) or ""
    if ch~="" then RequestSync(ch) else SetStatus("No channel set for "..item.org) end
  elseif item.type=="push_base"  then PushToChannel(BaseChannel,PersonalWPs,PersonalRoutes)
  elseif item.type=="push_org"   then
    local org=item.org
    if OrgData[org] then
      ActiveContext=org
      local ch=OrgData[org].channel or ""
      if ch~="" then PushToChannel(ch,OrgData[org].wps,OrgData[org].routes)
      else SetStatus("No channel set for "..org) end
    else SetStatus("Sync from org first") end
  end
  DrawHUD()
end

-- ── Init ──────────────────────────────────────────────────────
do
  local ok,res=pcall(require,"autoconf/custom/"..CustomAtlas)
  if ok then Atlas=res; system.print("[NAV] Loaded custom atlas: "..CustomAtlas)
  else
    local ok2,res2=pcall(require,"atlas")
    if ok2 then Atlas=res2; system.print("[NAV] Loaded default atlas")
    else system.print("[NAV] WARNING: No atlas loaded — planet distances unavailable") end
  end
end
LoadData()
UpdateChannels()
unit.setTimer("nav_tick",5)
UpdateWaypoint()
DrawHUD()
system.print("=== Navigator "..VERSION.." (No Screen) ===  "..ShipID)
system.print("Target: "..(NavTarget and NavTarget.n or "none"))
system.print("Alt+Q/C = scroll  |  Alt+D = select  |  Shift = toggle HUD  |  type: help")


--[[@
slot=-1
event=onStop()
args=
]]
system.showScreen(0)


--[[@
slot=-1
event=onTimer(tag)
args="nav_tick"
]]
if StatusMsg~="" and system.getArkTime()>StatusExpiry then StatusMsg="" end
UpdateWaypoint()
DrawHUD()


--[[@
slot=-4
event=onActionStart(action)
args="lalt"
]]
L_ALT=true


--[[@
slot=-4
event=onActionLoop(action)
args="lalt"
]]
L_ALT=true


--[[@
slot=-4
event=onActionStop(action)
args="lalt"
]]
L_ALT=false


--[[@
slot=-4
event=onActionStart(action)
args="lshift"
]]
HUD_VISIBLE=not HUD_VISIBLE
DrawHUD()


--[[@
slot=-4
event=onActionStart(action)
args="up"
]]
if not L_ALT then return end
if SubIdx==0 then
  SectionIdx=math.max(1,SectionIdx-1); ActiveOrg=nil; ActiveContext="personal"
else
  local items=GetSubItems(); local sel=GetSelectable(items)
  SubIdx=math.max(1,SubIdx-1)
end
DrawHUD()


--[[@
slot=-4
event=onActionStart(action)
args="down"
]]
if not L_ALT then return end
if SubIdx==0 then
  SectionIdx=math.min(#SECTIONS,SectionIdx+1); ActiveOrg=nil; ActiveContext="personal"
else
  local items=GetSubItems(); local sel=GetSelectable(items)
  SubIdx=math.min(#sel,SubIdx+1)
end
DrawHUD()


--[[@
slot=-4
event=onActionStart(action)
args="straferight"
]]
if not L_ALT then return end
ActivateMenuItem()


--[[@
slot=-4
event=onActionStart(action)
args="strafeleft"
]]
if not L_ALT then return end
if SECTIONS[SectionIdx]=="ORG" and ActiveOrg then
  ActiveOrg=nil; ActiveContext="personal"; SubIdx=1
else
  SubIdx=0
end
DrawHUD()


--[[@
slot=-1
event=onTimer(tag)
args="push_tick"
]]
if not PushSending then unit.setTimer("push_tick",0) return end
if PushQueueIdx>#PushQueue then
  PushSending=false; unit.setTimer("push_tick",0)
  SetStatus("Pushed "..#PushQueue.." items to "..PushQueueCh)
  DrawHUD(); return
end
local item=PushQueue[PushQueueIdx]
if item.type=="wp" then
  emitter.send(PushQueueCh,"<PushWP>"..json.encode(item.data):gsub('"',"@@@"))
elseif item.type=="route" then
  emitter.send(PushQueueCh,"<PushRoute>"..json.encode(item.data):gsub('"',"@@@"))
end
PushQueueIdx=PushQueueIdx+1



--[[@
slot=1
event=onReceived(channel,message)
args=*,*
]]
-- isOrg: receiving on SyncingChannel (org sync request) or ShipID (first sync push)
local isOrg=(SyncingChannel~="" and channel==SyncingChannel)

if message:find("<OrgName>",1,true) then
  SyncOrgName=Trim(message:gsub("<OrgName>",""))
  EnsureOrg(SyncOrgName,channel)
end
if message:find("<OrgSyncStart>",1,true) then
  -- Base is sending cached org data; switch routing context
  local body=message:gsub("<OrgSyncStart>","")
  local orgName=body:match("^(.+)|ch:") or body
  local orgCh=body:match("|ch:(.+)$") or ""
  EnsureOrg(orgName,orgCh)
  SyncContext=orgName
end
if message:find("<SyncCount>",1,true) then
  SyncReceived=0; SyncContext="personal"
  SetStatus("Syncing from "..(isOrg and (SyncOrgName~="" and SyncOrgName or "org") or "base").."...")
end
if message:find("<SyncWP>",1,true) then
  local raw=message:gsub("<SyncWP>",""):gsub("@@@",'"')
  local ok,wp=pcall(json.decode,raw)
  if ok and wp and wp.n and wp.c then
    SyncReceived=(SyncReceived or 0)+1
    if isOrg and SyncOrgName~="" then
      EnsureOrg(SyncOrgName)
      local list=OrgData[SyncOrgName].wps
      local found=false
      for _,e in ipairs(list) do if e.n:lower()==wp.n:lower() then e.c=wp.c;found=true;break end end
      if not found then table.insert(list,{n=wp.n,c=wp.c}) end
    elseif SyncContext~="personal" and OrgData[SyncContext] then
      local list=OrgData[SyncContext].wps
      local found=false
      for _,e in ipairs(list) do if e.n:lower()==wp.n:lower() then e.c=wp.c;found=true;break end end
      if not found then table.insert(list,{n=wp.n,c=wp.c}) end
    else
      local found=false
      for _,e in ipairs(PersonalWPs) do if e.n:lower()==wp.n:lower() then e.c=wp.c;found=true;break end end
      if not found then table.insert(PersonalWPs,{n=wp.n,c=wp.c}) end
    end
  end
end
if message:find("<SyncRoute>",1,true) then
  local raw=message:gsub("<SyncRoute>",""):gsub("@@@",'"')
  local ok,r=pcall(json.decode,raw)
  if ok and r and r.n then
    SyncReceived=(SyncReceived or 0)+1
    local list
    if isOrg and SyncOrgName~="" then
      list=(OrgData[SyncOrgName] and OrgData[SyncOrgName].routes) or PersonalRoutes
    elseif SyncContext~="personal" and OrgData[SyncContext] then
      list=OrgData[SyncContext].routes
    else
      list=PersonalRoutes
    end
    local found=false
    for i,e in ipairs(list) do if e.n:lower()==r.n:lower() then list[i]=r;found=true;break end end
    if not found then table.insert(list,r) end
  end
end
if message:find("<SyncDenied>",1,true) then
  SetStatus("Sync denied — ask org admin to whitelist you",8)
  DrawHUD(); return
end
if message:find("<PushPending>",1,true) then
  SetStatus("Push queued for admin approval",6)
  DrawHUD(); return
end

if message:find("<SyncComplete>",1,true) then
  table.sort(PersonalWPs,   function(a,b) return a.n:lower()<b.n:lower() end)
  table.sort(PersonalRoutes,function(a,b) return a.n:lower()<b.n:lower() end)
  for _,org in ipairs(OrgNames) do
    if OrgData[org] then
      table.sort(OrgData[org].wps,    function(a,b) return a.n:lower()<b.n:lower() end)
      table.sort(OrgData[org].routes, function(a,b) return a.n:lower()<b.n:lower() end)
    end
  end
  SyncContext="personal"
  if SyncingChannel~="" and channel==SyncingChannel then
    SyncingChannel=""; UpdateChannels()
    system.print("[NAV] Org sync complete — channel closed")
  end
  SaveData(); SetStatus("Sync done: "..SyncReceived.." items")
end
if message:find("<PushWP>",1,true) then
  local raw=message:gsub("<PushWP>",""):gsub("@@@",'"')
  local ok,wp=pcall(json.decode,raw)
  if ok and wp and wp.n and wp.c then
    local found=false
    for _,e in ipairs(PersonalWPs) do if e.n:lower()==wp.n:lower() then e.c=wp.c;found=true;break end end
    if not found then table.insert(PersonalWPs,{n=wp.n,c=wp.c}) end
    SaveData()
  end
end


--[[@
slot=-4
event=onInputText(text)
args=*
]]
local t=Trim(text); local lo=t:lower()

if lo=="help" then
  system.print("═══════════════════════════════")
  system.print("  NAVIGATOR v2.0  (No Screen)")
  system.print("═══════════════════════════════")
  system.print("add NAME [::pos{..}]   save WP")
  system.print("del NAME               delete WP")
  system.print("newroute NAME          create route")
  system.print("addstop ROUTE WP/pos   add stop")
  system.print("delstop ROUTE N        remove stop N")
  system.print("delroute NAME          delete route")
  system.print("nav NAME               navigate to WP or route")
  system.print("nav off                clear nav")
  system.print("next / prev            next/prev stop")
  system.print("sync / orgsync         sync from base")
  system.print("push / orgpush         push to base")
  system.print("firstsync CHANNEL      first-time org sync, e.g: firstsync NavOrg")
  system.print("org NAME               switch active context")
  system.print("search NAME            filter atlas by name")
  system.print("search                 clear atlas filter")
  system.print("list / routes          list items")
  system.print("status                 show current nav")
  system.print("hudpos X Y              move HUD (e.g. hudpos 13 15)")
  system.print("Alt+Up/Down = browse  |  Alt+Right = activate")
  return
end

local addN,addC=t:match("^[Aa][Dd][Dd]%s+(.-)%s*(::pos%b{})")
if not addN then addN=t:match("^[Aa][Dd][Dd]%s+(.+)") end  -- no coords = use current pos
if addN then
  addN=Trim(addN)
  if addC and addC~="" then
    if ParsePos(addC) then AddWP(addN,addC) else SetStatus("Bad coords") end
  else
    local p=GetCurrentPosStr()
    if p then AddWP(addN,p) else SetStatus("No position") end
  end
  return
end

local srQ=t:match("^[Ss][Ee][Aa][Rr][Cc][Hh]%s*(.*)")
if srQ~=nil then
  AtlasSearch=Trim(srQ)
  SubIdx=0
  if AtlasSearch=="" then SetStatus("Atlas filter cleared")
  else SetStatus("Atlas filter: "..AtlasSearch) end
  DrawHUD(); return
end

local delN=t:match("^[Dd][Ee][Ll]%s+(.+)$")
if delN and delN:lower()~="route" then DelWP(Trim(delN)); return end

local nrN=t:match("^[Nn][Ee][Ww][Rr][Oo][Uu][Tt][Ee]%s+(.+)")
if nrN then AddRoute(Trim(nrN)); return end

local asRT,asArg=t:match("^[Aa][Dd][Dd][Ss][Tt][Oo][Pp]%s+(.-)%s+(::pos%b{})")
if not asRT then asRT,asArg=t:match("^[Aa][Dd][Dd][Ss][Tt][Oo][Pp]%s+(.-)%s*$") end
if asRT then AddStop(Trim(asRT),Trim(asArg or "")); return end

local dsRT,dsN=t:match("^[Dd][Ee][Ll][Ss][Tt][Oo][Pp]%s+(.-)%s+(%d+)%s*$")
if dsRT then DelStop(Trim(dsRT),tonumber(dsN)); return end

local drN=t:match("^[Dd][Ee][Ll][Rr][Oo][Uu][Tt][Ee]%s+(.+)")
if drN then DelRoute(Trim(drN)); return end

local navN=t:match("^[Nn][Aa][Vv]%s+(.*)")
if navN then
  navN=Trim(navN)
  if navN=="" or navN:lower()=="off" or navN:lower()=="clear" then
    ClearWaypoint();SetStatus("Nav cleared")
  else
    if not SetNavWP(navN) then SetNavRoute(navN,1) end
  end
  return
end

if lo=="next"    then NextStop(); return end
if lo=="prev"    then PrevStop(); return end
local fsCh=t:match("^[Ff][Ii][Rr][Ss][Tt][Ss][Yy][Nn][Cc]%s+(.+)")
if fsCh then RequestSync(Trim(fsCh)); return end
if lo=="firstsync" then SetStatus("Usage: firstsync CHANNEL  (channel shown on org sync PB screen)"); return end
if lo=="sync"    then RequestSync(BaseChannel); return end
if lo=="orgsync" then
  local ch=OrgChannelForContext()
  if ch then RequestSync(ch) else SetStatus("No org active — use org menu to sync") end
  return
end
if lo=="push"    then PushToChannel(BaseChannel,PersonalWPs,PersonalRoutes); return end
if lo=="orgpush" then
  local org=ActiveContext
  local ch=OrgChannelForContext()
  if org~="personal" and OrgData[org] and ch then PushToChannel(ch,OrgData[org].wps,OrgData[org].routes)
  elseif not ch then SetStatus("No channel for org — do first sync first")
  else SetStatus("Set org context first: org ORGNAME") end
  return
end

local orgCtx=t:match("^[Oo][Rr][Gg]%s+(.+)")
if orgCtx then
  orgCtx=Trim(orgCtx)
  if orgCtx:lower()=="personal" then ActiveContext="personal"; SetStatus("Context: personal")
  else
    local found=false
    for _,o in ipairs(OrgNames) do if o:lower()==orgCtx:lower() then ActiveContext=o;found=true;break end end
    if found then SetStatus("Context: "..ActiveContext)
    else SetStatus("Unknown org: "..orgCtx.."  known: "..table.concat(OrgNames,", ")) end
  end
  return
end

if lo=="status" then
  if not NavTarget then system.print("[NAV] No target") return end
  local tp=ParsePos(NavTarget.c); local cp=GetCurrentPos()
  local dist=(tp and cp) and FormatDist(CalcDist(cp,tp)) or "---"
  system.print("[NAV] "..(NavTarget.t=="route" and "[ROUTE]" or "[WP]").." "..NavTarget.n.."  "..dist)
  if NavTarget.t=="route" then system.print("[NAV] Stop "..NavTarget.stopIdx.."/"..NavTarget.stopTotal) end
  return
end

if lo=="list" then
  system.print("─── PERSONAL WPs ("..#PersonalWPs..") ───")
  for i,wp in ipairs(PersonalWPs) do system.print(i..".  "..wp.n.."  "..wp.c) end
  for _,org in ipairs(OrgNames) do
    local wps=OrgData[org].wps
    system.print("─── "..org.." WPs ("..#wps..") ───")
    for i,wp in ipairs(wps) do system.print(i..".  "..wp.n.."  "..wp.c) end
  end
  return
end

if lo=="routes" then
  system.print("─── PERSONAL ROUTES ("..#PersonalRoutes..") ───")
  for i,r in ipairs(PersonalRoutes) do
    system.print(i..".  "..r.n.."  ("..#r.pts.." stops)")
    for j,s in ipairs(r.pts) do system.print("    "..j..".  "..(s.label or s.c)) end
  end
  for _,org in ipairs(OrgNames) do
    local rs=OrgData[org].routes
    system.print("─── "..org.." ROUTES ("..#rs..") ───")
    for i,r in ipairs(rs) do
      system.print(i..".  "..r.n.."  ("..#r.pts.." stops)")
      for j,s in ipairs(r.pts) do system.print("    "..j..".  "..(s.label or s.c)) end
    end
  end
  return
end

local hpX,hpY=t:match("^[Hh][Uu][Dd][Pp][Oo][Ss]%s+(%d+)%s+(%d+)%s*$")
if hpX then
  HudPX=math.max(0,math.min(90,tonumber(hpX))); HudPY=math.max(0,math.min(90,tonumber(hpY)))
  SaveData(); SetStatus("HUD position: "..HudPX.."% "..HudPY.."%"); DrawHUD(); return
end

SetStatus("Unknown: '"..lo.."'  type help")
