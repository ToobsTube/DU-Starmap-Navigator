-- ================================================================
-- NAVIGATOR SHIP - NO SCREEN VERSION v2.0.0
-- Dual Universe Navigation System
--
-- SLOT CONNECTIONS (connect in this order):
--   Slot 0: databank   (Databank)
--   Slot 1: receiver   (Receiver)
--   Slot 2: emitter    (Emitter)
--   Slot 3: screen     (Screen Unit — OPTIONAL, for theme picker)
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
    -- triangle profile — asymmetric arms
    local Vp=math.sqrt(2*dist/(1/Aa+1/Ad))
    return Vp/Aa+Vp/Ad
  else
    local d_cruise=dist-d_accel-d_decel
    return V/Aa+V/Ad+d_cruise/V
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
  -- Dim text
  p.dmr,p.dmg,p.dmb=p.txr*0.40,p.txg*0.40,p.txb*0.44
  p.nmr,p.nmg,p.nmb=p.txr*0.37,p.txg*0.43,p.txb*0.61
  p.lbr,p.lbg,p.lbb=p.txr*0.51,p.txg*0.51,p.txb*0.76
  p.tir,p.tig,p.tib=p.txr*0.67,p.txg*0.67,p.txb*0.85
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
function BuildPickerScript()
  local P=Palette
  local slots=ThemeSlots
  local elem=PickerElem
  local cur=slots[elem]
  local cr,cg,cb=HSV2RGB(cur.h,cur.s,cur.v)
  local profName=GetActiveProfileName()
  local profNames=GetThemeProfiles()
  local swatches={}
  for i=1,8 do
    local r,g,b=HSV2RGB(slots[i].h,slots[i].s,slots[i].v)
    table.insert(swatches,string.format("{%.3f,%.3f,%.3f}",r,g,b))
  end
  local swLit="{"..table.concat(swatches,",").."}"
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
  local lblLit="{"
  for i,l in ipairs(THEME_SLOT_LABELS) do
    if i>1 then lblLit=lblLit.."," end
    lblLit=lblLit..'"'..l..'"'
  end
  lblLit=lblLit.."}"
  local pnLit="{"
  for i,n in ipairs(profNames) do
    if i>1 then pnLit=pnLit.."," end
    pnLit=pnLit..'"'..n..'"'
  end
  pnLit=pnLit.."}"
  local S={}
  local h1={}
  h1[#h1+1]="local json=require('dkjson')\nlocal SW,SH=getResolution()\nlocal cx,cy=getCursor() local pr=getCursorReleased() local Out=\"\"\n"
  h1[#h1+1]=string.format("local Bgr,Bgg,Bgb=%f,%f,%f\n",P.bgr,P.bgg,P.bgb)
  h1[#h1+1]=string.format("local Txr,Txg,Txb=%f,%f,%f\n",P.txr,P.txg,P.txb)
  h1[#h1+1]=string.format("local Hdr,Hdg,Hdb=%f,%f,%f\n",P.hdr,P.hdg,P.hdb)
  h1[#h1+1]=string.format("local PHr,PHg,PHb=%f,%f,%f\n",P.phdr,P.phdg,P.phdb)
  h1[#h1+1]=string.format("local Lnr,Lng,Lnb=%f,%f,%f\n",P.lnr,P.lng,P.lnb)
  h1[#h1+1]=string.format("local BNfr,BNfg,BNfb=%f,%f,%f local BNsr,BNsg,BNsb=%f,%f,%f\n",P.bnfr,P.bnfg,P.bnfb,P.bnsr,P.bnsg,P.bnsb)
  h1[#h1+1]=string.format("local BHfr,BHfg,BHfb=%f,%f,%f local BHsr,BHsg,BHsb=%f,%f,%f\n",P.bhfr,P.bhfg,P.bhfb,P.bhsr,P.bhsg,P.bhsb)
  h1[#h1+1]=string.format("local BDfr,BDfg,BDfb=%f,%f,%f local BDsr,BDsg,BDsb=%f,%f,%f local BDtr,BDtg,BDtb=%f,%f,%f\n",P.bdfr,P.bdfg,P.bdfb,P.bdsr,P.bdsg,P.bdsb,P.bdtr,P.bdtg,P.bdtb)
  h1[#h1+1]=string.format("local FTr,FTg,FTb=%f,%f,%f\n",P.ftr,P.ftg,P.ftb)
  h1[#h1+1]=string.format("local Ar,Ag,Ab=%f,%f,%f local Nr,Ng,Nb=%f,%f,%f\n",P.ar,P.ag,P.ab,P.nr,P.ng,P.nb)
  h1[#h1+1]=string.format("local SelElem=%d\n",elem)
  h1[#h1+1]=string.format("local CurH,CurS,CurV=%f,%f,%f\n",cur.h,cur.s,cur.v)
  h1[#h1+1]=string.format("local CurR,CurG,CurB=%f,%f,%f\n",cr,cg,cb)
  h1[#h1+1]="local ProfName=\""..profName.."\"\n"
  h1[#h1+1]="local LABELS="..lblLit.."\n"
  h1[#h1+1]="local SWATCHES="..swLit.."\n"
  h1[#h1+1]="local SAVED_SWATCHES="..savedSwLit.."\n"
  h1[#h1+1]="local PROFILES="..pnLit.."\n"
  S[1]=table.concat(h1)
  S[2]=[[
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
setNextFillColor(Lbg,Bgr,Bgg,Bgb,1) addBox(Lbg,0,0,SW,SH)
local function h2r(h,s,v)
  h=h%360 local c=v*s local x=c*(1-math.abs((h/60)%2-1)) local m=v-c
  local r,g,b
  if     h<60  then r,g,b=c,x,0 elseif h<120 then r,g,b=x,c,0
  elseif h<180 then r,g,b=0,c,x elseif h<240 then r,g,b=0,x,c
  elseif h<300 then r,g,b=x,0,c else r,g,b=c,0,x end
  return r+m,g+m,b+m
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
setNextFillColor(Lp,PHr,PHg,PHb,1) setNextStrokeColor(Lp,Lnr,Lng,Lnb,0.8)
setNextStrokeWidth(Lp,1) addBox(Lp,0,0,SW,32)
local clX,clW=4,70
local clHv=(cx>=clX and cx<clX+clW and cy>=4 and cy<28)
if clHv then setNextFillColor(Lb,0.6,0.15,0.1,0.9) else setNextFillColor(Lb,0.35,0.08,0.05,0.8) end
setNextStrokeColor(Lb,0.8,0.3,0.2,0.7) setNextStrokeWidth(Lb,1)
addBoxRounded(Lb,clX,4,clW,24,3)
setNextTextAlign(Lt,AlignH_Center,AlignV_Middle) addText(Lt,fT,"X CLOSE",clX+clW/2,16)
if clHv and pr then Out=json.encode({"theme_close"}) end
setNextTextAlign(Lx,AlignH_Center,AlignV_Middle) addText(Lx,fB,"COLOR THEME SETTINGS",SW/2,16)
setNextFillColor(Lt,Txr*0.6,Txg*0.6,Txb*0.6,1) setNextTextAlign(Lt,AlignH_Right,AlignV_Middle)
addText(Lt,fS,"Profile: "..ProfName,SW-8,16)
addLine(Ll,0,32,SW,32)
local elX,elW=0,170
local huX,huW=170,40
local svX,svW=214,256
local svH=256
local vpX=svX+svW+8
local vpW=SW-vpX
local bodyY=36 local bodyH=SH-36-36
]]
  S[4]=[[
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
  local sw=SWATCHES[i]
  setNextFillColor(Lc,sw[1],sw[2],sw[3],1)
  setNextStrokeColor(Lc,Txr*0.5,Txg*0.5,Txb*0.5,0.5) setNextStrokeWidth(Lc,1)
  addBoxRounded(Lc,elX+8,ey+5,18,18,3)
  local L=sel and Lh or Lt
  if sel then setNextFillColor(Lh,Ar,Ag,Ab,1) end
  setNextTextAlign(L,AlignH_Left,AlignV_Middle) addText(L,fT,LABELS[i],elX+32,ey+14)
  if hv and pr then Out=json.encode({"theme_sel_elem",i}) end
end
]]
  S[5]=[[
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
if pr and cx>=huX and cx<huX+huW and cy>=hueY and cy<hueY+hueH then
  local h=((cy-hueY)/hueH)*360
  Out=json.encode({"theme_set_hue",h})
end
local svY=bodyY+4
local cellW=svW/16 local cellH=svH/16
for sy=0,15 do
  for sx=0,15 do
    local s=sx/15 local v=1-sy/15
    local gr,gg,gb=h2r(CurH,s,v)
    setNextFillColor(Lc,gr,gg,gb,1) addBox(Lc,svX+sx*cellW,svY+sy*cellH,cellW+0.5,cellH+0.5)
  end
end
local chx=svX+CurS*15*cellW+cellW/2
local chy=svY+(1-CurV)*15*cellH+cellH/2
setNextStrokeColor(Ll,1,1,1,0.9) setNextStrokeWidth(Ll,1)
addLine(Ll,chx-8,chy,chx+8,chy) addLine(Ll,chx,chy-8,chx,chy+8)
setNextStrokeColor(Ll,0,0,0,0.6) setNextStrokeWidth(Ll,1)
addLine(Ll,chx-7,chy-1,chx+7,chy-1) addLine(Ll,chx-1,chy-7,chx-1,chy+7)
if pr and cx>=svX and cx<svX+svW and cy>=svY and cy<svY+svH then
  local ns=(cx-svX)/svW local nv=1-(cy-svY)/svH
  Out=json.encode({"theme_set_sv",ns,nv})
end
]]
  local vpX = 214 + 256 + 8
  S[6]=string.format([[
local valY=bodyY+8
-- Preview swatch (split: saved | current)
local pvW=vpW-16 local pvH=60 local pvHalf=math.floor(pvW/2)
local sw0=SAVED_SWATCHES[SelElem]
setNextFillColor(Lc,sw0[1],sw0[2],sw0[3],1) addBox(Lc,vpX+8,valY,pvHalf,pvH)
setNextFillColor(Lc,CurR,CurG,CurB,1) addBox(Lc,vpX+8+pvHalf,valY,pvW-pvHalf,pvH)
setNextFillColor(Lt,0,0,0,0) setNextStrokeColor(Lt,Txr*0.5,Txg*0.5,Txb*0.5,0.6) setNextStrokeWidth(Lt,1)
addBoxRounded(Lt,vpX+8,valY,pvW,pvH,6)
addLine(Ll,vpX+8+pvHalf,valY+4,vpX+8+pvHalf,valY+pvH-4)
local sv=sw0[1]+sw0[2]+sw0[3]
local scx=vpX+8+pvHalf/2
if sv>1.5 then setNextFillColor(Lt,0,0,0,0.75) else setNextFillColor(Lt,1,1,1,0.75) end
setNextTextAlign(Lt,AlignH_Center,AlignV_Middle) addText(Lt,fS,"SAVED",scx,valY+18)
if sv>1.5 then setNextFillColor(Lt,0,0,0,0.55) else setNextFillColor(Lt,1,1,1,0.55) end
setNextTextAlign(Lt,AlignH_Center,AlignV_Middle) addText(Lt,fS,string.format("#%%02X%%02X%%02X",math.floor(sw0[1]*255+0.5),math.floor(sw0[2]*255+0.5),math.floor(sw0[3]*255+0.5)),scx,valY+38)
local pv=CurR+CurG+CurB
local ccx=vpX+8+pvHalf+(pvW-pvHalf)/2
if pv>1.5 then setNextFillColor(Lt,0,0,0,0.9) else setNextFillColor(Lt,1,1,1,0.9) end
setNextTextAlign(Lt,AlignH_Center,AlignV_Middle) addText(Lt,fT,LABELS[SelElem],ccx,valY+18)
if pv>1.5 then setNextFillColor(Lt,0,0,0,0.6) else setNextFillColor(Lt,1,1,1,0.6) end
setNextTextAlign(Lt,AlignH_Center,AlignV_Middle) addText(Lt,fS,string.format("#%%02X%%02X%%02X",math.floor(CurR*255+0.5),math.floor(CurG*255+0.5),math.floor(CurB*255+0.5)),ccx,valY+38)
valY=valY+70
setNextFillColor(Lt,Txr*0.6,Txg*0.6,Txb*0.6,1) setNextTextAlign(Lt,AlignH_Left,AlignV_Top)
addText(Lt,fS,"RGB",vpX+8,valY)
setNextTextAlign(Lt,AlignH_Left,AlignV_Top)
addText(Lt,fT,string.format("R: %%d   G: %%d   B: %%d",math.floor(CurR*255+0.5),math.floor(CurG*255+0.5),math.floor(CurB*255+0.5)),vpX+8,valY+14)
valY=valY+38
setNextFillColor(Lt,Txr*0.6,Txg*0.6,Txb*0.6,1) setNextTextAlign(Lt,AlignH_Left,AlignV_Top)
addText(Lt,fS,"HSV",vpX+8,valY)
setNextTextAlign(Lt,AlignH_Left,AlignV_Top)
addText(Lt,fT,string.format("H: %%d   S: %%d%%%%   V: %%d%%%%",math.floor(CurH+0.5),math.floor(CurS*100+0.5),math.floor(CurV*100+0.5)),vpX+8,valY+14)
valY=valY+38
setNextFillColor(Lt,Txr*0.6,Txg*0.6,Txb*0.6,1) setNextTextAlign(Lt,AlignH_Left,AlignV_Top)
addText(Lt,fS,"HEX",vpX+8,valY)
setNextTextAlign(Lt,AlignH_Left,AlignV_Top)
addText(Lt,fT,string.format("#%%02X%%02X%%02X",math.floor(CurR*255+0.5),math.floor(CurG*255+0.5),math.floor(CurB*255+0.5)),vpX+8,valY+14)
valY=valY+42
setNextFillColor(Lt,Txr*0.4,Txg*0.4,Txb*0.4,1) setNextTextAlign(Lt,AlignH_Left,AlignV_Top)
addText(Lt,fS,"Chat: theme ELEMENT #HEX",vpX+8,valY)
setNextFillColor(Lt,Txr*0.4,Txg*0.4,Txb*0.4,1) setNextTextAlign(Lt,AlignH_Left,AlignV_Top)
addText(Lt,fS,"Chat: theme ELEMENT R G B",vpX+8,valY+14)
]], vpX, vpX)
  S[7]=[[
addLine(Ll,0,SH-36,SW,SH-36)
setNextFillColor(Lp,FTr,FTg,FTb,0.95) addBox(Lp,0,SH-36,SW,36)
local px=8 local py=SH-30 local pH=22 local pG=4
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
local abX=SW-270
if Btn("+ New",abX,py,55,pH,true) then Out=json.encode({"theme_new"}) end abX=abX+59
if Btn("Save",abX,py,50,pH,true) then Out=json.encode({"theme_save"}) end abX=abX+54
if Btn("Delete",abX,py,55,pH,#PROFILES>1) then Out=json.encode({"theme_delete"}) end abX=abX+59
if Btn("Reset",abX,py,50,pH,true) then Out=json.encode({"theme_reset"}) end
setOutput(Out) requestAnimationFrame(5)
]]
  return table.concat(S)
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

local VERSION="v2.1.0"
CustomAtlas  ="atlas"  --export: Atlas file to load (default=atlas, set to custom filename in autoconf/custom/)
BaseChannel ="NavBase" --export: Personal base channel
CalcSpeed   =30000    --export: Time Calc max speed in space in km/h (e.g. 30000)
CalcThrust  =0        --export: Time Calc total thrust in kN from ship stats (0 = use CalcAccel fallback)
CalcBrake   =0        --export: Time Calc total brake force in kN from ship stats (0 = auto-detect, fallback to thrust)
CalcAccel   =5        --export: Time Calc fallback acceleration in m/s2 — ignored if CalcThrust is set
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
AutoFly      = false
HudPX        = 13    -- runtime HUD X% (set from databank or HudX export)
HudPY        = 15    -- runtime HUD Y% (set from databank or HudY export)

-- Theme state
ThemeSlots       = nil   -- loaded on init
Palette          = nil   -- derived from ThemeSlots
PickerElem       = 1     -- 1-8, which slot is being edited
ShowThemePicker  = false -- true when optional screen shows picker
PickerProfileScroll = 0

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
  AutoFly=(databank.getStringValue("autofly")=="1")
  ShipID=BuildShipID()
  -- Export params always win for position; databank only used if export is at default
  local hx=tonumber(databank.getStringValue("hud_x"))
  local hy=tonumber(databank.getStringValue("hud_y"))
  HudPX=(HudX~=13) and HudX or (hx or HudX)
  HudPY=(HudY~=15) and HudY or (hy or HudY)
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
  databank.setStringValue("autofly", AutoFly and "1" or "0")
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

function SendAutopilot(name, coords)
  if not coords or coords=="" then return end
  -- HUD databank integration: write to shared databank (slot 4, optional)
  -- Arch HUD reads nav_arch_dest; Saga HUD reads nav_saga_dest
  if archbank then
    local dest = (name or "Navigator").."|"..coords
    archbank.setStringValue("nav_arch_dest", dest)
    archbank.setStringValue("nav_saga_dest", dest)
    archbank.setStringValue("autofly", AutoFly and "1" or "0")
    system.print("[NAV] sent to HUD bank: "..(name or "Navigator"))
  end
end

function SetNavWP(name)
  for _,wp in ipairs(ContextWPs()) do
    if wp.n:lower()==name:lower() then
      NavTarget={t="wp",n=wp.n,c=wp.c,tab=ContextTabIdx()}
      SaveData(); UpdateWaypoint()
      SendAutopilot(wp.n, wp.c)
      SetStatus("Navigating: "..wp.n)
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
      local stopLabel=r.n.." stop "..idx.."/"..#r.pts
      SendAutopilot(stopLabel, r.pts[idx].c)
      SetStatus("Route: "..stopLabel)
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
      local stopLabel=r.n.." stop "..idx.."/"..#r.pts
      SendAutopilot(stopLabel, r.pts[idx].c)
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
  emitter.send(ch,"<RequestSync>"..ShipID.."|pid:"..GetPlayerID().."|pname:"..GetPlayerName())
  SetStatus("Sync requested on "..ch)
end

function PushToChannel(ch,wps,routes)
  if not emitter then SetStatus("No emitter") return end
  PushQueue={}
  for _,wp in ipairs(wps) do
    if not wp.lk then table.insert(PushQueue,{type="wp",  data={n=wp.n,c=wp.c}}) end
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
      table.insert(items,{type="wp",n=wp.n,c=wp.c,dist=d,ctx="personal",lk=wp.lk})
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
          table.insert(items,{type="wp",n=wp.n,c=wp.c,dist=d,ctx=ActiveOrg,lk=wp.lk})
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
    local mass=construct and construct.getMass() or 0
    local Aa=CalcThrust and mass>0 and (CalcThrust*1000/mass) or (CalcAccel or 5)
    local brakeN=construct and construct.getMaxBrake and construct.getMaxBrake() or 0
    local Ad=CalcBrake and CalcBrake>0 and (CalcBrake*1000/math.max(mass,1))
           or (brakeN>0 and mass>0 and brakeN/mass) or Aa
    local dynLabel
    if CalcThrust and CalcThrust>0 then
      dynLabel=string.format("Thrust: %g kN (%.1f m/s\xc2\xb2)  Brake: %g kN (%.1f m/s\xc2\xb2)",
        CalcThrust,Aa, (CalcBrake and CalcBrake>0) and CalcBrake or brakeN/1000, Ad)
    else
      dynLabel=string.format("Accel: %g m/s\xc2\xb2",(CalcAccel or 5))
    end
    table.insert(items,{type="info",label=string.format("Speed: %g km/h  |  %s",(CalcSpeed or 30000),dynLabel)})
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

  -- ── Theme-derived CSS colors ────────────────────────────────────
  local P=Palette
  local function rgba(r,g,b,a) return string.format("rgba(%d,%d,%d,%.2f)",math.floor(r*255),math.floor(g*255),math.floor(b*255),a) end
  local cA  = string.format("rgb(%d,%d,%d)", math.floor(P.ar*255), math.floor(P.ag*255), math.floor(P.ab*255))
  local cBg = string.format("rgba(%d,%d,%d,0.93)", math.floor(P.bgr*255), math.floor(P.bgg*255), math.floor(P.bgb*255))
  local cBd = rgba(P.lnr, P.lng, P.lnb, 0.45)
  local cPH = rgba(P.phdr, P.phdg, P.phdb, 0.60)
  local cSl = rgba(P.ar, P.ag, P.ab, 0.35)
  local cDv = rgba(P.lnr*0.6, P.lng*0.6, P.lnb*0.6, 0.25)
  local cNB = rgba(P.phdr*0.6, P.phdg*0.6, P.phdb*0.6, 0.60)
  local cFt = string.format("rgb(%d,%d,%d)", math.floor(P.ftr*255), math.floor(P.ftg*255), math.floor(P.ftb*255))
  local cRi = string.format("rgb(%d,%d,%d)", math.floor(P.txr*0.55*255), math.floor(P.txg*0.55*255), math.floor(P.txb*0.76*255))
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
    local lkTag=""
    if NavTarget.t=="wp" then
      local wps=ContextWPs()
      for _,wp in ipairs(wps) do if wp.n:lower()==NavTarget.n:lower() and wp.lk then lkTag=string.format(' <span style="color:%s">[LK]</span>',cA); break end end
    end
    h[#h+1]=string.format('<div class="nav">&#9658; %s: %s%s%s &nbsp; %s</div>', lbl, NavTarget.n:sub(1,20), si2, lkTag, dist)
  else
    h[#h+1]='<div class="nav" style="color:rgb(65,85,115);">&#9658; No target</div>'
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
      local lkBadge=item.lk and string.format(' <span style="color:%s;font-size:%dpx">LK</span>',cA,fsS) or ""
      h[#h+1]=string.format('<div class="%s"><span><span class="num">%d</span>%s%s</span><span><span style="opacity:0.65">%s</span><span class="arr">&#62;</span></span></div>',
        cls, sIdx, item.n:sub(1,18), lkBadge, item.dist or "---")
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
    SendAutopilot(item.n, item.c)
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

-- ── Theme helpers ─────────────────────────────────────────────
function RefreshTheme()
  Palette=DeriveTheme(ThemeSlots)
end

function DrawPickerScreen()
  if not screen then return end
  if not ShowThemePicker then
    if not Palette then Palette=DeriveTheme(ThemeSlots or DefaultShipTheme()) end
    local P=Palette
    screen.setRenderScript(string.format([[
local Lbg=createLayer() local Lt=createLayer()
local SW,SH=getResolution()
setNextFillColor(Lbg,%f,%f,%f,1) addBox(Lbg,0,0,SW,SH)
local fB=loadFont("Montserrat-Light",22) local fS=loadFont("Montserrat-Light",14)
setNextFillColor(Lt,%f,%f,%f,1) setNextTextAlign(Lt,AlignH_Center,AlignV_Middle)
addText(Lt,fB,"THEME EDITOR",SW/2,SH/2-14)
setNextFillColor(Lt,%f,%f,%f,1) setNextTextAlign(Lt,AlignH_Center,AlignV_Middle)
addText(Lt,fS,"Alt+0 to open",SW/2,SH/2+14)
]], P.bgr,P.bgg,P.bgb, P.ar,P.ag,P.ab, P.txr*0.5,P.txg*0.5,P.txb*0.5))
    return
  end
  local ok2,result=pcall(BuildPickerScript)
  if not ok2 then system.print("[NAV] picker err: "..tostring(result)); return end
  screen.setRenderScript(result)
end

-- BuildPickerScript is defined in library.onStart to stay within per-handler local variable limits
-- (moved there to avoid DU's per-handler CPU/local-variable budget exhaustion)

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
ThemeSlots=LoadTheme()
Palette=DeriveTheme(ThemeSlots)
UpdateChannels()
if archbank then system.print("[NAV] HUD bank=OK (Arch+Saga)") end
unit.setTimer("nav_tick",5)
UpdateWaypoint()
if screen then
  screen.activate()
  DrawPickerScreen()
  unit.setTimer("screen_poll",0.05)
end
DrawHUD()
system.print("=== Navigator "..VERSION.." (No Screen) ===  "..ShipID)
system.print("Target: "..(NavTarget and NavTarget.n or "none"))
system.print("Alt+Q/C = scroll  |  Alt+D = select  |  Shift = toggle HUD  |  type: help"..
  (screen and "  |  Alt+0 = theme picker" or ""))


--[[@
slot=-1
event=onStop()
args=
]]
system.showScreen(0)
if screen then
  if not Palette then Palette=DeriveTheme(ThemeSlots or DefaultShipTheme()) end
  local P=Palette
  screen.setRenderScript(string.format([[
local Lbg=createLayer() local Lt=createLayer()
local SW,SH=getResolution()
setNextFillColor(Lbg,%f,%f,%f,1) addBox(Lbg,0,0,SW,SH)
local fB=loadFont("Montserrat-Light",22) local fS=loadFont("Montserrat-Light",14)
setNextFillColor(Lt,%f,%f,%f,1) setNextTextAlign(Lt,AlignH_Center,AlignV_Middle)
addText(Lt,fB,"THEME EDITOR",SW/2,SH/2-14)
setNextFillColor(Lt,%f,%f,%f,1) setNextTextAlign(Lt,AlignH_Center,AlignV_Middle)
addText(Lt,fS,"Offline — activate PB to start",SW/2,SH/2+14)
]], P.bgr,P.bgg,P.bgb, P.ar,P.ag,P.ab, P.txr*0.5,P.txg*0.5,P.txb*0.5))
end


--[[@
slot=-1
event=onTimer(tag)
args="nav_tick"
]]
if AutoFly and NavTarget and NavTarget.t=="route" then
  local cp=GetCurrentPos()
  local tp=cp and ParsePos(NavTarget.c)
  if tp then
    local dist=CalcDist(cp,tp)
    local inAtmo=(unit.getAtmosphereDensity() or 0)>0
    local advance
    if inAtmo then
      advance = dist and dist<2000
    else
      local vel=construct.getVelocity()
      local speed=vel and math.sqrt(vel[1]*vel[1]+vel[2]*vel[2]+vel[3]*vel[3]) or 0
      advance = dist and dist<10000 and speed<50
    end
    if advance then
      if NavTarget.stopIdx>=NavTarget.stopTotal then
        AutoFly=false
        if databank then databank.setStringValue("autofly","0") end
        SetStatus("Route complete — Auto Fly off")
      else NextStop() end
    end
  end
end
if StatusMsg~="" and system.getArkTime()>StatusExpiry then StatusMsg="" end
UpdateWaypoint()
DrawHUD()


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
if act=="theme_close" then ShowThemePicker=false
elseif act=="theme_sel_elem" then PickerElem=d[2] or 1
elseif act=="theme_set_hue" then
  local h2=d[2] or 0
  ThemeSlots[PickerElem].h=h2; RefreshTheme()
elseif act=="theme_set_sv" then
  local s2,v2=d[2] or 0.5, d[3] or 0.5
  ThemeSlots[PickerElem].s=math.max(0,math.min(1,s2))
  ThemeSlots[PickerElem].v=math.max(0,math.min(1,v2))
  RefreshTheme()
elseif act=="theme_save" then
  SaveTheme(GetActiveProfileName(),ThemeSlots)
  SetStatus("Theme saved: "..GetActiveProfileName())
elseif act=="theme_load" then
  local name=d[2] or ""
  local raw2=databank and databank.getStringValue("theme_p_"..name) or ""
  if raw2~="" then
    local ok3,data=pcall(json.decode,raw2)
    if ok3 and data and #data>=8 then
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
DrawPickerScreen()
if not ShowThemePicker then DrawHUD() end


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
args="option0"
]]
if not L_ALT then return end
if not screen then SetStatus("No screen connected — theme via chat only"); return end
ShowThemePicker=not ShowThemePicker
if ShowThemePicker then
  local sn=GetActiveProfileName()
  if databank and databank.getStringValue("theme_p_"..sn)==""  then SaveTheme(sn,ThemeSlots) end
end
DrawPickerScreen()
if ShowThemePicker then SetStatus("Theme picker opened on screen")
else SetStatus("Theme picker closed"); DrawHUD() end


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
      for _,e in ipairs(list) do if e.n:lower()==wp.n:lower() then if not e.lk then e.c=wp.c end found=true;break end end
      if not found then table.insert(list,{n=wp.n,c=wp.c}) end
    elseif SyncContext~="personal" and OrgData[SyncContext] then
      local list=OrgData[SyncContext].wps
      local found=false
      for _,e in ipairs(list) do if e.n:lower()==wp.n:lower() then if not e.lk then e.c=wp.c end found=true;break end end
      if not found then table.insert(list,{n=wp.n,c=wp.c}) end
    else
      local found=false
      for _,e in ipairs(PersonalWPs) do if e.n:lower()==wp.n:lower() then if not e.lk then e.c=wp.c end found=true;break end end
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
    for _,e in ipairs(PersonalWPs) do if e.n:lower()==wp.n:lower() then if not e.lk then e.c=wp.c end found=true;break end end
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
  system.print("lock NAME              lock WP (won't push or be overwritten by sync)")
  system.print("unlock NAME            unlock WP")
  system.print("autofly on/off         auto-advance route stops")
  system.print("sync / orgsync         sync from base")
  system.print("push / orgpush         push to base")
  system.print("firstsync CHANNEL      first-time org sync, e.g: firstsync NavOrg")
  system.print("org NAME               switch active context")
  system.print("search NAME            filter atlas by name")
  system.print("search                 clear atlas filter")
  system.print("coords NAME            print WP coords to console")
  system.print("list / routes          list items")
  system.print("status                 show current nav")
  system.print("hudpos X Y              move HUD (e.g. hudpos 13 15)")
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
  system.print("Alt+Up/Down = browse  |  Alt+Right = activate"..
    (screen and "  |  Alt+0 = theme picker" or ""))
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
if not asRT then asRT,asArg=t:match("^[Aa][Dd][Dd][Ss][Tt][Oo][Pp]%s+(.-)%s+([^%s].+)$") end
if not asRT then asRT=t:match("^[Aa][Dd][Dd][Ss][Tt][Oo][Pp]%s+(.-)%s*$") end
if asRT then
  local arg=Trim(asArg or "")
  -- "here" keyword: use current nav target WP coords
  if arg=="" or arg:lower()=="here" then
    if NavTarget and NavTarget.c then arg=NavTarget.c
    else SetStatus("No nav target — nav to a WP first, then: addstop ROUTE here"); return end
  end
  AddStop(Trim(asRT),arg); return
end

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
local lkN=t:match("^[Ll][Oo][Cc][Kk]%s+(.*)")
if lkN~=nil then
  lkN=Trim(lkN)
  if lkN=="" then SetStatus("Usage: lock WPNAME"); return end
  local wps=ContextWPs()
  for _,wp in ipairs(wps) do if wp.n:lower()==lkN:lower() then wp.lk=true; SaveData(); SetStatus("Locked: "..wp.n); return end end
  SetStatus("WP not found: "..lkN); return
end
local ulN=t:match("^[Uu][Nn][Ll][Oo][Cc][Kk]%s+(.*)")
if ulN~=nil then
  ulN=Trim(ulN)
  if ulN=="" then SetStatus("Usage: unlock WPNAME"); return end
  local wps=ContextWPs()
  for _,wp in ipairs(wps) do if wp.n:lower()==ulN:lower() then wp.lk=nil; SaveData(); SetStatus("Unlocked: "..wp.n); return end end
  SetStatus("WP not found: "..ulN); return
end
local afCmd=lo:match("^autofly%s*(.*)")
if afCmd~=nil then
  if afCmd=="on" or afCmd=="1" then
    AutoFly=true
    if databank then databank.setStringValue("autofly","1") end
    SetStatus("Auto Fly: ON")
  elseif afCmd=="off" or afCmd=="0" then
    AutoFly=false
    if databank then databank.setStringValue("autofly","0") end
    SetStatus("Auto Fly: OFF")
  else SetStatus("Auto Fly is "..(AutoFly and "ON" or "OFF").."  —  autofly on / autofly off") end
  return
end
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

local coordN=t:match("^[Cc][Oo][Oo][Rr][Dd][Ss]%s+(.*)")
if coordN~=nil then
  coordN=Trim(coordN)
  if coordN=="" then SetStatus("Usage: coords WPNAME"); return end
  local wps=ContextWPs()
  for _,wp in ipairs(wps) do
    if wp.n:lower()==coordN:lower() then
      system.print("[NAV] "..wp.n.."  "..wp.c); return
    end
  end
  SetStatus("WP not found: "..coordN); return
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
if lo=="hudpos" then SetStatus("HUD position: "..HudPX.."% "..HudPY.."%"); return end

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
    DrawHUD(); return
  end

  -- theme save NAME
  local saveName=arg:match("^[Ss][Aa][Vv][Ee]%s+(.+)")
  if saveName then
    SaveTheme(Trim(saveName),ThemeSlots); RefreshTheme()
    SetStatus("Theme saved: "..Trim(saveName)); DrawHUD(); DrawPickerScreen(); return
  end
  if argLo=="save" then
    SaveTheme(GetActiveProfileName(),ThemeSlots)
    SetStatus("Saved: "..GetActiveProfileName()); DrawHUD(); DrawPickerScreen(); return
  end

  -- theme load NAME
  local loadName=arg:match("^[Ll][Oo][Aa][Dd]%s+(.+)")
  if loadName then
    loadName=Trim(loadName)
    local raw2=databank and databank.getStringValue("theme_p_"..loadName) or ""
    if raw2~="" then
      local ok3,data=pcall(json.decode,raw2)
      if ok3 and data and #data>=8 then
        ThemeSlots=data; databank.setStringValue("theme_profile_active",loadName)
        RefreshTheme(); SetStatus("Loaded: "..loadName)
      else SetStatus("Invalid profile data") end
    else SetStatus("Profile not found: "..loadName) end
    DrawHUD(); DrawPickerScreen(); return
  end

  -- theme delete NAME
  local delName=arg:match("^[Dd][Ee][Ll][Ee][Tt][Ee]%s+(.+)")
  if delName then
    DeleteTheme(Trim(delName)); ThemeSlots=LoadTheme(); RefreshTheme()
    SetStatus("Deleted: "..Trim(delName)); DrawHUD(); DrawPickerScreen(); return
  end

  -- theme rename NAME
  local renName=arg:match("^[Rr][Ee][Nn][Aa][Mm][Ee]%s+(.+)")
  if renName then
    local oldName=GetActiveProfileName()
    local newName=Trim(renName)
    SaveTheme(newName,ThemeSlots)
    if oldName~=newName then DeleteTheme(oldName) end
    SetStatus("Renamed to: "..newName); DrawHUD(); DrawPickerScreen(); return
  end

  -- theme profiles
  if argLo=="profiles" then
    local names=GetThemeProfiles()
    system.print("═══ THEME PROFILES ══════════════════")
    for i,n in ipairs(names) do
      local mark=(n==GetActiveProfileName()) and " <" or ""
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
    SetStatus("Exported — copy the line above"); DrawHUD(); return
  end

  -- theme import THEME:...
  if arg:sub(1,6)=="THEME:" then
    local iName,iSlots=ImportTheme(arg)
    if iName and iSlots then
      ThemeSlots=iSlots; SaveTheme(iName,iSlots); RefreshTheme()
      SetStatus("Imported: "..iName)
    else SetStatus("Invalid import string") end
    DrawHUD(); DrawPickerScreen(); return
  end

  -- theme reset
  if argLo=="reset" then
    ThemeSlots=DefaultShipTheme(); RefreshTheme()
    SaveTheme(GetActiveProfileName(),ThemeSlots)
    SetStatus("Theme reset to defaults"); DrawHUD(); DrawPickerScreen(); return
  end

  -- theme ELEMENT #HEX  or  theme ELEMENT R G B
  for i,name in ipairs(THEME_SLOT_NAMES) do
    if argLo:sub(1,#name)==name:lower() then
      local rest=Trim(arg:sub(#name+1))
      local hex=rest:match("^(#%x%x%x%x%x%x)$")
      if hex then
        local r,g,b=Hex2RGB(hex)
        if r then
          local h2,s2,v2=RGB2HSV(r,g,b)
          ThemeSlots[i]={h=h2,s=s2,v=v2}; RefreshTheme()
          SaveTheme(GetActiveProfileName(),ThemeSlots)
          SetStatus(THEME_SLOT_LABELS[i].." set to "..hex)
        else SetStatus("Invalid hex code") end
        DrawHUD(); DrawPickerScreen(); return
      end
      local rv,gv,bv=rest:match("^(%d+)%s+(%d+)%s+(%d+)$")
      if rv then
        local r,g,b=tonumber(rv)/255,tonumber(gv)/255,tonumber(bv)/255
        r,g,b=math.min(1,math.max(0,r)),math.min(1,math.max(0,g)),math.min(1,math.max(0,b))
        local h2,s2,v2=RGB2HSV(r,g,b)
        ThemeSlots[i]={h=h2,s=s2,v=v2}; RefreshTheme()
        SaveTheme(GetActiveProfileName(),ThemeSlots)
        SetStatus(THEME_SLOT_LABELS[i].." set to "..RGB2Hex(r,g,b))
        DrawHUD(); DrawPickerScreen(); return
      end
    end
  end

  SetStatus("Unknown theme command. Type: theme"); DrawHUD(); return
end

SetStatus("Unknown: '"..lo.."'  type help")
