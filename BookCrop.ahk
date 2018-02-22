#singleinstance, force
#Persistent
SetBatchLines -1

info =
(C
;BookCrop
Quickly crop many same sized images via an overlay preview

version 2018-02-22
By Nod5
Free Software -- http://www.gnu.org/licenses/gpl-3.0.html
Made in Windows 10

HOW TO USE
 1. Drag and drop jpeg/tif images or a folder with images
 2. BookCrop overlays them into one preview
 3. Draw a rectangle and click "crop" to crop all images

SETUP
- Install latest GraphicsMagick (Q8 version is faster)
- Get two files from libjpeg-turbo:
    - Download libjpeg-turbo-1.5.3-gcc64.exe or newer
    - Unzip the .exe with 7zip
    - browse to \bin subfolder
    - copy jpegtran.exe and libjpeg-62.dll and place next to BookCrop.exe

MORE FEATURES
Ctrl+Click and draw another rectangle to split crop to two images (L and R suffix)

Ctrl+Tab starts R L mode
Files ending with L.jpg and R.jpg are previewed and cropped separately

R/L at preview: rotate preview in 90 degree steps

S at preview: Scrub mode
Draw a rectangle to whiten that area in binarized tif input images.
Useful for scrubbing noise near inner/outer edges on book page photos.

Command line input: a folder path or image filepaths or a .txt with
one image filepath per line

Drop a folder: Process all jpg or tif in folder (whichever there is more of)

Drop a single jpg or tif: Quick preview. Move threshold slider to refresh.
Change threshold in quick preview if the overlay is too dark or light.

Important: Preview and cropping only works well on same size input images.
Advice: Use crop to subfolder, so you can redo if you overcrop.
)

xwintitle = BookCrop

;variable inventory
; x1 y1  x2 y2   = crop rectangle top left and bottom right corners:
; screenx1       = x1 relative to screen    top left
; picx1          = x1 relative to gui pic   top left
; x1             = x1 relative to gui pic   top left
; extra_x1       =  ... for extra second rectangle

; x y w h        = upscaled, relative to full image   top left
; extra_x ...    = ... for extra second rectangle

; x1 in LetUserSelectRect() = (local) ongoing rect top left relative to screen


;gui to drag drop images onto
Gui,6: font, s8 cgray
Gui,6: Add, Text,x290 y345 gsplash, ?
Gui,6: font, s12 bold
Gui,6: Add, GroupBox, x5 y2 w290 h300
if A_IsCompiled
  Gui,6: Add, Picture,x130 y75, %A_ScriptName%  ;use script icon
Gui,6: Add, Text,x78 y125 h130 w200 vtxt,Drop .jpg folder
Gui,6: Show,h360 w300 y250,%xwintitle%

checkini()
if splash = 1
  goto splash

crop_scrub := "Crop" ;default to crop mode


