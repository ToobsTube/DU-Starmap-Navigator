-- ================================================================
-- NAVIGATOR ORG BASE - ADMIN PB v2.0.0
-- Dual Universe Navigation System
--
-- SLOT CONNECTIONS (connect in this order):
--   Slot 0: screen     (Screen Unit)
--   Slot 1: databank   (SHARED databank — same one orgbase_sync uses)
--   Slot 2: receiver   (Receiver)
--   Slot 3: emitter    (Emitter)
--
-- RDMS: restrict "use element" to admins only.
-- This PB is the ONLY one that writes to the shared databank.
-- Org name is set here and read by the Sync PB automatically.
--
-- Ships push WPs/routes here; admin edits via screen + chat.
-- ================================================================

--[[@
slot=-5
event=onStart()
args=
]]
function Trim(s) return (s or ""):match("^%s*(.-)%s*$") end

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

function DefaultOrgTheme()
  return {
    {h=30, s=0.85,v=0.65},  -- accent (warm amber)
    {h=20, s=0.50,v=0.02},  -- background (dark brown)
    {h=0,  s=0,   v=0.82},  -- text
    {h=40, s=1.0, v=1.0},   -- header (orange-gold)
    {h=30, s=1.0, v=0.22},  -- btnNormal (dark brown buttons)
    {h=30, s=0.85,v=0.55},  -- btnHover (brighter brown hover)
    {h=30, s=0.85,v=0.55},  -- selected (warm selection)
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
  p.rtdr,p.rtdg,p.rtdb=HSV2RGB(slots[8].h,slots[8].s*0.6,slots[8].v*0.35)
  p.rtlr,p.rtlg,p.rtlb=HSV2RGB(slots[8].h,slots[8].s*0.5,math.min(slots[8].v*1.1,1))
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
  p.bdtr,p.bdtg,p.bdtb=0.28,0.28,0.38
  -- Dim text (number indices, inactive)
  p.dmr,p.dmg,p.dmb=p.txr*0.40,p.txg*0.40,p.txb*0.44
  p.nmr,p.nmg,p.nmb=p.txr*0.37,p.txg*0.43,p.txb*0.61
  p.lbr,p.lbg,p.lbb=p.txr*0.51,p.txg*0.51,p.txb*0.76
  p.tir,p.tig,p.tib=p.txr*0.67,p.txg*0.67,p.txb*0.85
  return p
end

function LoadTheme()
  if not databank then return DefaultOrgTheme() end
  local name=databank.getStringValue("orgtheme_profile_active")
  if name=="" then return DefaultOrgTheme() end
  local raw=databank.getStringValue("orgtheme_p_"..name)
  if raw=="" then return DefaultOrgTheme() end
  local ok,data=pcall(json.decode,raw)
  if not ok or not data then return DefaultOrgTheme() end
  if #data<8 then return DefaultOrgTheme() end
  for i=1,8 do
    if type(data[i])~="table" or not data[i].h then return DefaultOrgTheme() end
  end
  return data
end

function SaveTheme(name,slots)
  if not databank then return end
  name=name:gsub("[^%w%s_-]",""):sub(1,20)
  if name=="" then name="Default" end
  databank.setStringValue("orgtheme_p_"..name,json.encode(slots))
  databank.setStringValue("orgtheme_profile_active",name)
  local raw=databank.getStringValue("orgtheme_profile_names") or "[]"
  local ok,names=pcall(json.decode,raw)
  if not ok or type(names)~="table" then names={} end
  local found=false
  for _,n in ipairs(names) do if n==name then found=true;break end end
  if not found then table.insert(names,name) end
  databank.setStringValue("orgtheme_profile_names",json.encode(names))
end

function DeleteTheme(name)
  if not databank then return end
  databank.setStringValue("orgtheme_p_"..name,"")
  local raw=databank.getStringValue("orgtheme_profile_names") or "[]"
  local ok,names=pcall(json.decode,raw)
  if not ok then return end
  for i,n in ipairs(names) do if n==name then table.remove(names,i);break end end
  databank.setStringValue("orgtheme_profile_names",json.encode(names))
  if databank.getStringValue("orgtheme_profile_active")==name then
    databank.setStringValue("orgtheme_profile_active",names[1] or "")
  end
end

function GetThemeProfiles()
  if not databank then return {} end
  local raw=databank.getStringValue("orgtheme_profile_names") or "[]"
  local ok,names=pcall(json.decode,raw)
  if not ok then return {} end
  return names
end

function GetActiveProfileName()
  if not databank then return "Default" end
  local n=databank.getStringValue("orgtheme_profile_active")
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
function ParsePos(s)
  if not s or s=="" then return nil end
  local w,b,x,y,z=s:match("::pos{(%d+),(%d+),([-%.%d]+),([-%.%d]+),([-%.%d]+)}")
  if x then return {w=tonumber(w),b=tonumber(b),x=tonumber(x),y=tonumber(y),z=tonumber(z)} end
  return nil
end
function SetStatus(msg,dur)
  StatusMsg=msg; StatusExpiry=system.getArkTime()+(dur or 6)
  system.print("[ORG-ADMIN] "..msg)
end


--[[@
slot=-1
event=onStart()
args=
]]

local VERSION="v2.0.0"
OrgChannel  ="NavOrg"      --export: Set once — saved to databank and read by Sync PB
OrgName     ="MyOrg"       --export: Display name for this org (shown on sync PB screen)

WaypointList = {}
RouteList    = {}
SelWP        = ""
SelRoute     = ""
SelStop      = 0
ScrollWP     = 0
ScrollRT     = 0
StatusMsg    = ""; StatusExpiry=0
LastScreenOut= ""

function LoadData()
  if not databank then WaypointList={};RouteList={};return end
  local function jd(k) local v=databank.getStringValue(k); return (v and v~="") and json.decode(v) or nil end
  WaypointList = jd("waypoints")     or {}
  RouteList    = jd("routes")        or {}
  Whitelist    = jd("org_whitelist") or {}
  local ch=databank.getStringValue("org_channel")
  if ch and ch~="" then OrgChannel=ch end
  local nm=databank.getStringValue("org_name")
  if nm and nm~="" then OrgName=nm end
end

Whitelist    = {}  -- {[playerID]=displayName}
PendingWPs   = {}  -- [{data,from,pid}]
PendingRoutes= {}  -- [{data,from,pid}]
SelPending   = 0   -- index into combined pending list
ShowPending  = false

-- Theme state
ShowThemePicker = false
ThemeSlots      = nil
Palette         = nil
PickerElem      = 1
PickerProfileScroll = 0

function LoadPending()
  if not databank then PendingWPs={};PendingRoutes={};return end
  local function jd(k) local v=databank.getStringValue(k); return (v and v~="") and json.decode(v) or nil end
  PendingWPs    = jd("pending_wps")    or {}
  PendingRoutes = jd("pending_routes") or {}
end

function SavePending()
  if not databank then return end
  databank.setStringValue("pending_wps",    json.encode(PendingWPs))
  databank.setStringValue("pending_routes", json.encode(PendingRoutes))
end

function GetPendingList()
  local list={}
  for _,v in ipairs(PendingWPs)    do table.insert(list,{type="wp",   item=v}) end
  for _,v in ipairs(PendingRoutes) do table.insert(list,{type="route",item=v}) end
  return list
end

function SaveData()
  if not databank then return end
  databank.setStringValue("waypoints",     json.encode(WaypointList))
  databank.setStringValue("routes",        json.encode(RouteList))
  databank.setStringValue("org_channel",   OrgChannel)
  databank.setStringValue("org_name",      OrgName)
  databank.setStringValue("org_whitelist", json.encode(Whitelist))
end

-- ── WP management ────────────────────────────────────────────
function MergeWP(name,posStr)
  for _,wp in ipairs(WaypointList) do
    if wp.n:lower()==name:lower() then wp.c=posStr; SaveData(); return end
  end
  table.insert(WaypointList,{n=name,c=posStr})
  table.sort(WaypointList,function(a,b) return a.n:lower()<b.n:lower() end)
  SaveData()
end

function AddWP(name,posStr)
  MergeWP(name,posStr); SetStatus("Saved WP: "..name)
end

function DelWP(name)
  for i,wp in ipairs(WaypointList) do
    if wp.n:lower()==name:lower() then
      table.remove(WaypointList,i)
      if SelWP==name then SelWP="" end
      SaveData(); SetStatus("Deleted: "..name); return true
    end
  end
  SetStatus("WP not found: "..name); return false
end

function RenameWP(old,new_)
  for _,v in ipairs(WaypointList) do if v.n:lower()==new_:lower() then SetStatus("Name exists: "..new_) return end end
  for _,wp in ipairs(WaypointList) do
    if wp.n:lower()==old:lower() then
      wp.n=new_; if SelWP==old then SelWP=new_ end
      table.sort(WaypointList,function(a,b) return a.n:lower()<b.n:lower() end)
      SaveData(); SetStatus("Renamed: "..new_); return
    end
  end
  SetStatus("WP not found: "..old)
end

function SetWPCoords(name,posStr)
  for _,wp in ipairs(WaypointList) do
    if wp.n:lower()==name:lower() then wp.c=posStr; SaveData(); SetStatus("Coords updated: "..name); return end
  end
  SetStatus("WP not found: "..name)
end

-- ── Route management ─────────────────────────────────────────
function MergeRoute(r)
  for i,e in ipairs(RouteList) do
    if e.n:lower()==r.n:lower() then RouteList[i]=r; SaveData(); return end
  end
  table.insert(RouteList,r)
  table.sort(RouteList,function(a,b) return a.n:lower()<b.n:lower() end)
  SaveData()
end

function AddRoute(name)
  for _,r in ipairs(RouteList) do if r.n:lower()==name:lower() then SetStatus("Exists: "..name) return false end end
  table.insert(RouteList,{n=name,pts={}})
  table.sort(RouteList,function(a,b) return a.n:lower()<b.n:lower() end)
  SaveData(); SetStatus("Route created: "..name); return true
end

function DelRoute(name)
  for i,r in ipairs(RouteList) do
    if r.n:lower()==name:lower() then
      table.remove(RouteList,i)
      if SelRoute==name then SelRoute="";SelStop=0 end
      SaveData(); SetStatus("Route deleted: "..name); return true
    end
  end
  SetStatus("Not found: "..name); return false
end

function RenameRoute(old,new_)
  for _,v in ipairs(RouteList) do if v.n:lower()==new_:lower() then SetStatus("Name exists: "..new_) return end end
  for _,r in ipairs(RouteList) do
    if r.n:lower()==old:lower() then
      r.n=new_; if SelRoute==old then SelRoute=new_ end
      table.sort(RouteList,function(a,b) return a.n:lower()<b.n:lower() end)
      SaveData(); SetStatus("Renamed: "..new_); return
    end
  end
  SetStatus("Not found: "..old)
end

function AddStop(routeName,arg)
  for _,r in ipairs(RouteList) do
    if r.n:lower()==routeName:lower() then
      local c,lbl=arg,arg
      if not ParsePos(arg) then
        local found=false
        for _,wp in ipairs(WaypointList) do
          if wp.n:lower()==arg:lower() then c=wp.c;lbl=wp.n;found=true;break end
        end
        if not found then SetStatus("Not a WP name or ::pos{}") return end
      end
      table.insert(r.pts,{c=c,label=lbl})
      SaveData(); SetStatus("Stop added ("..#r.pts..")"); return
    end
  end
  SetStatus("Route not found: "..routeName)
end

function DelStop(routeName,idx)
  for _,r in ipairs(RouteList) do
    if r.n:lower()==routeName:lower() then
      if idx<1 or idx>#r.pts then SetStatus("Index out of range") return end
      table.remove(r.pts,idx)
      if SelStop==idx then SelStop=math.max(0,idx-1) end
      SaveData(); SetStatus("Stop "..idx.." removed"); return
    end
  end
end

-- ── Screen ───────────────────────────────────────────────────
function RefreshTheme()
  Palette=DeriveTheme(ThemeSlots)
end

function DrawScreen()
  if not screen then return end
  local builder=ShowThemePicker and BuildPickerScript or BuildScreenScript
  local ok,result=pcall(builder)
  if not ok then system.print("[ORG-ADMIN] render error: "..tostring(result)); return end
  screen.setRenderScript(result)
end

function BuildScreenScript()
  local selRoutePts={}
  if SelRoute~="" then
    for _,r in ipairs(RouteList) do if r.n==SelRoute then selRoutePts=r.pts;break end end
  end
  LoadPending()
  local pendingList=GetPendingList()

  -- Build Lua table literals — no dkjson needed in render script
  local function luaWPList(list)
    local t={}
    for _,v in ipairs(list) do table.insert(t,string.format("{n=%q,c=%q}",v.n,v.c)) end
    return "{"..table.concat(t,",").."}"
  end
  local function luaStopList(list)
    local t={}
    for _,p in ipairs(list) do
      table.insert(t,string.format("{c=%q,label=%q}",p.c,p.label or p.c:sub(1,24)))
    end
    return "{"..table.concat(t,",").."}"
  end
  local function luaRouteList(list)
    local t={}
    for _,r in ipairs(list) do
      local dummy={}
      for i=1,#(r.pts or {}) do dummy[i]="{}" end
      table.insert(t,string.format("{n=%q,pts={%s}}",r.n,table.concat(dummy,",")))
    end
    return "{"..table.concat(t,",").."}"
  end
  local function luaPendingList(list)
    local t={}
    for _,e in ipairs(list) do
      local it=e.item or {}
      local d=it.data or {}
      local label=it.pname and it.pname~="" and it.pname or (it.from or "?")
      table.insert(t,string.format("{type=%q,n=%q,from=%q}",e.type,d.n or "?",label))
    end
    return "{"..table.concat(t,",").."}"
  end

  local wpLit  = luaWPList(WaypointList)
  local rtLit  = luaRouteList(RouteList)
  local ptLit  = luaStopList(selRoutePts)
  local pdLit  = luaPendingList(pendingList)

  local S={}
  local P=Palette

  S[1]=string.format([[
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
local SelPending=%d local ShowPending=%s
local StatusMsg=%q local OrgName=%q local OrgChannel=%q
local WP=%s
local RT=%s
local STOPS=%s
local PENDING=%s
local function ENC(t) local s="[" for i,v in ipairs(t) do if i>1 then s=s.."," end if type(v)=="string" then s=s..'"'..v..'"' else s=s..tostring(v) end end return s.."]" end
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
    SelPending,tostring(ShowPending),
    StatusMsg,OrgName,OrgChannel,wpLit,rtLit,ptLit,pdLit)

  S[2]=[[
local Lbg=createLayer() local Lp=createLayer() local Ll=createLayer()
local Lb=createLayer() local Ls=createLayer() local Lt=createLayer()
local Lh=createLayer() local Lx=createLayer() local Lst=createLayer()
local cx,cy=getCursor() local pr=getCursorReleased() local Out=""
local fT=loadFont("Montserrat-Light",18) local fS=loadFont("Montserrat-Light",13)
local fH=loadFont("Montserrat-Light",20) local fB=loadFont("Montserrat-Light",22)
setDefaultFillColor(Lt,Shape_Text,Txr,Txg,Txb,1)
setDefaultFillColor(Lh,Shape_Text,Ar,Ag,Ab,1)
setDefaultFillColor(Ls,Shape_Text,Nr,Ng,Nb,1)
setDefaultFillColor(Lx,Shape_Text,Hdr,Hdg,Hdb,1)
setDefaultFillColor(Lst,Shape_Text,Str,Stg,Stb,1)
setDefaultStrokeColor(Ll,Shape_Line,Lnr,Lng,Lnb,0.6)
setDefaultStrokeWidth(Ll,Shape_Line,1)
setNextFillColor(Lbg,Bgr,Bgg,Bgb,1) addBox(Lbg,0,0,SW,SH)
local wpX,wpW=0,400 local rtX,rtW=400,300 local actX,actW=700,324
local CON_Y=32 local vis=math.floor((SH-64)/C)-1
local function PH(x,w,r,g,b)
  setNextFillColor(Lp,r,g,b,0.88) addBox(Lp,x,CON_Y,w,C)
end
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
setNextStrokeWidth(Lp,2) addBox(Lp,0,0,SW,C)
setNextTextAlign(Lx,AlignH_Left,AlignV_Middle) addText(Lx,fB,"◄ ORG BASE ADMIN ►  "..OrgName,8,C/2)
local pendingBadge=""
if #PENDING>0 then pendingBadge="  ⚠ "..#PENDING.." PENDING" end
setNextFillColor(Lt,DMr,DMg,DMb,1) setNextTextAlign(Lt,AlignH_Right,AlignV_Middle)
addText(Lt,fT,#WP.." WPs  |  "..#RT.." Routes  |  ch: "..OrgChannel..pendingBadge,SW-8,C/2)
if #PENDING>0 then
  setNextFillColor(Lst,Str,Stg,Stb,1) setNextTextAlign(Lst,AlignH_Right,AlignV_Middle)
  addText(Lst,fT,pendingBadge,SW-8,C/2)
end
addLine(Ll,0,C,SW,C)
addLine(Ll,wpX+wpW,CON_Y,wpX+wpW,SH-32) addLine(Ll,rtX+rtW,CON_Y,rtX+rtW,SH-32)
]]

  S[4]=[[
-- WAYPOINTS
PH(wpX,wpW,PHr,PHg,PHb)
setNextTextAlign(Lx,AlignH_Center,AlignV_Middle)
addText(Lx,fH,"WAYPOINTS ["..#WP.."]",wpX+wpW/2,CON_Y+C/2)
addLine(Ll,wpX,CON_Y+C,wpX+wpW,CON_Y+C)
local maxSW=math.max(0,#WP-vis) local sCW=math.max(0,math.min(ScrollWP,maxSW))
for i=1,vis do
  local idx=i+sCW if idx>#WP then break end
  local wp=WP[idx] local ry=CON_Y+C+(i-1)*C
  local sel=(wp.n==SelWP) local hv=(cx>=wpX and cx<wpX+wpW and cy>=ry and cy<ry+C)
  if sel then
    setNextFillColor(Lp,SLr,SLg,SLb,0.22) setNextStrokeColor(Lp,Ar,Ag,Ab,0.9)
    setNextStrokeWidth(Lp,1) addBox(Lp,wpX,ry,wpW,C)
  elseif hv then setNextFillColor(Lp,1,1,1,0.04) addBox(Lp,wpX,ry,wpW,C) end
  setNextFillColor(Lt,NMr,NMg,NMb,1) setNextTextAlign(Lt,AlignH_Right,AlignV_Middle)
  addText(Lt,fS,idx..".",wpX+26,ry+C/2)
  local L=(sel or hv) and Ls or Lt
  if sel then setNextFillColor(Ls,Nr,Ng,Nb,1) end
  setNextTextAlign(L,AlignH_Left,AlignV_Middle) addText(L,fT,wp.n,wpX+30,ry+C/2)
  setNextStrokeColor(Ll,Lnr,Lng,Lnb,0.18) addLine(Ll,wpX,ry+C,wpX+wpW,ry+C)
  if hv and pr then Out=ENC({"selwp",wp.n}) end
end
if #WP>vis then
  local sbX=wpX+wpW-10 local sbW=10 local sbY=CON_Y+C+2 local sbH=vis*C-4
  local tH=math.max(18,sbH*(vis/#WP)) local tY=sbY+(sbH-tH)*(sCW/math.max(1,maxSW))
  setNextFillColor(Ll,STr,STg,STb,0.5) addBox(Ll,sbX,sbY,sbW,sbH)
  setNextFillColor(Ll,SHr,SHg,SHb,0.8) addBox(Ll,sbX,tY,sbW,tH)
  if cx>=sbX and cx<sbX+sbW and cy>=sbY and cy<sbY+sbH and pr then
    Out=ENC({"scrollwp",cy<tY+tH/2 and -1 or 1})
  end
end
]]

  S[5]=[[
-- ROUTES / STOPS
if SelStop>0 and SelRT~="" then
  PH(rtX,rtW,PHr,PHg,PHb)
  setNextFillColor(Lh,Ar,Ag,Ab,1) setNextTextAlign(Lh,AlignH_Left,AlignV_Middle)
  addText(Lh,fH,"◄ "..SelRT,rtX+8,CON_Y+C/2)
  addLine(Ll,rtX,CON_Y+C,rtX+rtW,CON_Y+C)
  local maxSR=math.max(0,#STOPS-vis) local sCR=math.max(0,math.min(ScrollRT,maxSR))
  for i=1,vis do
    local idx=i+sCR if idx>#STOPS then break end
    local st=STOPS[idx] local ry=CON_Y+C+(i-1)*C
    local sel=(SelStop==idx) local hv=(cx>=rtX and cx<rtX+rtW and cy>=ry and cy<ry+C)
    if sel then
      setNextFillColor(Lp,SLr,SLg,SLb,0.22) setNextStrokeColor(Lp,Ar,Ag,Ab,0.9)
      setNextStrokeWidth(Lp,1) addBox(Lp,rtX,ry,rtW,C)
    elseif hv then setNextFillColor(Lp,1,1,1,0.04) addBox(Lp,rtX,ry,rtW,C) end
    setNextFillColor(Lt,NMr,NMg,NMb,1) setNextTextAlign(Lt,AlignH_Right,AlignV_Middle)
    addText(Lt,fS,idx..".",rtX+22,ry+C/2)
    local lbl=st.label or st.c:sub(1,24)
    local L=(sel or hv) and Ls or Lt
    if sel then setNextFillColor(Ls,Nr,Ng,Nb,1) end
    setNextTextAlign(L,AlignH_Left,AlignV_Middle) addText(L,fT,lbl,rtX+26,ry+C/2)
    setNextStrokeColor(Ll,Lnr,Lng,Lnb,0.18) addLine(Ll,rtX,ry+C,rtX+rtW,ry+C)
    if hv and pr then Out=ENC({"selstop",idx}) end
  end
else
  PH(rtX,rtW,Rtdr,Rtdg,Rtdb)
  setNextFillColor(Lh,Rtr,Rtg,Rtb,1) setNextTextAlign(Lh,AlignH_Center,AlignV_Middle)
  addText(Lh,fH,"ROUTES ["..#RT.."]",rtX+rtW/2,CON_Y+C/2)
  addLine(Ll,rtX,CON_Y+C,rtX+rtW,CON_Y+C)
  local maxSR=math.max(0,#RT-vis) local sCR=math.max(0,math.min(ScrollRT,maxSR))
  for i=1,vis do
    local idx=i+sCR if idx>#RT then break end
    local r=RT[idx] local ry=CON_Y+C+(i-1)*C
    local sel=(r.n==SelRT) local hv=(cx>=rtX and cx<rtX+rtW and cy>=ry and cy<ry+C)
    if sel then
      setNextFillColor(Lp,Rtdr,Rtdg,Rtdb,0.22) setNextStrokeColor(Lp,Rtr,Rtg,Rtb,0.9)
      setNextStrokeWidth(Lp,1) addBox(Lp,rtX,ry,rtW,C)
    elseif hv then setNextFillColor(Lp,1,1,1,0.04) addBox(Lp,rtX,ry,rtW,C) end
    local L=(sel or hv) and Ls or Lt
    if sel then setNextFillColor(Ls,Rtlr,Rtlg,Rtlb,1) end
    setNextTextAlign(L,AlignH_Left,AlignV_Middle) addText(L,fT,r.n,rtX+8,ry+C/2)
    local np=#(r.pts or {})
    setNextFillColor(Lt,Rtdr,Rtdg,Rtdb,1) setNextTextAlign(Lt,AlignH_Right,AlignV_Middle)
    addText(Lt,fS,np.."▶",rtX+rtW-6,ry+C/2)
    setNextStrokeColor(Ll,Lnr,Lng,Lnb,0.18) addLine(Ll,rtX,ry+C,rtX+rtW,ry+C)
    if hv and pr then Out=ENC({"selrt",r.n}) end
  end
end
]]

  S[6]=[[
-- ACTION PANEL
local pendingLabel="ORG ADMIN"..(#PENDING>0 and "  ⚠"..#PENDING or "")
if ShowPending then
  PH(actX,actW,PHr,PHg,PHb)
  setNextFillColor(Lst,Str,Stg,Stb,1) setNextTextAlign(Lst,AlignH_Center,AlignV_Middle)
  addText(Lst,fH,"PENDING ["..#PENDING.."]",actX+actW/2,CON_Y+C/2)
  addLine(Ll,actX,CON_Y+C,actX+actW,CON_Y+C)
  local bX=actX+6 local bW=actW-12 local bH=26 local bG=4
  local pvis=math.floor((SH-64-C-(bH+bG)*3)/C)
  for i=1,math.min(pvis,#PENDING) do
    local entry=PENDING[i]
    local ry=CON_Y+C+(i-1)*C
    local sel=(SelPending==i)
    local hv=(cx>=actX and cx<actX+actW and cy>=ry and cy<ry+C)
    if sel then
      setNextFillColor(Lp,SLr,SLg,SLb,0.4) setNextStrokeColor(Lp,Ar,Ag,Ab,0.9)
      setNextStrokeWidth(Lp,1) addBox(Lp,actX,ry,actW,C)
    elseif hv then setNextFillColor(Lp,1,1,1,0.04) addBox(Lp,actX,ry,actW,C) end
    local badge=entry.type=="wp" and "[WP]" or "[RT]"
    local name=entry.n or "?"
    local from=entry.from or "?"
    setNextFillColor(Lst,Str,Stg,Stb,1) setNextTextAlign(Lst,AlignH_Left,AlignV_Middle)
    addText(Lst,fS,badge,actX+6,ry+C/2)
    local L=sel and Ls or Lt
    setNextTextAlign(L,AlignH_Left,AlignV_Middle) addText(L,fT,name:sub(1,18),actX+46,ry+C/2)
    setNextFillColor(Lt,DMr,DMg,DMb,1) setNextTextAlign(Lt,AlignH_Right,AlignV_Middle)
    addText(Lt,fS,from:sub(1,20),actX+actW-6,ry+C/2)
    if hv and pr then Out=ENC({"selpending",i}) end
  end
  if #PENDING==0 then
    setNextFillColor(Lt,DMr,DMg,DMb,1) setNextTextAlign(Lt,AlignH_Center,AlignV_Middle)
    addText(Lt,fT,"No pending items",actX+actW/2,CON_Y+C*3)
  end
  local by=SH-32-(bH+bG)*3
  if Btn("✔ ACCEPT",   bX,by,bW/2-2,bH,SelPending>0) then Out=ENC({"approve",SelPending}) end
  if Btn("✕ REJECT",   bX+bW/2+2,by,(bW/2)-2,bH,SelPending>0) then Out=ENC({"reject",SelPending}) end by=by+bH+bG
  if Btn("✔ ACCEPT ALL",bX,by,bW/2-2,bH,#PENDING>0) then Out=ENC({"approveall"}) end
  if Btn("✕ REJECT ALL",bX+bW/2+2,by,(bW/2)-2,bH,#PENDING>0) then Out=ENC({"rejectall"}) end by=by+bH+bG
  if Btn("◄ BACK",     bX,by,bW,bH,true) then Out=ENC({"showpending",false}) end
else
  PH(actX,actW,PHr,PHg,PHb)
  setNextTextAlign(Lx,AlignH_Center,AlignV_Middle)
  addText(Lx,fH,pendingLabel,actX+actW/2,CON_Y+C/2)
  addLine(Ll,actX,CON_Y+C,actX+actW,CON_Y+C)
  local selInfo=""
  if SelWP~="" then selInfo="[WP] "..SelWP
  elseif SelRT~="" and SelStop>0 then selInfo="[STOP "..SelStop.."] "..SelRT
  elseif SelRT~="" then selInfo="[ROUTE] "..SelRT end
  if selInfo~="" then
    setNextFillColor(Ls,Nr,Ng,Nb,1) setNextTextAlign(Ls,AlignH_Left,AlignV_Top)
    addText(Ls,fS,"SELECTED:",actX+8,CON_Y+C+8)
    setNextFillColor(Ls,Nr,Ng,Nb,1) setNextTextAlign(Ls,AlignH_Left,AlignV_Top)
    addText(Ls,fT,selInfo,actX+8,CON_Y+C+22)
  end
  local bX=actX+6 local bW=actW-12 local bH=26 local bG=4
  local by=SH-32-(bH+bG)*9
  if Btn("★ ADD WP (chat: add NAME)",bX,by,bW,bH,true)            then Out=ENC({"hint_add"})            end by=by+bH+bG
  if Btn("✎ RENAME",                 bX,by,bW,bH,selInfo~="")     then Out=ENC({"hint_rename"})         end by=by+bH+bG
  if Btn("✎ SET COORDS",             bX,by,bW,bH,selInfo~="")     then Out=ENC({"hint_setpos"})         end by=by+bH+bG
  if Btn("+ NEW ROUTE",              bX,by,bW,bH,true)            then Out=ENC({"hint_newroute"})       end by=by+bH+bG
  if Btn("+ ADD STOP TO ROUTE",      bX,by,bW,bH,SelRT~="" and SelStop==0) then Out=ENC({"hint_addstop"}) end by=by+bH+bG
  if Btn("✕ DELETE SELECTED",        bX,by,bW,bH,selInfo~="")     then Out=ENC({"delete"})              end by=by+bH+bG
  if Btn("✕ CLEAR ALL WPs",          bX,by,bW,bH,#WP>0)           then Out=ENC({"clearwps"})            end by=by+bH+bG
  if Btn("✕ CLEAR ALL ROUTES",       bX,by,bW,bH,#RT>0)           then Out=ENC({"clearroutes"})         end by=by+bH+bG
  if Btn("⚠ REVIEW PENDING ["..#PENDING.."]",bX,by,bW,bH,true)   then Out=ENC({"showpending",true})    end
end
]]

  S[7]=[[
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
if thHv and pr then Out=ENC({"open_theme"}) end
-- Status / hint text
if StatusMsg~="" then
  setNextTextAlign(Lst,AlignH_Center,AlignV_Middle) addText(Lst,fT,StatusMsg,SW/2-40,SH-16)
else
  setNextFillColor(Lt,DMr,DMg,DMb,1) setNextTextAlign(Lt,AlignH_Center,AlignV_Middle)
  addText(Lt,fS,"ADMIN ONLY  |  chat: add / del / rename / setpos / newroute / addstop / help",SW/2-40,SH-16)
end
setOutput(Out) requestAnimationFrame(2)
]]
  return table.concat(S)
end

-- ── Color Picker Screen ─────────────────────────────────────
function BuildPickerScript()
  local P=Palette
  local slots=ThemeSlots
  local elem=PickerElem
  local cur=slots[elem]
  local cr,cg,cb=HSV2RGB(cur.h,cur.s,cur.v)
  local profName=GetActiveProfileName()
  local profNames=GetThemeProfiles()

  -- Build element color swatches as Lua table literal
  local swatches={}
  for i=1,8 do
    local r,g,b=HSV2RGB(slots[i].h,slots[i].s,slots[i].v)
    table.insert(swatches,string.format("{%.3f,%.3f,%.3f}",r,g,b))
  end
  local swLit="{"..table.concat(swatches,",").."}"

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
local PROFILES=%s
local function ENC(t) local s="[" for i,v in ipairs(t) do if i>1 then s=s.."," end if type(v)=="string" then s=s..'"'..v..'"' else s=s..tostring(v) end end return s.."]" end
]],
    P.bgr,P.bgg,P.bgb, P.txr,P.txg,P.txb, P.hdr,P.hdg,P.hdb,
    P.phdr,P.phdg,P.phdb, P.lnr,P.lng,P.lnb,
    P.bnfr,P.bnfg,P.bnfb, P.bnsr,P.bnsg,P.bnsb,
    P.bhfr,P.bhfg,P.bhfb, P.bhsr,P.bhsg,P.bhsb,
    P.bdfr,P.bdfg,P.bdfb, P.bdsr,P.bdsg,P.bdsb, P.bdtr,P.bdtg,P.bdtb,
    P.ftr,P.ftg,P.ftb,
    P.ar,P.ag,P.ab, P.nr,P.ng,P.nb,
    elem, cur.h,cur.s,cur.v, cr,cg,cb,
    profName, lblLit, swLit, pnLit)

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
-- HEADER
setNextFillColor(Lp,PHr,PHg,PHb,1) setNextStrokeColor(Lp,Lnr,Lng,Lnb,0.8)
setNextStrokeWidth(Lp,1) addBox(Lp,0,0,SW,32)
-- Close button
local clX,clW=4,70
local clHv=(cx>=clX and cx<clX+clW and cy>=4 and cy<28)
if clHv then setNextFillColor(Lb,0.6,0.15,0.1,0.9) else setNextFillColor(Lb,0.35,0.08,0.05,0.8) end
setNextStrokeColor(Lb,0.8,0.3,0.2,0.7) setNextStrokeWidth(Lb,1)
addBoxRounded(Lb,clX,4,clW,24,3)
setNextTextAlign(Lt,AlignH_Center,AlignV_Middle) addText(Lt,fT,"X CLOSE",clX+clW/2,16)
if clHv and pr then Out=ENC({"theme_close"}) end
-- Title
setNextTextAlign(Lx,AlignH_Center,AlignV_Middle) addText(Lx,fB,"COLOR THEME SETTINGS",SW/2,16)
-- Profile name
setNextFillColor(Lt,Txr*0.6,Txg*0.6,Txb*0.6,1) setNextTextAlign(Lt,AlignH_Right,AlignV_Middle)
addText(Lt,fS,"Profile: "..ProfName,SW-8,16)
addLine(Ll,0,32,SW,32)

-- LAYOUT REGIONS
local elX,elW=0,170           -- element list
local huX,huW=170,40          -- hue bar
local svX,svW=214,256         -- SV grid (16x16)
local svH=256
local vpX=svX+svW+8           -- values panel
local vpW=SW-vpX
local bodyY=36 local bodyH=SH-36-36
]]

  S[4]=[[
-- ELEMENT LIST
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
  if hv and pr then Out=ENC({"theme_sel_elem",i}) end
end
]]

  S[5]=[[
-- HUE BAR
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
  Out=ENC({"theme_set_hue",h})
end

-- SV GRID
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
  Out=ENC({"theme_set_sv",ns,nv})
end
]]

  S[6]=string.format([[
-- VALUES & PREVIEW
local valY=bodyY+8
-- Preview swatch (large)
setNextFillColor(Lc,CurR,CurG,CurB,1)
setNextStrokeColor(Lc,Txr*0.5,Txg*0.5,Txb*0.5,0.6) setNextStrokeWidth(Lc,1)
addBoxRounded(Lc,%d+8,valY,vpW-16,60,6)
setNextTextAlign(Lt,AlignH_Center,AlignV_Middle)
local pv=CurR+CurG+CurB -- brightness check for text visibility
if pv>1.5 then setNextFillColor(Lt,0,0,0,0.9) else setNextFillColor(Lt,1,1,1,0.9) end
addText(Lt,fH,LABELS[SelElem],%d+vpW/2,valY+30)
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
-- PROFILE BAR (footer)
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
  if hv and pr then Out=ENC({"theme_load",pn}) end
  px=px+tw+pG
end
-- Action buttons
local abX=SW-270
if Btn("+ New",abX,py,55,pH,true) then Out=ENC({"theme_new"}) end abX=abX+59
if Btn("Save",abX,py,50,pH,true) then Out=ENC({"theme_save"}) end abX=abX+54
if Btn("Delete",abX,py,55,pH,#PROFILES>1) then Out=ENC({"theme_delete"}) end abX=abX+59
if Btn("Reset",abX,py,50,pH,true) then Out=ENC({"theme_reset"}) end
setOutput(Out) requestAnimationFrame(5)
]]
  return table.concat(S)
end

-- ── Init ──────────────────────────────────────────────────────
LoadData()
SaveData()  -- persist --export values to databank immediately
ThemeSlots=LoadTheme()
Palette=DeriveTheme(ThemeSlots)
if screen   then screen.activate() end
if receiver then receiver.setChannelList({OrgChannel}) end
system.print("=== Org Admin "..VERSION.." ===  "..OrgName.."  ch:"..OrgChannel)
system.print("WPs:"..#WaypointList.."  Routes:"..#RouteList)
unit.setTimer("screen_poll",0.05)
DrawScreen()


--[[@
slot=-1
event=onStop()
args=
]]
if screen then screen.setCenteredText("Org Admin") end


--[[@
slot=-1
event=onTimer(tag)
args="screen_poll"
]]
if not screen then return end
local raw=screen.getScriptOutput()
if not raw or raw=="" or raw==LastScreenOut then return end
LastScreenOut=raw
local ok,d=pcall(json.decode,raw)
if not ok or type(d)~="table" then return end
local act=d[1]
if     act=="scrollwp"    then ScrollWP=math.max(0,ScrollWP+(d[2] or 1))
elseif act=="scrollrt"    then ScrollRT=math.max(0,ScrollRT+(d[2] or 1))
elseif act=="selwp"       then SelWP=(SelWP==d[2] and "" or d[2]); SelRoute=""; SelStop=0
elseif act=="selrt"       then
  if SelRoute==d[2] then SelStop=(SelStop==0 and 1 or 0)
  else SelRoute=d[2]; SelStop=0; SelWP="" end
elseif act=="selstop"     then SelStop=(SelStop==d[2] and 0 or d[2])
elseif act=="delete"      then
  if SelWP~="" then DelWP(SelWP); SelWP=""
  elseif SelRoute~="" and SelStop>0 then DelStop(SelRoute,SelStop); SelStop=0
  elseif SelRoute~="" then DelRoute(SelRoute); SelRoute=""; SelStop=0 end
elseif act=="clearwps"    then WaypointList={}; SelWP=""; SaveData(); SetStatus("WPs cleared")
elseif act=="clearroutes" then RouteList={}; SelRoute=""; SelStop=0; SaveData(); SetStatus("Routes cleared")
elseif act=="hint_add"    then SetStatus("Chat: add NAME ::pos{0,0,x,y,z}",8)
elseif act=="hint_rename" then SetStatus("Chat: rename NEWNAME",8)
elseif act=="hint_setpos" then SetStatus("Chat: setpos ::pos{0,0,x,y,z}",8)
elseif act=="hint_newroute" then SetStatus("Chat: newroute NAME",8)
elseif act=="hint_addstop"  then SetStatus("Chat: addstop WPname  or  addstop ::pos{...}",8)
elseif act=="showpending" then ShowPending=d[2]; SelPending=0
elseif act=="selpending"  then SelPending=(SelPending==d[2] and 0 or d[2])
elseif act=="approve" then
  LoadPending()
  local idx=d[2]
  local nwp=#PendingWPs
  if idx>=1 and idx<=nwp then
    local item=PendingWPs[idx]
    if item and item.data and item.data.n and item.data.c then
      MergeWP(item.data.n, item.data.c)
      SetStatus("Approved WP: "..item.data.n)
    end
    table.remove(PendingWPs, idx)
  elseif idx>=1 then
    local ri=idx-nwp
    if ri>=1 and ri<=#PendingRoutes then
      local item=PendingRoutes[ri]
      if item and item.data and item.data.n then
        MergeRoute(item.data)
        SetStatus("Approved route: "..item.data.n)
      end
      table.remove(PendingRoutes, ri)
    end
  end
  SelPending=0; SavePending()
elseif act=="reject" then
  LoadPending()
  local idx=d[2]
  local nwp=#PendingWPs
  local name="?"
  if idx>=1 and idx<=nwp then
    name=(PendingWPs[idx] and PendingWPs[idx].data and PendingWPs[idx].data.n) or "?"
    table.remove(PendingWPs, idx)
  elseif idx>=1 then
    local ri=idx-nwp
    if ri>=1 and ri<=#PendingRoutes then
      name=(PendingRoutes[ri] and PendingRoutes[ri].data and PendingRoutes[ri].data.n) or "?"
      table.remove(PendingRoutes, ri)
    end
  end
  SelPending=0; SavePending(); SetStatus("Rejected: "..name)
elseif act=="approveall" then
  LoadPending()
  local count=0
  for _,item in ipairs(PendingWPs) do
    if item.data and item.data.n and item.data.c then MergeWP(item.data.n, item.data.c); count=count+1 end
  end
  for _,item in ipairs(PendingRoutes) do
    if item.data and item.data.n then MergeRoute(item.data); count=count+1 end
  end
  PendingWPs={}; PendingRoutes={}; SelPending=0
  SavePending(); SetStatus("Approved all ("..count.." items)")
elseif act=="rejectall" then
  LoadPending()
  local count=#PendingWPs+#PendingRoutes
  PendingWPs={}; PendingRoutes={}; SelPending=0
  SavePending(); SetStatus("Rejected all ("..count.." items)")
-- Theme picker actions
elseif act=="open_theme"  then ShowThemePicker=true
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
  local raw2=databank and databank.getStringValue("orgtheme_p_"..name) or ""
  if raw2~="" then
    local ok2,data=pcall(json.decode,raw2)
    if ok2 and data and #data>=8 then
      ThemeSlots=data
      databank.setStringValue("orgtheme_profile_active",name)
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
  ThemeSlots=DefaultOrgTheme(); RefreshTheme()
  SaveTheme(GetActiveProfileName(),ThemeSlots)
  SetStatus("Theme reset to defaults")
end
DrawScreen()


--[[@
slot=2
event=onReceived(channel,message)
args=*,*
]]
-- Accept pushed WPs/routes from ships (admin decides to keep or discard via del)
if message:find("<PushWP>",1,true) then
  local raw=message:gsub("<PushWP>",""):gsub("@@@",'"')
  local ok,wp=pcall(json.decode,raw)
  if ok and wp and wp.n and wp.c then
    MergeWP(wp.n,wp.c); SetStatus("Received WP: "..wp.n); DrawScreen()
  end
end

if message:find("<PushRoute>",1,true) then
  local raw=message:gsub("<PushRoute>",""):gsub("@@@",'"')
  local ok,r=pcall(json.decode,raw)
  if ok and r and r.n then
    MergeRoute(r); SetStatus("Received route: "..r.n); DrawScreen()
  end
end


--[[@
slot=-4
event=onInputText(text)
args=*
]]
local t=Trim(text); local lo=t:lower()

if lo=="help" then
  system.print("══════════════════════════════════")
  system.print("  ORG ADMIN v2.0  CHAT COMMANDS")
  system.print("══════════════════════════════════")
  system.print("add NAME ::pos{..}  add/update WP")
  system.print("del                 delete selected item")
  system.print("rename NEWNAME      rename selected item")
  system.print("setpos ::pos{..}    update selected coords")
  system.print("newroute NAME       create empty route")
  system.print("addstop WPname      add stop to selected route")
  system.print("addstop ::pos{..}   add raw pos stop")
  system.print("delstop N           remove stop N")
  system.print("setorg NAME         set org display name")
  system.print("setch CHANNEL       set org channel")
  system.print("addmember ID NAME   add player to whitelist")
  system.print("removemember ID     remove player from whitelist")
  system.print("listmembers         show whitelist")
  system.print("list / routes       list data")
  system.print("── Theme ─────────────────────────")
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

local addN,addC=t:match("^[Aa][Dd][Dd]%s+(.-)%s*(::pos%b{})")
if not addN then addN=t:match("^[Aa][Dd][Dd]%s+(.+)") end
if addN then
  addN=Trim(addN); addC=addC and Trim(addC) or ""
  if ParsePos(addC) then AddWP(addN,addC)
  else SetStatus("Provide coords: add NAME ::pos{0,0,x,y,z}",8) end
  DrawScreen(); return
end

local nrN=t:match("^[Nn][Ee][Ww][Rr][Oo][Uu][Tt][Ee]%s+(.+)")
if nrN then AddRoute(Trim(nrN)); DrawScreen(); return end

local rnN=t:match("^[Rr][Ee][Nn][Aa][Mm][Ee]%s+(.+)")
if rnN then
  rnN=Trim(rnN)
  if SelWP~="" then RenameWP(SelWP,rnN)
  elseif SelRoute~="" then RenameRoute(SelRoute,rnN)
  else SetStatus("Select a WP or route first") end
  DrawScreen(); return
end

local spC=t:match("^[Ss][Ee][Tt][Pp][Oo][Ss]%s+(.*)")
if spC then
  spC=Trim(spC)
  if not ParsePos(spC) then SetStatus("Bad coords") DrawScreen(); return end
  if SelWP~="" then SetWPCoords(SelWP,spC)
  elseif SelRoute~="" and SelStop>0 then
    for _,r in ipairs(RouteList) do
      if r.n==SelRoute and r.pts[SelStop] then r.pts[SelStop].c=spC; SaveData(); SetStatus("Stop updated") end
    end
  else SetStatus("Select a WP or stop first") end
  DrawScreen(); return
end

local asA=t:match("^[Aa][Dd][Dd][Ss][Tt][Oo][Pp]%s+(.*)")
if asA then
  if SelRoute=="" then SetStatus("Select a route first")
  else AddStop(SelRoute,Trim(asA)) end
  DrawScreen(); return
end

local dsN=t:match("^[Dd][Ee][Ll][Ss][Tt][Oo][Pp]%s+(%d+)")
if dsN then
  if SelRoute=="" then SetStatus("Select a route first")
  else DelStop(SelRoute,tonumber(dsN)) end
  DrawScreen(); return
end

if lo=="del" then
  if SelWP~="" then DelWP(SelWP); SelWP=""
  elseif SelRoute~="" and SelStop>0 then DelStop(SelRoute,SelStop); SelStop=0
  elseif SelRoute~="" then DelRoute(SelRoute); SelRoute=""; SelStop=0
  else SetStatus("Select something first") end
  DrawScreen(); return
end

local soN=t:match("^[Ss][Ee][Tt][Oo][Rr][Gg]%s+(.+)")
if soN then OrgName=Trim(soN); SaveData(); SetStatus("Org name: "..OrgName); DrawScreen(); return end

local scC=t:match("^[Ss][Ee][Tt][Cc][Hh]%s+(.+)")
if scC then
  OrgChannel=Trim(scC); SaveData()
  if receiver then receiver.setChannelList({OrgChannel}) end
  SetStatus("Channel: "..OrgChannel); DrawScreen(); return
end

if lo=="list" then
  system.print("─── ORG WPs ["..OrgName.."] ("..#WaypointList..") ───")
  for i,wp in ipairs(WaypointList) do system.print(i..".  "..wp.n.."  "..wp.c) end
  return
end

if lo=="routes" then
  system.print("─── ORG ROUTES ["..OrgName.."] ("..#RouteList..") ───")
  for i,r in ipairs(RouteList) do
    system.print(i..".  "..r.n.."  ("..#r.pts.." stops)")
    for j,s in ipairs(r.pts) do system.print("    "..j..".  "..(s.label or s.c)) end
  end
  return
end

-- addmember PLAYERID NAME
local amID,amN=t:match("^[Aa][Dd][Dd][Mm][Ee][Mm][Bb][Ee][Rr]%s+(%d+)%s+(.*)")
if amID then
  amN=Trim(amN); if amN=="" then amN="Member" end
  Whitelist[amID]=amN; SaveData()
  SetStatus("Added: "..amN.." ("..amID..")"); DrawScreen(); return
end

-- removemember PLAYERID
local rmID=t:match("^[Rr][Ee][Mm][Oo][Vv][Ee][Mm][Ee][Mm][Bb][Ee][Rr]%s+(%d+)")
if rmID then
  local nm2=Whitelist[rmID] or rmID
  Whitelist[rmID]=nil; SaveData()
  SetStatus("Removed: "..nm2.." ("..rmID..")"); DrawScreen(); return
end

if lo=="listmembers" then
  local count=0
  system.print("─── WHITELIST ["..OrgName.."] ───")
  for pid,nm2 in pairs(Whitelist) do
    count=count+1; system.print(count..".  "..nm2.."  (pid:"..pid..")")
  end
  if count==0 then system.print("  (empty — use: addmember PLAYERID NAME)") end
  return
end

-- ── Theme commands ────────────────────────────────────────────
if lo:sub(1,5)=="theme" then
  local arg=Trim(t:sub(6))
  local argLo=arg:lower()

  if arg=="" then
    system.print("═══ THEME COLORS ════════════════════")
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
    local raw3=databank and databank.getStringValue("orgtheme_p_"..loadName) or ""
    if raw3~="" then
      local ok3,data=pcall(json.decode,raw3)
      if ok3 and data and #data>=8 then
        ThemeSlots=data; databank.setStringValue("orgtheme_profile_active",loadName)
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
    ThemeSlots=DefaultOrgTheme(); RefreshTheme()
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
          local h,s2,v=RGB2HSV(r,g,b)
          ThemeSlots[i]={h=h,s=s2,v=v}; RefreshTheme()
          SaveTheme(GetActiveProfileName(),ThemeSlots)
          SetStatus(THEME_SLOT_LABELS[i].." set to "..hex)
        else SetStatus("Invalid hex code") end
        DrawScreen(); return
      end
      local rv,gv,bv=rest:match("^(%d+)%s+(%d+)%s+(%d+)$")
      if rv then
        local r,g,b=tonumber(rv)/255,tonumber(gv)/255,tonumber(bv)/255
        r,g,b=math.min(1,math.max(0,r)),math.min(1,math.max(0,g)),math.min(1,math.max(0,b))
        local h,s2,v=RGB2HSV(r,g,b)
        ThemeSlots[i]={h=h,s=s2,v=v}; RefreshTheme()
        SaveTheme(GetActiveProfileName(),ThemeSlots)
        SetStatus(THEME_SLOT_LABELS[i].." set to "..RGB2Hex(r,g,b))
        DrawScreen(); return
      end
    end
  end

  SetStatus("Unknown theme command. Type: theme"); DrawScreen(); return
end

SetStatus("Unknown: '"..lo.."'  type help"); DrawScreen()
