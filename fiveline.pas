(* RetroNick's version of popular fiveline puzzle/logic game          *)
(* This Program is free and open source. Do what ever you like with   *)
(* the code. Tested on freepascal for Dos GO32 target but should work *)
(* on anything that uses the graph unit.                              *)
(*                                                                    *)
(* If you can't sleep at night please visit my github and youtube     *)
(* channel. A sub and follow would be nice :)                         *)
(*                                                                    *)
(* https://github.com/RetroNick2020                                   *)
(* https://www.youtube.com/channel/UCLak9dN2fgKU9keY2XEBRFQ           *)
(* https://twitter.com/Nickshardware                                  *)
(* nickshardware2020@gmail.com                                        *)
(*                                                                    *)

Program FiveLine;
     uses crt,graph,pathfind,squeue,SysUtils;
Const
  ProgramName ='Fiveline v1.0';
  ProgramAuthor = 'RetroNick';
  ProgramReleaseDate = 'October 1 - 2021';

  HSize = 9;   //if you cange hsize or vsize make sure to change in
  VSize = 9;   //pathfind unit also

  GBItemRadius = 10;
  GBSQWidth  = 30;
  GBSQHeight = 30;
  GBSQThick  = 3;

  GBItemEmpty  = 0;
  GBItemCrossHair = 1;
  GBItemLocked    = 2;
  GBItemUnLocked  = 3;

  GBItemBorder       = 4;
  GBItemBorderRemove = 5;

  GBItemRed    = 10;
  GBItemGreen  = 11;
  GBItemBrown  = 12;
  GBItemCyan   = 13;
  GBItemLightBlue = 14;
  GBItemLightGray = 15;
  GBItemBrick     = 16;

type
GameBoardRec = record
                  Item : integer;
               end;

GameBoard = array[0..HSize-1,0..VSize-1] of GameBoardRec;

//used for storing path when performing a MoveTo command
//move piece another valid position
pathpoints = record
              x,y : integer;
             end;

//used for storing all the item/color lines that are 5 items (or more) wide
itempoints = record
              x,y,stepx,stepy,item,count : integer;
             end;

 ItemLockRec = record
                 isLocked : boolean;
                 x,y      : integer;
               end;

 CrossHairRec = record
                 isVisible : boolean;
                 x,y      : integer;
                 lastx,lasty : integer;
               end;


 apathpoints = array of pathpoints;
 aitempoints = array[0..1000] of itempoints;

 scoreRec = Record
                 xoff,yoff : integer;
                 score : longint;
                 mx    : integer;
                 pos   : integer;
              end;

 helpRec = record
              xoff,yoff : integer;
           end;

 GBPosRec = Record
              xoff,yoff : integer;
 end;

var
 GB            : GameBoard;
 GBPos         : GBPosRec;
 GBItemLock    : ItemLockRec;
 GBCrossHair   : CrossHairRec;
 GBRowsCleared : Boolean;
 aiCounter     : integer;

 score         : ScoreRec;
 help          : helpRec;
 cheatmode     : boolean;

function GetKey : integer;
var
 ch : char;
begin
 Repeat Until Keypressed;
 ch:=readkey;
 if ch = #0 then
 begin
   ch:=readkey;
 end;
 GetKey:=ORD(ch);
end;

Procedure InitGameBoard;
var
 i, j : integer;
begin
 for j:=0 to vsize-1 do
 begin
   for i:=0 to hsize-1 do
   begin
     GB[i,j].Item:=GBItemEmpty;
   end;
 end;
end;

Procedure InitItemLock;
begin
  GBItemLock.isLocked:=false;
  GBItemLock.x:=0;
  GBItemLock.y:=0;
end;

Procedure InitCrossHair;
begin
  GBCrossHair.x:=4;
  GBCrossHair.y:=4;
  GBCrossHair.isVisible:=true;
end;

Procedure InitAiQueue;
begin
 aiCounter:=0;
end;

procedure GB_Bar(x,y,x2,y2 : integer);
begin
 Bar(x+GBPos.xoff,y+GBPos.yoff,x2+GBPos.xoff,y2+GBPos.yoff);
end;

procedure GB_Rectangle(x,y,x2,y2 : integer);
begin
 Rectangle(x+GBPos.xoff,y+GBPos.yoff,x2+GBPos.xoff,y2+GBPos.yoff);
end;

procedure GB_Line(x,y,x2,y2 : integer);
begin
 Line(x+GBPos.xoff,y+GBPos.yoff,x2+GBPos.xoff,y2+GBPos.yoff);
end;

procedure GB_FillEllipse(x,y,r1,r2 : integer);
begin
  FillEllipse(x+GBPos.xoff,y+GBPos.yoff,r1,r2);
end;

procedure DrawFilledRect(x,y : integer);
begin
  GB_Bar(x*GBSQWidth+1,y*GBSQHeight+1,
      x*GBSQWidth+GBSQWidth-1,y*GBSQHeight+GBSQHeight-1);
end;

procedure DrawRect(x,y,Thick : integer);
var
 i : integer;
begin
 for i:=1 to Thick do
 begin
   GB_Rectangle(x*GBSQWidth+i,y*GBSQHeight+i,x*GBSQWidth+GBSQWidth-i,y*GBSQHeight+GBSQHeight-i);
 end;
end;

procedure DrawCross(x,y,w,h,wthick,hthick : integer);
var
 xoff,yoff,wtoff,htoff : integer;
begin
  xoff:=(GBSQWidth-w) div 2;
  yoff:=(GBSQHeight-h) div 2;

  wtoff:=(GBSQHeight-wthick) div 2;
  htoff:=(GBSQWidth-hthick) div 2;

// -
  GB_Bar(x*GBSQWidth+xoff,y*GBSQHeight+wtoff,
      x*GBSQWidth+xoff+w, y*GBSQHeight+wtoff+wthick);

// |
  GB_Bar(x*GBSQWidth+htoff,y*GBSQHeight+yoff,
      x*GBSQWidth+htoff+hthick,y*GBSQHeight+yoff+h);
end;

Procedure DrawFillEllip(x,y,r : integer);
var
 xoff,yoff : integer;
begin
  xoff:=GBSQWidth div 2;
  yoff:=GBSQHeight div 2;
  GB_FillEllipse(x*GBSQWidth+xoff,y*GBSQHeight+yoff,r,r);
end;

Procedure DrawGameBoardItem(x,y,item : integer);
begin
  if item=GBItemEmpty then
  begin
    SetFillStyle(SolidFill,Blue);
    DrawFilledRect(x,y);
  end
  else if item=GBItemLocked then
  begin
    SetColor(Brown);
    DrawRect(x,y,GBSQThick);
  end
  else if item=GBItemUnLocked then
  begin
    SetColor(Blue);
    DrawRect(x,y,GBSQThick);
  end
  else if item=GBItemBorder then
  begin
    SetColor(Yellow);
    DrawRect(x,y,GBSQThick);
  end
  else if item=GBItemBorderRemove then
  begin
    SetColor(Blue);
    DrawRect(x,y,GBSQThick);
  end
  else if item=GBItemBrick then
  begin
    SetFillStyle(xHatchFill,Yellow);
    GB_Bar(x*30+1,y*30+1,x*30+30-1,y*30+30-1);
  end
  else if item=GBItemCrossHair then
  begin
    SetFillStyle(SolidFill,Black);
    DrawCross(x,y,13,13,3,3);
  end
  else if item=GBItemRed then
  begin
    SetColor(Black);
    SetFillStyle(SolidFill,Red);
    DrawFillEllip(x,y,GBItemRadius);
  end
  else if item=GBItemGreen then
  begin
    SetColor(Black);
    SetFillStyle(SolidFill,Green);
    DrawFillEllip(x,y,GBItemRadius);
  end
  else if item=GBItemBrown then
  begin
    SetColor(Black);
    SetFillStyle(SolidFill,Brown);
    DrawFillEllip(x,y,GBItemRadius);
  end
  else if item=GBItemCyan then
  begin
    SetColor(Black);
    SetFillStyle(SolidFill,Cyan);
    DrawFillEllip(x,y,GBItemRadius);
  end
  else if item=GBItemLightGray then
  begin
    SetColor(Black);
    SetFillStyle(SolidFill,LightGray);
    DrawFillEllip(x,y,GBItemRadius);
  end
  else if item=GBItemLightBlue then
  begin
    SetColor(Black);
    SetFillStyle(SolidFill,lightblue);
    DrawFillEllip(x,y,GBItemRadius);
  end;
end;

procedure DrawCrossHair;
begin
  DrawGameBoardItem(GBCrossHair.x,GBCrossHair.y,GBItemCrossHair);
end;

procedure DrawLocked;
begin
  if GBItemLock.isLocked then
  begin
    DrawGameBoardItem(GBItemLock.x,GBItemLock.y,GBItemLocked);
  end
  else
  begin
    DrawGameBoardItem(GBItemLock.x,GBItemLock.y,GBItemUnLocked);
  end;
end;

procedure MoveCrossHairLeft;
begin
  if GBCrossHair.x > 0 then
  begin
     //erase cross hair by redrawing item at location x,y
     DrawGameBoardItem(GBCrossHair.x,
                       GBCrossHair.y,
                       GB[GBCrossHair.x,GBCrossHair.y].Item);
     //update current x
     dec(GBCrossHair.x);
     DrawCrossHair;
  end;
end;

procedure MoveCrossHairRight;
begin
  if GBCrossHair.x < (HSIZE-1) then
  begin
     //erase cross hair by redrawing item at location x,y
     DrawGameBoardItem(GBCrossHair.x,
                       GBCrossHair.y,
                       GB[GBCrossHair.x,GBCrossHair.y].Item);
     //update current x
     inc(GBCrossHair.x);
     //draw cross hair at updated x,y
     DrawCrossHair;
  end;
end;

procedure MoveCrossHairDown;
begin
  if GBCrossHair.y < (VSIZE-1) then
  begin
     //erase cross hair by redrawing item at location x,y
     DrawGameBoardItem(GBCrossHair.x,
                       GBCrossHair.y,
                       GB[GBCrossHair.x,GBCrossHair.y].Item);
     //update current y
     inc(GBCrossHair.y);
     //draw cross hair at updated x,y
     DrawCrossHair;
  end;
end;

procedure MoveCrossHairUp;
begin
  if GBCrossHair.y > 0 then
  begin
     //erase cross hair by redrawing item at location x,y
     DrawGameBoardItem(GBCrossHair.x,
                       GBCrossHair.y,
                       GB[GBCrossHair.x,GBCrossHair.y].Item);

     //update current y
     dec(GBCrossHair.y);
     //draw cross hair at updated x,y
     DrawCrossHair;
  end;
end;

Procedure DrawGameGrid;
var
i,j : integer;
begin
 SetFillStyle(SolidFill,Blue);
 GB_Bar(0,0,HSize*GBSQWidth,Vsize*GBSQHeight);

 SetColor(white);
 GB_Rectangle(0,0,HSize*GBSQWidth,VSize*GBSQHeight);

 for i:=1 to HSize-1 do
 begin
   GB_line(i*GBSQWidth,0,i*GBSQWidth,VSize*GBSQHeight);
 end;
 for j:=1 to VSize-1 do
 begin
   GB_line(0,j*GBSQHeight,HSize*GBSQWidth,j*GBSQHeight);
 end;
end;

Procedure DrawGameBoardItems;
var
 i,j : integer;
begin
 for j:=0 to VSIZE-1 do
 begin
  for i:=0 to HSIZE-1 do
  begin
    DrawGameBoardItem(i,j,GB[i,j].Item);
  end;
 end;
 DrawLocked;
 DrawCrossHair;
end;

Procedure DrawGameBoard;
begin
  DrawGameGrid;
  DrawGameBoardItems;
end;

//as long it is not empty it should be moveable
Function canSelectItem(x,y : integer) : Boolean;
begin
  canSelectItem:=(GB[x,y].Item <> GBItemEmpty);
end;

//from selected position
function canMoveTo(x,y : integer) : Boolean;
begin
  canMoveTo:=(GB[x,y].Item = GBItemEmpty);
end;

Procedure MoveGameBoardItem(startx,starty,endx,endy : integer);
begin
 GB[endx,endy].Item:=GB[startx,starty].Item;
 GB[startx,starty].Item:=GBItemEmpty;
end;

function isPosInRange(x,y : integer) : boolean;
var
 maxx,maxy : integer;
begin
 maxx:=HSIZE-1;
 maxy:=VSIZE-1;
 isPosInRange:=(x>=0) and (x<=maxx) and (y>=0) and (y<=maxy);
end;

function isColorSame(Var TGB : GameBoard;x1,y1,x2,y2 : integer) : boolean;
var
 c1,c2 : integer;
begin
 c1:=TGB[x1,y1].Item;
 c2:=TGB[x2,y2].Item;
 IsColorSame:=(c1>0) and (c1=c2); 
end;

//looks for continous color in any direction
//stepx and stepy can be 0 or 1 or -1

function FindColorCount(Var TGB : GameBoard;startx,starty,stepx,stepy,count : integer) : integer;
var
 i,c : integer;
 xpos,ypos : integer;
begin
 xpos:=startx;
 ypos:=starty;
 c:=1;
 for i:=1 to count-1 do
 begin
    if isPosInRange(xpos,ypos) and isPosInRange(xpos+stepx,ypos+stepy) then
    begin
      if isColorSame(TGB,xpos,ypos,xpos+stepx,ypos+stepy) then
      begin
        inc(c);
      end
      else
      begin
        FindColorCount:=c;
        exit;
      end;
    end;
    inc(xpos,stepx);
    inc(ypos,stepy);
  end;
  FindColorCount:=c;
end;

procedure AddRowsToQueue(x,y,stepx,stepy,count : integer;
                                   var apoints : aitempoints);
var
 item : integer;
begin
 apoints[aiCounter].item:=GB[x,y].Item;
 apoints[aiCounter].x:=x;
 apoints[aiCounter].y:=y;
 apoints[aiCounter].stepx:=stepx;
 apoints[aiCounter].stepy:=stepy;
 apoints[aiCounter].count:=count;
 inc(aiCounter);
end;

Procedure SetGameBoardPos(xpos,ypos : integer);
begin
 GBPos.xoff:=xpos;
 GBPos.yoff:=ypos;
end;

Procedure SetGameHelpPos(xpos,ypos : integer);
begin
 help.xoff:=xpos;
 help.yoff:=ypos;
end;

Procedure SetGameScorePos(xpos,ypos : integer);
begin
 score.xoff:=xpos;
 score.yoff:=ypos;
end;

procedure DrawTitle;
begin
 SetTextStyle(DefaultFont,HorizDir,2);
 SetColor(White);
 OutTextXY(10,10,ProgramName);
 OutTextXY(10,30,'By '+ProgramAuthor);
 
 SetTextStyle(DefaultFont,HorizDir,1);
 OutTextXY(10,50,'Released on '+ProgramReleaseDate);
end;

procedure DrawGameOver;
begin
 SetTextStyle(DefaultFont,HorizDir,2);
 SetColor(Yellow);
 OutTextXY(GBPos.xoff+65,GBPos.yoff+160,'Game Over');
end;

procedure DrawHelp;
var
  w,h : integer;
begin
 w:=285;
 h:=250;

 SetTextStyle(DefaultFont,HorizDir,1);
 SetColor(Yellow);
 SetFillStyle(SolidFill,Blue);
 Bar(help.xoff,help.yoff,help.xoff+w,help.yoff+h);
 OutTextXY(help.xoff+10,help.yoff+10, 'How To Play Fiveline');
 SetColor(White);
 OutTextXY(help.xoff+10,help.yoff+30, 'Arrange five or more balls of same');
 OutTextXY(help.xoff+10,help.yoff+44, 'color in any direction to remove');
 OutTextXY(help.xoff+10,help.yoff+58, 'from board. Each failed attempt ');
 OutTextXY(help.xoff+10,help.yoff+72, 'will introduce more balls to the');
 OutTextXY(help.xoff+10,help.yoff+86, 'board. Use arrow keys and Enter');
 OutTextXY(help.xoff+10,help.yoff+100,'key to select your ball. Move ');
 OutTextXY(help.xoff+10,help.yoff+114,'crosshair to an empty location and');
 OutTextXY(help.xoff+10,help.yoff+128,'press ENTER to move your ball.');
 OutTextXY(help.xoff+10,help.yoff+142,'Only balls with a valid path can');
 OutTextXY(help.xoff+10,help.yoff+156,'be moved!');

 SetColor(Yellow);
 OutTextXY(help.xoff+10,help.yoff+176,'R = Restart Game');
 OutTextXY(help.xoff+10,help.yoff+196,'X or Q = QUIT');
 OutTextXY(help.xoff+10,help.yoff+216,'C = Enable/Disable cheat mode');
 if cheatmode then
 begin
   SetColor(Green);
   OutTextXY(help.xoff+10,help.yoff+230,'Keys 0 1 2 3 4 5 6 are Enabled');
 end;
end;

Procedure DisplayScore(justscore : boolean);
var
 w,h : integer;
begin
 w:=285;
 h:=70;
 SetColor(White);
 SetFillStyle(SolidFill,Blue);
 if justscore = false then
 begin
   Bar(Score.xoff,score.yoff,Score.xoff+w,score.yoff+h);
   SetTextStyle(DefaultFont,HorizDir,2);
   OutTextXY(Score.xoff+10,score.yoff+8,'SCORE:');
 end;

 //erase previouse score and line points
 SetFillStyle(SolidFill,Blue);
 Bar(Score.xoff,score.yoff+28,Score.xoff+w,score.yoff+h);
 SetTextStyle(DefaultFont,HorizDir,2);
 OutTextXY(Score.xoff+10,score.yoff+30,IntToStr(score.score));
 SetColor(Yellow);
 OutTextXY(Score.xoff+10,score.yoff+50,IntToStr(score.pos)+'x'+IntToStr(score.mx));
end;

procedure UpdateScore(pos, count : integer);
begin
 score.pos:=pos;
 score.mx:=abs(4-count)*10; //5 line rows = 10 points per ball, 6 line = 20, 7 line =30
 Inc(score.Score,score.mx);
 DisplayScore(true);
end;

procedure DrawRowBoarder(x,y,stepx,stepy,count : integer; item : integer);
var
 i : integer;
begin
 for i:=1 to count do
 begin
   DrawGameBoardItem(x,y,item);
   inc(x,stepx);
   inc(y,stepy);

   //update score as we are removing the row
   if item = GBItemEmpty then UpdateScore(i,count);
   Delay(500);
 end;
end;

procedure DrawRowOfColors(var apoints : aitempoints;item : integer);
var
 i : integer;
begin
 for i:=0 to aiCounter-1 do
 begin
   DrawRowBoarder(apoints[i].x,apoints[i].y,
                  apoints[i].stepx,apoints[i].stepy,
                  apoints[i].count,item);
 end;
end;

procedure DeleteRowFromBoard(var TGB : GameBoard; x,y,stepx,stepy,count : integer);
var
 i : integer;
begin
 for i:=1 to count do
 begin
   TGB[x,y].Item:=GBItemEmpty;
   inc(x,stepx);
   inc(y,stepy);
 end;
end;


function FindRowOfColors(var apoints : aitempoints) : integer;
var
 TGB : GameBoard;
 i,j : integer;
 count : integer;
 rowcount : integer;
begin
 rowcount:=0;
 //Make Copy GM
 TGB:=GB;

 //horizonatal check
 for j:=0 to VSize-1 do   //VSIZE-1    0 to 8
 begin
   for i:=0 to HSize-5 do //HSIZE-5    0 to 4
   begin
     count:=FindColorCount(TGB,i,j,1,0,9);
     if count > 4 then
     begin
        inc(rowcount);
        AddRowsToQueue(i,j,1,0,count,apoints);
        //Remove Line from from TGB - solves 6 to 9 in a row duplicate problem
        DeleteRowFromBoard(TGB,i,j,1,0,count);
     end;
   end;
 end;

 //Make Copy GM Again - not a mistake
 TGB:=GB;
  //vertical check
 for i:=0 to HSize-1 do   //HSIZE-1    0 to 8
 begin
   for j:=0 to VSize-5 do //VSIZE-5    0 to 4
   begin
     count:=FindColorCount(TGB,i,j,0,1,9);
     if count > 4 then
     begin
       inc(rowcount);
       AddRowsToQueue(i,j,0,1,count,apoints);
       //Remove Line from from TGB - solves 6 to 9 in a row duplicate problem
       DeleteRowFromBoard(TGB,i,j,0,1,count);
     end;
   end;
 end;

 //Make Copy GM 3rd time
 TGB:=GB;

 //horizonatal down/right
 for j:=0 to VSize-5 do     //VSIZE-5   0 to 4
 begin
   for i:=0 to HSize-5 do   //HSIZE-5   0 to 4
   begin
     count:=FindColorCount(TGB,i,j,1,1,9);
     if count > 4 then
     begin
        inc(rowcount);
        AddRowsToQueue(i,j,1,1,count,apoints);
        //Remove Line from from TGB - solves 6 to 9 in a row duplicate problem
        DeleteRowFromBoard(TGB,i,j,1,1,count);
     end;
   end;
 end;

  //Make Copy GM 4th time
 TGB:=GB;
  //horizonatal down/left
 for j:=0 to VSize-5 do      //VSIZE-5  0 to 4
 begin
   for i:=4 to HSize-1 do    //HSIZE-1  4 to 8
   begin
     count:=FindColorCount(TGB,i,j,-1,1,9);
     if count > 4 then
     begin
        inc(rowcount);
        AddRowsToQueue(i,j,-1,1,count,apoints);
        //Remove Line from from TGB - solves 6 to 9 in a row duplicate problem
        DeleteRowFromBoard(TGB,i,j,-1,1,count);
     end;
   end;
 end;
 FindRowOfColors:=rowcount;
end;

Function ValidMovesLeft : integer;
var
 count,i,j : integer;
begin
 count:=0;
 for j:=0 to VSize-1 do
 begin
   for i:=0 to Hsize-1 do
   begin
     if GB[i,j].Item = GBItemEmpty then inc(count);
   end;
 end;
 ValidMovesLeft:=count;
end;

Function isGameOver : boolean;
begin
  isGameOver:=(ValidMovesLeft = 0);
end;

Procedure GetXYForMoveX(mvx : integer;var x,y : integer);
var
 i,j : integer;
 count : integer;
begin
 count:=0;
 x:=-1;
 y:=-1;
 for j:=0 to VSize-1 do
 begin
   for i:=0 to Hsize-1 do
   begin
     if GB[i,j].Item = GBItemEmpty then inc(count);
     if count = mvx then
     begin
       x:=i;
       y:=j;
       exit;
     end;
   end;
 end;
end;

Procedure GetRandomSpot(var x,y : integer);
var
  r : integer;
  vcount : integer;
begin
 x:=-1;
 y:=-1;
 vcount:=ValidMovesLeft;
 if vcount > 0 then
 begin
   r:=random(vcount)+1;
   GetXYForMoveX(r,x,y);
 end;
end;

Function GetRandomItem : integer;
begin
  GetRandomItem:=random(6)+GBItemRed;
end;

//for debug / cheat mode
Procedure PlotItem(item : integer);
begin
  GB[GBCrossHair.x,GBCrossHair.y].Item:=item;
  DrawGameBoardItem(GBCrossHair.x,GBCrossHair.y,item);
  DrawCrossHair;
end;

Procedure LockItem;
begin
 if GB[GBCrossHair.x,GBCrossHair.y].Item<>GBItemEmpty then
 begin
   if GBItemLock.isLocked then
   begin
     GBItemLock.isLocked:=false;
     DrawLocked;  //erase current lock
   end;
   GBItemLock.x:=GBCrossHair.x;
   GBItemLock.y:=GBCrossHair.y;
   GBItemLock.isLocked:=true;
   DrawLocked;
 end;
end;

// Copy GameBoard data to PGrid in a format that our path finding algorithm
// can make use of it. each color ball is considered a wall/obstacle.

Procedure CopyGbToPga(Var PGrid : PGA);
var
 i,j : integer;
begin
 For j:=0 to VSize-1 do
 begin
   for i:=0 to  HSize-1 do
   begin
      if GB[i,j].Item<>GBItemEmpty then PlaceWall(PGrid,i,j);
   end;
 end;
end;

function isPathToItem(sx,sy,tx,ty : integer) : boolean;
var
 PGrid : PGA;
 FoundPath : SimpleQueueRec;
begin
  ClearGrid(PGrid);
  CopyGbToPga(PGrid);
  isPathToItem:=FindTargetPath(PGrid,sx,sy,tx,ty,FoundPath);
end;

//check if the destination location is one block to the right,left,up,down
function isNextToMoveBlock(sx,sy,tx,ty : integer) : boolean;
var
 vpos : boolean;
 dx,dy : integer;
begin
  isNextToMoveBlock:=false;
  vpos:=isPosInRange(sx,sy) and isPosInRange(tx,ty);
  if vpos=false then exit;
  dx:=abs(sx-tx);
  dy:=abs(sy-ty);
  isNextToMoveBlock:=((dx=1) and (dy=0)) or ((dx=0) and (dy=1))
end;

Procedure RemoveRows(var apoints : aitempoints; count : integer);
var
 i : integer;
begin
 For i:=0 to count-1 do
 begin
   DeleteRowFromBoard(GB,apoints[i].x,apoints[i].y,
                         apoints[i].stepx,apoints[i].stepy,
                         apoints[i].count);
 end;
 DrawRowOfColors(apoints,GBItemEmpty);
end;

Procedure SetRowsClearedStatus(status : boolean);
begin
  GBRowsCleared:=status;
end;

Function GetRowsClearedStatus : boolean;
begin
  GetRowsClearedStatus:=GBRowsCleared;
end;

Procedure CheckForRows;
var
 count : integer;
 apoints : aitempoints;
begin
 SetRowsClearedStatus(False);
 InitAIQueue;
 count:=FindRowOfColors(apoints);
 if count > 0 then
 begin
    DrawRowOfColors(apoints,GBItemBorder);
    RemoveRows(apoints,count);
    SetRowsClearedStatus(true);
 end;
end;

Procedure AniMoveBoardItem(sx,sy,tx,ty : integer);
var
 PGrid : PGA;
 FoundPath : SimpleQueueRec;
 qr : locationRec;
 i : integer;
 item : integer;
 isPathToItem : boolean;
begin
  ClearGrid(PGrid);
  CopyGbToPga(PGrid);
  InitSQueue(FoundPath);

  isPathToItem:=FindTargetPath(PGrid,sx,sy,tx,ty,FoundPath);
  if isPathToItem = false then exit;

  item:=GB[sx,sy].item;

  for i:=1 to SQueueCount(FoundPath) do
  begin
    SQueueGet(FoundPath,i,qr);
    DrawGameBoardItem(qr.x,qr.y,GBItemBrick);
    Delay(500);
  end;
  DrawGameBoardItem(sx,sy,GBItemEmpty);
  for i:=1 to SQueueCount(FoundPath) do
  begin
    SQueueGet(FoundPath,i,qr);
    DrawGameBoardItem(qr.x,qr.y,Item);
    Delay(500);
    DrawGameBoardItem(qr.x,qr.y,GBItemBrick);
  end;
  DrawGameBoardItem(tx,ty,item);

  for i:=1 to SQueueCount(FoundPath) do
  begin
    SQueueGet(FoundPath,i,qr);
    DrawGameBoardItem(qr.x,qr.y,GBItemEmpty);
    Delay(500);
  end;

end;

Function MovedItem : Boolean;
var
 canMove  : boolean;
 pathMove  : Boolean;
 nextMove : Boolean;
begin
 MovedItem:=false;
 canMove:=false;
 canmove:=GBItemLock.isLocked and canMoveTo(GBCrossHair.x,GBCrossHair.y);
 if canmove = false then exit;

 nextMove:=isNextToMoveBlock(GBItemLock.x,GBItemLock.y,GBCrossHair.x,GBCrossHair.y);

 if nextmove = false then
 begin
    pathmove:=isPathToItem(GBItemLock.x,GBItemLock.y,GBCrossHair.x,GBCrossHair.y);
    if pathmove = false then exit;
 end;

 GBItemLock.isLocked:=false;
 DrawLocked;  //erase current lock

 if pathmove then AniMoveBoardItem(GBItemLock.x,GBItemLock.y,
                                   GBCrossHair.x,GBCrossHair.y);
 MoveGameBoardItem(GBItemLock.x,GBItemLock.y,
                   GBCrossHair.x,GBCrossHair.y);

 GBItemLock.isLocked:=false;
 DrawGameBoardItem(GBItemLock.x,GBItemLock.y,GB[GBItemLock.x,GBItemLock.y].Item);
 DrawGameBoardItem(GBCrossHair.x,GBCrossHair.y,GB[GBCrossHair.x,GBCrossHair.y].Item);

 CheckForRows;
 DrawCrossHair;
 MovedItem:=true;
end;

Procedure ComputerMove;
var
 item,x,y,i : integer;
 count      : integer;
begin
 count:=validMovesLeft;
 if count > 3 then count:=3;
 for i:=1 to count do
 begin
   GetRandomSpot(x,y);
   item:=GetRandomItem;
   GB[x,y].Item:=Item;
   DrawGameBoardItem(x,y,item);
   Delay(1200);
 end;
end;


Procedure CheatAction(k : integer);
begin
  if k=ord('1') then PlotItem(GBItemRed);
  if k=ord('2') then PlotItem(GBItemGreen);
  if k=ord('3') then PlotItem(GBItemBrown);
  if k=ord('4') then PlotItem(GBItemCyan);
  if k=ord('5') then PlotItem(GBItemLightBlue);
  if k=ord('6') then PlotItem(GBItemLightGray);
  if k=ord('0') then PlotItem(GBItemEmpty);
end;

Procedure LockOrMove;
begin
 if GBItemLock.isLocked then
 begin
   if GB[GBCrossHair.x,GBCrossHair.y].item <> GBItemEmpty then
   begin
     LockItem;
   end
   else
   begin
     if MovedItem then
     begin
       // we only drop new balls when a line has NOT been cleared after a move
       if GetRowsClearedStatus=false then
       begin
          ComputerMove;  //drop more balls
          CheckForRows;  //check if one of those balls connected 5 or more
          DrawCrossHair;
       end;
     end;
   end;
 end
 else
 begin
   LockItem;
 end;
end;

procedure InitScore;
begin
  score.Score:=0;
  score.mx:=0;
  score.pos:=0;
end;

Procedure StartGame;
begin
  cheatmode:=false;
  InitScore;
  SetGameBoardPos(30,70);
  SetGameHelpPos(330,90);
  SetGameScorePos(330,10);
  DrawTitle;
  DisplayScore(false);
  InitAIQueue;
  InitGameBoard;
  InitItemLock;
  InitCrossHair;
  DrawGameBoard;
  DrawHelp;
  ComputerMove;
  DrawCrossHair;
end;

var
  gd,gm    : smallint;
         k : integer;
  gameover : boolean;
begin
 gd:=ega;
 gm:=egahi;
 initgraph(gd,gm,'');

 Randomize;
 gameover:=false;
 StartGame;
 Repeat
  k:=GetKey;
  if gameover = false then
  begin
    if k=75 then MoveCrossHairLeft;
    if k=77 then MoveCrossHairRight;
    if k=72 then MoveCrossHairUp;
    if k=80 then MoveCrossHairDown;
  end;
//  if k=ord('[') then CheckForRows;
//  if k=ord('g')  then DrawGameBoard;
//  if k=ord('p') then DrawPath;

  if (k=ord('r')) or (k=ord('R')) then 
  begin
     gameover:=false;
     StartGame;
  end;
  if (k=ord('l')) or (k=ord('L')) or (k=13) then LockOrMove;

  //check if board is filled up/gave over
  gameover:=isGameOver;
  if gameover then DrawGameOver;
  //if (k=ord('m')) then MovedItem;

  if CheatMode then CheatAction(k);
  if (k=ord('c')) or (k=ord('C')) then
  begin
     Cheatmode:=NOT cheatmode;
     DrawHelp;
  end;
 Until (k=ord('q')) or (k=ord('Q')) or (k=ord('x')) or (k=ord('X'));
 closegraph;
end.