;parse command line parameters
if A_Args[1]
{

  ;textfile with linebreak separated image paths
  If ( SubStr(A_Args[1], -3) == ".txt" ) and FileExist(A_Args[1])
  {
    txtfile := A_Args[1]
    FileEncoding, UTF-8
    FileRead, params, *t %txtfile%  ;*t formats `n`r into `n
    goto param_started
  }

  ;else add each param to list
  Else If InStr( FileExist(A_Args[1]), "D" ) ;folder
  {
  params := A_Args[1]
  goto param_started
  }

  ;else make list of params
  for key, value in A_Args
    params .= value "`n"
  goto param_started
}


;function: read ini settings or create default ini if none exists
checkini() {
global
xini = %A_ScriptFullPath%.ini
ifnotexist, %xini%
{
xinitext =
(
[%xwintitle%]
splash=1
subdir=1
scrubdir=1
threshold=20
)
FileAppend, %xinitext%, %xini%
}
;settings from ini or default
xval = splash,subdir,scrubdir,threshold  ;default: 1,1,1,20
Loop, Parse, xval,`,
  IniRead, %A_LoopField%, %xini%, %xwintitle%, %A_LoopField%, 1
threshold := threshold > 1 and threshold <= 99 ? threshold : 20
}


#IfWinActive, BookCrop ahk_class AutoHotkeyGUI
;toggle R L mode
^Tab:: 
GuiControlGet,xt,6:,txt
txt := InStr(xt,"R L") ? "Drop .jpg folder" : "Drop .jpg folder`nto crop R L suffixed`nimages separately"
GuiControl,6:, txt, %txt%
return


;toggle scrub mode
s::
if blockshift or xext == "jpg"
  return
GuiControlGet, crop_scrub,5:, crop
crop_scrub := crop_scrub == "Crop" ? "Scrub" : "Crop"
GuiControl, 5:, crop, %crop_scrub%  ;toggle button text
GuiControl, 5: Move, crop, % (crop_scrub == "Crop") ? "w70" : "w170"
return


;rotate images before crop
r:: 
l::
GuiControlGet,button_control, 5:, Button1  ;only in pic mode
if !button_control
  return

;degrees to apply in this rotation
deg := a_thislabel == "r" ? 90 : -90

;total rotation after this. used later to rotate img before crop
totrot += deg
totrot := totrot<0 ? totrot+360 : totrot>360 ? totrot-360 : totrot  ;0 90 180 270

;case1: rotated pic height won't fit inside screen height  -> shrink preview height to fit
;case2: last rotation involved height shrink of preview    -> use original preview backup
;case3: rotated height fits and no previous height shrink  -> rotate

;case1: pic will not fit screen height, so shrink it
if (pic_w > A_ScreenHeight-145)
{
  ;backup preview, to use if rotate again
  If !FileExist(overlay "_orig.png")
  {
    FileCopy, % overlay, % overlay "_orig.png", 1
    ;backup dimensions
    orig_pic_h := pic_h , orig_pic_w := pic_w
  }

  ;new height
  pic_h := A_ScreenHeight-145
  ;extra proportion used later for extra upscale
  rot_prop := pic_h/pic_w
  ;rotate and resize
  ;note: -geometry xH makes gm pick a width that keeps aspect ratio
  Runwait  "%gm%" convert "%overlay%" -rotate %deg% -geometry x%pic_h% "%overlay%" ,,hide
  ;get new width of resized preview
  rot_Img := ComObjCreate("WIA.ImageFile")
  rot_Img.LoadFile(overlay)
  pic_w := rot_Img.Width
}

;case2: previous rotate did height shrink
else if rot_prop
{
  ;assume this step rotates back into original preview or its 180 degree mirror
  ;restore backup
  FileCopy, % overlay "_orig.png", % overlay, 1
  ;use totrot here since we're operating on the original preview image
  if (totrot != 360)
    Runwait  "%gm%" convert "%overlay%" -rotate %totrot% "%overlay%" ,,hide
  ;reuse original vars
  pic_h := orig_pic_h , pic_w := orig_pic_w
  ;clear extra rot_prop, since were back at original preview size
  rot_prop := ""
}

;case3: regular rotate
else
{
  Runwait  "%gm%" convert "%overlay%" -rotate %deg% "%overlay%" ,,hide
  ;flip vars
  stemp := pic_h , pic_h := pic_w, pic_w := stemp
}

;msgbox % "pic_h=" pic_h " | pic_w=" pic_w " | totrot=" totrot " | rot_prop=" rot_prop

x1 =
;remove all gui
Loop, 14
  Gui, %A_Index%: destroy
makegui()  ;global
return


;show help window
Tab:: goto splash

#IfWinActive


;help window
splash:
WinGetPos,mainx,mainy, mainw,, %xwintitle%
mainx += mainw

Gui 7:+LastFoundExist
IfWinExist
{
  ;close help window if already open
  gui,7: destroy
  return
}
Gui, 7: +ToolWindow -SysMenu -Caption -resize +AlwaysOnTop +0x800000 -DPIScale
Gui, 7: Font, bold s12
Gui, 7: Add, Text,, %xwintitle%
Gui, 7: Font, normal s9
Gui, 7: Add, Text,, %info%
Gui, 7: Add, Checkbox,xm Checked%splash% section vsplashbox gsplashbox, show on startup
Gui, 7: Add, Checkbox,xm Checked%subdir% section vsubdirbox gsubdirbox, crop to subfolder
Gui, 7: Add, Checkbox,xm Checked%scrubdir% section vscrubdirbox gscrubdirbox, scrub to subfolder
Gui, 7: Add, text, yp+30 x20 w55 h15,threshold
Gui, 7: Add, text, vtext yp xp+47 w20 h15,%threshold%
Gui, 7: Add, Slider, NoTicks yp+15 x11 w180 h20 vslider gslider, %threshold%
Gui, 7: Add, Link,ys xm+200,<a href="https://github.com/nod5/BookCrop">github.com/nod5/BookCrop</a>
Gui, 7: Add, Link,yp+20 xm+200,<a href="http://sourceforge.net/projects/graphicsmagick/files/graphicsmagick-binaries/">graphicsmagick.org</a>
Gui, 7: Add, Link,yp+20 xm+200,<a href="http://sourceforge.net/projects/libjpeg-turbo/files/">libjpeg-turbo</a>
Gui, 7: show, x%mainx% y%mainy%
return

;help window slider for preview binarization threshold
;single image preview mode: update preview on each slider drag
;multi image preview mode: apply threshold change next time images are dropped
slider:
Gui, Submit, NoHide
IniWrite, %slider%, %xini%, %xwintitle%, threshold
threshold := slider
GuiControl,,text, %slider%

if !single_image_mode
  return
if !FileExist(gm)
  gm := checkpaths() ;checks graphicsmagick and jpegtran, returns full gm.exe path
if !FileExist(gm)
  return
;make new threshold binarized preview
RunWait "%gm%" convert -size %pic_w%x%pic_h% "%firstfile%" -sample %pic_w%x%pic_h% -threshold %threshold%`% -transparent white -flatten "%overlay%" ,,hide
Gui,5: destroy
makegui()  ;global
return

7GuiEscape: 
gui,7: destroy
return

;helpwin checkboxes: write change to ini
splashbox: 
Gui, Submit, NoHide
IniWrite, %splashbox%, %xini%, %xwintitle%, splash
return
subdirbox:
Gui, Submit, NoHide
IniWrite, %subdirbox%, %xini%, %xwintitle%, subdir
subdir := subdirbox
return
scrubdirbox:
Gui, Submit, NoHide
IniWrite, %scrubdirbox%, %xini%, %xwintitle%, scrubdir
scrubdir := scrubdirbox
return



;file drop event
6GuiDropFiles:
5GuiDropFiles:
param_started:
arr_R := "", arr_L := ""
single_image_mode := ""

if !FileExist(gm)
  gm := checkpaths() ;checks graphicsmagick and jpegtran, returns full gm.exe path
if !FileExist(gm)
  return
xext =

;files from parameter or dropped
dropped := params ? params : A_GuiEvent

Loop, parse, dropped, `n
{
  if (a_index == 1)
    firstfile := A_LoopField
  if (a_index == 2) 
    secondfile := A_LoopField
  if (a_index == 2) 
    Break
}
FileGetAttrib, xattrib, %firstfile%
SplitPath, firstfile,,xdir,xext
SplitPath, secondfile,,xdir2,xext2

if xattrib not contains D           ;no directory
  if xext not in jpg,tif,tiff       ;no jpg or tif
    return

if xattrib contains D
  ;directory -> use it, but trim end slash
  xdir := SubStr(firstfile, 0) == "\" ? SubStr(firstfile,1,-1) : firstfile

overlay := xdir "\" A_scriptname "_over.png"  ;overlay filepath

FileDelete, %overlay%  ;remove old overlay
FileDelete, %overlay%_orig.png

Gui,5: destroy
Gui,6: destroy
Gui,7: destroy

;single image mode -> preview mode for threshold adjustment, no cropping
if !secondfile
if xext in jpg,tif,tiff
{
  getdim(firstfile, prop, pic_w, pic_h, imgw, imgh)  ;ByRef returns
  ;make single image preview
  RunWait "%gm%" convert -size %pic_w%x%pic_h% "%firstfile%" -sample %pic_w%x%pic_h% -threshold %threshold%`% -transparent white -flatten "%overlay%" ,,hide

  single_image_mode := 1
  makegui()  ;global
  return
}

;multi image mode

at := Object() , aj := Object()  ;tiff or jpg array

;image drop -> overlay all dropped tif or jpg
if xext in jpg,tif,tiff       ;firstfile  is jpg or tif
if xext2 in jpg,tif,tiff      ;secondfile is jpg or tif
{
  Loop, parse, dropped, `n
  {
    SplitPath, A_LoopField,,,tempext
    if (tempext == "tif" or tempext == "tiff")
      at.Insert(A_LoopField)
    if (tempext == "jpg")
      aj.Insert(A_LoopField)
  }
}

;folder drop -> overlay all tif or jpg in folder
if InStr(xattrib, "D")
{
  Loop, Files, %xdir%\*.jpg
    aj.Insert(A_LoopFileFullpath)
  Loop, Files, %xdir%\*.tif
    at.Insert(A_LoopFileFullpath)
  Loop, Files, %xdir%\*.tiff
    at.Insert(A_LoopFileFullpath)
}

;if at most one jpg or tiff
if (aj.MaxIndex() <= 1 and at.MaxIndex() <= 1)
  return

;process most common image type
xext := aj.MaxIndex() >= at.MaxIndex() ? "jpg" : "tif"
;arr_do is most common image array
arr_do := aj.MaxIndex() >= at.MaxIndex() ? aj : at

;make R L arrays based on filename R L suffix
arr_R := Object() , arr_L := Object()
if InStr(txt,"R L") ;R L mode (as shown in gui text)
{
  for key, val in arr_do
  {
    SplitPath, val,,,valext
    if      SubStr(val,"-" StrLen(valext)+1) == "R." xext   ;R.jpg
      arr_R.Insert(val)
    else if SubStr(val,"-" StrLen(valext)+1) == "L." xext  ;L.jpg
      arr_L.Insert(val)
  }

  if !arr_R.MaxIndex() or !arr_L.MaxIndex()  ;R or L array empty
  {
    msgbox error: R or L files missing!
    reload
  }
  
  arr_do := arr_L  ;do L array first
}

;CREATE OVERLAY
; notes:
; binarize with transparent white
; mpc format is faster than jpg
; run many jobs to max out cpu cores

rightside:  ;jump back here later to do R side when in in R L mode

;assume first file's dimensions for all
getdim(arr_do[1], prop, pic_w, pic_h, imgw, imgh)  ;ByRef returns
;number of images in batch
xcount := arr_do.MaxIndex()

SetTimer, prog, 200
Progress, 0,, Creating overlay,%xwintitle%

tick := A_TickCount  ;for speedtest

for key, imgpath in arr_do
{
  ;resize binarize to mpc files
  Run "%gm%" convert -size %pic_w%x%pic_h% "%imgpath%" -sample %pic_w%x%pic_h% -threshold %threshold%`% -transparent white "%imgpath%_%A_scriptname%_temp.mpc" ,,hide
  sleep 10
}

;wait until all jobs end
while processExist("gm.exe")
  sleep 100

;flatten all mpc into one overlay image
;note: very fast, no need to optimize
Runwait  "%gm%" convert "%xdir%\*_%A_scriptname%_temp.mpc" -flatten "%overlay%" ,,hide
FileDelete, %xdir%\*_%A_scriptname%_temp.mpc
FileDelete, %xdir%\*_%A_scriptname%_temp.cache
tick := A_TickCount - tick
SetTimer, prog, Off
progress, off
;show overlay preview gui
makegui()  ;global
;msgbox overlay time = %tick% ms ;speedtest
return


;progress timer
prog:
Loop, %xdir%\*.mpc
  mpc_count := a_index
prog := ( mpc_count / xcount ) * 100
progress, %prog%
return



;user clicks on overlay preview pic
pic:
if single_image_mode
  return

;if Control is pressed and selection1 exists, do selection2
xcontr := GetKeyState("Control") == 1 and x1 ? 1 : ""

;get vars for transform from screen relative to pic relative x/y
;pic position relative to screen
WinGetPos, px,py,pw,ph, ahk_id %pichWnd%
edgex1 := px           ;pic left edge relative to screen
edgey1 := py           ;pic   top edge
edgex2 := px + pw      ;pic right edge
edgey2 := py + ph      ;pic  low  edge


;Draw rectangle as mouse moves. Return rectangle on Lbutton release.
;returns via ByRef
;returns rect corners relative to screen
LetUserSelectRect(screenx1, screeny1, screenx2, screeny2)

;cancel if no rectangle was made
if (screenx1 == screenx2 OR screeny1 == screeny2)
{
  Loop, 4
    Gui, %xcontr%%A_Index%: destroy  ;clear this selection
  return
}

;rect corners relative to pic top left
;screenx1 -= edgex1 , screeny1 -= edgey1
;screenx2 -= edgex1 , screeny2 -= edgey1
picx1 := screenx1 - edgex1 , picy1 := screeny1 - edgey1
picx2 := screenx2 - edgex1 , picy2 := screeny2 - edgey1


if (xcontr=="1") ;set selection2 crop vars
  extra_x1:=picx1, extra_x2:=picx2, extra_y1:=picy1, extra_y2:=picy2, r:=2
else             ;set selection1 crop vars
  x1:=picx1, x2:=picx2, y1:=picy1, y2:=picy2, r:=2, extra_x1:="", extra_y1:="", extra_x2:="", extra_y2:=""

;show rectangle on preview pic
;note: x y relative to parent
Gui, %xcontr%1:Show, % "NA X" picx1 " Y" picy1 " W" picx2-picx1 " H" r
Gui, %xcontr%2:Show, % "NA X" picx1 " Y" picy2-r " W" picx2-picx1 " H" r
Gui, %xcontr%3:Show, % "NA X" picx1 " Y" picy1 " W" r " H" picy2-picy1
Gui, %xcontr%4:Show, % "NA X" picx2-r " Y" picy1 " W" r " H" picy2-picy1

GuiControl,5: Enable, crop ;enable crop button
ControlFocus, Button1, ahk_id %MainhWnd% ;remove focus from the rectangle guis
return



;CROP OR SCRUB IMAGES
;based on user drawn rect
crop:

;prevent s from toggling crop/scrub mode below this line
blockshift := 1

if !x1   ;no selection
  return

tick := A_TickCount  ;for speedtest

;make image crop values by upscaling from selection rect

;pic was shrunk extra when rotating?
if rot_prop
  prop := prop * rot_prop

;rectangle
x :=round(x1/prop) , y :=round(y1/prop)

;flip imgw imgh if rotation from portrait to landscape (or vice versa)
if isOdd( totrot / 10) ;90 270 450 ... -90 -270 -450 ...
  stemp := imgw, imgw := imgh, imgh := stemp

;force crop area to be within imgw imgh bounds, else jpegtran fail
w := round( (x2-x1)/prop ) + x > imgw ? imgw - x : round( (x2-x1)/prop )
h := round( (y2-y1)/prop ) + y > imgh ? imgh - y : round( (y2-y1)/prop )

;extra rectangle
if extra_x1
{
  extra_x :=Round(extra_x1/prop), extra_y :=Round(extra_y1/prop)
  ;force crop area within imgw imgh bounds, else jpegtran fail
  extra_w :=Round( (extra_x2-extra_x1)/prop ) + extra_x > imgw ? imgw : Round( (extra_x2-extra_x1)/prop )
  extra_h :=Round( (extra_y2-extra_y1)/prop ) + extra_y > imgh ? imgh : Round( (extra_y2-extra_y1)/prop )
}

;prepare for cropping

if extra_x   ;split crop to two images
  xcount *= 2
Progress, 0,, Cropping,,
settimer, progout, 600
xtimestart := A_now


if (crop_scrub == "Crop" and subdir) or (crop_scrub == "Scrub" and scrubdir)
{
  ;crop to subfolder, don't overwrite input images
  ; if one image mode or if L side of two image mode: create subdir
  ; if R side of two image mode: reuse that subdir

  if (arr_do[1] != arr_R[1])
  {
    xoutdir := xdir "\" xtimestart
    FileCreateDir, % xoutdir

  }
}
else  ;not subdir mode, overwrite inputs
  xoutdir := xdir


;set crop tool based on image type
cropper := xext == "tif" ? gm : A_scriptdir "\jpegtran.exe"
;rotation argument
rot := !totrot ? "" : "-rotate " totrot
if totrot in 0,360,720,-360,-720
  rot := ""

for key,imgpath in arr_do
{
  SplitPath, imgpath,xname,,,xnoext

  ;scrub tif/tiff selection(s) white with graphicsmagick
  if (xext == "tif" and crop_scrub == "Scrub")
  {
    xend := x + w , yend := y + h
    xend2 := extra_x + extra_w , yend2 := extra_y + extra_h
    if extra_x ;selection1 and selection2
      Run "%cropper%" convert "%imgpath%" %rot% -fill white -draw "rectangle %X%`,%Y% %xend%`,%yend% rectangle %extra_x%`,%extra_y% %xend2%`,%yend2%" -threshold 50`% "%xoutdir%\%xname%" ,,hide
    else  ;selection1
      Run "%cropper%" convert "%imgpath%" %rot% -fill white -draw "rectangle %X%`,%Y% %xend%`,%yend%" -threshold 50`% "%xoutdir%\%xname%" ,,hide
  }
  
  ;crop tif with graphicsmagick
  else if (xext == "tif")
  {
    if extra_x   ;split crop R and L side
    {
      Run "%cropper%" convert %rot% -crop %extra_w%x%extra_h%+%extra_x%+%extra_y% "%imgpath%" "%xoutdir%\%xnoext%R.%xext%",,hide
      Run "%cropper%" convert %rot% -crop %W%x%H%+%X%+%Y% "%imgpath%" "%xoutdir%\%xnoext%L.%xext%" ,,hide
    }
    else
      Run "%cropper%" convert %rot% -crop %W%x%H%+%X%+%Y% "%imgpath%" "%xoutdir%\%xname%" ,,hide
  }
  
  ;crop jpg with jpegtran
  else if (xext == "jpg")
  {
    if extra_x  ;split crop R and L side    ;jpegtran -crop WxH+X+Y  (X/Y = startpoints)
    {
      Run "%cropper%" %rot% -crop %extra_w%x%extra_h%+%extra_x%+%extra_y% -outfile "%xoutdir%\%xnoext%R.%xext%" "%imgpath%",,hide
      Run "%cropper%" %rot% -crop %W%x%H%+%X%+%Y% -outfile "%xoutdir%\%xnoext%L.%xext%" "%imgpath%",,hide
    }
    else
      Run "%cropper%" %rot% -crop %W%x%H%+%X%+%Y% -outfile "%xoutdir%\%xname%" "%imgpath%",,hide
  }
  sleep 10
}

SplitPath, cropper, cropperfilename
;wait for all gm.exe or jpegtran.exe jobs to end
while processExist(cropperfilename)
  sleep 100

settimer, progout, off
progress, off
sleep 300
FileDelete, %overlay%
FileDelete, %overlay%_orig.png

;if L side images was cropped, continue with R side
if (arr_do == arr_L)
{
  arr_do := arr_R, totrot := "", rot_prop := ""
  Gui,5: destroy
  Gui,6: destroy
  Gui,7: destroy
  goto rightside
}

tick := A_TickCount - tick
;msgbox crop time = %tick% ms   ;speedtest

reload
return


;progress bar while cropping
progout:
xtot = 0
Loop, %xoutdir%\*.%xext%
{
  FileGetTime, xtime, %A_LoopFileFullPath%  ;last mod time
  if ( xtime > xtimestart )  ;if modified since crop started
    xtot += 1                 ;progress one step
}
prog := ( xtot / xcount ) * 100
progress, %prog%
return


6GuiClose:
5GuiClose:
FileDelete, %overlay%
FileDelete, %overlay%_orig.png
ExitApp


;function: test if input is Odd
isOdd(n){   ;return 1 if odd, else 0
  return n&1
}


; FUNCTION: SHOW SELECTION RECTANGLE
; first corner set from mouse start position
; other corner tracks user mouse move
; click fixates second corner and returns screen relative rect corners
; note: x1 x2 y1 y2 are local vars for rect corners relative to screen
; they are ByRef returned into screenx1 screenx2 ...

; based on LetUserSelectRect function by Lexikos
; www.autohotkey.com/community/viewtopic.php?t=49784

LetUserSelectRect(ByRef X1, ByRef Y1, ByRef X2, ByRef Y2)
{
  CoordMode, Mouse, Screen  
  static r := 2  ;line thickness

  global xcontr
  Loop 4 
  {
    if !xcontr  ;clear sel2 if new sel1
      Gui, 1%A_Index%: destroy
    Gui, %xcontr%%A_Index%: destroy  ;clear same type sel
    Gui, %xcontr%%A_Index%: -Caption +ToolWindow +AlwaysOnTop -DPIScale
    Gui, %xcontr%%A_Index%: Color, Red
    if !xcontr
      GuiControl,5: Disable, crop
  }
  
  if GetKeyState("Lbutton", "P") == "U"
    return ;user already released button (quick click)

  MouseGetPos, xo, yo             ;first click position
  SetTimer, lusr_update, 10      ;selection rectangle update timer 
  KeyWait, LButton                ;wait for LButton release
  SetTimer, lusr_update, Off
  global MainhWnd
  Loop 4                          ;make child
    Gui, %xcontr%%A_Index%: +Parent%MainhWnd%
  return

  lusr_update:
  CoordMode, Mouse, Screen
  MouseGetPos, x, y
  ;flip x1/x2 y1/y2 if negative rect draw
  y1 := y<yo ? y:yo , y2 := y<yo ? yo:y
  x1 := x<xo ? x:xo , x2 := x<xo ? xo:x

  ;pic edges relative to screen
  global edgex1, edgey1, edgex2, edgey2
  ;bound draw at pic edges
  x1 := x1 < edgex1 ? edgex1:x1 , x2 := x2>edgex2 ? edgex2:x2
  y1 := y1 < edgey1 ? edgey1:y1 , y2 := y2>edgey2 ? edgey2:y2

  ; Update selection rectangle   ;gui 1 2 3 4 (sel 1) or 11 12 13 14 (sel 2)
  Gui, %xcontr%1:Show, % "NA X" x1 " Y" y1 " W" x2-x1 " H" r
  Gui, %xcontr%2:Show, % "NA X" x1 " Y" y2-r " W" x2-x1 " H" r
  Gui, %xcontr%3:Show, % "NA X" x1 " Y" y1 " W" r " H" y2-y1
  Gui, %xcontr%4:Show, % "NA X" x2-r " Y" y1 " W" r " H" y2-y1
  return
}



;function: check that dependencies exist and get graphicsmagick gm.exe path
checkpaths() {   
  ;search program folders, since gm updates can break registry lookup method
  prog := StrReplace(A_ProgramFiles, " (x86)", "") ;Program Files path in any locale
  Loop, Files, %prog%\GraphicsMagick* , D
    binpath := A_LoopFileFullPath
  Loop, Files,  %prog% (x86)\GraphicsMagick* , D
    binpath := A_LoopFileFullPath
  if !FileExist(binpath "\gm.exe")
    msgbox, Error: GraphicsMagick not found.`nInstall it and try again.
  If !FileExist(A_Scriptdir "\jpegtran.exe") or !FileExist(A_Scriptdir "\libjpeg-62.dll")
    msgbox, Error: jpegtran.exe and/or libjpeg-62.dll not found.`nPlace them next to BookCrop.
  If FileExist(binpath "\gm.exe") and FileExist(A_Scriptdir "\jpegtran.exe") and FileExist(A_Scriptdir "\libjpeg-62.dll")
    return % binpath "\gm.exe"
}



;function: get image source dimensions and calculate gui pic dimensions
getdim(xdimfile, ByRef prop, ByRef pic_w, ByRef pic_h, Byref imgw, Byref imgh) {
  Img := ComObjCreate("WIA.ImageFile")
  Img.LoadFile(xdimfile)

  ;image dimensions
  imgw := Img.Width , imgh := Img.Height

  ;try: fit image pic to screen height
  pic_h := A_ScreenHeight-145
  ;exact proportion, used later to upscale rectangle before crop
  prop :=  pic_h/imgh
  pic_w := imgw*prop

  ;if too wide, fit pic to screen width instead (landscape image)
  pic_wmax := A_ScreenWidth-100
  if pic_w > pic_wmax            ;if too wide then fit pic to screen width instead
    pic_w := A_ScreenWidth-100, prop := pic_w/imgw, pic_h := imgh*prop

  ;pic dimensions
  pic_h := Round(pic_h), pic_w := Round(pic_w)
}



;function: check if process exist
processExist(im){
  process,exist,% im
  return errorLevel  ;PID or 0
}



;function: make new overlay preview window
makegui() {
  global
  Gui,5: destroy
  Gui,6: destroy
  pic_h := pic_h < 50 ? A_screenheight-100 : pic_h
  pic_w := pic_w < 50 ? A_screenwidth : pic_w

  Gui,5: -DPIScale
  Gui,5: margin,0,0
  Gui,5: font, s12 bold
  hbut := pic_h+5
  htot := pic_h+40
  xspl := pic_w-10
  Gui,5: Add, Button, x100 y%hbut% vcrop gcrop, Crop
  GuiControl,5: Disable, crop  ;disabled until selection1
  Gui,5: font, s8 cgray norm
  Gui,5: Show,w%pic_w% h%htot%,%xwintitle%
  Gui,5: Add, Text,x%xspl% yp+10 gsplash, ?  ;helpwin button
  Gui,5: +LastFound
  MainhWnd := WinExist()

  ;pic overlay child window
  Gui, 6: margin,0,0
  Gui, 6: Add, Pic, vpic gpic, %overlay%
  Gui, 6: +Owner -Caption -SysMenu -resize +ToolWindow +0x800000 -DPIScale
  Gui, 6: Show, x0 y0
  Gui, 6: +LastFound
  pichWnd := WinExist()
  Gui, 6: +Parent%MainhWnd%
}
