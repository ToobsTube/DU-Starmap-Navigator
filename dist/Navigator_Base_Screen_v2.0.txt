-- ================================================================
-- NAVIGATOR BASE SCREEN v2.0.0
-- Paste this script directly into the Screen Unit's Lua editor.
-- The Programming Board feeds data via setScriptInput().
-- ================================================================
local json=require('dkjson')
local input=json.decode(getInput()) or {}
local SW,SH=getResolution()
local C=32
local ScrollWP = input.scrollWP or 0
local ScrollRT = input.scrollRT or 0
local SelWP    = input.selWP    or ""
local SelRoute = input.selRT    or ""
local SelStop  = input.selStop  or 0
local StatusMsg= input.status   or ""
local Sending  = input.sending  or false
local WP       = input.wps      or {}
local RT       = input.routes   or {}
local STOPS    = input.stops    or {}
local acked    = input.ack      or false

last_action = last_action or ""
if acked then last_action="" end
local function setAction(a) if last_action=="" then last_action=a end end

local cx,cy=getCursor()
local pr=getCursorReleased()

-- Proportional column widths
local wpX=0
local wpW=math.floor(SW*0.39)
local rtX=wpW
local rtW=math.floor(SW*0.29)
local actX=rtX+rtW
local actW=SW-actX
local CON_Y=32
local vis=math.floor((SH-64)/C)-1

local Lbg=createLayer() local Lp=createLayer() local Ll=createLayer()
local Lb=createLayer() local Ls=createLayer() local Lt=createLayer()
local Lh=createLayer() local Lx=createLayer() local Lst=createLayer()
local fT=loadFont("Montserrat-Light",math.floor(SH*0.031))
local fS=loadFont("Montserrat-Light",math.floor(SH*0.022))
local fH=loadFont("Montserrat-Light",math.floor(SH*0.035))
local fB=loadFont("Montserrat-Light",math.floor(SH*0.042))
setDefaultFillColor(Lt,Shape_Text,0.82,0.82,0.82,1)
setDefaultFillColor(Lh,Shape_Text,0.70,0.85,1.0,1)
setDefaultFillColor(Ls,Shape_Text,0.0,0.87,1.0,1)
setDefaultFillColor(Lx,Shape_Text,1.0,0.86,0.0,1)
setDefaultFillColor(Lst,Shape_Text,1.0,0.78,0.2,1)
setDefaultStrokeColor(Ll,Shape_Line,0.15,0.32,0.62,0.6)
setDefaultStrokeWidth(Ll,Shape_Line,1)
setNextFillColor(Lbg,0,0.008,0.04,1) addBox(Lbg,0,0,SW,SH)

local function PH(x,w,r,g,b)
  setNextFillColor(Lp,r,g,b,0.88) addBox(Lp,x,CON_Y,w,C)
end
local function Btn(tx,x,y,w,h,en)
  local hv=(cx>=x and cx<x+w and cy>=y and cy<y+h)
  if not en then
    setNextFillColor(Lb,0.06,0.06,0.14,0.7) setNextStrokeColor(Lb,0.18,0.18,0.28,0.5)
    setNextStrokeWidth(Lb,1) addBoxRounded(Lb,x,y,w,h,4)
    setNextFillColor(Lt,0.28,0.28,0.38,1) setNextTextAlign(Lt,AlignH_Center,AlignV_Middle)
    addText(Lt,fT,tx,x+w/2,y+h/2) return false
  elseif hv then
    setNextFillColor(Lb,0.0,0.31,0.78,1) setNextStrokeColor(Lb,0.4,0.63,1.0,1)
    setNextStrokeWidth(Lb,1) addBoxRounded(Lb,x,y,w,h,4)
    setNextTextAlign(Lt,AlignH_Center,AlignV_Middle) addText(Lt,fT,tx,x+w/2,y+h/2)
  else
    setNextFillColor(Lb,0.0,0.16,0.55,0.9) setNextStrokeColor(Lb,0.32,0.5,0.87,1)
    setNextStrokeWidth(Lb,1) addBoxRounded(Lb,x,y,w,h,4)
    setNextTextAlign(Lt,AlignH_Center,AlignV_Middle) addText(Lt,fT,tx,x+w/2,y+h/2)
  end
  return hv and pr
