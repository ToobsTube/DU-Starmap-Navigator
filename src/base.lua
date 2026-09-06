-- ================================================================
-- NAVIGATOR PERSONAL BASE v2.2.0
-- Dual Universe Navigation System
--
-- SLOT CONNECTIONS: link to ANY slot, in any order — auto-detected at startup.
--   Required: Screen Unit, Databank, Receiver, Emitter
-- Check the Lua console after activating for a "[BASE] slot1=... slot2=..." line
-- confirming what was detected as what.
--
-- Screen script is embedded — no separate screen file needed.
-- Paste nothing into the Screen; the PB pushes the render script.
--
-- TAB SYSTEM:
--   Personal tab holds your WPs and routes.
--   Org tabs are created automatically when ships push org data here.
-- ================================================================

--[[@
slot=-5
event=onStart()
args=
]]
-- ── Screen render script builder ──────────────────────────────
-- Theme state
ShowThemePicker = false
ThemeSlots      = nil
Palette         = nil
PickerElem      = 1
PickerProfileScroll = 0

function RefreshTheme()
  Palette=DeriveTheme(ThemeSlots)
end

function BuildScreenScript()
  local P=Palette
  local S={}

  S[1]=string.format([[
local json=require('dkjson')
local d=json.decode(getInput()) or {}
local View=d.view or "wps"
local Items=d.items or {}
local Total=d.total or 0
local SelName=d.sel or ""
local SelIdx=(type(d.sel)=="number") and d.sel or 0
local Ctx=d.ctx
local Pending=d.pending or ""
local Status=d.status or ""
local Sending=d.sending or false
local ack=d.ack or false
local RouteNm=d.rt or ""
local OrgList=d.orgs or {}
-- Theme
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
    P.dmr,P.dmg,P.dmb, P.nmr,P.nmg,P.nmb, P.lbr,P.lbg,P.lbb, P.tir,P.tig,P.tib)

  S[2]=[[
if not _S then _S={action=""} end
if ack then _S.action="" end
local function setAct(a) if _S.action=="" then _S.action=a end end
local SW,SH=getResolution()
local cx,cy=getCursor() local pr=getCursorReleased()
local C=32
local Lbg=createLayer() local Lp=createLayer() local Ll=createLayer()
local Lb=createLayer()  local Ls=createLayer() local Lt=createLayer()
local Lh=createLayer()  local Lx=createLayer()
local fT=loadFont("Montserrat-Light",math.floor(SH*0.031))
local fS=loadFont("Montserrat-Light",math.floor(SH*0.022))
local fH=loadFont("Montserrat-Light",math.floor(SH*0.035))
local fB=loadFont("Montserrat-Light",math.floor(SH*0.042))
setDefaultFillColor(Lt,Shape_Text,Txr,Txg,Txb,1)
setDefaultFillColor(Lh,Shape_Text,Ar,Ag,Ab,1)
setDefaultFillColor(Ls,Shape_Text,Nr,Ng,Nb,1)
setDefaultFillColor(Lx,Shape_Text,Hdr,Hdg,Hdb,1)
setDefaultStrokeColor(Ll,Shape_Line,Lnr,Lng,Lnb,0.6)
setDefaultStrokeWidth(Ll,Shape_Line,1)
setNextFillColor(Lbg,Bgr,Bgg,Bgb,1) addBox(Lbg,0,0,SW,SH)
local function Btn(tx,x,y,w,h,en)
  local hv=(cx>=x and cx<x+w and cy>=y and cy<y+h)
  if not en then
    setNextFillColor(Lb,BDfr,BDfg,BDfb,0.7) setNextStrokeColor(Lb,BDsr,BDsg,BDsb,0.5) setNextStrokeWidth(Lb,1)
    addBoxRounded(Lb,x,y,w,h,4)
    setNextFillColor(Lt,BDtr,BDtg,BDtb,1) setNextTextAlign(Lt,AlignH_Center,AlignV_Middle) addText(Lt,fT,tx,x+w/2,y+h/2)
    return false
  end
  if hv then setNextFillColor(Lb,BHfr,BHfg,BHfb,1) setNextStrokeColor(Lb,BHsr,BHsg,BHsb,1) setNextStrokeWidth(Lb,1)
  else setNextFillColor(Lb,BNfr,BNfg,BNfb,0.9) setNextStrokeColor(Lb,BNsr,BNsg,BNsb,1) setNextStrokeWidth(Lb,1) end
  addBoxRounded(Lb,x,y,w,h,4)
  setNextTextAlign(Lt,AlignH_Center,AlignV_Middle) addText(Lt,fT,tx,x+w/2,y+h/2)
  return hv and pr
end
]]

  S[3]=[[
-- TOP NAV BAR
local tabH=C
local navTabs={
  {l="WAYPOINTS",v="wps"},
  {l=View=="stops" and ("◄ "..RouteNm:sub(1,14)) or "ROUTES",v="routes"},
  {l=Ctx and ("◄ "..(Ctx:sub(1,12))) or "ORGS",v="orgs"},
}
setNextFillColor(Lp,TBr,TBg,TBb,1) addBox(Lp,0,0,SW,tabH)
local tabW=math.floor(SW/#navTabs)
for i,tab in ipairs(navTabs) do
  local tx=(i-1)*tabW
  local active=(View==tab.v) or (View=="stops" and tab.v=="routes")
  local isBack=(View=="stops" and tab.v=="routes")
  if active then
    setNextFillColor(Lp,TAr,TAg,TAb,1) setNextStrokeColor(Lp,Ar,Ag,Ab,0.8) setNextStrokeWidth(Lp,1)
    addBox(Lp,tx,0,tabW,tabH)
  end
  local L=active and Lx or Lt
  if not active then setNextFillColor(Lt,TIr,TIg,TIb,1) end
  setNextTextAlign(L,AlignH_Center,AlignV_Middle)
  addText(L,active and fB or fT,tab.l,tx+tabW/2,tabH/2)
  if i>1 then addLine(Ll,tx,0,tx,tabH) end
  local hv=(cx>=tx and cx<tx+tabW and cy>=0 and cy<tabH)
  if hv and pr and (not active or isBack) then
    if tab.v=="wps" then setAct(json.encode({"nav_personal"}))
    else setAct(json.encode({"nav",tab.v})) end
  end
end
addLine(Ll,0,tabH,SW,tabH)
if Sending then
  setNextFillColor(Lt,Str,Stg,Stb,1) setNextTextAlign(Lt,AlignH_Right,AlignV_Middle)
  addText(Lt,fS,"⟳",SW-6,tabH/2)
end
local CON_Y=tabH+2
local FOOT_Y=SH-32
]]

  S[4]=[[
-- CONTENT AREA
local hasSel=(View=="wps" and SelName~="") or (View=="routes" and SelName~="")
           or (View=="stops" and SelIdx>0)
local actH=hasSel and 36 or 0
setNextFillColor(Lp,PHr,PHg,PHb,1) addBox(Lp,0,CON_Y,SW,C)
addLine(Ll,0,CON_Y+C,SW,CON_Y+C)
local listY=CON_Y+C
local listH=FOOT_Y-actH-listY-2
local vis=math.max(1,math.floor(listH/C))
local lW=SW-22  -- list item width (leaves room for scroll buttons)

local function ScrollBtns()
  if Total<=#Items then return end
  local upHv=(cx>=SW-20 and cx<SW and cy>=listY and cy<listY+C)
  if upHv then setNextFillColor(Lb,BHfr,BHfg,BHfb,0.9) else setNextFillColor(Lb,BNfr,BNfg,BNfb,0.5) end
  addBox(Lb,SW-20,listY,20,C-1)
  setNextFillColor(Lt,Txr,Txg,Txb,1) setNextTextAlign(Lt,AlignH_Center,AlignV_Middle)
  addText(Lt,fS,"▲",SW-10,listY+C/2)
  if upHv and pr then setAct(json.encode({"scroll",-1})) end
  local dnY=FOOT_Y-actH-C
  local dnHv=(cx>=SW-20 and cx<SW and cy>=dnY and cy<dnY+C)
  if dnHv then setNextFillColor(Lb,BHfr,BHfg,BHfb,0.9) else setNextFillColor(Lb,BNfr,BNfg,BNfb,0.5) end
  addBox(Lb,SW-20,dnY,20,C-1)
  setNextFillColor(Lt,Txr,Txg,Txb,1) setNextTextAlign(Lt,AlignH_Center,AlignV_Middle)
  addText(Lt,fS,"▼",SW-10,dnY+C/2)
  if dnHv and pr then setAct(json.encode({"scroll",1})) end
end

if View=="wps" then
  setNextFillColor(Lx,Hdr,Hdg,Hdb,1) setNextTextAlign(Lx,AlignH_Left,AlignV_Middle)
  addText(Lx,fH," WAYPOINTS ["..Total.."]  "..(Ctx or "Personal"),8,CON_Y+C/2)
  if SelName~="" and d.sel_c and d.sel_c~="" then
    setNextFillColor(Lt,DMr,DMg,DMb,0.85) setNextTextAlign(Lt,AlignH_Right,AlignV_Middle)
    addText(Lt,fS,d.sel_c.."  ",lW,CON_Y+C/2)
  end
  ScrollBtns()
  for i,wp in ipairs(Items) do
    local ry=listY+(i-1)*C
    if ry+C>FOOT_Y-actH then break end
    local absIdx=i+(d.scroll or 0)
    local sel=(wp.n==SelName)
    local hv=(cx>=0 and cx<lW and cy>=ry and cy<ry+C)
    if sel then
      setNextFillColor(Lp,SLr,SLg,SLb,0.22) setNextStrokeColor(Lp,Ar,Ag,Ab,0.9) setNextStrokeWidth(Lp,1) addBox(Lp,0,ry,lW,C)
    elseif hv then setNextFillColor(Lp,1,1,1,0.04) addBox(Lp,0,ry,lW,C) end
    setNextFillColor(Lt,NMr,NMg,NMb,1) setNextTextAlign(Lt,AlignH_Right,AlignV_Middle) addText(Lt,fS,absIdx..".",26,ry+C/2)
    local Ln=sel and Ls or Lt
    if sel then setNextFillColor(Ls,Nr,Ng,Nb,1) end
    setNextTextAlign(Ln,AlignH_Left,AlignV_Middle) addText(Ln,fT,wp.n,30,ry+C/2)
    local coord_mark=wp.hc and "●" or "—"
    setNextFillColor(Lt,wp.hc and DMr or NMr, wp.hc and DMg or NMg, wp.hc and DMb or NMb,0.6)
    setNextTextAlign(Lt,AlignH_Right,AlignV_Middle) addText(Lt,fS,coord_mark,lW-2,ry+C/2)
    setNextStrokeColor(Ll,Lnr,Lng,Lnb,0.15) addLine(Ll,0,ry+C,SW,ry+C)
    if hv and pr then setAct(json.encode({"sel",wp.n})) end
  end

elseif View=="routes" then
  setNextFillColor(Lx,Hdr,Hdg,Hdb,1) setNextTextAlign(Lx,AlignH_Left,AlignV_Middle)
  addText(Lx,fH," ROUTES ["..Total.."]  "..(Ctx or "Personal"),8,CON_Y+C/2)
  ScrollBtns()
  for i,r in ipairs(Items) do
    local ry=listY+(i-1)*C
    if ry+C>FOOT_Y-actH then break end
    local sel=(r.n==SelName)
    local hv=(cx>=0 and cx<lW and cy>=ry and cy<ry+C)
    if sel then
      setNextFillColor(Lp,Rtdr,Rtdg,Rtdb,0.22) setNextStrokeColor(Lp,Rtr,Rtg,Rtb,0.9) setNextStrokeWidth(Lp,1) addBox(Lp,0,ry,lW,C)
    elseif hv then setNextFillColor(Lp,1,1,1,0.04) addBox(Lp,0,ry,lW,C) end
    local Ln=sel and Ls or Lt
    if sel then setNextFillColor(Ls,Rtlr,Rtlg,Rtlb,1) end
    setNextTextAlign(Ln,AlignH_Left,AlignV_Middle) addText(Ln,fT,r.n,8,ry+C/2)
    setNextFillColor(Lt,Rtdr,Rtdg,Rtdb,1) setNextTextAlign(Lt,AlignH_Right,AlignV_Middle)
    addText(Lt,fT,(r.pc or 0).." ▶",lW-4,ry+C/2)
    setNextStrokeColor(Ll,Lnr,Lng,Lnb,0.15) addLine(Ll,0,ry+C,SW,ry+C)
    if hv and pr then setAct(json.encode({"sel",r.n})) end
  end

elseif View=="stops" then
  setNextFillColor(Lh,Ar,Ag,Ab,1) setNextTextAlign(Lh,AlignH_Left,AlignV_Middle)
  addText(Lh,fH," "..RouteNm.."  ["..Total.." stops]",8,CON_Y+C/2)
  ScrollBtns()
  for i,st in ipairs(Items) do
    local ry=listY+(i-1)*C
    if ry+C>FOOT_Y-actH then break end
    local absIdx=i+(d.scroll or 0)
    local sel=(SelIdx==absIdx)
    local hv=(cx>=0 and cx<lW and cy>=ry and cy<ry+C)
    if sel then
      setNextFillColor(Lp,SLr,SLg,SLb,0.22) setNextStrokeColor(Lp,Ar,Ag,Ab,0.9) setNextStrokeWidth(Lp,1) addBox(Lp,0,ry,lW,C)
    elseif hv then setNextFillColor(Lp,1,1,1,0.04) addBox(Lp,0,ry,lW,C) end
    local lbl=(st.label and st.label~="") and st.label or ""
    setNextFillColor(Lt,NMr,NMg,NMb,1) setNextTextAlign(Lt,AlignH_Right,AlignV_Middle) addText(Lt,fS,absIdx..".",26,ry+C/2)
    local Ln=sel and Ls or Lt
    if sel then setNextFillColor(Ls,Nr,Ng,Nb,1) end
    setNextTextAlign(Ln,AlignH_Left,AlignV_Middle) addText(Ln,fT,lbl~="" and lbl or (st.c or ""),30,ry+C/2)
    if lbl~="" then
      setNextFillColor(Lt,DMr,DMg,DMb,0.7) setNextTextAlign(Lt,AlignH_Right,AlignV_Middle)
      addText(Lt,fS,st.c or "",lW-2,ry+C/2)
    end
    setNextStrokeColor(Ll,Lnr,Lng,Lnb,0.15) addLine(Ll,0,ry+C,SW,ry+C)
    if hv and pr then setAct(json.encode({"sel",absIdx})) end
  end

else -- orgs view
  setNextFillColor(Lx,Hdr,Hdg,Hdb,1) setNextTextAlign(Lx,AlignH_Left,AlignV_Middle)
  addText(Lx,fH," ORGANIZATIONS",8,CON_Y+C/2)
  local bG=6 local cols=3
  local btnW=math.floor((SW-8)/cols)-bG local btnH=C+8
  if #OrgList==0 then
    setNextFillColor(Lt,DMr,DMg,DMb,1) setNextTextAlign(Lt,AlignH_Center,AlignV_Middle)
    addText(Lt,fS,"No orgs — push from a ship to register one",SW/2,listY+C)
  end
  for i,o in ipairs(OrgList) do
    local col=((i-1)%cols) local row=math.floor((i-1)/cols)
    local bx=4+col*(btnW+bG)
    local by=listY+bG+row*(btnH+bG)
    if by+btnH>FOOT_Y then break end
    local active=(Ctx==o)
    local hv=(cx>=bx and cx<bx+btnW and cy>=by and cy<by+btnH)
    if active then setNextFillColor(Lb,TAr,TAg,TAb,1) setNextStrokeColor(Lb,Ar,Ag,Ab,0.9) setNextStrokeWidth(Lb,2)
    elseif hv then setNextFillColor(Lb,BHfr,BHfg,BHfb,1) setNextStrokeColor(Lb,BHsr,BHsg,BHsb,1) setNextStrokeWidth(Lb,1)
    else setNextFillColor(Lb,BNfr,BNfg,BNfb,0.7) setNextStrokeColor(Lb,BNsr,BNsg,BNsb,0.8) setNextStrokeWidth(Lb,1) end
    addBoxRounded(Lb,bx,by,btnW,btnH,5)
    local Lo=active and Lx or Lt
    if active then setNextFillColor(Lx,Hdr,Hdg,Hdb,1) end
    setNextTextAlign(Lo,AlignH_Center,AlignV_Middle) addText(Lo,fT,o,bx+btnW/2,by+btnH/2)
    if hv and pr then setAct(json.encode({"nav_org",o})) end
  end
end
]]

  S[5]=[[
-- ACTION BAR (when item selected)
if hasSel then
  local abY=FOOT_Y-actH
  setNextFillColor(Lp,PHr,PHg,PHb,0.95) addBox(Lp,0,abY,SW,actH)
  addLine(Ll,0,abY,SW,abY)
  local bH=actH-6 local bG=4 local bx=4
  if View=="wps" then
    local bW=math.floor((SW-8-bG*4)/5)
    if Btn("ADD WP",    bx,abY+3,bW,bH,true) then setAct(json.encode({"cmd","add_wp"}))    end bx=bx+bW+bG
    if Btn("RENAME",    bx,abY+3,bW,bH,true) then setAct(json.encode({"cmd","rename"}))    end bx=bx+bW+bG
    if Btn("SET COORDS",bx,abY+3,bW,bH,true) then setAct(json.encode({"cmd","set_coords"}))end bx=bx+bW+bG
    if Btn("PRINT",     bx,abY+3,bW,bH,true) then setAct(json.encode({"cmd","print"}))     end bx=bx+bW+bG
    if Btn("DELETE",    bx,abY+3,bW,bH,true) then setAct(json.encode({"cmd","delete"}))    end
  elseif View=="routes" then
    local bW=math.floor((SW-8-bG*4)/5)
    if Btn("NEW ROUTE", bx,abY+3,bW,bH,true) then setAct(json.encode({"cmd","new_route"})) end bx=bx+bW+bG
    if Btn("STOPS ▶",   bx,abY+3,bW,bH,true) then setAct(json.encode({"cmd","open_stops"}))end bx=bx+bW+bG
    if Btn("RENAME",    bx,abY+3,bW,bH,true) then setAct(json.encode({"cmd","rename"}))    end bx=bx+bW+bG
    if Btn("ADD STOP",  bx,abY+3,bW,bH,true) then setAct(json.encode({"cmd","add_stop"}))  end bx=bx+bW+bG
    if Btn("DELETE",    bx,abY+3,bW,bH,true) then setAct(json.encode({"cmd","delete"}))    end
  elseif View=="stops" then
    local bW=math.floor((SW-8-bG*4)/5)
    if Btn("ADD STOP",   bx,abY+3,bW,bH,true)     then setAct(json.encode({"cmd","add_stop"}))  end bx=bx+bW+bG
    if Btn("RENAME",     bx,abY+3,bW,bH,SelIdx>0) then setAct(json.encode({"cmd","rename"}))    end bx=bx+bW+bG
    if Btn("SET COORDS", bx,abY+3,bW,bH,SelIdx>0) then setAct(json.encode({"cmd","set_coords"}))end bx=bx+bW+bG
    if Btn("PRINT",      bx,abY+3,bW,bH,SelIdx>0) then setAct(json.encode({"cmd","print"}))     end bx=bx+bW+bG
    if Btn("DEL STOP",   bx,abY+3,bW,bH,SelIdx>0) then setAct(json.encode({"cmd","delete"}))    end
  end
end
]]

  S[6]=[[
-- FOOTER
addLine(Ll,0,FOOT_Y,SW,FOOT_Y)
setNextFillColor(Lp,FTr,FTg,FTb,0.95) addBox(Lp,0,FOOT_Y,SW,32)
local thX=SW-80 local thW=72 local thY=FOOT_Y+5 local thH=22
local thHv=(cx>=thX and cx<thX+thW and cy>=thY and cy<thY+thH)
if thHv then setNextFillColor(Lb,BHfr,BHfg,BHfb,0.8) setNextStrokeColor(Lb,BHsr,BHsg,BHsb,0.8)
else setNextFillColor(Lb,BNfr,BNfg,BNfb,0.6) setNextStrokeColor(Lb,BNsr,BNsg,BNsb,0.6) end
setNextStrokeWidth(Lb,1) addBoxRounded(Lb,thX,thY,thW,thH,3)
setNextTextAlign(Lt,AlignH_Center,AlignV_Middle) addText(Lt,fS,"THEME",thX+thW/2,thY+thH/2)
if thHv and pr then setAct(json.encode({"open_theme"})) end
if Pending~="" then
  setNextFillColor(Lt,Str,Stg,Stb,1) setNextTextAlign(Lt,AlignH_Left,AlignV_Middle)
  addText(Lt,fT,"► "..Pending,8,FOOT_Y+16)
elseif Status~="" then
  setNextFillColor(Lt,Str,Stg,Stb,1) setNextTextAlign(Lt,AlignH_Left,AlignV_Middle)
  addText(Lt,fT,Status,8,FOOT_Y+16)
else
  setNextFillColor(Lt,DMr,DMg,DMb,1) setNextTextAlign(Lt,AlignH_Left,AlignV_Middle)
  addText(Lt,fS,"NAV BASE v2.3  |  chat: help",8,FOOT_Y+16)
end
setOutput(json.encode({a=_S.action}))
requestAnimationFrame(2)
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
local fT=loadFont("Montserrat-Light",math.floor(SH*0.031))
local fS=loadFont("Montserrat-Light",math.floor(SH*0.022))
local fH=loadFont("Montserrat-Light",math.floor(SH*0.035))
local fB=loadFont("Montserrat-Light",math.floor(SH*0.042))
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
if clHv and pr then Out=json.encode({"theme_close"}) end
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
  if hv and pr then Out=json.encode({"theme_sel_elem",i}) end
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
  Out=json.encode({"theme_set_hue",h})
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
  Out=json.encode({"theme_set_sv",ns,nv})
end
]]

  local vpX = 214 + 256 + 8  -- svX + svW + 8 (must match render-script layout in S[3])

  S[6]=string.format([[
-- VALUES & PREVIEW
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


--[[@
slot=-5
event=onStart()
args=
]]
function Trim(s) return (s or ""):match("^%s*(.-)%s*$") end
function ParsePos(s)
  if not s or s=="" then return nil end
  local w,b,x,y,z=s:match("::pos{(%d+),(%d+),([-%.%d]+),([-%.%d]+),([-%.%d]+)}")
  if x then return {w=tonumber(w),b=tonumber(b),x=tonumber(x),y=tonumber(y),z=tonumber(z)} end
  return nil
end
function SetStatus(msg,dur)
  StatusMsg=msg; StatusExpiry=system.getArkTime()+(dur or 6)
  system.print("[BASE] "..msg)
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

function DefaultBaseTheme()
  return {
    {h=195,s=1.0,v=1.0},    -- accent (cyan)
    {h=220,s=1.0,v=0.04},   -- background
    {h=0,  s=0,  v=0.82},   -- text
    {h=48, s=1.0,v=1.0},    -- header (gold)
    {h=220,s=1.0,v=0.40},   -- btnNormal
    {h=220,s=0.85,v=0.65},  -- btnHover
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
  if not databank then return DefaultBaseTheme() end
  local name=databank.getStringValue("theme_profile_active")
  if name=="" then return DefaultBaseTheme() end
  local raw=databank.getStringValue("theme_p_"..name)
  if raw=="" then return DefaultBaseTheme() end
  local ok,data=pcall(json.decode,raw)
  if not ok or not data then return DefaultBaseTheme() end
  if #data<8 then return DefaultBaseTheme() end
  for i=1,8 do
    if type(data[i])~="table" or not data[i].h then return DefaultBaseTheme() end
  end
  return data
end

function StoreThemeProfile(name,slots)
  if not databank then return end
  name=name:gsub("[^%w%s_-]",""):sub(1,20)
  if name=="" then name="Default" end
  databank.setStringValue("theme_p_"..name,json.encode(slots))
  local raw=databank.getStringValue("theme_profile_names") or "[]"
  local ok,names=pcall(json.decode,raw)
  if not ok or type(names)~="table" then names={} end
  local found=false
  for _,n in ipairs(names) do if n==name then found=true;break end end
  if not found then table.insert(names,name) end
  databank.setStringValue("theme_profile_names",json.encode(names))
  return name
end

function SaveTheme(name,slots)
  local stored=StoreThemeProfile(name,slots)
  if not databank or not stored then return end
  databank.setStringValue("theme_profile_active",stored)
end

-- Store an incoming (network) profile without clobbering a differently-named
-- collision — same name+same content is treated as already-known (no-op rename),
-- same name+different content gets auto-suffixed ("Name-2", "Name-3", ...).
function StoreThemeProfileDedup(name,slots)
  if not databank then return end
  name=name:gsub("[^%w%s_-]",""):sub(1,20)
  if name=="" then name="Default" end
  local encoded=json.encode(slots)
  local finalName=name
  if databank.getStringValue("theme_p_"..finalName)~="" and databank.getStringValue("theme_p_"..finalName)~=encoded then
    local i=2
    repeat
      finalName=name.."-"..i
      local existing=databank.getStringValue("theme_p_"..finalName)
      i=i+1
    until existing=="" or existing==encoded
  end
  return StoreThemeProfile(finalName,slots)
end

function DeleteTheme(name)
  if not databank then return end
  databank.setStringValue("theme_p_"..name,"")
  local raw=databank.getStringValue("theme_profile_names")
  if not raw or raw=="" then return end
  local ok,names=pcall(json.decode,raw)
  if not ok or type(names)~="table" then return end
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

function AutoName(prefix,list)
  local i=1
  while true do
    local c=prefix.."-"..i; local taken=false
    for _,v in ipairs(list) do if v.n:lower()==c:lower() then taken=true;break end end
    if not taken then return c end; i=i+1
  end
end


--[[@
slot=-1
event=onStart()
args=
]]

-- ── Slot auto-detect ────────────────────────────────────────────
-- Link Screen, Databank, Receiver, Emitter to ANY of the PB's slots, in any
-- order — same technique as the ship PBs (see src/ship_noscreen.lua for the
-- full write-up). Check the Lua console on startup ("[BASE] slot1=...") to
-- confirm what got detected.
do
  -- Primary check: DU's own type introspection. getElementClass() (confirmed
  -- present on a "Modern Screen xs" via a live field dump, 2026-09-06)
  -- logs a deprecation warning in-game telling scripts to use getClass()
  -- instead — try that first, fall back to the deprecated name for older
  -- game versions that might not have getClass() yet. Either way the
  -- returned string gets a lowercase substring match, robust to exact
  -- naming we haven't seen across other screen/receiver/emitter variants.
  local function classOf(s)
    local ok,cls=pcall(function() return s.getClass() end)
    if ok and type(cls)=="string" then return cls:lower() end
    ok,cls=pcall(function() return s.getElementClass() end)
    if ok and type(cls)=="string" then return cls:lower() end
    return nil
  end
  local function probe(s)
    if not s then return nil end
    local cls=classOf(s)
    if cls then
      if cls:find("screen")   then return "screen" end
      if cls:find("databank") then return "databank" end
      if cls:find("receiver") then return "receiver" end
      if cls:find("emitter")  then return "emitter" end
    end
    -- Fallback for class names this doesn't recognize, or if
    -- getElementClass() itself isn't available on some element. Previously
    -- getRenderScript()/getScriptInput() were the primary screen check —
    -- confirmed via that field dump that NEITHER getter actually exists on
    -- a "Modern Screen xs" (only the setter halves do), which is why the
    -- old capability-probe silently misclassified a real screen as
    -- "unrecognized". getScriptOutput() (the real read counterpart DU
    -- screens expose) is checked first here as the better fallback.
    if pcall(function() return s.getScriptOutput() end)
      or pcall(function() return s.getRenderScript() end)
      or pcall(function() return s.getScriptInput() end) then return "screen" end
    if pcall(function() return s.getChannelList() end) then return "receiver" end
    if pcall(function() return s.getKeyList() end)      then return "databank" end
    return "emitter"
  end
  -- Best-effort: read the element's in-game display name (works if you've
  -- renamed it via right-click -> Rename). Wrapped in pcall so if this isn't
  -- the right method on some element type, it just silently returns nil.
  local function tryName(s)
    local ok,n=pcall(function() return s.getName() end)
    if ok and n and n~="" then return n end
    return nil
  end
  -- Literal slotN references only — DU's sandbox does not support building
  -- these names dynamically (e.g. _ENV["slot"..i]) and silently fails.
  local raw={slot1,slot2,slot3,slot4,slot5,slot6,slot7,slot8,slot9,slot10}
  for i,s in ipairs(raw) do
    local kind=probe(s)
    if kind=="databank" and not databank then databank=s
    elseif kind=="receiver" and not receiver then receiver=s
    elseif kind=="emitter"  and not emitter  then emitter=s
    elseif kind=="screen"   and not screen   then screen=s
    end
  end
  local dbg={}
  for i,s in ipairs(raw) do
    local role=(s==databank and "databank") or (s==receiver and "receiver")
      or (s==emitter and "emitter") or (s==screen and "screen") or "unrecognized"
    local nm=tryName(s)
    local cls=(role=="unrecognized") and classOf(s) or nil
    table.insert(dbg,"slot"..i.."="..role..(nm and ("("..nm..")") or "")..(cls and ("[class:"..cls.."]") or ""))
  end
  system.print("[BASE] "..(#dbg>0 and table.concat(dbg,"  ") or "no slots linked"))
end

local VERSION="v2.2.0"
BaseChannel = "NavBase" --export: Channel ships use to reach this base

WaypointList = {}
RouteList    = {}
OrgNames     = {}   -- ordered list of org names
OrgData      = {}   -- {[name]={channel,wps,routes}}
PullQueue    = {}   -- [{org,channel},...] for syncorgs (legacy, unused)
PullQueueIdx = 1
PullOrgName  = nil  -- org currently being pulled (syncorgs)
PullStaging  = nil  -- {wps,routes} staging buffer for current pull
PushOrgName  = nil  -- org context during a ship→base push with org data
SelWP        = ""   -- full name (with prefix)
SelRoute     = ""   -- full name (with prefix)
SelStop      = 0
OrgContext   = nil  -- nil=personal, else org name string
ActiveView   = "wps" -- "wps"|"routes"|"stops"|"orgs"
ViewScroll   = 0    -- PB-owned scroll position
PendingAction= ""   -- guided chat: "add_wp"|"rename"|"set_coords"|"new_route"|"add_stop"
PendingTarget= ""   -- item name context for pending action
AllowedShips = {}   -- whitelist of ship IDs; empty = allow all
StatusMsg    = ""; StatusExpiry=0
SendQueue    = {}
SendIndex    = 1
Sending      = false
pending_ack  = false
LastScreenOut= ""


function LoadData()
  if not databank then WaypointList={};RouteList={};OrgNames={};OrgData={};return end
  local function jd(k) local v=databank.getStringValue(k); return (v and v~="") and json.decode(v) or nil end
  WaypointList = jd("waypoints")     or {}
  RouteList    = jd("routes")        or {}
  OrgNames     = jd("org_names")     or {}
  AllowedShips = jd("allowed_ships") or {}
  OrgData      = {}
  for _,org in ipairs(OrgNames) do
    local ch  = databank.getStringValue("org_"..org.."_ch")  or ""
    local wps = jd("org_"..org.."_wps") or {}
    local rts = jd("org_"..org.."_rts") or {}
    OrgData[org] = {channel=ch, wps=wps, routes=rts}
  end
end

function SaveData()
  if not databank then return end
  databank.setStringValue("waypoints",     json.encode(WaypointList))
  databank.setStringValue("routes",        json.encode(RouteList))
  databank.setStringValue("org_names",     json.encode(OrgNames))
  databank.setStringValue("allowed_ships", json.encode(AllowedShips))
  for _,org in ipairs(OrgNames) do
    local od=OrgData[org]
    if od then
      databank.setStringValue("org_"..org.."_ch",  od.channel or "")
      databank.setStringValue("org_"..org.."_wps", json.encode(od.wps    or {}))
      databank.setStringValue("org_"..org.."_rts", json.encode(od.routes or {}))
    end
  end
end

function UpdateChannels()
  if not receiver then return end
  local chs={BaseChannel}
  for _,org in ipairs(OrgNames) do
    local od=OrgData[org]
    if od and od.channel~="" then table.insert(chs,od.channel) end
  end
  receiver.setChannelList(chs)
end

function StartNextOrgPull()
  if PullQueueIdx>#PullQueue then
    system.print("[BASE] All org syncs complete")
    SetStatus("All orgs synced"); PushState(); return
  end
  if Sending then unit.setTimer("next_org_pull",2); return end
  local entry=PullQueue[PullQueueIdx]
  PullOrgName=nil; PullStaging={wps={},routes={}}
  system.print("[BASE] Pulling org: "..entry.channel)
  SetStatus("Syncing org: "..entry.org)
  emitter.send(entry.channel,"<RequestSync>BASE|pid:0")
  PushState()
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
      SaveData(); SetStatus("Deleted WP: "..name); return true
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
      SaveData(); SetStatus("Renamed to: "..new_); return
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
  for _,r in ipairs(RouteList) do if r.n:lower()==name:lower() then SetStatus("Route exists: "..name) return false end end
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
  SetStatus("Route not found: "..name); return false
end

function RenameRoute(old,new_)
  for _,v in ipairs(RouteList) do if v.n:lower()==new_:lower() then SetStatus("Name exists: "..new_) return end end
  for _,r in ipairs(RouteList) do
    if r.n:lower()==old:lower() then
      r.n=new_; if SelRoute==old then SelRoute=new_ end
      table.sort(RouteList,function(a,b) return a.n:lower()<b.n:lower() end)
      SaveData(); SetStatus("Renamed to: "..new_); return
    end
  end
  SetStatus("Route not found: "..old)
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

-- ── Send queue (throttled sync to ship) ──────────────────────
function StartSend(requester)
  LoadData()
  SendQueue={}
  for _,wp in ipairs(WaypointList) do
    table.insert(SendQueue,{type="wp",data={n=wp.n,c=wp.c}})
  end
  for _,r in ipairs(RouteList) do
    table.insert(SendQueue,{type="route",data={n=r.n,pts=r.pts}})
  end
  for _,tn in ipairs(GetThemeProfiles()) do
    local raw=databank.getStringValue("theme_p_"..tn)
    local ok,slots=pcall(json.decode,raw)
    if ok and slots then
      table.insert(SendQueue,{type="theme",data={n=tn,slots=slots}})
    end
  end
  for _,org in ipairs(OrgNames) do
    local od=OrgData[org]
    if od and od.channel~="" and (#od.wps>0 or #od.routes>0) then
      table.insert(SendQueue,{type="org_hdr",msg="<OrgSyncStart>"..org.."|ch:"..od.channel})
      for _,wp in ipairs(od.wps) do
        table.insert(SendQueue,{type="wp",data={n=wp.n,c=wp.c}})
      end
      for _,r in ipairs(od.routes) do
        table.insert(SendQueue,{type="route",data={n=r.n,pts=r.pts}})
      end
    end
  end
  SendIndex=1; Sending=true
  emitter.send(BaseChannel,"<SyncCount>"..#SendQueue)
  unit.setTimer("send_tick",0.2)
  SetStatus("Sending "..#SendQueue.." items to: "..requester)
  PushState()
end

-- ── Screen push ───────────────────────────────────────────────
function GetTabList()
  local t={"Personal"}
  for _,o in ipairs(OrgNames) do table.insert(t,o) end
  return t
end

function GetActiveWPs()
  if OrgContext==nil then return WaypointList end
  local od=OrgData[OrgContext]; return od and od.wps or {}
end

function GetActiveRoutes()
  if OrgContext==nil then return RouteList end
  local od=OrgData[OrgContext]; return od and od.routes or {}
end

-- Legacy aliases used by chat handler
function GetTabWPs()   return GetActiveWPs()   end
function GetTabRoutes() return GetActiveRoutes() end

local PAGE=16  -- max items sent per push

function PushState()
  if not screen then return end
  if ShowThemePicker then
    local ok,result=pcall(BuildPickerScript)
    if not ok then system.print("[BASE] picker render error: "..tostring(result)); return end
    screen.setRenderScript(result); return
  end

  local inp
  if ActiveView=="wps" then
    local all=GetActiveWPs()
    local sc=math.max(0,math.min(ViewScroll,math.max(0,#all-PAGE)))
    local items={}
    for i=sc+1,math.min(sc+PAGE,#all) do
      table.insert(items,{n=all[i].n,hc=(all[i].c~="")})
    end
    local sel_c=""
    if SelWP~="" then
      for _,wp in ipairs(all) do if wp.n:lower()==SelWP:lower() then sel_c=wp.c or ""; break end end
    end
    inp={view="wps",items=items,total=#all,scroll=sc,
         sel=SelWP,sel_c=sel_c,ctx=OrgContext,pending=PendingAction,
         status=StatusMsg,sending=Sending,ack=pending_ack}

  elseif ActiveView=="routes" then
    local all=GetActiveRoutes()
    local sc=math.max(0,math.min(ViewScroll,math.max(0,#all-PAGE)))
    local items={}
    for i=sc+1,math.min(sc+PAGE,#all) do
      table.insert(items,{n=all[i].n,pc=#(all[i].pts or {})})
    end
    inp={view="routes",items=items,total=#all,scroll=sc,
         sel=SelRoute,ctx=OrgContext,pending=PendingAction,
         status=StatusMsg,sending=Sending,ack=pending_ack}

  elseif ActiveView=="stops" then
    local stops={}
    for _,r in ipairs(GetActiveRoutes()) do
      if r.n==SelRoute then stops=r.pts; break end
    end
    local sc=math.max(0,math.min(ViewScroll,math.max(0,#stops-PAGE)))
    local items={}
    for i=sc+1,math.min(sc+PAGE,#stops) do
      table.insert(items,{c=stops[i].c,label=stops[i].label or ""})
    end
    inp={view="stops",rt=SelRoute,items=items,total=#stops,scroll=sc,
         sel=SelStop,ctx=OrgContext,pending=PendingAction,
         status=StatusMsg,ack=pending_ack}

  else -- "orgs"
    inp={view="orgs",orgs=OrgNames,ctx=OrgContext,
         status=StatusMsg,ack=pending_ack}
  end

  pending_ack=false
  local enc=json.encode(inp)
  if #enc>1024 then
    system.print("[BASE] input overflow "..#enc.."  truncating items")
    inp.items={}; enc=json.encode(inp)
  end
  screen.setScriptInput(enc)
  local ok,result=pcall(BuildScreenScript)
  if not ok then system.print("[BASE] render error: "..tostring(result)); return end
  screen.setRenderScript(result)
end

-- ── Init ──────────────────────────────────────────────────────
LoadData()
ThemeSlots=LoadTheme()
Palette=DeriveTheme(ThemeSlots)
UpdateChannels()
unit.setTimer("heartbeat",30)
unit.setTimer("screen_init",1)
unit.setTimer("screen_poll",0.05)
system.print("=== Nav Base "..VERSION.." ===  WPs:"..#WaypointList.."  Routes:"..#RouteList)
system.print("Orgs cached: "..#OrgNames)
ActiveView="wps"; OrgContext=nil; ViewScroll=0
PendingAction=""; PendingTarget=""
if screen then screen.activate() end
PushState()


--[[@
slot=-1
event=onStop()
args=
]]
if screen then
  if not Palette then Palette=DeriveTheme(ThemeSlots or DefaultBaseTheme()) end
  local P=Palette
  screen.setRenderScript(string.format([[
local Lbg=createLayer() local Lt=createLayer()
local SW,SH=getResolution()
setNextFillColor(Lbg,%f,%f,%f,1) addBox(Lbg,0,0,SW,SH)
local fB=loadFont("Montserrat-Light",22) local fS=loadFont("Montserrat-Light",14)
setNextFillColor(Lt,%f,%f,%f,1) setNextTextAlign(Lt,AlignH_Center,AlignV_Middle)
addText(Lt,fB,"NAV BASE",SW/2,SH/2-14)
setNextFillColor(Lt,%f,%f,%f,1) setNextTextAlign(Lt,AlignH_Center,AlignV_Middle)
addText(Lt,fS,"Offline — activate PB to start",SW/2,SH/2+14)
]], P.bgr,P.bgg,P.bgb, P.ar,P.ag,P.ab, P.txr*0.5,P.txg*0.5,P.txb*0.5))
end


--[[@
slot=-1
event=onTimer(tag)
args="screen_init"
]]
unit.stopTimer("screen_init")
PushState()


--[[@
slot=-1
event=onTimer(tag)
args="send_tick"
]]
if not Sending then return end
if SendIndex>#SendQueue then
  emitter.send(BaseChannel,"<SyncComplete>")
  Sending=false
  SetStatus("Sync complete ("..#SendQueue.." items sent)")
  PushState(); return
end
local item=SendQueue[SendIndex]
if item.type=="wp" then
  emitter.send(BaseChannel,"<SyncWP>"..json.encode(item.data):gsub('"',"@@@"))
elseif item.type=="route" then
  emitter.send(BaseChannel,"<SyncRoute>"..json.encode(item.data):gsub('"',"@@@"))
elseif item.type=="theme" then
  emitter.send(BaseChannel,"<SyncTheme>"..json.encode(item.data):gsub('"',"@@@"))
elseif item.type=="org_hdr" then
  emitter.send(BaseChannel,item.msg)
end
SendIndex=SendIndex+1


--[[@
slot=-1
event=onTimer(tag)
args="heartbeat"
]]
if StatusMsg~="" and system.getArkTime()>StatusExpiry then StatusMsg=""; PushState() end
UpdateChannels()
system.print("[BASE] Alive  WPs:"..#WaypointList.."  Routes:"..#RouteList.."  Orgs:"..#OrgNames)


--[[@
slot=-1
event=onTimer(tag)
args="next_org_pull"
]]
unit.stopTimer("next_org_pull")
StartNextOrgPull()


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

-- Theme picker mode: output is a JSON array like ["theme_close"]
if ShowThemePicker then
  local act=d[1] or ""
  if act=="" then PushState(); return end
  if     act=="theme_close"    then ShowThemePicker=false
  elseif act=="theme_sel_elem" then PickerElem=d[2] or 1
  elseif act=="theme_set_hue"  then
    local h=d[2] or 0
    ThemeSlots[PickerElem].h=h; RefreshTheme()
  elseif act=="theme_set_sv"   then
    local s,v=d[2] or 0.5, d[3] or 0.5
    ThemeSlots[PickerElem].s=math.max(0,math.min(1,s))
    ThemeSlots[PickerElem].v=math.max(0,math.min(1,v))
    RefreshTheme()
  elseif act=="theme_save"     then
    SaveTheme(GetActiveProfileName(),ThemeSlots)
    SetStatus("Theme saved: "..GetActiveProfileName())
  elseif act=="theme_load"     then
    local name=d[2] or ""
    local raw2=databank and databank.getStringValue("theme_p_"..name) or ""
    if raw2~="" then
      local ok2,data=pcall(json.decode,raw2)
      if ok2 and data and #data>=8 then
        ThemeSlots=data
        databank.setStringValue("theme_profile_active",name)
        RefreshTheme()
        SetStatus("Loaded: "..name)
      end
    else SetStatus("Profile not found: "..name) end
  elseif act=="theme_new"      then
    local names=GetThemeProfiles()
    local newName="Theme "..#names+1
    SaveTheme(newName,ThemeSlots)
    SetStatus("Created: "..newName.." (chat: theme rename NAME)")
  elseif act=="theme_delete"   then
    local name=GetActiveProfileName()
    DeleteTheme(name)
    ThemeSlots=LoadTheme(); RefreshTheme()
    SetStatus("Deleted: "..name)
  elseif act=="theme_reset"    then
    ThemeSlots=DefaultBaseTheme(); RefreshTheme()
    SaveTheme(GetActiveProfileName(),ThemeSlots)
    SetStatus("Theme reset to defaults")
  end
  PushState(); return
end

-- Main screen mode: output is {a=action}
if not d.a or d.a=="" then PushState(); return end
pending_ack=true

local ok2,act=pcall(json.decode,d.a)
if not ok2 or type(act)~="table" then PushState(); return end
local cmd=act[1]

-- Navigation
if cmd=="nav" then
  local v=act[2]
  if v=="routes" and ActiveView=="stops" then
    -- back from stops to routes list
    ActiveView="routes"; SelStop=0; ViewScroll=0
  else
    ActiveView=v; SelWP=""; SelRoute=""; SelStop=0; ViewScroll=0
  end

elseif cmd=="nav_personal" then
  OrgContext=nil; SelWP=""; SelRoute=""; SelStop=0; ViewScroll=0
  ActiveView="wps"

elseif cmd=="nav_org" then
  OrgContext=act[2]; SelWP=""; SelRoute=""; SelStop=0; ViewScroll=0
  if ActiveView=="orgs" then ActiveView="wps" end

elseif cmd=="scroll" then
  local all = ActiveView=="wps" and GetActiveWPs()
           or ActiveView=="routes" and GetActiveRoutes()
           or ActiveView=="stops" and (function()
                for _,r in ipairs(GetActiveRoutes()) do
                  if r.n==SelRoute then return r.pts end
                end; return {}
              end)()
           or {}
  local maxScroll=math.max(0,#all-PAGE)
  ViewScroll=math.max(0,math.min(ViewScroll+(act[2] or 0),maxScroll))

elseif cmd=="sel" then
  if ActiveView=="wps" then
    SelWP=(SelWP==act[2] and "" or act[2]); SelRoute=""; SelStop=0
  elseif ActiveView=="routes" then
    SelRoute=(SelRoute==act[2] and "" or act[2]); SelWP=""; SelStop=0
  elseif ActiveView=="stops" then
    SelStop=(SelStop==act[2] and 0 or act[2])
  end

-- Guided chat actions (buttons set pending, user types the data)
elseif cmd=="cmd" then
  local c=act[2]
  if c=="add_wp" then
    PendingAction="add_wp"; PendingTarget=""
    SetStatus("Type WP name in chat",30)
  elseif c=="rename" then
    if SelWP~="" then PendingAction="rename"; PendingTarget=SelWP
    elseif SelRoute~="" and SelStop==0 then PendingAction="rename"; PendingTarget=SelRoute
    elseif SelStop>0 then PendingAction="rename"; PendingTarget=tostring(SelStop) end
    if PendingAction~="" then SetStatus("Type new name in chat",30) end
  elseif c=="set_coords" then
    if SelWP~="" then PendingAction="set_coords"; PendingTarget=SelWP
    elseif SelStop>0 then PendingAction="set_coords"; PendingTarget=tostring(SelStop) end
    if PendingAction~="" then SetStatus("Type ::pos{} in chat",30) end
  elseif c=="new_route" then
    PendingAction="new_route"; PendingTarget=""
    SetStatus("Type route name in chat",30)
  elseif c=="add_stop" then
    if SelRoute~="" then
      PendingAction="add_stop"; PendingTarget=SelRoute
      SetStatus("Type WP name or ::pos{} in chat",30)
    end
  elseif c=="open_stops" then
    if SelRoute~="" then ActiveView="stops"; SelStop=0; ViewScroll=0 end
  elseif c=="print" then
    if SelWP~="" then
      for _,wp in ipairs(GetActiveWPs()) do
        if wp.n==SelWP then
          system.print("[WP] "..wp.n..(OrgContext and "  ("..OrgContext..")" or ""))
          system.print(wp.c)
          break
        end
      end
    elseif SelStop>0 then
      for _,r in ipairs(GetActiveRoutes()) do
        if r.n==SelRoute and r.pts[SelStop] then
          local s=r.pts[SelStop]
          local lbl=(s.label and s.label~="") and s.label or ("Stop "..SelStop)
          system.print("[ROUTE] "..SelRoute.."  stop "..SelStop..": "..lbl)
          system.print(s.c)
          break
        end
      end
    end
  elseif c=="delete" then
    if ActiveView=="wps" and SelWP~="" then
      if OrgContext==nil then DelWP(SelWP); SelWP=""
      else
        local od=OrgData[OrgContext]
        if od then for i,wp in ipairs(od.wps) do if wp.n==SelWP then table.remove(od.wps,i);break end end
          SaveData(); SetStatus("Deleted WP: "..SelWP); SelWP="" end
      end
    elseif ActiveView=="routes" and SelRoute~="" then
      if OrgContext==nil then DelRoute(SelRoute); SelRoute=""; SelStop=0
      else
        local od=OrgData[OrgContext]
        if od then for i,r in ipairs(od.routes) do if r.n==SelRoute then table.remove(od.routes,i);break end end
          SaveData(); SetStatus("Deleted route: "..SelRoute); SelRoute=""; SelStop=0 end
      end
    elseif ActiveView=="stops" and SelStop>0 then
      if OrgContext==nil then DelStop(SelRoute,SelStop); SelStop=0
      else
        local od=OrgData[OrgContext]
        if od then for _,r in ipairs(od.routes) do if r.n==SelRoute then table.remove(r.pts,SelStop);break end end
          SaveData(); SetStatus("Stop removed"); SelStop=0 end
      end
    end
  end

elseif cmd=="open_theme" then
  ShowThemePicker=true
  local sn=GetActiveProfileName()
  if databank and databank.getStringValue("theme_p_"..sn)==""  then SaveTheme(sn,ThemeSlots) end
end
PushState()


--[[@
slot=2
event=onReceived(channel,message)
args=*,*
]]
-- Org channel responses (from org sync PBs during syncorgs pull)
if channel~=BaseChannel then
  if message:find("<OrgName>",1,true) then
    local orgName=Trim(message:gsub("<OrgName>",""))
    -- Find which pull queue entry this channel belongs to and resolve real org name
    for _,e in ipairs(PullQueue) do
      if e.channel==channel then
        if orgName~=e.org then
          -- Real org name differs from placeholder — rename the OrgNames entry
          local found=false
          for i,o in ipairs(OrgNames) do
            if o==e.org then OrgNames[i]=orgName; OrgData[orgName]=OrgData[e.org]; OrgData[e.org]=nil; found=true; break end
          end
          if not found then OrgData[orgName]={channel=channel,wps={},routes={}} end
          e.org=orgName
        end
        PullOrgName=orgName
        PullStaging={wps={},routes={}}
        system.print("[BASE] Org pull: "..channel.." → "..orgName)
        break
      end
    end
  elseif message:find("<SyncWP>",1,true) and PullOrgName and PullStaging then
    local raw=message:gsub("<SyncWP>",""):gsub("@@@",'"')
    local ok,wp=pcall(json.decode,raw)
    if ok and wp and wp.n and wp.c then table.insert(PullStaging.wps,{n=wp.n,c=wp.c}) end
  elseif message:find("<SyncRoute>",1,true) and PullOrgName and PullStaging then
    local raw=message:gsub("<SyncRoute>",""):gsub("@@@",'"')
    local ok,r=pcall(json.decode,raw)
    if ok and r and r.n then table.insert(PullStaging.routes,r) end
  elseif message:find("<SyncComplete>",1,true) and PullOrgName then
    table.sort(PullStaging.wps,    function(a,b) return a.n:lower()<b.n:lower() end)
    table.sort(PullStaging.routes, function(a,b) return a.n:lower()<b.n:lower() end)
    if not OrgData[PullOrgName] then OrgData[PullOrgName]={} end
    OrgData[PullOrgName].channel = channel
    OrgData[PullOrgName].wps     = PullStaging.wps
    OrgData[PullOrgName].routes  = PullStaging.routes
    local n=#PullStaging.wps; local m=#PullStaging.routes
    system.print("[BASE] Org pull done: "..PullOrgName.."  WPs:"..n.."  Routes:"..m)
    SaveData(); PushState()
    PullOrgName=nil; PullStaging=nil
    PullQueueIdx=PullQueueIdx+1
    SetStatus("Org synced: "..(n+m).." items")
    unit.setTimer("next_org_pull",1)
  end
  return
end

-- BaseChannel messages
if message:find("<OrgSyncStart>",1,true) then
  local body=message:gsub("<OrgSyncStart>","")
  local orgName=body:match("^(.+)|ch:") or body
  local orgCh=body:match("|ch:(.+)$") or ""
  -- Ensure org entry exists
  local found=false
  for _,o in ipairs(OrgNames) do if o==orgName then found=true; break end end
  if not found then
    -- Check if an entry with this channel exists under a different name
    for i,o in ipairs(OrgNames) do
      if OrgData[o] and OrgData[o].channel==orgCh then
        OrgData[orgName]=OrgData[o]; OrgData[o]=nil; OrgNames[i]=orgName; found=true; break
      end
    end
    if not found then
      table.insert(OrgNames,orgName)
      OrgData[orgName]={channel=orgCh,wps={},routes={}}
    end
  end
  if OrgData[orgName] then OrgData[orgName].channel=orgCh end
  PushOrgName=orgName
  system.print("[BASE] Incoming org data: "..orgName)
end

if message:find("<PushWP>",1,true) then
  local raw=message:gsub("<PushWP>",""):gsub("@@@",'"')
  local ok,wp=pcall(json.decode,raw)
  if ok and wp and wp.n and wp.c then
    if PushOrgName and OrgData[PushOrgName] then
      local list=OrgData[PushOrgName].wps
      local found=false
      for _,e in ipairs(list) do if e.n:lower()==wp.n:lower() then e.c=wp.c;found=true;break end end
      if not found then table.insert(list,{n=wp.n,c=wp.c}) end
    else
      MergeWP(wp.n,wp.c)
    end
    SetStatus("Received WP: "..wp.n); PushState()
  end
end

if message:find("<PushRoute>",1,true) then
  local raw=message:gsub("<PushRoute>",""):gsub("@@@",'"')
  local ok,r=pcall(json.decode,raw)
  if ok and r and r.n then
    if PushOrgName and OrgData[PushOrgName] then
      local list=OrgData[PushOrgName].routes
      local found=false
      for i,e in ipairs(list) do if e.n:lower()==r.n:lower() then list[i]=r;found=true;break end end
      if not found then table.insert(list,r) end
    else
      MergeRoute(r)
    end
    SetStatus("Received route: "..r.n); PushState()
  end
end

if message:find("<PushTheme>",1,true) then
  local raw=message:gsub("<PushTheme>",""):gsub("@@@",'"')
  local ok,th=pcall(json.decode,raw)
  if ok and th and th.n and th.slots and #th.slots==8 then
    local stored=StoreThemeProfileDedup(th.n,th.slots)
    SetStatus("Received theme: "..(stored or th.n)); PushState()
  end
end

if message:find("<SyncComplete>",1,true) then
  if PushOrgName and OrgData[PushOrgName] then
    table.sort(OrgData[PushOrgName].wps,    function(a,b) return a.n:lower()<b.n:lower() end)
    table.sort(OrgData[PushOrgName].routes, function(a,b) return a.n:lower()<b.n:lower() end)
    system.print("[BASE] Org push complete: "..PushOrgName)
    PushOrgName=nil
  end
  SaveData(); PushState()
end

if message:find("<RequestSync>",1,true) then
  if Sending then return end
  local raw=message:gsub("<RequestSync>","")
  local shipID=raw:match("^([^|]+)") or raw
  local pname=raw:match("|pname:(.+)$") or ""
  if #AllowedShips>0 then
    local ok=false
    for _,s in ipairs(AllowedShips) do
      local sl=s:lower()
      if sl==shipID:lower() or (pname~="" and sl==pname:lower()) then ok=true; break end
    end
    if not ok then
      local label=shipID..(pname~="" and " ("..pname..")" or "")
      system.print("[BASE] Sync denied: "..label)
      return
    end
  end
  PushOrgName=nil  -- reset context for new sync session
  StartSend(shipID..(pname~="" and " ("..pname..")" or ""))
end


--[[@
slot=-4
event=onInputText(text)
args=*
]]
local t=Trim(text); local lo=t:lower()

-- ── Guided chat: consume pending action ──────────────────────
if PendingAction~="" then
  local pa=PendingAction; local pt=PendingTarget
  PendingAction=""; PendingTarget=""
  if pa=="add_wp" then
    if ActiveView=="wps" then
      if OrgContext==nil then AddWP(t,"") -- coords will be blank, user can setpos after
      else
        local od=OrgData[OrgContext]
        if od then table.insert(od.wps,{n=t,c=""}); SaveData(); SetStatus("WP added: "..t) end
      end
    end
  elseif pa=="rename" then
    if ActiveView=="stops" and SelStop>0 then
      -- rename the stop's label
      local routes=GetActiveRoutes()
      for _,r in ipairs(routes) do
        if r.n==SelRoute and r.pts[SelStop] then
          r.pts[SelStop].label=t; SaveData(); SetStatus("Stop renamed: "..t); break
        end
      end
    elseif OrgContext==nil then
      if ActiveView=="wps" and SelWP~="" then RenameWP(pt,t)
      elseif ActiveView=="routes" and SelRoute~="" then RenameRoute(pt,t) end
    else
      local od=OrgData[OrgContext]
      if od then
        if ActiveView=="wps" then
          for _,wp in ipairs(od.wps) do if wp.n==pt then wp.n=t;SelWP=t;break end end
        else
          for _,r in ipairs(od.routes) do if r.n==pt then r.n=t;SelRoute=t;break end end
        end
        SaveData(); SetStatus("Renamed to: "..t)
      end
    end
  elseif pa=="set_coords" then
    if not ParsePos(t) then SetStatus("Bad coords — need ::pos{0,0,x,y,z}",8); PushState(); return end
    if ActiveView=="wps" and pt~="" then
      if OrgContext==nil then SetWPCoords(pt,t)
      else
        local od=OrgData[OrgContext]
        if od then for _,wp in ipairs(od.wps) do if wp.n==pt then wp.c=t;break end end
          SaveData(); SetStatus("Coords updated") end
      end
    elseif ActiveView=="stops" then
      local idx=tonumber(pt) or 0
      for _,r in ipairs(GetActiveRoutes()) do
        if r.n==SelRoute and r.pts[idx] then
          r.pts[idx].c=t; SaveData(); SetStatus("Stop coords updated"); break
        end
      end
    end
  elseif pa=="new_route" then
    if OrgContext==nil then AddRoute(t)
    else
      local od=OrgData[OrgContext]
      if od then table.insert(od.routes,{n=t,pts={}}); SaveData(); SetStatus("Route created: "..t) end
    end
  elseif pa=="add_stop" then
    if OrgContext==nil then AddStop(pt,t)
    else
      local od=OrgData[OrgContext]
      if od then
        for _,r in ipairs(od.routes) do
          if r.n==pt then
            local c,lbl=t,t
            if not ParsePos(t) then
              local found=false
              for _,wp in ipairs(od.wps) do if wp.n:lower()==t:lower() then c=wp.c;lbl=wp.n;found=true;break end end
              if not found then SetStatus("Not a WP name or ::pos{}"); PushState(); return end
            end
            table.insert(r.pts,{c=c,label=lbl}); SaveData(); SetStatus("Stop added"); break
          end
        end
      end
    end
  end
  PushState(); return
end

if lo=="help" then
  system.print("══════════════════════════════════")
  system.print("  NAV BASE v2.2  CHAT COMMANDS")
  system.print("══════════════════════════════════")
  system.print("add NAME ::pos{..}  add/update WP on active tab")
  system.print("del                 delete selected item")
  system.print("rename NEWNAME      rename selected item")
  system.print("setpos ::pos{..}    update selected WP coords")
  system.print("newroute NAME       create route on active tab")
  system.print("addstop WPname      add stop to selected route")
  system.print("addstop ::pos{..}   add raw pos stop")
  system.print("delstop N           remove stop N")
  system.print("list                list waypoints on active tab")
  system.print("routes              list routes on active tab")
  system.print("tab NAME            switch active tab")
  system.print("listorgs            show cached orgs and counts")
  system.print("── Sync whitelist ────────────────")
  system.print("allow NAME          allow player name or ship ID")
  system.print("deny NAME           remove player name or ship ID")
  system.print("allowlist           show whitelist (empty=all allowed)")
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
  system.print("Note: ships that 'theme push' land here as new profiles automatically —")
  system.print("      no copy/paste needed. Every ship pulls them on its next sync.")
  return
end

local tabN=t:match("^[Tt][Aa][Bb]%s+(.+)")
if tabN then
  tabN=Trim(tabN)
  if tabN:lower()=="personal" then OrgContext=nil; SelWP=""; SelRoute=""; SelStop=0
  else
    for _,o in ipairs(OrgNames) do
      if o:lower()==tabN:lower() then OrgContext=o; SelWP=""; SelRoute=""; SelStop=0; break end
    end
  end
  SetStatus("Context: "..(OrgContext or "Personal")); PushState(); return
end

local addN,addC=t:match("^[Aa][Dd][Dd]%s+(.-)%s*(::pos%b{})")
if addN then
  addC=Trim(addC)
  if not ParsePos(addC) then SetStatus("Provide coords: add NAME ::pos{0,0,x,y,z}",8); PushState(); return end
  if OrgContext==nil then AddWP(addN,addC)
  else
    local od=OrgData[OrgContext]
    if od then
      local found=false
      for _,wp in ipairs(od.wps) do if wp.n:lower()==addN:lower() then wp.c=addC;found=true;break end end
      if not found then table.insert(od.wps,{n=addN,c=addC}) end
      SaveData(); SetStatus("Saved WP: "..addN)
    end
  end
  PushState(); return
end

local nrN=t:match("^[Nn][Ee][Ww][Rr][Oo][Uu][Tt][Ee]%s+(.+)")
if nrN then
  nrN=Trim(nrN)
  if OrgContext==nil then AddRoute(nrN)
  else
    local od=OrgData[OrgContext]
    if od then table.insert(od.routes,{n=nrN,pts={}}); SaveData(); SetStatus("Route created: "..nrN) end
  end
  PushState(); return
end

local rnN=t:match("^[Rr][Ee][Nn][Aa][Mm][Ee]%s+(.+)")
if rnN then
  rnN=Trim(rnN)
  if OrgContext==nil then
    if SelWP~="" then RenameWP(SelWP,rnN)
    elseif SelRoute~="" then RenameRoute(SelRoute,rnN)
    else SetStatus("Select a WP or route first") end
  else
    local od=OrgData[OrgContext]
    if od and SelWP~="" then
      for _,wp in ipairs(od.wps) do if wp.n==SelWP then wp.n=rnN;SelWP=rnN;break end end
      SaveData(); SetStatus("Renamed to: "..rnN)
    elseif od and SelRoute~="" then
      for _,r in ipairs(od.routes) do if r.n==SelRoute then r.n=rnN;SelRoute=rnN;break end end
      SaveData(); SetStatus("Renamed to: "..rnN)
    else SetStatus("Select a WP or route first") end
  end
  PushState(); return
end

local spC=t:match("^[Ss][Ee][Tt][Pp][Oo][Ss]%s+(.*)")
if spC then
  spC=Trim(spC)
  if not ParsePos(spC) then SetStatus("Bad coords"); PushState(); return end
  if SelWP~="" then SetWPCoords(SelWP,spC)
  elseif SelRoute~="" and SelStop>0 then
    for _,r in ipairs(GetActiveRoutes()) do
      if r.n==SelRoute and r.pts[SelStop] then
        r.pts[SelStop].c=spC; SaveData(); SetStatus("Stop updated")
      end
    end
  else SetStatus("Select a WP or stop first") end
  PushState(); return
end

local asA=t:match("^[Aa][Dd][Dd][Ss][Tt][Oo][Pp]%s+(.*)")
if asA then
  asA=Trim(asA)
  if SelRoute=="" then SetStatus("Select a route first"); PushState(); return end
  if OrgContext==nil then AddStop(SelRoute,asA)
  else
    local od=OrgData[OrgContext]
    if od then
      for _,r in ipairs(od.routes) do
        if r.n==SelRoute then
          local c,lbl=asA,asA
          if not ParsePos(asA) then
            local found=false
            for _,wp in ipairs(od.wps) do if wp.n:lower()==asA:lower() then c=wp.c;lbl=wp.n;found=true;break end end
            if not found then SetStatus("Not a WP name or ::pos{}"); PushState(); return end
          end
          table.insert(r.pts,{c=c,label=lbl}); SaveData(); SetStatus("Stop added"); break
        end
      end
    end
  end
  PushState(); return
end

local dsN=t:match("^[Dd][Ee][Ll][Ss][Tt][Oo][Pp]%s+(%d+)")
if dsN then
  if SelRoute=="" then SetStatus("Select a route first")
  else DelStop(SelRoute,tonumber(dsN)) end
  PushState(); return
end

if lo=="del" then
  if SelWP~="" then
    if OrgContext==nil then DelWP(SelWP); SelWP=""
    else
      local od=OrgData[OrgContext]
      if od then for i,wp in ipairs(od.wps) do if wp.n==SelWP then table.remove(od.wps,i);break end end
        SaveData(); SetStatus("Deleted: "..SelWP); SelWP="" end
    end
  elseif SelRoute~="" and SelStop>0 then
    if OrgContext==nil then DelStop(SelRoute,SelStop); SelStop=0
    else
      local od=OrgData[OrgContext]
      if od then for _,r in ipairs(od.routes) do if r.n==SelRoute then table.remove(r.pts,SelStop);break end end
        SaveData(); SetStatus("Stop removed"); SelStop=0 end
    end
  elseif SelRoute~="" then
    if OrgContext==nil then DelRoute(SelRoute); SelRoute=""; SelStop=0
    else
      local od=OrgData[OrgContext]
      if od then for i,r in ipairs(od.routes) do if r.n==SelRoute then table.remove(od.routes,i);break end end
        SaveData(); SetStatus("Deleted: "..SelRoute); SelRoute=""; SelStop=0 end
    end
  else SetStatus("Select something first") end
  PushState(); return
end

if lo=="list" then
  local ctx=OrgContext or "Personal"
  local wps=GetActiveWPs()
  system.print("─── WAYPOINTS ["..ctx.."] ("..#wps..") ───")
  for i,wp in ipairs(wps) do system.print(i..".  "..wp.n.."  "..wp.c) end
  return
end

if lo=="routes" then
  local ctx=OrgContext or "Personal"
  local rts=GetActiveRoutes()
  system.print("─── ROUTES ["..ctx.."] ("..#rts..") ───")
  for i,r in ipairs(rts) do
    system.print(i..".  "..r.n.."  ("..#r.pts.." stops)")
    for j,s in ipairs(r.pts) do system.print("    "..j..".  "..(s.label or s.c)) end
  end
  return
end

if lo=="listorgs" then
  system.print("─── ORG CACHE ("..(#OrgNames)..") ───")
  for _,o in ipairs(OrgNames) do
    local od=OrgData[o] or {}
    system.print("  "..o.."  ch:"..(od.channel or "?").."  WPs:"..(#(od.wps or {})).."  Routes:"..(#(od.routes or {})))
  end
  return
end

-- ── Sync whitelist commands ───────────────────────────────────
local allowArg=t:match("^[Aa][Ll][Ll][Oo][Ww]%s+(.+)")
if allowArg then
  allowArg=Trim(allowArg)
  for _,s in ipairs(AllowedShips) do
    if s:lower()==allowArg:lower() then SetStatus("Already allowed: "..allowArg); return end
  end
  table.insert(AllowedShips,allowArg)
  SaveData(); system.print("[BASE] Allowed: "..allowArg)
  SetStatus("Allowed: "..allowArg); PushState(); return
end

local denyArg=t:match("^[Dd][Ee][Nn][Yy]%s+(.+)")
if denyArg then
  denyArg=Trim(denyArg)
  for i,s in ipairs(AllowedShips) do
    if s:lower()==denyArg:lower() then
      table.remove(AllowedShips,i)
      SaveData(); system.print("[BASE] Removed: "..denyArg)
      SetStatus("Removed: "..denyArg); PushState(); return
    end
  end
  SetStatus("Not in list: "..denyArg); return
end

if lo=="allowlist" then
  if #AllowedShips==0 then
    system.print("[BASE] Whitelist empty — all ships allowed")
  else
    system.print("─── SYNC WHITELIST ("..(#AllowedShips)..") ───")
    for i,s in ipairs(AllowedShips) do system.print("  "..i..".  "..s) end
  end
  return
end

-- ── Theme commands ────────────────────────────────────────────
if lo:sub(1,5)=="theme" then
  local arg=Trim(t:sub(6))
  local argLo=arg:lower()

  if arg=="" or argLo=="show" or argLo=="list" then
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
    PushState(); return
  end

  -- theme save NAME
  local saveName=arg:match("^[Ss][Aa][Vv][Ee]%s+(.+)")
  if saveName then
    SaveTheme(Trim(saveName),ThemeSlots); RefreshTheme()
    SetStatus("Theme saved: "..Trim(saveName)); PushState(); return
  end
  if argLo=="save" then
    SaveTheme(GetActiveProfileName(),ThemeSlots)
    SetStatus("Saved: "..GetActiveProfileName()); PushState(); return
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
    PushState(); return
  end

  -- theme delete NAME
  local delName=arg:match("^[Dd][Ee][Ll][Ee][Tt][Ee]%s+(.+)")
  if delName then
    DeleteTheme(Trim(delName)); ThemeSlots=LoadTheme(); RefreshTheme()
    SetStatus("Deleted: "..Trim(delName)); PushState(); return
  end

  -- theme rename NAME
  local renName=arg:match("^[Rr][Ee][Nn][Aa][Mm][Ee]%s+(.+)")
  if renName then
    local oldName=GetActiveProfileName()
    local newName=Trim(renName)
    SaveTheme(newName,ThemeSlots)
    if oldName~=newName then DeleteTheme(oldName) end
    SetStatus("Renamed to: "..newName); PushState(); return
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
    SetStatus("Exported — copy the line above"); PushState(); return
  end

  -- theme import THEME:...
  local importArg=arg:match("^[Ii][Mm][Pp][Oo][Rr][Tt]%s+(.+)") or arg
  if importArg:sub(1,6)=="THEME:" then
    local iName,iSlots=ImportTheme(importArg)
    if iName and iSlots then
      ThemeSlots=iSlots; SaveTheme(iName,iSlots); RefreshTheme()
      SetStatus("Imported: "..iName)
    else SetStatus("Invalid import string") end
    PushState(); return
  end

  -- theme reset
  if argLo=="reset" then
    ThemeSlots=DefaultBaseTheme(); RefreshTheme()
    SaveTheme(GetActiveProfileName(),ThemeSlots)
    SetStatus("Theme reset to defaults"); PushState(); return
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
        PushState(); return
      end
      local rv,gv,bv=rest:match("^(%d+)%s+(%d+)%s+(%d+)$")
      if rv then
        local r,g,b=tonumber(rv)/255,tonumber(gv)/255,tonumber(bv)/255
        r,g,b=math.min(1,math.max(0,r)),math.min(1,math.max(0,g)),math.min(1,math.max(0,b))
        local h,s,v=RGB2HSV(r,g,b)
        ThemeSlots[i]={h=h,s=s,v=v}; RefreshTheme()
        SaveTheme(GetActiveProfileName(),ThemeSlots)
        SetStatus(THEME_SLOT_LABELS[i].." set to "..RGB2Hex(r,g,b))
        PushState(); return
      end
    end
  end

  SetStatus("Unknown theme command. Type: theme"); PushState(); return
end

SetStatus("Unknown: '"..lo.."'  type help"); PushState()
