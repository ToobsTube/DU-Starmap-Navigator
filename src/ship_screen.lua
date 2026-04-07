-- ================================================================
-- NAVIGATOR SHIP - SCREEN VERSION v2.0.0
-- Dual Universe Navigation System
--
-- SLOT CONNECTIONS (connect in this order):
--   Slot 0: screen     (Screen Unit)
--   Slot 1: databank   (Databank)
--   Slot 2: receiver   (Receiver)
--   Slot 3: emitter    (Emitter)
--
-- Mouse-driven UI. Chat commands for editing selected items.
-- Tabs: Personal | per org (learned from sync)
-- Left panel: Waypoints   Middle: Routes / Stops   Right: Nav + Actions
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
  local V=(CalcSpeed or 30000)/3.6
  local mass=construct and construct.getMass() or 0
  local Aa=CalcThrust and mass>0 and (CalcThrust*1000/mass) or (CalcAccel or 5)
  local brakeN=construct and construct.getMaxBrake and construct.getMaxBrake() or 0
  local Ad=CalcBrake and CalcBrake>0 and (CalcBrake*1000/math.max(mass,1))
         or (brakeN>0 and mass>0 and brakeN/mass)
         or Aa  -- fallback: symmetric (same as turn-and-burn)
  if Aa<=0 then return dist/math.max(V,1) end
  local d_accel=V*V/(2*Aa)
  local d_decel=V*V/(2*Ad)
  if d_accel+d_decel>=dist then
    -- triangle profile — find peak speed given asymmetric arms
    local Vp=math.sqrt(2*dist/(1/Aa+1/Ad))
    return Vp/Aa+Vp/Ad
  else
    return V/Aa+V/Ad+(dist-d_accel-d_decel)/V
  end
end
function ParsePos(s)
  if not s or s=="" then return nil end
  local w,b,x,y,z=s:match("::pos{(%d+),(%d+),([-%.%d]+),([-%.%d]+),([-%.%d]+)}")
  if not x then return nil end
  w,b,x,y,z=tonumber(w),tonumber(b),tonumber(x),tonumber(y),tonumber(z)
  if b==0 then return {x=x,y=y,z=z} end
  if Atlas then
    local sys=Atlas[0] or Atlas[1]
    if type(sys)=="table" then
      for _,body in pairs(sys) do
        if type(body)=="table" and body.id==b then
          local c=type(body.center)=="table" and body.center or nil
          if c and c[1] then
            local deg=math.pi/180
            local lat,lon,alt=x*deg,y*deg,z
            local r=(body.radius or 0)+alt
            local cx=r*math.cos(lat)*math.cos(lon)
            local cy=r*math.cos(lat)*math.sin(lon)
            local cz=r*math.sin(lat)
            return {x=c[1]+cx,y=c[2]+cy,z=c[3]+cz}
          end
        end
      end
    end
  end
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
  StatusMsg=msg; StatusExpiry=system.getArkTime()+(dur or 5)
  system.print("[NAV] "..msg)
end

-- ── Theme utilities ─────────────────────────────────────────
THEME_SLOT_NAMES={"accent","background","text","header","btnNormal","btnHover","selected","route"}
THEME_SLOT_LABELS={"Accent","Background","Text","Header","Btn Normal","Btn Hover","Selected","Route"}

function HSV2RGB(h,s,v)
  h=h%360; local c=v*s; local x=c*(1-math.abs((h/60)%2-1)); local m=v-c
  local r,g,b
  if     h<60  then r,g,b=c,x,0
  elseif h<120 then r,g,b=x,c,0
  elseif h<180 then r,g,b=0,c,x
  elseif h<240 then r,g,b=0,x,c
  elseif h<300 then r,g,b=x,0,c
  else              r,g,b=c,0,x end
  return r+m,g+m,b+m
end

function RGB2HSV(r,g,b)
  local mx=math.max(r,g,b); local mn=math.min(r,g,b); local d=mx-mn
  local h,s,v=0, mx>0 and d/mx or 0, mx
  if d>0 then
    if     mx==r then h=60*((g-b)/d%6)
    elseif mx==g then h=60*((b-r)/d+2)
    else              h=60*((r-g)/d+4) end
  end
  return h,s,v
end

function Hex2RGB(hex)
  hex=hex:gsub("^#","")
  if #hex~=6 then return nil end
  local r=tonumber(hex:sub(1,2),16)
  local g=tonumber(hex:sub(3,4),16)
  local b=tonumber(hex:sub(5,6),16)
  if not r or not g or not b then return nil end
  return r/255,g/255,b/255
end

function RGB2Hex(r,g,b)
  return string.format("#%02X%02X%02X",math.floor(r*255+0.5),math.floor(g*255+0.5),math.floor(b*255+0.5))
end

function DefaultShipTheme()
  return {
    {h=195,s=1.0,v=1.0},    -- accent (cyan)
    {h=210,s=0.80,v=0.04},  -- background
    {h=0,  s=0,  v=0.82},   -- text
    {h=48, s=1.0,v=1.0},    -- header (gold)
    {h=195,s=1.0,v=0.40},   -- btnNormal
    {h=195,s=0.85,v=0.65},  -- btnHover
    {h=195,s=1.0,v=0.86},   -- selected
    {h=140,s=0.70,v=1.0},   -- route (green)
  }
end

function DeriveTheme(slots)
  local p={}
  -- Accent
  p.ar,p.ag,p.ab=HSV2RGB(slots[1].h,slots[1].s,slots[1].v)
  local mx=math.max(p.ar,p.ag,p.ab,0.001)
  p.nr,p.ng,p.nb=p.ar/mx,p.ag/mx,p.ab/mx
  -- Background
  p.bgr,p.bgg,p.bgb=HSV2RGB(slots[2].h,slots[2].s,slots[2].v)
  -- Text
  p.txr,p.txg,p.txb=HSV2RGB(slots[3].h,slots[3].s,slots[3].v)
  -- Header
  p.hdr,p.hdg,p.hdb=HSV2RGB(slots[4].h,slots[4].s,slots[4].v)
  -- Status (fixed orange for visibility)
  p.str,p.stg,p.stb=1.0,0.78,0.2
  -- Lines (derived from accent)
  p.lnr,p.lng,p.lnb=HSV2RGB(slots[1].h,slots[1].s*0.5,slots[1].v*0.4)
  -- Button normal fill + stroke
  p.bnfr,p.bnfg,p.bnfb=HSV2RGB(slots[5].h,slots[5].s,slots[5].v)
  p.bnsr,p.bnsg,p.bnsb=HSV2RGB(slots[5].h,slots[5].s*0.85,math.min(slots[5].v*1.6,1))
  -- Button hover fill + stroke
  p.bhfr,p.bhfg,p.bhfb=HSV2RGB(slots[6].h,slots[6].s,slots[6].v)
  p.bhsr,p.bhsg,p.bhsb=HSV2RGB(slots[6].h,slots[6].s*0.75,math.min(slots[6].v*1.35,1))
  -- Selection
  p.slr,p.slg,p.slb=HSV2RGB(slots[7].h,slots[7].s,slots[7].v)
  -- Route
  p.rtr,p.rtg,p.rtb=HSV2RGB(slots[8].h,slots[8].s,slots[8].v)
  p.rtdr,p.rtdg,p.rtdb=HSV2RGB(slots[8].h,slots[8].s*0.6,slots[8].v*0.35) -- route dark (sel fill)
  p.rtlr,p.rtlg,p.rtlb=HSV2RGB(slots[8].h,slots[8].s*0.5,math.min(slots[8].v*1.1,1)) -- route light (sel text)
  -- Derived panel/tab/scroll
  p.phdr,p.phdg,p.phdb=HSV2RGB(slots[1].h,slots[1].s*0.6,slots[1].v*0.12)
  p.tabr,p.tabg,p.tabb=HSV2RGB(slots[1].h,slots[1].s*0.8,slots[1].v*0.35)
  p.tbbr,p.tbbg,p.tbbb=HSV2RGB(slots[1].h,slots[1].s*0.6,slots[1].v*0.08)
  p.sbtr,p.sbtg,p.sbtb=HSV2RGB(slots[1].h,slots[1].s*0.5,slots[1].v*0.3)
  p.sbhr,p.sbhg,p.sbhb=HSV2RGB(slots[1].h,slots[1].s*0.7,slots[1].v*0.7)
  p.ftr,p.ftg,p.ftb=HSV2RGB(slots[2].h,slots[2].s*0.7,math.max(slots[2].v*1.5,0.06))
  -- Disabled button (desaturated, dark)
  p.bdfr,p.bdfg,p.bdfb=0.06,0.06,0.14
  p.bdsr,p.bdsg,p.bdsb=0.18,0.18,0.28
  p.bdtr,p.bdtg,p.bdtb=0.28,0.28,0.38  -- disabled text
  -- Dim text (number indices, inactive)
  p.dmr,p.dmg,p.dmb=p.txr*0.40,p.txg*0.40,p.txb*0.44
  p.nmr,p.nmg,p.nmb=p.txr*0.37,p.txg*0.43,p.txb*0.61  -- number text
  p.lbr,p.lbg,p.lbb=p.txr*0.51,p.txg*0.51,p.txb*0.76  -- info label
  p.tir,p.tig,p.tib=p.txr*0.67,p.txg*0.67,p.txb*0.85  -- tab inactive
  return p
end

function LoadTheme()
  if not databank then return DefaultShipTheme() end
  local name=databank.getStringValue("theme_profile_active")
  if name=="" then
    -- Migration: check if AccentR/G/B differ from defaults
    if AccentR~=0 or AccentG~=200 or AccentB~=255 then
      local r,g,b=AccentR/255,AccentG/255,AccentB/255
      local h,s,v=RGB2HSV(r,g,b)
      local slots=DefaultShipTheme()
      slots[1]={h=h,s=s,v=v}
      SaveTheme("Migrated",slots)
      return slots
    end
    return DefaultShipTheme()
  end
  local raw=databank.getStringValue("theme_p_"..name)
  if raw=="" then return DefaultShipTheme() end
  local ok,data=pcall(json.decode,raw)
  if not ok or not data then return DefaultShipTheme() end
  -- Validate: must be array of 8 {h,s,v}
  if #data<8 then return DefaultShipTheme() end
  for i=1,8 do
    if type(data[i])~="table" or not data[i].h then return DefaultShipTheme() end
  end
  return data
end

function SaveTheme(name,slots)
  if not databank then return end
  name=name:gsub("[^%w%s_-]",""):sub(1,20)
  if name=="" then name="Default" end
  databank.setStringValue("theme_p_"..name,json.encode(slots))
  databank.setStringValue("theme_profile_active",name)
  local raw=databank.getStringValue("theme_profile_names") or "[]"
  local ok,names=pcall(json.decode,raw)
  if not ok or type(names)~="table" then names={} end
  local found=false
  for _,n in ipairs(names) do if n==name then found=true;break end end
  if not found then table.insert(names,name) end
  databank.setStringValue("theme_profile_names",json.encode(names))
end

function DeleteTheme(name)
  if not databank then return end
  databank.setStringValue("theme_p_"..name,"")
  local raw=databank.getStringValue("theme_profile_names") or "[]"
  local ok,names=pcall(json.decode,raw)
  if not ok then return end
  for i,n in ipairs(names) do if n==name then table.remove(names,i);break end end
  databank.setStringValue("theme_profile_names",json.encode(names))
  if databank.getStringValue("theme_profile_active")==name then
    databank.setStringValue("theme_profile_active",names[1] or "")
  end
end

function GetThemeProfiles()
  if not databank then return {} end
  local raw=databank.getStringValue("theme_profile_names")
  if not raw or raw=="" then return {} end
  local ok,names=pcall(json.decode,raw)
  if not ok or type(names)~="table" then return {} end
  return names
end

function GetActiveProfileName()
  if not databank then return "Default" end
  local n=databank.getStringValue("theme_profile_active")
  return n~="" and n or "Default"
end

function ExportTheme(name,slots)
  local parts={}
  for _,s in ipairs(slots) do
    table.insert(parts,string.format("%.2f,%.2f,%.2f",s.h,s.s,s.v))
  end
  return "THEME:"..name..":"..table.concat(parts,"|")
end

function ImportTheme(str)
  local prefix,name,body=str:match("^(THEME):(.-):(.*)")
  if not prefix then return nil,nil end
  local slots={}
  for part in body:gmatch("[^|]+") do
    local h,s,v=part:match("(.+),(.+),(.+)")
    h,s,v=tonumber(h),tonumber(s),tonumber(v)
    if not h then return nil,nil end
    table.insert(slots,{h=h,s=s,v=v})
  end
  if #slots~=8 then return nil,nil end
  return name,slots
end


--[[@
slot=-1
event=onStart()
args=
]]