end

-- HEADER
setNextFillColor(Lp,0,0.04,0.16,1) setNextStrokeColor(Lp,0.15,0.32,0.62,0.8)
setNextStrokeWidth(Lp,1) addBox(Lp,0,0,SW,C)
setNextTextAlign(Lx,AlignH_Left,AlignV_Middle) addText(Lx,fB,"◄ NAV BASE v2.0 ►",8,C/2)
if Sending then
  setNextFillColor(Lst,1.0,0.78,0.2,1) setNextTextAlign(Lst,AlignH_Right,AlignV_Middle)
  addText(Lst,fT,"⟳ SYNCING...",SW-8,C/2)
else
  setNextFillColor(Lt,0.35,0.35,0.50,1) setNextTextAlign(Lt,AlignH_Right,AlignV_Middle)
  addText(Lt,fT,#WP.." WPs  |  "..#RT.." Routes",SW-8,C/2)
end
addLine(Ll,0,C,SW,C)
addLine(Ll,wpX+wpW,CON_Y,wpX+wpW,SH-32)
addLine(Ll,rtX+rtW,CON_Y,rtX+rtW,SH-32)

-- WAYPOINTS
PH(wpX,wpW,0,0.04,0.14)
setNextFillColor(Lx,1.0,0.86,0.0,1) setNextTextAlign(Lx,AlignH_Center,AlignV_Middle)
addText(Lx,fH,"WAYPOINTS ["..#WP.."]",wpX+wpW/2,CON_Y+C/2)
addLine(Ll,wpX,CON_Y+C,wpX+wpW,CON_Y+C)
local maxSW=math.max(0,#WP-vis) local sCW=math.max(0,math.min(ScrollWP,maxSW))
for i=1,vis do
  local idx=i+sCW if idx>#WP then break end
  local wp=WP[idx] local ry=CON_Y+C+(i-1)*C
  local sel=(wp.n==SelWP) local hv=(cx>=wpX and cx<wpX+wpW and cy>=ry and cy<ry+C)
  if sel then
    setNextFillColor(Lp,0.0,0.59,0.86,0.22) setNextStrokeColor(Lp,0.0,0.78,1.0,0.9)
    setNextStrokeWidth(Lp,1) addBox(Lp,wpX,ry,wpW,C)
  elseif hv then setNextFillColor(Lp,1,1,1,0.04) addBox(Lp,wpX,ry,wpW,C) end
  setNextFillColor(Lt,0.30,0.35,0.50,1) setNextTextAlign(Lt,AlignH_Right,AlignV_Middle)
  addText(Lt,fS,idx..".",wpX+26,ry+C/2)
  local L=(sel or hv) and Ls or Lt
  if sel then setNextFillColor(Ls,0.0,0.87,1.0,1) end
  setNextTextAlign(L,AlignH_Left,AlignV_Middle) addText(L,fT,wp.n,wpX+30,ry+C/2)
  setNextStrokeColor(Ll,0.15,0.32,0.62,0.18) addLine(Ll,wpX,ry+C,wpX+wpW,ry+C)
  if hv and pr then setAction(json.encode({"selwp",wp.n})) end
end
if #WP>vis then
  local sbX=wpX+wpW-5 local sbY=CON_Y+C+2 local sbH=vis*C-4
  local tH=math.max(12,sbH*(vis/#WP)) local tY=sbY+(sbH-tH)*(sCW/math.max(1,maxSW))
  setNextFillColor(Ll,0.1,0.22,0.44,0.4) addBox(Ll,sbX,sbY,4,sbH)
  setNextFillColor(Ll,0.0,0.63,1.0,0.8) addBox(Ll,sbX,tY,4,tH)
end

-- ROUTES / STOPS
if SelStop>0 and SelRoute~="" then
  PH(rtX,rtW,0.0,0.06,0.14)
  setNextFillColor(Lh,0.70,0.85,1.0,1) setNextTextAlign(Lh,AlignH_Left,AlignV_Middle)
  addText(Lh,fH,"◄ "..SelRoute,rtX+8,CON_Y+C/2)
  addLine(Ll,rtX,CON_Y+C,rtX+rtW,CON_Y+C)
  local maxSR=math.max(0,#STOPS-vis) local sCR=math.max(0,math.min(ScrollRT,maxSR))
  for i=1,vis do
    local idx=i+sCR if idx>#STOPS then break end
    local st=STOPS[idx] local ry2=CON_Y+C+(i-1)*C
    local sel=(SelStop==idx) local hv=(cx>=rtX and cx<rtX+rtW and cy>=ry2 and cy<ry2+C)
    if sel then
      setNextFillColor(Lp,0.0,0.40,0.80,0.22) setNextStrokeColor(Lp,0.3,0.7,1.0,0.9)
      setNextStrokeWidth(Lp,1) addBox(Lp,rtX,ry2,rtW,C)
    elseif hv then setNextFillColor(Lp,1,1,1,0.04) addBox(Lp,rtX,ry2,rtW,C) end
    setNextFillColor(Lt,0.30,0.35,0.50,1) setNextTextAlign(Lt,AlignH_Right,AlignV_Middle)
    addText(Lt,fS,idx..".",rtX+22,ry2+C/2)
    local lbl=st.label or st.c:sub(1,24)
    local L=(sel or hv) and Ls or Lt
    if sel then setNextFillColor(Ls,0.4,0.8,1.0,1) end
    setNextTextAlign(L,AlignH_Left,AlignV_Middle) addText(L,fT,lbl,rtX+26,ry2+C/2)
    setNextStrokeColor(Ll,0.15,0.32,0.62,0.18) addLine(Ll,rtX,ry2+C,rtX+rtW,ry2+C)
    if hv and pr then setAction(json.encode({"selstop",idx})) end
  end
else
  PH(rtX,rtW,0,0.08,0.06)
  setNextFillColor(Lh,0.4,1.0,0.6,1) setNextTextAlign(Lh,AlignH_Center,AlignV_Middle)
  addText(Lh,fH,"ROUTES ["..#RT.."]",rtX+rtW/2,CON_Y+C/2)
  addLine(Ll,rtX,CON_Y+C,rtX+rtW,CON_Y+C)
  local maxSR=math.max(0,#RT-vis) local sCR=math.max(0,math.min(ScrollRT,maxSR))
  for i=1,vis do
    local idx=i+sCR if idx>#RT then break end
    local r=RT[idx] local ry2=CON_Y+C+(i-1)*C
    local sel=(r.n==SelRoute) local hv=(cx>=rtX and cx<rtX+rtW and cy>=ry2 and cy<ry2+C)
    if sel then
      setNextFillColor(Lp,0.0,0.50,0.25,0.22) setNextStrokeColor(Lp,0.2,0.86,0.47,0.9)
      setNextStrokeWidth(Lp,1) addBox(Lp,rtX,ry2,rtW,C)
    elseif hv then setNextFillColor(Lp,1,1,1,0.04) addBox(Lp,rtX,ry2,rtW,C) end
    local L=(sel or hv) and Ls or Lt
    if sel then setNextFillColor(Ls,0.3,1.0,0.55,1) end
    setNextTextAlign(L,AlignH_Left,AlignV_Middle) addText(L,fT,r.n,rtX+8,ry2+C/2)
    local np=#(r.pts or {})
    setNextFillColor(Lt,0.35,0.50,0.35,1) setNextTextAlign(Lt,AlignH_Right,AlignV_Middle)
    addText(Lt,fS,np.."▶",rtX+rtW-6,ry2+C/2)
    setNextStrokeColor(Ll,0.15,0.32,0.62,0.18) addLine(Ll,rtX,ry2+C,rtX+rtW,ry2+C)
    if hv and pr then setAction(json.encode({"selrt",r.n})) end
  end
end

-- ACTION PANEL
PH(actX,actW,0.04,0.01,0.12)
setNextFillColor(Lh,0.70,0.47,1.0,1) setNextTextAlign(Lh,AlignH_Center,AlignV_Middle)
addText(Lh,fH,"ACTIONS",actX+actW/2,CON_Y+C/2)
addLine(Ll,actX,CON_Y+C,actX+actW,CON_Y+C)
local selInfo=""
if SelWP~="" then selInfo="[WP] "..SelWP
elseif SelRoute~="" and SelStop>0 then selInfo="[STOP "..SelStop.."] "..SelRoute
elseif SelRoute~="" then selInfo="[ROUTE] "..SelRoute end
if selInfo~="" then
  setNextFillColor(Ls,0.0,0.87,1.0,1) setNextTextAlign(Ls,AlignH_Left,AlignV_Top)
  addText(Ls,fS,"SELECTED:",actX+8,CON_Y+C+8)
  setNextFillColor(Ls,0.0,0.87,1.0,1) setNextTextAlign(Ls,AlignH_Left,AlignV_Top)
  addText(Ls,fT,selInfo,actX+8,CON_Y+C+22)
end
local bX=actX+6 local bW=actW-12 local bH=26 local bG=4
local by=SH-32-(bH+bG)*8
if Btn("★ ADD WP (chat: add NAME)",bX,by,bW,bH,true)                       then setAction(json.encode({"hint_add"}))     end by=by+bH+bG
if Btn("✎ RENAME",                 bX,by,bW,bH,selInfo~="")                 then setAction(json.encode({"hint_rename"}))  end by=by+bH+bG
if Btn("✎ SET COORDS",             bX,by,bW,bH,selInfo~="")                 then setAction(json.encode({"hint_setpos"}))  end by=by+bH+bG
if Btn("+ NEW ROUTE",              bX,by,bW,bH,true)                        then setAction(json.encode({"hint_newroute"}))end by=by+bH+bG
if Btn("+ ADD STOP TO ROUTE",      bX,by,bW,bH,SelRoute~="" and SelStop==0) then setAction(json.encode({"hint_addstop"})) end by=by+bH+bG
if Btn("✕ DELETE SELECTED",        bX,by,bW,bH,selInfo~="")                 then setAction(json.encode({"delete"}))       end by=by+bH+bG
if Btn("✕ CLEAR ALL WPs",          bX,by,bW,bH,#WP>0)                       then setAction(json.encode({"clearwps"}))     end by=by+bH+bG
if Btn("✕ CLEAR ALL ROUTES",       bX,by,bW,bH,#RT>0)                       then setAction(json.encode({"clearroutes"}))  end

-- FOOTER
addLine(Ll,0,SH-32,SW,SH-32)
setNextFillColor(Lp,0,0.02,0.08,0.95) addBox(Lp,0,SH-32,SW,32)
if StatusMsg~="" then
  setNextTextAlign(Lst,AlignH_Center,AlignV_Middle) addText(Lst,fT,StatusMsg,SW/2,SH-16)
else
  setNextFillColor(Lt,0.28,0.28,0.44,1) setNextTextAlign(Lt,AlignH_Center,AlignV_Middle)
  addText(Lt,fS,"Click to select  |  chat: add / del / rename / setpos / newroute / addstop / delstop / help",SW/2,SH-16)
end

setOutput(json.encode({action=last_action}))
requestAnimationFrame(1)