local VERSION="v2.0.0"
Atlas        =nil
CustomAtlas ="atlas"   --export: Atlas file to load (default=atlas, set to custom filename in autoconf/custom/)
BaseChannel ="NavBase" --export: Personal base channel
AutopilotCmd=""        --export: Autopilot command prefix e.g. /goto or / (blank = disabled)
CalcSpeed   =30000    --export: Time Calc max speed in space in km/h (e.g. 30000)
CalcThrust  =0        --export: Time Calc total thrust in kN from ship stats (0 = use CalcAccel fallback)
CalcBrake   =0        --export: Time Calc total brake force in kN from ship stats (0 = auto-detect, fallback to thrust)
CalcAccel   =5        --export: Time Calc fallback acceleration in m/s2 — ignored if CalcThrust is set
AccentR=0    --export: Screen accent color Red 0-255 (default 0)
AccentG=200  --export: Screen accent color Green 0-255 (default 200)
AccentB=255  --export: Screen accent color Blue 0-255 (default 255)

-- Runtime state
PersonalWPs     = {}
PersonalRoutes  = {}
OrgNames        = {}   -- list of known org names, in order
OrgData         = {}   -- {orgName:{wps=[],routes=[]}}
NavTarget       = nil  -- {t,n,c,tab,stopIdx}
ShipID          = ""
StatusMsg       = ""; StatusExpiry=0
ActiveTab       = 0    -- 0=personal, 1..N=org index
SelWP           = ""
SelRoute        = ""
SelStop         = 0    -- >0 = viewing stops of SelRoute
ScrollWP        = 0
ScrollRT        = 0
AtlasSearch     = ""
CurrentPos      = nil
SyncReceived    = 0
LastScreenOut   = ""
SyncOrgName     = ""   -- org name being synced right now
SyncContext     = "personal"  -- routing target during a base sync
SyncingChannel  = ""          -- channel we're currently syncing from (open for duration of sync)
PushQueue    = {}
PushQueueCh  = ""
PushQueueIdx = 1
PushSending  = false

-- Theme state
ShowThemePicker = false
ShowFirstSync   = false
ThemeSlots      = nil   -- loaded on init
Palette         = nil   -- derived from ThemeSlots
PickerElem      = 1     -- 1-8, which slot is being edited
PickerProfileScroll = 0

-- ── Databank ──────────────────────────────────────────────────
function LoadData()
  if not databank then PersonalWPs={};PersonalRoutes={};return end
  local function jd(k) local v=databank.getStringValue(k); return (v and v~="") and json.decode(v) or nil end
  PersonalWPs    = jd("personal_wps")    or {}
  PersonalRoutes = jd("personal_routes") or {}
  OrgNames       = jd("org_names")       or {}
  OrgData        = {}
  for _,org in ipairs(OrgNames) do
    local k=OrgKey(org)
    OrgData[org]={wps=jd(k.."_wps") or {}, routes=jd(k.."_routes") or {}, channel=databank.getStringValue(k.."_ch") or ""}
  end
  NavTarget = jd("nav_target")
  ShipID = BuildShipID()
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
end

-- ── Tab helpers ───────────────────────────────────────────────
function GetTabWPs()
  if ActiveTab==0 then return PersonalWPs end
  local org=OrgNames[ActiveTab]; return org and OrgData[org] and OrgData[org].wps or {}
end
function GetTabRoutes()
  if ActiveTab==0 then return PersonalRoutes end
  local org=OrgNames[ActiveTab]; return org and OrgData[org] and OrgData[org].routes or {}
end
function GetTabName()
  if ActiveTab==0 then return "Personal" end
  return OrgNames[ActiveTab] or "Org"
end
function GetTabOrgChannel()
  if ActiveTab==0 then return nil end
  local org=OrgNames[ActiveTab]
  if org and OrgData[org] and OrgData[org].channel~="" then
    return OrgData[org].channel
  end
  return nil
end

-- ── WP management ────────────────────────────────────────────
function TabAddWP(name,posStr,tab)
  local list=(tab==0) and PersonalWPs or (OrgData[OrgNames[tab]] and OrgData[OrgNames[tab]].wps)
  if not list then SetStatus("Invalid tab") return false end
  for _,wp in ipairs(list) do
    if wp.n:lower()==name:lower() then wp.c=posStr; SaveData(); SetStatus("Updated: "..name); return true end
  end
  table.insert(list,{n=name,c=posStr})
  table.sort(list,function(a,b) return a.n:lower()<b.n:lower() end)
  SaveData(); SetStatus("Saved WP: "..name); return true
end

function TabDelWP(name,tab)
  local list=(tab==0) and PersonalWPs or (OrgData[OrgNames[tab]] and OrgData[OrgNames[tab]].wps)
  if not list then return false end
  for i,wp in ipairs(list) do
    if wp.n:lower()==name:lower() then
      table.remove(list,i)
      if SelWP==name then SelWP="" end
      if NavTarget and NavTarget.t=="wp" and NavTarget.n:lower()==name:lower() and NavTarget.tab==tab then
        NavTarget=nil
      end
      SaveData(); SetStatus("Deleted WP: "..name); return true
    end
  end
  SetStatus("WP not found: "..name); return false
end

function TabRenameWP(oldName,newName,tab)
  local list=(tab==0) and PersonalWPs or (OrgData[OrgNames[tab]] and OrgData[OrgNames[tab]].wps)
  if not list then return end
  for _,v in ipairs(list) do if v.n:lower()==newName:lower() then SetStatus("Name already exists: "..newName) return end end
  for _,wp in ipairs(list) do
    if wp.n:lower()==oldName:lower() then
      wp.n=newName
      if SelWP==oldName then SelWP=newName end
      if NavTarget and NavTarget.t=="wp" and NavTarget.n:lower()==oldName:lower() and NavTarget.tab==tab then NavTarget.n=newName end
      table.sort(list,function(a,b) return a.n:lower()<b.n:lower() end)
      SaveData(); SetStatus("Renamed to: "..newName); return
    end
  end
  SetStatus("WP not found: "..oldName)
end

-- ── Route management ─────────────────────────────────────────
function TabAddRoute(name,tab)
  local list=(tab==0) and PersonalRoutes or (OrgData[OrgNames[tab]] and OrgData[OrgNames[tab]].routes)
  if not list then SetStatus("Invalid tab") return false end
  for _,r in ipairs(list) do if r.n:lower()==name:lower() then SetStatus("Route exists: "..name) return false end end
  table.insert(list,{n=name,pts={}})
  table.sort(list,function(a,b) return a.n:lower()<b.n:lower() end)
  SaveData(); SetStatus("Route created: "..name); return true
end

function TabDelRoute(name,tab)
  local list=(tab==0) and PersonalRoutes or (OrgData[OrgNames[tab]] and OrgData[OrgNames[tab]].routes)
  if not list then return false end
  for i,r in ipairs(list) do
    if r.n:lower()==name:lower() then
      table.remove(list,i)
      if SelRoute==name then SelRoute="";SelStop=0 end
      if NavTarget and NavTarget.t=="route" and NavTarget.n:lower()==name:lower() and NavTarget.tab==tab then NavTarget=nil end
      SaveData(); SetStatus("Route deleted: "..name); return true
    end
  end
  SetStatus("Route not found: "..name); return false
end

function TabRenameRoute(oldName,newName,tab)
  local list=(tab==0) and PersonalRoutes or (OrgData[OrgNames[tab]] and OrgData[OrgNames[tab]].routes)
  if not list then return end
  for _,v in ipairs(list) do if v.n:lower()==newName:lower() then SetStatus("Name exists: "..newName) return end end
  for _,r in ipairs(list) do
    if r.n:lower()==oldName:lower() then
      r.n=newName
      if SelRoute==oldName then SelRoute=newName end
      if NavTarget and NavTarget.t=="route" and NavTarget.n:lower()==oldName:lower() and NavTarget.tab==tab then NavTarget.n=newName end
      table.sort(list,function(a,b) return a.n:lower()<b.n:lower() end)
      SaveData(); SetStatus("Renamed to: "..newName); return
    end
  end
  SetStatus("Route not found: "..oldName)
end

-- Resolve a stop argument: either a WP name or a raw ::pos{}
function ResolveStopCoords(arg,wps)
  if ParsePos(arg) then return arg,arg end
  for _,wp in ipairs(wps) do
    if wp.n:lower()==arg:lower() then return wp.c,wp.n end
  end
  return nil,nil
end

function AddStop(routeName,arg,tab)
  local routes=(tab==0) and PersonalRoutes or (OrgData[OrgNames[tab]] and OrgData[OrgNames[tab]].routes)
  local wps   =(tab==0) and PersonalWPs    or (OrgData[OrgNames[tab]] and OrgData[OrgNames[tab]].wps)
  if not routes then return end
  for _,r in ipairs(routes) do
    if r.n:lower()==routeName:lower() then
      local c,lbl=ResolveStopCoords(arg,wps)
      if not c then SetStatus("Not a WP name or ::pos{}") return end
      table.insert(r.pts,{c=c,label=lbl})
      SaveData(); SetStatus("Stop added to "..r.n.." ("..#r.pts.." stops)"); return
    end
  end
  SetStatus("Route not found: "..routeName)
end

function DelStop(routeName,idx,tab)
  local routes=(tab==0) and PersonalRoutes or (OrgData[OrgNames[tab]] and OrgData[OrgNames[tab]].routes)
  if not routes then return end
  for _,r in ipairs(routes) do
    if r.n:lower()==routeName:lower() then
      if idx<1 or idx>#r.pts then SetStatus("Stop index out of range") return end
      table.remove(r.pts,idx)
      if SelStop==idx then SelStop=math.max(0,idx-1) end
      if NavTarget and NavTarget.t=="route" and NavTarget.n:lower()==routeName:lower() then
        if NavTarget.stopIdx>=#r.pts then NavTarget.stopIdx=math.max(1,#r.pts) end
        if #r.pts>0 then NavTarget.c=r.pts[NavTarget.stopIdx].c end
      end
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

function SendAutopilot(name, coords)
  if not coords or coords=="" then return end
  -- Arch HUD databank integration: write to Arch's databank (slot 4, optional)
  if archbank then
    archbank.setStringValue("nav_arch_dest", (name or "Navigator").."|"..coords)
    system.print("[NAV] wrote to archbank: "..(name or "Navigator"))
  end
  -- Legacy AutopilotCmd (chat command fallback)
  if AutopilotCmd~="" then
    system.print(AutopilotCmd.." "..coords)
  end
end

function SetNavWP(name,tab)
  local list=(tab==0) and PersonalWPs or (OrgData[OrgNames[tab]] and OrgData[OrgNames[tab]].wps) or {}
  for _,wp in ipairs(list) do
    if wp.n:lower()==name:lower() then
      NavTarget={t="wp",n=wp.n,c=wp.c,tab=tab}
      SaveData(); UpdateWaypoint()
      SendAutopilot(wp.n, wp.c)
      if AutopilotCmd=="" then SetStatus("Navigating: "..wp.n) end
      return true
    end
  end
  SetStatus("WP not found: "..name); return false
end

function SetNavRoute(name,tab,startStop)
  local list=(tab==0) and PersonalRoutes or (OrgData[OrgNames[tab]] and OrgData[OrgNames[tab]].routes) or {}
  for _,r in ipairs(list) do
    if r.n:lower()==name:lower() then
      if #r.pts==0 then SetStatus("Route has no stops") return false end
      local idx=startStop or 1
      NavTarget={t="route",n=r.n,c=r.pts[idx].c,tab=tab,stopIdx=idx,stopTotal=#r.pts}
      SaveData(); UpdateWaypoint()
      local stopLabel=r.n.." stop "..idx.."/"..#r.pts
      SendAutopilot(stopLabel, r.pts[idx].c)
      if AutopilotCmd=="" then SetStatus("Route: "..stopLabel) end
      return true
    end
  end
  SetStatus("Route not found: "..name); return false
end

function NextStop()
  if not NavTarget or NavTarget.t~="route" then SetStatus("Not navigating a route") return end
  local routes=(NavTarget.tab==0) and PersonalRoutes or (OrgData[OrgNames[NavTarget.tab]] and OrgData[OrgNames[NavTarget.tab]].routes) or {}
  for _,r in ipairs(routes) do
    if r.n:lower()==NavTarget.n:lower() then
      local idx=NavTarget.stopIdx+1
      if idx>#r.pts then SetStatus("Already at last stop ("..r.n..")") return end
      NavTarget.stopIdx=idx; NavTarget.c=r.pts[idx].c; NavTarget.stopTotal=#r.pts
      SaveData(); UpdateWaypoint()
      local stopLabel=r.n.." stop "..idx.."/"..#r.pts
      SendAutopilot(stopLabel, r.pts[idx].c)
      SetStatus("Stop "..idx.."/"..#r.pts.."  "..(r.pts[idx].label or r.pts[idx].c:sub(1,30))); return
    end
  end
end

function PrevStop()
  if not NavTarget or NavTarget.t~="route" then return end
  local routes=(NavTarget.tab==0) and PersonalRoutes or (OrgData[OrgNames[NavTarget.tab]] and OrgData[OrgNames[NavTarget.tab]].routes) or {}
  for _,r in ipairs(routes) do
    if r.n:lower()==NavTarget.n:lower() then
      local idx=NavTarget.stopIdx-1
      if idx<1 then SetStatus("Already at first stop") return end
      NavTarget.stopIdx=idx; NavTarget.c=r.pts[idx].c; NavTarget.stopTotal=#r.pts
      SaveData(); UpdateWaypoint()
      local stopLabel=r.n.." stop "..idx.."/"..#r.pts
      SendAutopilot(stopLabel, r.pts[idx].c)
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
  -- Send auth header first so base can verify before accepting items
  emitter.send(ch,"<PushAuth>"..ShipID.."|pid:"..GetPlayerID().."|pname:"..GetPlayerName().."|count:"..#PushQueue)
  SetStatus("Pushing "..#PushQueue.." items to "..ch.."...")
  unit.setTimer("push_tick",0.25)
end

-- ── Org registry ─────────────────────────────────────────────
function EnsureOrg(name, ch)
  -- If another entry already owns this channel, rename it to the real name
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
  table.insert(OrgNames,name)
  OrgData[name]={wps={},routes={},channel=ch or ""}
  SaveData()
end

-- ── Mark current position ─────────────────────────────────────
function MarkWP()
  local p=GetCurrentPosStr()
  if not p then SetStatus("No position — is construct linked?") return end
  local wps=GetTabWPs()
  TabAddWP(AutoName("WP",wps),p,ActiveTab)
end

function MarkRouteStop()
  local p=GetCurrentPosStr()
  if not p then SetStatus("No position (core connected?)") return end
  if SelRoute=="" then SetStatus("Select a route first, then Mark Stop") return end
  AddStop(SelRoute,p,ActiveTab)
end

-- ── Screen ───────────────────────────────────────────────────
function RefreshTheme()
  Palette=DeriveTheme(ThemeSlots)
end

function DrawScreen()
  if not screen then return end
  if not Palette then Palette=DeriveTheme(ThemeSlots or DefaultShipTheme()) end
  local which=ShowThemePicker and "picker" or "screen"
  local builder=ShowThemePicker and BuildPickerScript or BuildScreenScript
  local ok,result=pcall(builder)
  if not ok then system.print("[NAV] "..which.." err: "..tostring(result)); return end
  local ok2,err=pcall(function() screen.setRenderScript(result) end)
  if not ok2 then system.print("[NAV] setScript err: "..tostring(err)) end
end

function BuildScreenScript()
  local wps    = GetTabWPs()
  local routes = GetTabRoutes()
  local ni     = NavTarget
  local nName  = ni and ni.n   or ""
  local nDist  = "---"
  local nCoord = ni and ni.c   or ""
  local nType  = ni and ni.t   or ""
  local nStop  = ni and ni.stopIdx   or 0
  local nTotal = ni and ni.stopTotal or 0
  local nTime="---"
  if ni and ni.c then
    local tp=ParsePos(ni.c); local cp=GetCurrentPos()
    if tp and cp then
      local d=CalcDist(cp,tp)
      nDist=FormatDist(d)
      local t=CalcTravelTime(d)
      if t then nTime=FormatTime(t) end
    end
  end

  -- Stops for selected route
  local selRoutePts = {}
  if SelRoute~="" then
    for _,r in ipairs(routes) do if r.n==SelRoute then selRoutePts=r.pts;break end end
  end

  -- Tab names
  local tabNames={"Personal"}
  for _,o in ipairs(OrgNames) do table.insert(tabNames,o) end
  table.insert(tabNames,"ATLAS")
  local atlasTabIdx=#tabNames-1  -- 0-based index of the ATLAS tab

  -- Build atlas body list (sorted by name)
  local atlasBodies={}
  if Atlas then
    for _,sys in pairs(Atlas) do
      if type(sys)=="table" then
        for _,body in pairs(sys) do
          if type(body)=="table" then
            local nm=type(body.name)=="table" and body.name[1] or body.name
            local c=type(body.center)=="table" and body.center or nil
            if type(nm)=="string" and nm~="" and c and c[1] and c[2] and c[3] then
              local pos=string.format("::pos{0,0,%.4f,%.4f,%.4f}",c[1],c[2],c[3])
              table.insert(atlasBodies,{n=nm,c=pos})
            end
          end
        end
      end
    end
    table.sort(atlasBodies,function(a,b) return a.n:lower()<b.n:lower() end)
    if AtlasSearch~="" then
      local q=AtlasSearch:lower()
      local filtered={}
      for _,b in ipairs(atlasBodies) do if b.n:lower():find(q,1,true) then table.insert(filtered,b) end end
      atlasBodies=filtered
    end
  end

  -- Build Lua table literals directly — avoids json encode/decode in render script
  local function luaList(list)
    local t={}
    for _,v in ipairs(list) do
      if v.n and v.c then
        table.insert(t, string.format("{n=%q,c=%q}", v.n, v.c))
      elseif type(v)=="string" then
        table.insert(t, string.format("%q", v))
      end
    end
    return "{"..table.concat(t,",").."}"
  end
  local function luaRoute(list)
    local t={}
    for _,r in ipairs(list) do
      local pts={}
      for _,p in ipairs(r.pts or {}) do
        local lbl=p.label or ""
        table.insert(pts, string.format("{c=%q,label=%q}", p.c or "", lbl))
      end
      table.insert(t, string.format("{n=%q,pts={%s}}", r.n, table.concat(pts,",")))
    end
    return "{"..table.concat(t,",").."}"
  end
  local function luaStrList(list)
    local t={}
    for _,s in ipairs(list) do table.insert(t, string.format("%q",s)) end
    return "{"..table.concat(t,",").."}"
  end

  local wpLit  = luaList(wps)
  local rtLit  = luaRoute(routes)
  local ptLit  = luaList(selRoutePts or {})
  local tnLit  = luaStrList(tabNames)
  local atLit  = luaList(atlasBodies)
  local orgChPairs={}
  for _,o in ipairs(OrgNames) do
    local ch=(OrgData[o] and OrgData[o].channel) or ""
    if ch~="" then table.insert(orgChPairs,string.format("{n=%q,ch=%q}",o,ch)) end
  end
  local orgChLit="{"..table.concat(orgChPairs,",").."}"

  local S={}
  local P=Palette
  if not P then error("Palette nil") end

  S[1]=string.format([[
local json=require('dkjson')
local C=32 local SW,SH=getResolution()
-- Theme palette (pre-derived)
local Ar,Ag,Ab=%f,%f,%f local Nr,Ng,Nb=%f,%f,%f
local Bgr,Bgg,Bgb=%f,%f,%f
local Txr,Txg,Txb=%f,%f,%f
local Hdr,Hdg,Hdb=%f,%f,%f
local Str,Stg,Stb=%f,%f,%f
local Lnr,Lng,Lnb=%f,%f,%f
local Rtr,Rtg,Rtb=%f,%f,%f local Rtdr,Rtdg,Rtdb=%f,%f,%f local Rtlr,Rtlg,Rtlb=%f,%f,%f
local BNfr,BNfg,BNfb=%f,%f,%f local BNsr,BNsg,BNsb=%f,%f,%f
local BHfr,BHfg,BHfb=%f,%f,%f local BHsr,BHsg,BHsb=%f,%f,%f
local BDfr,BDfg,BDfb=%f,%f,%f local BDsr,BDsg,BDsb=%f,%f,%f local BDtr,BDtg,BDtb=%f,%f,%f
local SLr,SLg,SLb=%f,%f,%f
local PHr,PHg,PHb=%f,%f,%f local TAr,TAg,TAb=%f,%f,%f local TBr,TBg,TBb=%f,%f,%f
local STr,STg,STb=%f,%f,%f local SHr,SHg,SHb=%f,%f,%f
local FTr,FTg,FTb=%f,%f,%f
local DMr,DMg,DMb=%f,%f,%f local NMr,NMg,NMb=%f,%f,%f local LBr,LBg,LBb=%f,%f,%f local TIr,TIg,TIb=%f,%f,%f
local ScrollWP=%d local ScrollRT=%d
local SelWP=%q local SelRT=%q local SelStop=%d
local nName=%q local nDist=%q local nTime=%q local nCoord=%q local nType=%q
local nStop=%d local nTotal=%d
local StatusMsg=%q
local ActiveTab=%d
local ATLAS_TAB=%d
local AtlasSearch=%q
local WP=%s
local RT=%s
local STOPS=%s
local TABS=%s
local ATLASBODIES=%s
local ORG_CHANNELS=%s
local ShowFirstSync=%s
]],
    P.ar,P.ag,P.ab, P.nr,P.ng,P.nb,
    P.bgr,P.bgg,P.bgb,
    P.txr,P.txg,P.txb,
    P.hdr,P.hdg,P.hdb,
    P.str,P.stg,P.stb,
    P.lnr,P.lng,P.lnb,
    P.rtr,P.rtg,P.rtb, P.rtdr,P.rtdg,P.rtdb, P.rtlr,P.rtlg,P.rtlb,
    P.bnfr,P.bnfg,P.bnfb, P.bnsr,P.bnsg,P.bnsb,
    P.bhfr,P.bhfg,P.bhfb, P.bhsr,P.bhsg,P.bhsb,
    P.bdfr,P.bdfg,P.bdfb, P.bdsr,P.bdsg,P.bdsb, P.bdtr,P.bdtg,P.bdtb,
    P.slr,P.slg,P.slb,
    P.phdr,P.phdg,P.phdb, P.tabr,P.tabg,P.tabb, P.tbbr,P.tbbg,P.tbbb,
    P.sbtr,P.sbtg,P.sbtb, P.sbhr,P.sbhg,P.sbhb,
    P.ftr,P.ftg,P.ftb,
    P.dmr,P.dmg,P.dmb, P.nmr,P.nmg,P.nmb, P.lbr,P.lbg,P.lbb, P.tir,P.tig,P.tib,
    ScrollWP,ScrollRT,SelWP,SelRoute,SelStop,
    nName,nDist,nTime,nCoord,nType,nStop,nTotal,
    StatusMsg,ActiveTab,atlasTabIdx,AtlasSearch,wpLit,rtLit,ptLit,tnLit,atLit,
    orgChLit,tostring(ShowFirstSync))

  S[2]=[[
local Lbg=createLayer() local Lp=createLayer() local Ll=createLayer()
local Lb=createLayer() local Ls=createLayer() local Lt=createLayer()
local Lh=createLayer() local Lx=createLayer()
local cx,cy=getCursor() local pr=getCursorReleased() local Out=""
local fT=loadFont("Montserrat-Light",18) local fS=loadFont("Montserrat-Light",13)
local fH=loadFont("Montserrat-Light",20) local fB=loadFont("Montserrat-Light",22)
setDefaultFillColor(Lt,Shape_Text,Txr,Txg,Txb,1)
setDefaultFillColor(Lh,Shape_Text,Ar,Ag,Ab,1)
setDefaultFillColor(Ls,Shape_Text,Nr,Ng,Nb,1)
setDefaultFillColor(Lx,Shape_Text,Hdr,Hdg,Hdb,1)
setDefaultStrokeColor(Ll,Shape_Line,Lnr,Lng,Lnb,0.6)
setDefaultStrokeWidth(Ll,Shape_Line,1)
setNextFillColor(Lbg,Bgr,Bgg,Bgb,1) addBox(Lbg,0,0,SW,SH)
-- panel edges
local wpX,wpW=0,352 local rtX,rtW=352,320 local nvX,nvW=672,352
local TAB_Y=32 local TAB_H=24 local CON_Y=56 local CON_H=SH-56-32
local vis=math.floor(CON_H/C)-1

local function PH(x,w,r,g,b) -- panel header bar
  setNextFillColor(Lp,r,g,b,0.88)
  addBox(Lp,x,CON_Y,w,C)
end
local function Row(x,w,i) return CON_Y+C+(i-1)*C end
local function Btn(tx,x,y,w,h,en)
  local hv=(cx>=x and cx<x+w and cy>=y and cy<y+h)
  if not en then
    setNextFillColor(Lb,BDfr,BDfg,BDfb,0.7) setNextStrokeColor(Lb,BDsr,BDsg,BDsb,0.5)
    setNextStrokeWidth(Lb,1) addBoxRounded(Lb,x,y,w,h,4)
    setNextFillColor(Lt,BDtr,BDtg,BDtb,1) setNextTextAlign(Lt,AlignH_Center,AlignV_Middle)
    addText(Lt,fT,tx,x+w/2,y+h/2) return false
  elseif hv then
    setNextFillColor(Lb,BHfr,BHfg,BHfb,1) setNextStrokeColor(Lb,BHsr,BHsg,BHsb,1)
    setNextStrokeWidth(Lb,1) addBoxRounded(Lb,x,y,w,h,4)
    setNextTextAlign(Lt,AlignH_Center,AlignV_Middle) addText(Lt,fT,tx,x+w/2,y+h/2)
  else
    setNextFillColor(Lb,BNfr,BNfg,BNfb,0.9) setNextStrokeColor(Lb,BNsr,BNsg,BNsb,1)
    setNextStrokeWidth(Lb,1) addBoxRounded(Lb,x,y,w,h,4)
    setNextTextAlign(Lt,AlignH_Center,AlignV_Middle) addText(Lt,fT,tx,x+w/2,y+h/2)
  end
  return hv and pr
end
]]

  S[3]=[[
-- HEADER
setNextFillColor(Lp,PHr,PHg,PHb,1) setNextStrokeColor(Lp,Lnr,Lng,Lnb,0.8)
setNextStrokeWidth(Lp,1) addBox(Lp,0,0,SW,C)
setNextTextAlign(Lx,AlignH_Left,AlignV_Middle) addText(Lx,fB,"◄ NAVIGATOR v2.0 ►",8,C/2)
if nName~="" then
  local lbl=(nType=="route" and "RT▶" or "WP▶")..nName..(nStop>0 and "  stop "..nStop.."/"..nTotal or "")
  setNextTextAlign(Lh,AlignH_Center,AlignV_Middle) addText(Lh,fH,lbl,SW/2,C/2)
  setNextTextAlign(Lh,AlignH_Right,AlignV_Middle)  addText(Lh,fH,nDist,SW-8,C/2)
else
  setNextFillColor(Lt,DMr,DMg,DMb,1) setNextTextAlign(Lt,AlignH_Center,AlignV_Middle)
  addText(Lt,fT,"No navigation target  —  select an item then click Navigate",SW/2,C/2)
end
addLine(Ll,0,C,SW,C)
]]

  S[4]=[[
-- TAB BAR
setNextFillColor(Lp,TBr,TBg,TBb,0.95) addBox(Lp,0,TAB_Y,SW,TAB_H)
local tw=math.min(140,math.floor(SW/#TABS))
local maxChars=math.max(3,math.floor(tw/7)-1)
for i,tn in ipairs(TABS) do
  local tx=(i-1)*tw local ty=TAB_Y
  local lbl=#tn>maxChars and tn:sub(1,maxChars-1)..".." or tn
  local active=(i-1==ActiveTab)
  if active then
    setNextFillColor(Lp,TAr,TAg,TAb,1) setNextStrokeColor(Lp,Ar,Ag,Ab,0.8)
    setNextStrokeWidth(Lp,1) addBox(Lp,tx,ty,tw,TAB_H)
    setNextTextAlign(Ls,AlignH_Center,AlignV_Middle) addText(Ls,fS,lbl,tx+tw/2,ty+TAB_H/2)
  else
    local hv=(cx>=tx and cx<tx+tw and cy>=ty and cy<ty+TAB_H)
    if hv then
      setNextFillColor(Lp,1,1,1,0.06) addBox(Lp,tx,ty,tw,TAB_H)
    end
    setNextFillColor(Lt,TIr,TIg,TIb,1) setNextTextAlign(Lt,AlignH_Center,AlignV_Middle)
    addText(Lt,fS,lbl,tx+tw/2,ty+TAB_H/2)
    if hv and pr then Out=json.encode({"tab",i-1}) end
  end
end
addLine(Ll,0,TAB_Y+TAB_H,SW,TAB_Y+TAB_H)
-- panel dividers
addLine(Ll,wpX+wpW,CON_Y,wpX+wpW,SH-32)
addLine(Ll,rtX+rtW,CON_Y,rtX+rtW,SH-32)
]]

  S[5]=[[
-- WAYPOINTS / ATLAS PANEL
if ActiveTab==ATLAS_TAB then
  -- ATLAS VIEW
  PH(wpX,wpW,PHr,PHg,PHb)
  setNextTextAlign(Ls,AlignH_Center,AlignV_Middle)
  local atlasHdr="ATLAS ["..#ATLASBODIES.."]"..(AtlasSearch~="" and "  /"..AtlasSearch or "")
  addText(Ls,fH,atlasHdr,wpX+wpW/2,CON_Y+C/2)
  addLine(Ll,wpX,CON_Y+C,wpX+wpW,CON_Y+C)
  local maxSA=math.max(0,#ATLASBODIES-vis+1) local sCA=math.max(0,math.min(ScrollWP,maxSA))
  for i=1,vis do
    local idx=i+sCA if idx>#ATLASBODIES then break end
    local b=ATLASBODIES[idx] local ry=Row(wpX,wpW,i)
    local sel=(b.n==SelWP) local hv=(cx>=wpX and cx<wpX+wpW and cy>=ry and cy<ry+C)
    if sel then
      setNextFillColor(Lp,SLr,SLg,SLb,0.28) setNextStrokeColor(Lp,Ar,Ag,Ab,0.9)
      setNextStrokeWidth(Lp,1) addBox(Lp,wpX,ry,wpW,C)
    elseif hv then setNextFillColor(Lp,1,1,1,0.04) addBox(Lp,wpX,ry,wpW,C) end
    setNextFillColor(Lt,NMr,NMg,NMb,1) setNextTextAlign(Lt,AlignH_Right,AlignV_Middle)
    addText(Lt,fS,idx..".",wpX+28,ry+C/2)
    local L=(sel or hv) and Ls or Lt
    if sel then setNextFillColor(Ls,Nr,Ng,Nb,1) end
    setNextTextAlign(L,AlignH_Left,AlignV_Middle) addText(L,fT,b.n,wpX+32,ry+C/2)
    setNextStrokeColor(Ll,Lnr,Lng,Lnb,0.20) addLine(Ll,wpX,ry+C,wpX+wpW,ry+C)
    if hv and pr then Out=json.encode({"selwp",b.n}) end
  end
  if #ATLASBODIES>vis then
    local sbX=wpX+wpW-10 local sbW=10 local sbY=CON_Y+C+2 local sbH=vis*C-4
    local tH=math.max(18,sbH*(vis/#ATLASBODIES)) local tY=sbY+(sbH-tH)*(sCA/math.max(1,maxSA))
    setNextFillColor(Ll,STr,STg,STb,0.4) addBox(Ll,sbX,sbY,sbW,sbH)
    setNextFillColor(Ll,SHr,SHg,SHb,0.8) addBox(Ll,sbX,tY,sbW,tH)
    if cx>=sbX and cx<sbX+sbW and cy>=sbY and cy<sbY+sbH and pr then
      Out=json.encode({"scrollwp",cy<tY+tH/2 and -1 or 1})
    end
  end
else
  -- WAYPOINTS VIEW
  PH(wpX,wpW,PHr,PHg,PHb)
  setNextTextAlign(Lx,AlignH_Center,AlignV_Middle)
  addText(Lx,fH,"WAYPOINTS ["..#WP.."]",wpX+wpW/2,CON_Y+C/2)
  addLine(Ll,wpX,CON_Y+C,wpX+wpW,CON_Y+C)
  local maxSW=math.max(0,#WP-vis+1) local sCW=math.max(0,math.min(ScrollWP,maxSW))
  for i=1,vis do
    local idx=i+sCW if idx>#WP then break end
    local wp=WP[idx] local ry=Row(wpX,wpW,i)
    local sel=(wp.n==SelWP) local hv=(cx>=wpX and cx<wpX+wpW and cy>=ry and cy<ry+C)
    if sel then
      setNextFillColor(Lp,SLr,SLg,SLb,0.28) setNextStrokeColor(Lp,Ar,Ag,Ab,0.9)
      setNextStrokeWidth(Lp,1) addBox(Lp,wpX,ry,wpW,C)
    elseif hv then setNextFillColor(Lp,1,1,1,0.04) addBox(Lp,wpX,ry,wpW,C) end
    setNextFillColor(Lt,NMr,NMg,NMb,1) setNextTextAlign(Lt,AlignH_Right,AlignV_Middle)
    addText(Lt,fS,idx..".",wpX+28,ry+C/2)
    local L=(sel or hv) and Ls or Lt
    if sel then setNextFillColor(Ls,Nr,Ng,Nb,1) end
    setNextTextAlign(L,AlignH_Left,AlignV_Middle) addText(L,fT,wp.n,wpX+32,ry+C/2)
    setNextStrokeColor(Ll,Lnr,Lng,Lnb,0.20) addLine(Ll,wpX,ry+C,wpX+wpW,ry+C)
    if hv and pr then Out=json.encode({"selwp",wp.n}) end
  end
  if #WP>vis then
    local sbX=wpX+wpW-10 local sbW=10 local sbY=CON_Y+C+2 local sbH=vis*C-4
    local tH=math.max(18,sbH*(vis/#WP)) local tY=sbY+(sbH-tH)*(sCW/math.max(1,maxSW))
    setNextFillColor(Ll,STr,STg,STb,0.4) addBox(Ll,sbX,sbY,sbW,sbH)
    setNextFillColor(Ll,SHr,SHg,SHb,0.8) addBox(Ll,sbX,tY,sbW,tH)
    if cx>=sbX and cx<sbX+sbW and cy>=sbY and cy<sbY+sbH and pr then
      Out=json.encode({"scrollwp",cy<tY+tH/2 and -1 or 1})
    end
  end
end
]]

  S[6]=[[
-- ROUTE / STOPS PANEL
if SelStop>0 and SelRT~="" then
  -- STOP LIST VIEW
  PH(rtX,rtW,PHr,PHg,PHb)
  setNextFillColor(Lh,Ar,Ag,Ab,1) setNextTextAlign(Lh,AlignH_Left,AlignV_Middle)
  addText(Lh,fH,"◄ "..SelRT.." STOPS",rtX+8,CON_Y+C/2)
  addLine(Ll,rtX,CON_Y+C,rtX+rtW,CON_Y+C)
  local maxSR=math.max(0,#STOPS-vis+1) local sCR=math.max(0,math.min(ScrollRT,maxSR))
  for i=1,vis do
    local idx=i+sCR if idx>#STOPS then break end
    local st=STOPS[idx] local ry=Row(rtX,rtW,i)
    local sel=(SelStop==idx) local hv=(cx>=rtX and cx<rtX+rtW and cy>=ry and cy<ry+C)
    if sel then
      setNextFillColor(Lp,SLr,SLg,SLb,0.28) setNextStrokeColor(Lp,Ar,Ag,Ab,0.9)
      setNextStrokeWidth(Lp,1) addBox(Lp,rtX,ry,rtW,C)
    elseif hv then setNextFillColor(Lp,1,1,1,0.04) addBox(Lp,rtX,ry,rtW,C) end
    setNextFillColor(Lt,NMr,NMg,NMb,1) setNextTextAlign(Lt,AlignH_Right,AlignV_Middle)
    addText(Lt,fS,idx..".",rtX+24,ry+C/2)
    local lbl=st.label or st.c:sub(1,26)
    local L=(sel or hv) and Ls or Lt
    if sel then setNextFillColor(Ls,Nr,Ng,Nb,1) end
    setNextTextAlign(L,AlignH_Left,AlignV_Middle) addText(L,fT,lbl,rtX+28,ry+C/2)
    setNextStrokeColor(Ll,Lnr,Lng,Lnb,0.20) addLine(Ll,rtX,ry+C,rtX+rtW,ry+C)
    if hv and pr then Out=json.encode({"selstop",idx}) end
  end
  if #STOPS>vis then
    local sbX=rtX+rtW-10 local sbW=10 local sbY=CON_Y+C+2 local sbH=vis*C-4
    local tH=math.max(18,sbH*(vis/#STOPS)) local tY=sbY+(sbH-tH)*(sCR/math.max(1,maxSR))
    setNextFillColor(Ll,STr,STg,STb,0.4) addBox(Ll,sbX,sbY,sbW,sbH)
    setNextFillColor(Ll,SHr,SHg,SHb,0.8) addBox(Ll,sbX,tY,sbW,tH)
    if cx>=sbX and cx<sbX+sbW and cy>=sbY and cy<sbY+sbH and pr then
      Out=json.encode({"scrollrt",cy<tY+tH/2 and -1 or 1})
    end
  end
else
  -- ROUTE LIST VIEW
  PH(rtX,rtW,Rtdr,Rtdg,Rtdb)
  setNextFillColor(Lh,Rtr,Rtg,Rtb,1) setNextTextAlign(Lh,AlignH_Center,AlignV_Middle)
  addText(Lh,fH,"ROUTES ["..#RT.."]",rtX+rtW/2,CON_Y+C/2)
  addLine(Ll,rtX,CON_Y+C,rtX+rtW,CON_Y+C)
  local maxSR=math.max(0,#RT-vis+1) local sCR=math.max(0,math.min(ScrollRT,maxSR))
  for i=1,vis do
    local idx=i+sCR if idx>#RT then break end
    local r=RT[idx] local ry=Row(rtX,rtW,i)
    local sel=(r.n==SelRT) local hv=(cx>=rtX and cx<rtX+rtW and cy>=ry and cy<ry+C)
    if sel then
      setNextFillColor(Lp,Rtdr,Rtdg,Rtdb,0.22) setNextStrokeColor(Lp,Rtr,Rtg,Rtb,0.9)
      setNextStrokeWidth(Lp,1) addBox(Lp,rtX,ry,rtW,C)
    elseif hv then setNextFillColor(Lp,1,1,1,0.04) addBox(Lp,rtX,ry,rtW,C) end
    local L=(sel or hv) and Ls or Lt
    if sel then setNextFillColor(Ls,Rtlr,Rtlg,Rtlb,1) end
    setNextTextAlign(L,AlignH_Left,AlignV_Middle) addText(L,fT,r.n,rtX+8,ry+C/2)
    local npts=#(r.pts or {})
    setNextFillColor(Lt,Rtdr,Rtdg,Rtdb,1) setNextTextAlign(Lt,AlignH_Right,AlignV_Middle)
    addText(Lt,fS,npts.." ▶",rtX+rtW-6,ry+C/2)
    setNextStrokeColor(Ll,Lnr,Lng,Lnb,0.20) addLine(Ll,rtX,ry+C,rtX+rtW,ry+C)
    if hv and pr then Out=json.encode({"selrt",r.n}) end
  end
  if #RT>vis then
    local sbX=rtX+rtW-10 local sbW=10 local sbY=CON_Y+C+2 local sbH=vis*C-4
    local tH=math.max(18,sbH*(vis/#RT)) local tY=sbY+(sbH-tH)*(sCR/math.max(1,maxSR))
    setNextFillColor(Ll,Rtdr,Rtdg,Rtdb,0.4) addBox(Ll,sbX,sbY,sbW,sbH)
    setNextFillColor(Ll,Rtlr,Rtlg,Rtlb,0.8) addBox(Ll,sbX,tY,sbW,tH)
    if cx>=sbX and cx<sbX+sbW and cy>=sbY and cy<sbY+sbH and pr then
      Out=json.encode({"scrollrt",cy<tY+tH/2 and -1 or 1})
    end
  end
end
]]

  S[7]=[[
-- NAV PANEL
PH(nvX,nvW,PHr,PHg,PHb)
setNextFillColor(Lh,Ar,Ag,Ab,1) setNextTextAlign(Lh,AlignH_Center,AlignV_Middle)
addText(Lh,fH,"NAVIGATION",nvX+nvW/2,CON_Y+C/2)
addLine(Ll,nvX,CON_Y+C,nvX+nvW,CON_Y+C)
-- info rows
local ny=CON_Y+C+8
local function NR(lbl,val)
  setNextFillColor(Lt,LBr,LBg,LBb,1) setNextTextAlign(Lt,AlignH_Left,AlignV_Top)
  addText(Lt,fS,lbl,nvX+6,ny)
  setNextFillColor(Lt,Txr,Txg,Txb,1) setNextTextAlign(Lt,AlignH_Left,AlignV_Top)
  addText(Lt,fT,val,nvX+6,ny+14); ny=ny+C+4
end
if nName~="" then
  NR("TARGET ["..(nType=="route" and "ROUTE" or "WP").."]", nName)
  NR("DISTANCE", nDist.."   ▸ "..nTime)
  if nStop>0 then NR("ROUTE STOP", nStop.." / "..nTotal) end
  setNextFillColor(Lt,LBr,LBg,LBb,1) setNextTextAlign(Lt,AlignH_Left,AlignV_Top)
  addText(Lt,fS,"COORDS",nvX+6,ny); ny=ny+13
  local c1=nCoord:sub(1,28) local c2=nCoord:sub(29)
  setNextFillColor(Lt,Txr*0.8,Txg*0.8,Txb*0.8,1) setNextTextAlign(Lt,AlignH_Left,AlignV_Top)
  addText(Lt,fS,c1,nvX+6,ny); ny=ny+13
  if c2~="" then setNextFillColor(Lt,Txr*0.8,Txg*0.8,Txb*0.8,1) setNextTextAlign(Lt,AlignH_Left,AlignV_Top) addText(Lt,fS,c2,nvX+6,ny) end
else
  setNextFillColor(Lt,DMr,DMg,DMb,1) setNextTextAlign(Lt,AlignH_Center,AlignV_Middle)
  addText(Lt,fT,"No target",nvX+nvW/2,CON_Y+C*3)
  setNextFillColor(Lt,DMr*0.7,DMg*0.7,DMb*0.7,1) setNextTextAlign(Lt,AlignH_Center,AlignV_Middle)
  addText(Lt,fS,"Select WP or Route",nvX+nvW/2,CON_Y+C*4)
end
-- Buttons
local bX=nvX+5 local bW=nvW-10 local bH=26 local bG=4
local by=SH-32-(bH+bG)*9-32
if Btn("★ MARK WP HERE",         bX,by,bW,bH,true)        then Out=json.encode({"mark_wp"})         end by=by+bH+bG
if Btn("★ MARK ROUTE STOP",      bX,by,bW,bH,SelRT~="")   then Out=json.encode({"mark_stop"})        end by=by+bH+bG
if ActiveTab==ATLAS_TAB then
  if Btn("▶ NAVIGATE TO BODY",   bX,by,bW,bH,SelWP~="")   then Out=json.encode({"nav_atlas",SelWP})  end by=by+bH+bG
  by=by+bH+bG  -- skip route button slot
else
  if Btn("▶ NAVIGATE WP",        bX,by,bW,bH,SelWP~="")   then Out=json.encode({"nav_wp",SelWP})     end by=by+bH+bG
  if Btn("▶ NAVIGATE ROUTE",     bX,by,bW,bH,SelRT~="")   then Out=json.encode({"nav_rt",SelRT})     end by=by+bH+bG
end
if Btn("▶▶ NEXT STOP",           bX,by,bW,bH,nType=="route") then Out=json.encode({"next_stop"})     end by=by+bH+bG
if Btn("◀◀ PREV STOP",           bX,by,bW,bH,nType=="route") then Out=json.encode({"prev_stop"})     end by=by+bH+bG
if Btn("✕ CLEAR NAV",            bX,by,bW,bH,nName~="")   then Out=json.encode({"clear_nav"})        end by=by+bH+bG
local isOrgTab=(ActiveTab>0 and ActiveTab~=ATLAS_TAB)
if isOrgTab then
  if Btn("⟳ SYNC ORG",           bX,by,bW,bH,true)        then Out=json.encode({"sync","org"})       end by=by+bH+bG
  if Btn("⬆ PUSH TO ORG",        bX,by,bW,bH,true)        then Out=json.encode({"push","org"})       end by=by+bH+bG
else
  if Btn("⟳ SYNC BASE",          bX,by,bW,bH,true)        then Out=json.encode({"sync","base"})      end by=by+bH+bG
  if Btn("⬆ PUSH TO BASE",       bX,by,bW,bH,true)        then Out=json.encode({"push","base"})      end by=by+bH+bG
end
if Btn("▶ FIRST ORG SYNC",bX,by,bW,bH,true) then Out=json.encode({"firstsync_hint"}) end
]]

  S[8]=[[
-- FOOTER
addLine(Ll,0,SH-32,SW,SH-32)
setNextFillColor(Lp,FTr,FTg,FTb,0.95) addBox(Lp,0,SH-32,SW,32)
-- [THEME] button in footer
local thX=SW-80 local thW=72 local thY=SH-28 local thH=22
local thHv=(cx>=thX and cx<thX+thW and cy>=thY and cy<thY+thH)
if thHv then
  setNextFillColor(Lb,BHfr,BHfg,BHfb,0.8) setNextStrokeColor(Lb,BHsr,BHsg,BHsb,0.8)
else
  setNextFillColor(Lb,BNfr,BNfg,BNfb,0.6) setNextStrokeColor(Lb,BNsr,BNsg,BNsb,0.6)
end
setNextStrokeWidth(Lb,1) addBoxRounded(Lb,thX,thY,thW,thH,3)
setNextTextAlign(Lt,AlignH_Center,AlignV_Middle) addText(Lt,fS,"THEME",thX+thW/2,thY+thH/2)
if thHv and pr then Out=json.encode({"open_theme"}) end
-- Status / hint text
if StatusMsg~="" then
  setNextFillColor(Lt,Str,Stg,Stb,1) setNextTextAlign(Lt,AlignH_Center,AlignV_Middle) addText(Lt,fT,StatusMsg,SW/2-40,SH-16)
else
  setNextFillColor(Lt,DMr,DMg,DMb,1) setNextTextAlign(Lt,AlignH_Center,AlignV_Middle)
  if SelWP~="" or SelRT~="" then
    addText(Lt,fS,"Selected: "..(SelWP~="" and "WP ["..SelWP.."]" or "Route ["..SelRT.."]").."  |  chat: rename / setpos / del / addstop / delstop N",SW/2-40,SH-16)
  else
    addText(Lt,fS,"Click WP or Route to select  |  chat: help  |  Mark WP Here to save position",SW/2-40,SH-16)
  end
end
setOutput(Out) requestAnimationFrame(2)
]]
  return table.concat(S)
end

-- ── Color Picker Screen ─────────────────────────────────────
function BuildPickerScript()
  if not ThemeSlots then ThemeSlots=DefaultShipTheme() end
  if not Palette then Palette=DeriveTheme(ThemeSlots) end
  local P=Palette
  local slots=ThemeSlots
  local elem=PickerElem or 1
  local cur=slots[elem] or {h=0,s=0,v=0}
  local cr,cg,cb=HSV2RGB(cur.h,cur.s,cur.v)
  local profName=GetActiveProfileName()
  local profNames=GetThemeProfiles()

  -- Build element color swatches as Lua table literal (live/unsaved)
  local swatches={}
  for i=1,8 do
    local s=slots[i] or {h=0,s=0,v=0}
    local r,g,b=HSV2RGB(s.h,s.s,s.v)
    table.insert(swatches,string.format("{%.3f,%.3f,%.3f}",r,g,b))
  end
  local swLit="{"..table.concat(swatches,",").."}"

  -- Build saved swatches from databank (what's actually stored)
  local savedSlots=nil
  if databank then
    local sn=GetActiveProfileName()
    local sr=databank.getStringValue("theme_p_"..sn)
    if sr and sr~="" then
      local ok,sd=pcall(json.decode,sr)
      if ok and type(sd)=="table" and #sd>=8 then savedSlots=sd end
    end
  end
  if not savedSlots then savedSlots=slots end
  local savedSwatches={}
  for i=1,8 do
    local s=savedSlots[i] or {h=0,s=0,v=0}
    local r,g,b=HSV2RGB(s.h,s.s,s.v)
    table.insert(savedSwatches,string.format("{%.3f,%.3f,%.3f}",r,g,b))
  end
  local savedSwLit="{"..table.concat(savedSwatches,",").."}"

  -- Element labels
  local lblLit="{"
  for i,l in ipairs(THEME_SLOT_LABELS) do
    if i>1 then lblLit=lblLit.."," end
    lblLit=lblLit..string.format("%q",l)
  end
  lblLit=lblLit.."}"

  -- Profile names
  local pnLit="{"
  for i,n in ipairs(profNames) do
    if i>1 then pnLit=pnLit.."," end
    pnLit=pnLit..string.format("%q",n)
  end
  pnLit=pnLit.."}"

  local S={}
  S[1]=string.format([[
local json=require('dkjson')
local SW,SH=getResolution()
local cx,cy=getCursor() local pr=getCursorReleased() local Out=""
local Bgr,Bgg,Bgb=%f,%f,%f
local Txr,Txg,Txb=%f,%f,%f
local Hdr,Hdg,Hdb=%f,%f,%f
local PHr,PHg,PHb=%f,%f,%f
local Lnr,Lng,Lnb=%f,%f,%f
local BNfr,BNfg,BNfb=%f,%f,%f local BNsr,BNsg,BNsb=%f,%f,%f
local BHfr,BHfg,BHfb=%f,%f,%f local BHsr,BHsg,BHsb=%f,%f,%f
local BDfr,BDfg,BDfb=%f,%f,%f local BDsr,BDsg,BDsb=%f,%f,%f local BDtr,BDtg,BDtb=%f,%f,%f
local FTr,FTg,FTb=%f,%f,%f
local Ar,Ag,Ab=%f,%f,%f local Nr,Ng,Nb=%f,%f,%f
local SelElem=%d
local CurH,CurS,CurV=%f,%f,%f
local CurR,CurG,CurB=%f,%f,%f
local ProfName=%q
local LABELS=%s
local SWATCHES=%s
local SAVED_SWATCHES=%s
local PROFILES=%s
]],
    P.bgr,P.bgg,P.bgb, P.txr,P.txg,P.txb, P.hdr,P.hdg,P.hdb,
    P.phdr,P.phdg,P.phdb, P.lnr,P.lng,P.lnb,
    P.bnfr,P.bnfg,P.bnfb, P.bnsr,P.bnsg,P.bnsb,
    P.bhfr,P.bhfg,P.bhfb, P.bhsr,P.bhsg,P.bhsb,
    P.bdfr,P.bdfg,P.bdfb, P.bdsr,P.bdsg,P.bdsb, P.bdtr,P.bdtg,P.bdtb,
    P.ftr,P.ftg,P.ftb,
    P.ar,P.ag,P.ab, P.nr,P.ng,P.nb,
    elem, cur.h,cur.s,cur.v, cr,cg,cb,
    profName, lblLit, swLit, savedSwLit, pnLit)

  S[2]=[[
-- Layers & fonts
local Lbg=createLayer() local Lp=createLayer() local Ll=createLayer()
local Lb=createLayer() local Lc=createLayer() local Lt=createLayer()
local Lh=createLayer() local Lx=createLayer()
local fT=loadFont("Montserrat-Light",18) local fS=loadFont("Montserrat-Light",13)
local fH=loadFont("Montserrat-Light",20) local fB=loadFont("Montserrat-Light",22)
setDefaultFillColor(Lt,Shape_Text,Txr,Txg,Txb,1)
setDefaultFillColor(Lh,Shape_Text,Ar,Ag,Ab,1)
setDefaultFillColor(Lx,Shape_Text,Hdr,Hdg,Hdb,1)
setDefaultStrokeColor(Ll,Shape_Line,Lnr,Lng,Lnb,0.6)
setDefaultStrokeWidth(Ll,Shape_Line,1)

-- Background
setNextFillColor(Lbg,Bgr,Bgg,Bgb,1) addBox(Lbg,0,0,SW,SH)

-- HSV to RGB (local to render script)
local function h2r(h,s,v)
  h=h%360 local c=v*s local x=c*(1-math.abs((h/60)%2-1)) local m=v-c
  local r,g,b
  if     h<60  then r,g,b=c,x,0 elseif h<120 then r,g,b=x,c,0
  elseif h<180 then r,g,b=0,c,x elseif h<240 then r,g,b=0,x,c
  elseif h<300 then r,g,b=x,0,c else r,g,b=c,0,x end
  return r+m,g+m,b+m
end

-- Button helper
local function Btn(tx,x,y,w,h,en)
  local hv=(cx>=x and cx<x+w and cy>=y and cy<y+h)
  if not en then
    setNextFillColor(Lb,BDfr,BDfg,BDfb,0.7) setNextStrokeColor(Lb,BDsr,BDsg,BDsb,0.5)
    setNextStrokeWidth(Lb,1) addBoxRounded(Lb,x,y,w,h,4)
    setNextFillColor(Lt,BDtr,BDtg,BDtb,1) setNextTextAlign(Lt,AlignH_Center,AlignV_Middle)
    addText(Lt,fT,tx,x+w/2,y+h/2) return false
  elseif hv then
    setNextFillColor(Lb,BHfr,BHfg,BHfb,1) setNextStrokeColor(Lb,BHsr,BHsg,BHsb,1)
    setNextStrokeWidth(Lb,1) addBoxRounded(Lb,x,y,w,h,4)
    setNextTextAlign(Lt,AlignH_Center,AlignV_Middle) addText(Lt,fT,tx,x+w/2,y+h/2)
  else
    setNextFillColor(Lb,BNfr,BNfg,BNfb,0.9) setNextStrokeColor(Lb,BNsr,BNsg,BNsb,1)
    setNextStrokeWidth(Lb,1) addBoxRounded(Lb,x,y,w,h,4)
    setNextTextAlign(Lt,AlignH_Center,AlignV_Middle) addText(Lt,fT,tx,x+w/2,y+h/2)
  end
  return hv and pr
end
]]

  S[3]=[[
-- ═══ HEADER ═══
setNextFillColor(Lp,PHr,PHg,PHb,1) setNextStrokeColor(Lp,Lnr,Lng,Lnb,0.8)
setNextStrokeWidth(Lp,1) addBox(Lp,0,0,SW,32)
-- Close button
local clX,clW=4,70
local clHv=(cx>=clX and cx<clX+clW and cy>=4 and cy<28)
if clHv then setNextFillColor(Lb,0.6,0.15,0.1,0.9) else setNextFillColor(Lb,0.35,0.08,0.05,0.8) end
setNextStrokeColor(Lb,0.8,0.3,0.2,0.7) setNextStrokeWidth(Lb,1)
addBoxRounded(Lb,clX,4,clW,24,3)
setNextTextAlign(Lt,AlignH_Center,AlignV_Middle) addText(Lt,fT,"X CLOSE",clX+clW/2,16)
if clHv and pr then Out=json.encode({"theme_close"}) end
-- Title
setNextTextAlign(Lx,AlignH_Center,AlignV_Middle) addText(Lx,fB,"COLOR THEME SETTINGS",SW/2,16)
-- Profile name
setNextFillColor(Lt,Txr*0.6,Txg*0.6,Txb*0.6,1) setNextTextAlign(Lt,AlignH_Right,AlignV_Middle)
addText(Lt,fS,"Profile: "..ProfName,SW-8,16)
addLine(Ll,0,32,SW,32)

-- ═══ LAYOUT REGIONS ═══
local elX,elW=0,170           -- element list
local huX,huW=170,40          -- hue bar
local svX,svW=214,256         -- SV grid (16x16)
local svH=256
local vpX=svX+svW+8           -- values panel
local vpW=SW-vpX
local bodyY=36 local bodyH=SH-36-36
]]

  S[4]=[[
-- ═══ ELEMENT LIST ═══
setNextFillColor(Lp,PHr*0.8,PHg*0.8,PHb*0.8,0.5) addBox(Lp,elX,bodyY,elW,bodyH)
setNextTextAlign(Lx,AlignH_Center,AlignV_Middle) addText(Lx,fS,"ELEMENTS",elX+elW/2,bodyY+14)
addLine(Ll,elX,bodyY+28,elX+elW,bodyY+28)
for i=1,8 do
  local ey=bodyY+28+(i-1)*30
  local hv=(cx>=elX and cx<elX+elW and cy>=ey and cy<ey+30)
  local sel=(i==SelElem)
  if sel then
    setNextFillColor(Lp,Ar,Ag,Ab,0.20) setNextStrokeColor(Lp,Ar,Ag,Ab,0.6)
    setNextStrokeWidth(Lp,1) addBox(Lp,elX+2,ey,elW-4,28)
  elseif hv then
    setNextFillColor(Lp,1,1,1,0.06) addBox(Lp,elX+2,ey,elW-4,28)
  end
  -- Color swatch
  local sw=SWATCHES[i]
  setNextFillColor(Lc,sw[1],sw[2],sw[3],1)
  setNextStrokeColor(Lc,Txr*0.5,Txg*0.5,Txb*0.5,0.5) setNextStrokeWidth(Lc,1)
  addBoxRounded(Lc,elX+8,ey+5,18,18,3)
  -- Label
  local L=sel and Lh or Lt
  if sel then setNextFillColor(Lh,Ar,Ag,Ab,1) end
  setNextTextAlign(L,AlignH_Left,AlignV_Middle) addText(L,fT,LABELS[i],elX+32,ey+14)
  if hv and pr then Out=json.encode({"theme_sel_elem",i}) end
end
]]

  S[5]=[[
-- ═══ HUE BAR ═══
local hueY=bodyY+4 local hueH=bodyH-8
local hStep=hueH/36
for i=0,35 do
  local hh=i*10
  local hr,hg,hb=h2r(hh,1,1)
  setNextFillColor(Lc,hr,hg,hb,1) addBox(Lc,huX+4,hueY+i*hStep,huW-8,hStep+1)
  if math.abs(hh-CurH)<5 or (CurH>355 and hh==0) then
    setNextStrokeColor(Ll,1,1,1,1) setNextStrokeWidth(Ll,2)
    addBox(Ll,huX+2,hueY+i*hStep,huW-4,hStep)
  end
end
-- Hue click
if pr and cx>=huX and cx<huX+huW and cy>=hueY and cy<hueY+hueH then
  local h=((cy-hueY)/hueH)*360
  Out=json.encode({"theme_set_hue",h})
end

-- ═══ SV GRID ═══
local svY=bodyY+4
local cellW=svW/16 local cellH=svH/16
for sy=0,15 do
  for sx=0,15 do
    local s=sx/15 local v=1-sy/15
    local gr,gg,gb=h2r(CurH,s,v)
    setNextFillColor(Lc,gr,gg,gb,1) addBox(Lc,svX+sx*cellW,svY+sy*cellH,cellW+0.5,cellH+0.5)
  end
end
-- Crosshair on current S,V
local chx=svX+CurS*15*cellW+cellW/2
local chy=svY+(1-CurV)*15*cellH+cellH/2
setNextStrokeColor(Ll,1,1,1,0.9) setNextStrokeWidth(Ll,1)
addLine(Ll,chx-8,chy,chx+8,chy) addLine(Ll,chx,chy-8,chx,chy+8)
setNextStrokeColor(Ll,0,0,0,0.6) setNextStrokeWidth(Ll,1)
addLine(Ll,chx-7,chy-1,chx+7,chy-1) addLine(Ll,chx-1,chy-7,chx-1,chy+7)
-- SV click
if pr and cx>=svX and cx<svX+svW and cy>=svY and cy<svY+svH then
  local ns=(cx-svX)/svW local nv=1-(cy-svY)/svH
  Out=json.encode({"theme_set_sv",ns,nv})
end
]]

  local vpX = 214 + 256 + 8  -- svX + svW + 8 (must match render-script layout in S[3])

  S[6]=string.format([[
-- ═══ VALUES & PREVIEW ═══
local valY=bodyY+8
-- Preview swatch (split: saved | current)
local pvW=vpW-16 local pvH=60 local pvHalf=math.floor(pvW/2)
local sw0=SAVED_SWATCHES[SelElem]
-- Saved color (left half)
setNextFillColor(Lc,sw0[1],sw0[2],sw0[3],1) addBox(Lc,vpX+8,valY,pvHalf,pvH)
-- Current color (right half)
setNextFillColor(Lc,CurR,CurG,CurB,1) addBox(Lc,vpX+8+pvHalf,valY,pvW-pvHalf,pvH)
-- Rounded border on top layer (transparent fill so colors show through)
setNextFillColor(Lt,0,0,0,0) setNextStrokeColor(Lt,Txr*0.5,Txg*0.5,Txb*0.5,0.6) setNextStrokeWidth(Lt,1)
addBoxRounded(Lt,vpX+8,valY,pvW,pvH,6)
-- Divider line
addLine(Ll,vpX+8+pvHalf,valY+4,vpX+8+pvHalf,valY+pvH-4)
-- Saved side labels
local sv=sw0[1]+sw0[2]+sw0[3]
local scx=vpX+8+pvHalf/2
if sv>1.5 then setNextFillColor(Lt,0,0,0,0.75) else setNextFillColor(Lt,1,1,1,0.75) end
setNextTextAlign(Lt,AlignH_Center,AlignV_Middle) addText(Lt,fS,"SAVED",scx,valY+18)
if sv>1.5 then setNextFillColor(Lt,0,0,0,0.55) else setNextFillColor(Lt,1,1,1,0.55) end
setNextTextAlign(Lt,AlignH_Center,AlignV_Middle) addText(Lt,fS,string.format("#%%02X%%02X%%02X",math.floor(sw0[1]*255+0.5),math.floor(sw0[2]*255+0.5),math.floor(sw0[3]*255+0.5)),scx,valY+38)
-- Current side labels
local pv=CurR+CurG+CurB
local ccx=vpX+8+pvHalf+(pvW-pvHalf)/2
if pv>1.5 then setNextFillColor(Lt,0,0,0,0.9) else setNextFillColor(Lt,1,1,1,0.9) end
setNextTextAlign(Lt,AlignH_Center,AlignV_Middle) addText(Lt,fT,LABELS[SelElem],ccx,valY+18)
if pv>1.5 then setNextFillColor(Lt,0,0,0,0.6) else setNextFillColor(Lt,1,1,1,0.6) end
setNextTextAlign(Lt,AlignH_Center,AlignV_Middle) addText(Lt,fS,string.format("#%%02X%%02X%%02X",math.floor(CurR*255+0.5),math.floor(CurG*255+0.5),math.floor(CurB*255+0.5)),ccx,valY+38)
valY=valY+70
-- RGB values
setNextFillColor(Lt,Txr*0.6,Txg*0.6,Txb*0.6,1) setNextTextAlign(Lt,AlignH_Left,AlignV_Top)
addText(Lt,fS,"RGB",vpX+8,valY)
setNextTextAlign(Lt,AlignH_Left,AlignV_Top)
addText(Lt,fT,string.format("R: %%d   G: %%d   B: %%d",math.floor(CurR*255+0.5),math.floor(CurG*255+0.5),math.floor(CurB*255+0.5)),vpX+8,valY+14)
valY=valY+38
-- HSV values
setNextFillColor(Lt,Txr*0.6,Txg*0.6,Txb*0.6,1) setNextTextAlign(Lt,AlignH_Left,AlignV_Top)
addText(Lt,fS,"HSV",vpX+8,valY)
setNextTextAlign(Lt,AlignH_Left,AlignV_Top)
addText(Lt,fT,string.format("H: %%d°   S: %%d%%%%   V: %%d%%%%",math.floor(CurH+0.5),math.floor(CurS*100+0.5),math.floor(CurV*100+0.5)),vpX+8,valY+14)
valY=valY+38
-- Hex value
setNextFillColor(Lt,Txr*0.6,Txg*0.6,Txb*0.6,1) setNextTextAlign(Lt,AlignH_Left,AlignV_Top)
addText(Lt,fS,"HEX",vpX+8,valY)
setNextTextAlign(Lt,AlignH_Left,AlignV_Top)
addText(Lt,fT,string.format("#%%02X%%02X%%02X",math.floor(CurR*255+0.5),math.floor(CurG*255+0.5),math.floor(CurB*255+0.5)),vpX+8,valY+14)
valY=valY+42
-- Hint
setNextFillColor(Lt,Txr*0.4,Txg*0.4,Txb*0.4,1) setNextTextAlign(Lt,AlignH_Left,AlignV_Top)
addText(Lt,fS,"Chat: theme ELEMENT #HEX",vpX+8,valY)
setNextFillColor(Lt,Txr*0.4,Txg*0.4,Txb*0.4,1) setNextTextAlign(Lt,AlignH_Left,AlignV_Top)
addText(Lt,fS,"Chat: theme ELEMENT R G B",vpX+8,valY+14)
]], vpX, vpX)

  S[7]=[[
-- ═══ PROFILE BAR (footer) ═══
addLine(Ll,0,SH-36,SW,SH-36)
setNextFillColor(Lp,FTr,FTg,FTb,0.95) addBox(Lp,0,SH-36,SW,36)
local px=8 local py=SH-30 local pH=22 local pG=4
-- Profile name buttons (scrollable)
for i,pn in ipairs(PROFILES) do
  local tw=math.min(100,math.max(50,#pn*8+16))
  if px+tw>SW-280 then break end
  local hv=(cx>=px and cx<px+tw and cy>=py and cy<py+pH)
  local active=(pn==ProfName)
  if active then
    setNextFillColor(Lb,Ar*0.3,Ag*0.3,Ab*0.3,0.9) setNextStrokeColor(Lb,Ar,Ag,Ab,0.9)
  elseif hv then
    setNextFillColor(Lb,BHfr,BHfg,BHfb,0.7) setNextStrokeColor(Lb,BHsr,BHsg,BHsb,0.7)
  else
    setNextFillColor(Lb,BNfr,BNfg,BNfb,0.5) setNextStrokeColor(Lb,BNsr,BNsg,BNsb,0.5)
  end
  setNextStrokeWidth(Lb,1) addBoxRounded(Lb,px,py,tw,pH,3)
  setNextTextAlign(Lt,AlignH_Center,AlignV_Middle) addText(Lt,fS,pn,px+tw/2,py+pH/2)
  if hv and pr then Out=json.encode({"theme_load",pn}) end
  px=px+tw+pG
end
-- Action buttons
local abX=SW-270
if Btn("+ New",abX,py,55,pH,true) then Out=json.encode({"theme_new"}) end abX=abX+59
if Btn("Save",abX,py,50,pH,true) then Out=json.encode({"theme_save"}) end abX=abX+54
if Btn("Delete",abX,py,55,pH,#PROFILES>1) then Out=json.encode({"theme_delete"}) end abX=abX+59
if Btn("Reset",abX,py,50,pH,true) then Out=json.encode({"theme_reset"}) end
setOutput(Out) requestAnimationFrame(5)
]]
  return table.concat(S)
end

-- ── Init ──────────────────────────────────────────────────────
local ok,res=pcall(require,"autoconf/custom/"..CustomAtlas)
if ok then Atlas=res; system.print("[NAV] Loaded custom atlas: "..CustomAtlas)
else
  local ok2,res2=pcall(require,"atlas")
  if ok2 then Atlas=res2; system.print("[NAV] Loaded default atlas")
  else system.print("[NAV] WARNING: No atlas loaded — planet distances unavailable") end
end
LoadData()
ThemeSlots=LoadTheme()
Palette=DeriveTheme(ThemeSlots)
CurrentPos=GetCurrentPos()
if screen then screen.activate() end
UpdateChannels()
if archbank then system.print("[NAV] archbank=OK") end
unit.setTimer("nav_tick",1)
unit.setTimer("screen_poll",0.05)
UpdateWaypoint()
system.print("=== Navigator "..VERSION.." ===  "..ShipID)
DrawScreen()


--[[@
slot=-1
event=onStop()
args=
]]
if NavTarget and NavTarget.c then system.setWaypoint("") end
if screen then
  local P=Palette
  screen.setRenderScript(string.format([[
local Lbg=createLayer() local Lt=createLayer() local Lf=createLayer()
local SW,SH=getResolution()
setNextFillColor(Lbg,%f,%f,%f,1) addBox(Lbg,0,0,SW,SH)
local fB=loadFont("Montserrat-Light",28) local fS=loadFont("Montserrat-Light",15)
setDefaultFillColor(Lt,Shape_Text,%f,%f,%f,1)
setDefaultFillColor(Lf,Shape_Text,%f,%f,%f,0.45)
setNextTextAlign(Lt,AlignH_Center,AlignV_Middle) addText(Lt,fB,"◄ NAVIGATOR ►",SW/2,SH/2-18)
setNextTextAlign(Lf,AlignH_Center,AlignV_Middle) addText(Lf,fS,"Offline  —  activate PB to start",SW/2,SH/2+16)
]],P.bgr,P.bgg,P.bgb,  P.ar,P.ag,P.ab,  P.nr,P.ng,P.nb))
end


--[[@
slot=-1
event=onTimer(tag)
args="nav_tick"
]]
CurrentPos=GetCurrentPos()
if StatusMsg~="" and system.getArkTime()>StatusExpiry then StatusMsg="" end
UpdateWaypoint()
DrawScreen()


--[[@
slot=-1
event=onTimer(tag)
args="screen_poll"
]]
if not screen then return end
local raw=screen.getScriptOutput()
if not raw or raw=="" then return end
local ok,d=pcall(json.decode,raw)
if not ok or type(d)~="table" then return end
local act=d[1]
local isScroll=(act=="scrollwp" or act=="scrollrt")
if not isScroll then
  if raw==LastScreenOut then return end
  LastScreenOut=raw
end
if     act=="scrollwp"  then ScrollWP=math.max(0,ScrollWP+(d[2] or 1))
elseif act=="scrollrt"  then ScrollRT=math.max(0,ScrollRT+(d[2] or 1))
elseif act=="tab"       then ActiveTab=d[2]; SelWP=""; SelRoute=""; SelStop=0; ScrollWP=0; ScrollRT=0
elseif act=="selwp"     then SelWP=(SelWP==d[2] and "" or d[2]); SelRoute=""; SelStop=0
elseif act=="selrt"     then
  if SelRoute==d[2] then SelStop=(SelStop==0 and 1 or 0)
  else SelRoute=d[2]; SelStop=0; SelWP="" end
elseif act=="selstop"   then SelStop=(SelStop==d[2] and 0 or d[2])
elseif act=="nav_wp"    then SetNavWP(d[2],ActiveTab)
elseif act=="nav_rt"    then SetNavRoute(d[2],ActiveTab,1)
elseif act=="nav_atlas" then
  if Atlas then
    for _,sys in pairs(Atlas) do
      for _,body in pairs(sys) do
        local nm=type(body.name)=="table" and body.name[1] or body.name
        if nm==d[2] and body.center then
          local c=body.center
          local pos=string.format("::pos{0,0,%.4f,%.4f,%.4f}",c[1],c[2],c[3])
          NavTarget={t="wp",n=nm,c=pos}
          SaveData(); UpdateWaypoint(); SendAutopilot(pos)
          SetStatus("Navigating: "..nm)
        end
      end
    end
  end
elseif act=="next_stop" then NextStop()
elseif act=="prev_stop" then PrevStop()
elseif act=="clear_nav" then ClearWaypoint();SetStatus("Nav cleared")
elseif act=="mark_wp"   then MarkWP()
elseif act=="mark_stop" then MarkRouteStop()
elseif act=="sync"      then
  if d[2]=="base" then RequestSync(BaseChannel)
  else
    local ch=GetTabOrgChannel()
    if ch then RequestSync(ch) else SetStatus("No channel for this org — do First Sync first") end
  end
elseif act=="push"      then
  if d[2]=="base" then PushToChannel(BaseChannel,PersonalWPs,PersonalRoutes)
  else
    local org=OrgNames[ActiveTab]
    if org and OrgData[org] then PushToChannel(GetTabOrgChannel(),OrgData[org].wps,OrgData[org].routes)
    else SetStatus("No org tab selected") end
  end
elseif act=="firstsync_hint" then SetStatus("Type: firstsync CHANNEL  (channel shown on org sync PB screen)",10)
-- Theme picker actions
elseif act=="open_theme"  then
  ShowThemePicker=true
  local sn=GetActiveProfileName()
  if databank and databank.getStringValue("theme_p_"..sn)==""  then SaveTheme(sn,ThemeSlots) end
elseif act=="theme_close" then ShowThemePicker=false
elseif act=="theme_sel_elem" then PickerElem=d[2] or 1
elseif act=="theme_set_hue" then
  local h=d[2] or 0
  ThemeSlots[PickerElem].h=h; RefreshTheme()
elseif act=="theme_set_sv" then
  local s,v=d[2] or 0.5, d[3] or 0.5
  ThemeSlots[PickerElem].s=math.max(0,math.min(1,s))
  ThemeSlots[PickerElem].v=math.max(0,math.min(1,v))
  RefreshTheme()
elseif act=="theme_save" then
  SaveTheme(GetActiveProfileName(),ThemeSlots)
  SetStatus("Theme saved: "..GetActiveProfileName())
elseif act=="theme_load" then
  local name=d[2] or ""
  local raw=databank and databank.getStringValue("theme_p_"..name) or ""
  if raw~="" then
    local ok2,data=pcall(json.decode,raw)
    if ok2 and data and #data>=8 then
      ThemeSlots=data
      databank.setStringValue("theme_profile_active",name)
      RefreshTheme()
      SetStatus("Loaded: "..name)
    end
  else SetStatus("Profile not found: "..name) end
elseif act=="theme_new" then
  local names=GetThemeProfiles()
  local newName="Theme "..#names+1
  SaveTheme(newName,ThemeSlots)
  SetStatus("Created: "..newName.." (chat: theme rename NAME)")
elseif act=="theme_delete" then
  local name=GetActiveProfileName()
  DeleteTheme(name)
  ThemeSlots=LoadTheme(); RefreshTheme()
  SetStatus("Deleted: "..name)
elseif act=="theme_reset" then
  ThemeSlots=DefaultShipTheme(); RefreshTheme()
  SaveTheme(GetActiveProfileName(),ThemeSlots)
  SetStatus("Theme reset to defaults")
end
DrawScreen()


--[[@
slot=-1
event=onTimer(tag)
args="push_tick"
]]
if not PushSending then unit.setTimer("push_tick",0) return end
if PushQueueIdx>#PushQueue then
  PushSending=false; unit.setTimer("push_tick",0)
  SetStatus("Pushed "..#PushQueue.." items to "..PushQueueCh)
  DrawScreen(); return
end
local item=PushQueue[PushQueueIdx]
if item.type=="wp" then
  emitter.send(PushQueueCh,"<PushWP>"..json.encode(item.data):gsub('"',"@@@"))
elseif item.type=="route" then
  emitter.send(PushQueueCh,"<PushRoute>"..json.encode(item.data):gsub('"',"@@@"))
end
PushQueueIdx=PushQueueIdx+1



--[[@
slot=2
event=onReceived(channel,message)
args=*,*
]]
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
  local n=tonumber((message:gsub("<SyncCount>",""))) or 0
  SetStatus("Syncing "..n.." items from "..(isOrg and (SyncOrgName~="" and SyncOrgName or "org") or "base").."...")
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
  DrawScreen(); return
end
if message:find("<PushPending>",1,true) then
  SetStatus("Push queued for admin approval",6)
  DrawScreen(); return
end

if message:find("<SyncComplete>",1,true) then
  table.sort(PersonalWPs,    function(a,b) return a.n:lower()<b.n:lower() end)
  table.sort(PersonalRoutes, function(a,b) return a.n:lower()<b.n:lower() end)
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
  SaveData()
  SetStatus("Sync done: "..SyncReceived.." items")
end

-- Receive pushed WPs from other ships (base-to-ship) — not typical but supported
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
DrawScreen()


--[[@
slot=-4
event=onInputText(text)
args=*
]]
local t=Trim(text); local lo=t:lower()

if lo=="help" then
  system.print("═══════════════════════════════════════")
  system.print("  NAVIGATOR v2.0  CHAT COMMANDS")
  system.print("═══════════════════════════════════════")
  system.print("── Waypoints ─────────────────────────")
  system.print("add NAME           save current pos as WP")
  system.print("add NAME ::pos{..} save coords as WP")
  system.print("del                delete selected WP")
  system.print("rename NEWNAME     rename selected WP or route")
  system.print("setpos ::pos{..}   update selected WP coords")
  system.print("nav                navigate to selected WP")
  system.print("── Routes ────────────────────────────")
  system.print("newroute NAME      create empty route")
  system.print("addstop WPname     add WP to selected route")
  system.print("addstop ::pos{..}  add raw pos to selected route")
  system.print("delstop N          remove stop N from selected route")
  system.print("del                delete selected route")
  system.print("nav                start route from stop 1")
  system.print("next               advance to next stop")
  system.print("prev               go back to previous stop")
  system.print("── Sync / Push ───────────────────────")
  system.print("sync               sync personal from base")
  system.print("orgsync            sync org from org base (current tab)")
  system.print("firstsync CHANNEL  first-time org sync, e.g: firstsync NavOrg")
  system.print("push               push personal to base")
  system.print("orgpush            push org data to org base (current tab)")
  system.print("── Atlas ─────────────────────────────")
  system.print("search NAME        filter atlas by name")
  system.print("search             clear atlas filter")
  system.print("── List ──────────────────────────────")
  system.print("list               list all personal WPs")
  system.print("routes             list all personal routes")
  system.print("status             show current nav target")
  system.print("── Theme ─────────────────────────────")
  system.print("theme              show all theme colors")
  system.print("theme accent #HEX  set element by hex")
  system.print("theme accent R G B set element by RGB 0-255")
  system.print("theme save [NAME]  save current theme")
  system.print("theme load NAME    load a saved theme")
  system.print("theme profiles     list saved profiles")
  system.print("theme export       export as copyable string")
  system.print("theme import T:..  import from string")
  system.print("theme reset        restore defaults")
  return
end

-- add NAME [coords]
local addN,addC=t:match("^[Aa][Dd][Dd]%s+(.-)%s*(::pos%b{})")
if not addN then addN=t:match("^[Aa][Dd][Dd]%s+(.+)") end  -- no coords = use current pos
if addN then
  addN=Trim(addN)
  if addC and addC~="" then
    if ParsePos(addC) then TabAddWP(addN,addC,ActiveTab)
    else SetStatus("Bad coords. Use ::pos{0,0,x,y,z}") end
  else
    local p=GetCurrentPosStr()
    if p then TabAddWP(addN,p,ActiveTab) else SetStatus("No position — core connected?") end
  end
  DrawScreen(); return
end

-- newroute NAME
local nrN=t:match("^[Nn][Ee][Ww][Rr][Oo][Uu][Tt][Ee]%s+(.+)")
if nrN then TabAddRoute(Trim(nrN),ActiveTab); DrawScreen(); return end

-- addstop ARG (requires a route selected)
local asA=t:match("^[Aa][Dd][Dd][Ss][Tt][Oo][Pp]%s+(.*)")
if asA then
  asA=Trim(asA)
  if SelRoute=="" then SetStatus("Select a route first") else AddStop(SelRoute,asA,ActiveTab) end
  DrawScreen(); return
end

-- delstop N
local dsN=t:match("^[Dd][Ee][Ll][Ss][Tt][Oo][Pp]%s+(%d+)")
if dsN then
  if SelRoute=="" then SetStatus("Select a route first")
  else DelStop(SelRoute,tonumber(dsN),ActiveTab) end
  DrawScreen(); return
end

-- rename NEWNAME
local rnN=t:match("^[Rr][Ee][Nn][Aa][Mm][Ee]%s+(.+)")
if rnN then
  rnN=Trim(rnN)
  if SelWP~="" then TabRenameWP(SelWP,rnN,ActiveTab)
  elseif SelRoute~="" then TabRenameRoute(SelRoute,rnN,ActiveTab)
  else SetStatus("Select a WP or route first") end
  DrawScreen(); return
end

-- setpos ::pos{...}
local spC=t:match("^[Ss][Ee][Tt][Pp][Oo][Ss]%s+(.*)")
if spC then
  spC=Trim(spC)
  if not ParsePos(spC) then SetStatus("Bad coords. Use ::pos{0,0,x,y,z}") DrawScreen(); return end
  if SelWP~="" then
    TabAddWP(SelWP,spC,ActiveTab)  -- AddWP detects existing name → updates
  elseif SelRoute~="" and SelStop>0 then
    local routes=(ActiveTab==0) and PersonalRoutes or (OrgData[OrgNames[ActiveTab]] and OrgData[OrgNames[ActiveTab]].routes) or {}
    for _,r in ipairs(routes) do
      if r.n==SelRoute and r.pts[SelStop] then
        r.pts[SelStop].c=spC; SaveData(); SetStatus("Stop "..SelStop.." updated")
      end
    end
  else SetStatus("Select a WP or a stop first") end
  DrawScreen(); return
end

-- search NAME  (filter atlas)
local srQ=t:match("^[Ss][Ee][Aa][Rr][Cc][Hh]%s*(.*)")
if srQ~=nil then
  AtlasSearch=Trim(srQ)
  ScrollWP=0; SelWP=""
  if AtlasSearch=="" then SetStatus("Atlas filter cleared")
  else SetStatus("Atlas filter: "..AtlasSearch) end
  DrawScreen(); return
end

-- del
if lo=="del" then
  if SelWP~="" then TabDelWP(SelWP,ActiveTab); SelWP=""
  elseif SelRoute~="" then TabDelRoute(SelRoute,ActiveTab); SelRoute=""; SelStop=0
  else SetStatus("Select a WP or route first") end
  DrawScreen(); return
end

-- nav (navigate to selected item)
if lo=="nav" then
  if SelWP~="" then SetNavWP(SelWP,ActiveTab)
  elseif SelRoute~="" then SetNavRoute(SelRoute,ActiveTab,1)
  else SetStatus("Select a WP or route first") end
  DrawScreen(); return
end

if lo=="nav off" or lo=="nav clear" then
  ClearWaypoint(); SetStatus("Nav cleared"); DrawScreen(); return
end

if lo=="next" then NextStop(); DrawScreen(); return end
if lo=="prev" then PrevStop(); DrawScreen(); return end

local fsCh=t:match("^[Ff][Ii][Rr][Ss][Tt][Ss][Yy][Nn][Cc]%s+(.+)")
if fsCh then
  fsCh=Trim(fsCh)
  -- match against known org channels case-insensitively so "navorg" finds "NavOrg"
  local resolved=fsCh
  for _,org in ipairs(OrgNames) do
    local ch=(OrgData[org] and OrgData[org].channel) or ""
    if ch:lower()==fsCh:lower() then resolved=ch; break end
  end
  RequestSync(resolved); DrawScreen(); return
end
if lo=="firstsync" then SetStatus("Usage: firstsync CHANNEL  (channel shown on org sync PB screen)",8); DrawScreen(); return end
if lo=="sync"    then RequestSync(BaseChannel);                                DrawScreen(); return end
if lo=="orgsync" then
  local ch=GetTabOrgChannel()
  if ch then RequestSync(ch) else SetStatus("No org tab — use org menu to sync") end
  DrawScreen(); return
end
if lo=="push"    then PushToChannel(BaseChannel,PersonalWPs,PersonalRoutes);  DrawScreen(); return end
if lo=="orgpush" then
  local org=OrgNames[ActiveTab]
  if org and OrgData[org] then PushToChannel(GetTabOrgChannel(),OrgData[org].wps,OrgData[org].routes)
  else SetStatus("Switch to an org tab first") end
  DrawScreen(); return
end

if lo=="status" then
  if not NavTarget then system.print("[NAV] No target") return end
  local tp=ParsePos(NavTarget.c); local cp=GetCurrentPos(); local dist="---"
  if tp and cp then dist=FormatDist(CalcDist(cp,tp)) end
  system.print("[NAV] "..(NavTarget.t=="route" and "[ROUTE] " or "[WP] ")..NavTarget.n.."  |  "..dist)
  if NavTarget.t=="route" then system.print("[NAV] Stop "..NavTarget.stopIdx.."/"..NavTarget.stopTotal) end
  return
end

if lo=="list" then
  system.print("─── PERSONAL WPs ("..#PersonalWPs..") ───")
  for i,wp in ipairs(PersonalWPs) do system.print(i..".  "..wp.n.."  "..wp.c) end
  return
end

if lo=="routes" then
  system.print("─── PERSONAL ROUTES ("..#PersonalRoutes..") ───")
  for i,r in ipairs(PersonalRoutes) do
    system.print(i..".  "..r.n.."  ("..#r.pts.." stops)")
    for j,s in ipairs(r.pts) do system.print("    "..j..".  "..(s.label or s.c)) end
  end
  return
end

-- ── Theme commands ────────────────────────────────────────────
if lo:sub(1,5)=="theme" then
  local arg=Trim(t:sub(6))
  local argLo=arg:lower()

  if arg=="" then
    system.print("══��� THEME COLORS ════════════════════")
    for i=1,8 do
      local s=ThemeSlots[i]
      local r,g,b=HSV2RGB(s.h,s.s,s.v)
      system.print(string.format("  %-12s H:%3d S:%3d%% V:%3d%%  %s",
        THEME_SLOT_LABELS[i],math.floor(s.h+0.5),math.floor(s.s*100+0.5),
        math.floor(s.v*100+0.5),RGB2Hex(r,g,b)))
    end
    system.print("  Profile: "..GetActiveProfileName())
    system.print("  theme ELEMENT #HEX | R G B")
    system.print("  theme save/load/delete/profiles/export/import/reset/rename")
    DrawScreen(); return
  end

  -- theme save NAME
  local saveName=arg:match("^[Ss][Aa][Vv][Ee]%s+(.+)")
  if saveName then
    SaveTheme(Trim(saveName),ThemeSlots); RefreshTheme()
    SetStatus("Theme saved: "..Trim(saveName)); DrawScreen(); return
  end
  if argLo=="save" then
    SaveTheme(GetActiveProfileName(),ThemeSlots)
    SetStatus("Saved: "..GetActiveProfileName()); DrawScreen(); return
  end

  -- theme load NAME
  local loadName=arg:match("^[Ll][Oo][Aa][Dd]%s+(.+)")
  if loadName then
    loadName=Trim(loadName)
    local raw=databank and databank.getStringValue("theme_p_"..loadName) or ""
    if raw~="" then
      local ok3,data=pcall(json.decode,raw)
      if ok3 and data and #data>=8 then
        ThemeSlots=data; databank.setStringValue("theme_profile_active",loadName)
        RefreshTheme(); SetStatus("Loaded: "..loadName)
      else SetStatus("Invalid profile data") end
    else SetStatus("Profile not found: "..loadName) end
    DrawScreen(); return
  end

  -- theme delete NAME
  local delName=arg:match("^[Dd][Ee][Ll][Ee][Tt][Ee]%s+(.+)")
  if delName then
    DeleteTheme(Trim(delName)); ThemeSlots=LoadTheme(); RefreshTheme()
    SetStatus("Deleted: "..Trim(delName)); DrawScreen(); return
  end

  -- theme rename NAME
  local renName=arg:match("^[Rr][Ee][Nn][Aa][Mm][Ee]%s+(.+)")
  if renName then
    local oldName=GetActiveProfileName()
    local newName=Trim(renName)
    SaveTheme(newName,ThemeSlots)
    if oldName~=newName then DeleteTheme(oldName) end
    SetStatus("Renamed to: "..newName); DrawScreen(); return
  end

  -- theme profiles
  if argLo=="profiles" then
    local names=GetThemeProfiles()
    system.print("═══ THEME PROFILES ══════════════════")
    for i,n in ipairs(names) do
      local mark=(n==GetActiveProfileName()) and " ◄" or ""
      system.print("  "..i..". "..n..mark)
    end
    return
  end

  -- theme export NAME
  local expName=arg:match("^[Ee][Xx][Pp][Oo][Rr][Tt]%s*(.*)")
  if expName~=nil then
    local name=(expName~="" and Trim(expName)) or GetActiveProfileName()
    local str=ExportTheme(name,ThemeSlots)
    system.print(str)
    SetStatus("Exported — copy the line above"); DrawScreen(); return
  end

  -- theme import THEME:...
  if arg:sub(1,6)=="THEME:" then
    local iName,iSlots=ImportTheme(arg)
    if iName and iSlots then
      ThemeSlots=iSlots; SaveTheme(iName,iSlots); RefreshTheme()
      SetStatus("Imported: "..iName)
    else SetStatus("Invalid import string") end
    DrawScreen(); return
  end

  -- theme reset
  if argLo=="reset" then
    ThemeSlots=DefaultShipTheme(); RefreshTheme()
    SaveTheme(GetActiveProfileName(),ThemeSlots)
    SetStatus("Theme reset to defaults"); DrawScreen(); return
  end

  -- theme ELEMENT #HEX  or  theme ELEMENT R G B
  for i,name in ipairs(THEME_SLOT_NAMES) do
    if argLo:sub(1,#name)==name:lower() then
      local rest=Trim(arg:sub(#name+1))
      local hex=rest:match("^(#%x%x%x%x%x%x)$")
      if hex then
        local r,g,b=Hex2RGB(hex)
        if r then
          local h,s,v=RGB2HSV(r,g,b)
          ThemeSlots[i]={h=h,s=s,v=v}; RefreshTheme()
          SaveTheme(GetActiveProfileName(),ThemeSlots)
          SetStatus(THEME_SLOT_LABELS[i].." set to "..hex)
        else SetStatus("Invalid hex code") end
        DrawScreen(); return
      end
      local rv,gv,bv=rest:match("^(%d+)%s+(%d+)%s+(%d+)$")
      if rv then
        local r,g,b=tonumber(rv)/255,tonumber(gv)/255,tonumber(bv)/255
        r,g,b=math.min(1,math.max(0,r)),math.min(1,math.max(0,g)),math.min(1,math.max(0,b))
        local h,s,v=RGB2HSV(r,g,b)
        ThemeSlots[i]={h=h,s=s,v=v}; RefreshTheme()
        SaveTheme(GetActiveProfileName(),ThemeSlots)
        SetStatus(THEME_SLOT_LABELS[i].." set to "..RGB2Hex(r,g,b))
        DrawScreen(); return
      end
    end
  end

  SetStatus("Unknown theme command. Type: theme"); DrawScreen(); return
end

SetStatus("Unknown: '"..lo.."'  type help")
DrawScreen()
