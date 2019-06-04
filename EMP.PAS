{ * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
  *     Remark Infos for this Source Code  ÄÄ  AZ-Group Club                *
  *     Author:  Le Ngoc Thanh                                              *
  *     From:    The University of Economics - Informatics Department       *
  *     Purpose: Foreign Languages - Computer - Math Testing                *
  *     Product: EMP.EXE                                                    *
  * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
program force;
uses    EMPIO, IPX;
{$M 16384, 0, 655360}
const
    ssocket     = $7777;           { for sending }
    rsocket     = $5555;           { for receiving }
    Emax        = 7;
    PRETEST_DAT = 'EMP.001';
    INFORMATIC  = 'EMP.002';
    Others      = 'EMP.003';
    Music       = 'EMP.004';
    Author      : array[1..14] of char = 'LE NGOC THANH'#26;
    { ======= Menu Infos }
    n = 4;         { Pad Number }
    m = 8;         { Bar Number }

    padprompt: array[1..n] of string[20] = (' Languages ', ' Computer ',
                                           ' Games ', ' System ');
    padwidth : array[1..n] of byte   = (13, 13, 14, 14);
    padpos   : array[1..n] of byte   = (0 , 12, 23, 31);
    padlength: array[1..n] of byte   = (6 ,  8,  7, 8);
    popprompt: array[1..n, 1..m] of string[20] =
    (('1~Learning ', '2~Exercise ', '3~Loading  ', 'Ä', '4~Review   ', '5~Printing ','',''),
     ('1~MS-DOS   ', '2~Excel    ', '3~Pascal   ', '4~Foxpro   ','5~C/C++    ', '6~Assembly ', 'Ä', '7~New Test '),
     ('1~ProVerbs  ', '2~CrossWord ', 'Ä','3~GraphDemo ','4~TextDemo  ','5~Calendar. ','6~MusicON ~',''),
     ('1~Help  F1  ', '2~Exit  F10 ','3~ClockON ~','4~Beep ON ~', 'Ä','5~Comp Data ','6~Decm Data ','7~Password  '));
     { ======= End of Menu Infos }

    p_set = ['.', ',', '?', '!', ' ', '''','"','-','&','%','$','(',')'];
    e_set : array[1..7, 1..5] of char = (('a',' ','…','ƒ','ü'),
                                         ('e','‚','Š','ˆ','ý'),
                                         ('c','‡','c','c','c'),
                                         ('C','€','C','C','C'),
                                         ('i','¡','','Œ',''),
                                         ('u','£','—','¯','û'),
                                         ('o','¢','•','“','ú'));
type
    string15  = string[15];
    string32  = string[32];
    string80  = string[80];
    string255 = string[255];
    BufResult = Array[1..401] of char;  { = 4 * Question number Max }

    P80     = ^Str80;
    Str80   = record
                     Info : string80;
                     Next, Prev : P80;
              end;

    P255    = ^Str255;  (* Tif 1 *)
    Str255  = record
                     Info : string;
                     Next, Prev: P255;
              end;

  { ====== Compress }
    StrNodePtr  = ^StrNodeType;
    StrNodeType = record     { descripts the forward string-table}
                    Value    : byte;
                    Code     : word;
                    Next     : StrNodePtr;
                    Alt      : StrNodePtr;
                  end;
    StrNodePtr_R  = ^StrNodeType_R;
    StrNodeType_R = record     {descripts the forward string-table}
                    Value    : byte;
                    Code     : word;
                    Next     : StrNodePtr;
                  end;
    CodeTablePtr  = ^CodeTableType;
    CodeTableType = record   { descripts the backward string-table}
                      LCode   : word;
                      Node    : char;
                      Next    : CodeTablePtr;
                    end;
  { ====== End of Compress }

  { ====== Data file Structure with Emax entries in maximum }
    FDATA     = Record
                 IDname : array[1..14] of char;        { Author Name  }
                 Enumber: Byte;                        { Number of Entries }
                 Ename  : array[1..Emax] of string[12];{ Entries name }
                 Esize  : Array[1..Emax] of Longint;   { Entries Size }
                 CodeID : Word;                        { In protected }
                 EItemNo: Array[1..Emax] of Byte;      { Entry Items Number }
               End;
var
   { Menu option and exercise selected }
   pad, pop, ExeDefault: byte;
   Key, Cks            : word;

   { For compress & Decompress processes }
   remain                     : boolean;
   r_var                      : byte;
   Code,Max_num               : word;
   InBuf_p, OutBuf_p, Cnt     : word;
   INbuffer                   : array[1..15000] of char;
   OUTbuffer                  : array[1..15010] of byte;
   Stack                      : array[1..1000] of char;
   RootAPtr                   : array[0..255] of pointer;
   Caro                       : array[1..30, 1..50] of char Absolute OUTbuffer;
   Cmdline                    : string Absolute OUTbuffer;

   { for interrupt procedure timeshow }
   tstr : string[18];
   tsso : string[5];
   ti   : byte;

   { for network jobs, Use OUTbuffer for network jobs }
   net: record
           Ripx, Sipx: IPXheader;
           Recb, Secb: ECB;
           Rbuf, Sbuf: record
                          Who  : string[3]; { WSs, HOT }
                          Ok   : boolean;   { True = answer from HOT in case success }
                          NetNo: byte4;
                          Netad: byte6;
                          Netim: byte6;
                          Msg  : String[80];
                          Ans  : BufResult;
                       end;
           NetWin    : array[15..20, 19..60] of word;
        end Absolute OUTbuffer;
   Network : string[3];

   { Program Variables }
   size_out : longint;
   fin, fout: File;
   F1, f2   : File;
   ITemCount: Byte;
   F_header : Fdata;
   Fname    : string[13];

   { Commun Variables }
   SubMin, clock  : boolean;
   Int1CSave      : pointer;
   NotTimeshow    : boolean;
   CMFOK, OnMusic : Boolean;
   CmfStatus      : Byte;
   MusicNo        : Byte;
   InBaigiai      : boolean;
   ID             : word;

   H255, C255,S255: P255;
   H80, C80, S80  : P80;
   HCfg, Ccfg     : P80;                { For config and header file }

   C_proc         : byte;
   Time, Rtime    : byte;
   Cur_job        : string[3];          { Info of current chain }

   { For fortune teller }
   ftl            : Record
                          nSinh, OnSinh, PnSinh: Date;
                    End;
   {=====================}

procedure help;      external;
procedure empdemo;   external;
{$L HELP.OBJ}

{=================================== Bell }

Procedure Bell(t: byte);
var
     bi: byte;
begin
     for bi := 1 to T do
         begin
               sound(900); delay(2);
               sound(1300 + 100); delay(2)
         end; sound_off;
end;
{=================================== Show a message }

procedure message(mesrow: byte; info : string; Wait,Clear,Bip: Boolean);
var
     old_color, old_row, old_col, old_zoom: byte;
begin
     if clear then Backup_screen;
     old_color := color; old_zoom := zoom_mode;
     old_row   := row; old_col := col;
     color     := 15+8*8;
     col := (80 - ord(info[0])) div 2;
     row := mesrow; zoom_mode := 1;
     zoom(row-2,col-7,row+2,col+ord(info[0])+7,single_frame);
     color     := 14+8*8;
     zoom_mode := old_zoom; write(info);
     if bip then bell(13);
     If Wait Then begin
                       While Not Keypressed Do ; Exit_key := Inkey;
                  end;
     color := old_color;
     row   := old_row; col := old_col;
     if clear then Restore_screen;
end;
{ ========================= Making Joke with main screen }

Procedure Demo(No: boolean);
var
   x, y   : integer;
   dx,dy  : shortint;
   di, dj : byte;
   dw     : word;
   wininfo: array[1..11, 1..60] of word absolute outbuffer;
begin
   { save screen infos }
   for di := 1 to 11 do
     for dj := 1 to 60 do
         wininfo[di, dj] := Memw[Video_seg: (7 + di)*160 + 2 * 9 + 2*dj];

   y := 8; x := 10;
   If No Then
      begin
          dx := 0;
          if mili_second > 50 then dy := 1 else dy := -1;
      end
   Else
      begin
          backup_screen;
          dy := random(2) - 1;
          dx := random(2) - 1;
      end;
   Repeat
         if (Second Mod 10 = 0) and (mili_second > 80) then
            begin
                dx := random(2) - 1; dy := random(2) - 1;
                if (dy = 0) and (dx = 0) then
                   if y > 20 then dy := -1
                   else if dx > 50 then dx := -1 else dx := 1;
            end;

         { clear old Image }
         for di := 1 to 11 do
                begin
                   dw := (y+di-1)*160 + 2*(x-1);
                   if (dw > 160) and (dw < 24*160) Then
                   for dj := 1 to 60 do
                       begin
                           dw := dw + 2;
                           If dw mod 160 = 0 Then Dw := Dw - 160;
                           Memw[Video_seg: dw] := 176+11*256;
                       end;
                end;
         { Recalculate }
         x := x + dx; y := y + dy;
         if ((x >= 140) and (dx > 0)) or ((x <= -60) and (dx < 0)) then
            dx := (-1)*dx;
         if ((y >= 35) and (dy > 0))  or ((y <= -10) and (dy < 0)) then
            begin
                 { Change Image color }
                 dy := (-1)*dy;
                 if y = 35 then
                    for dw := 1 to 1360 do
                       if (dw Mod 2 = 0) and (Outbuffer[dw] Mod 16 = 0) then
                                Outbuffer[dw] := Outbuffer[dw] + 16;
            end;
         for di := 1 to 11 do
                begin
                   dw := (y+di-1)*160 + 2*(x-1);
                   if (dw > 160) and (dw < 24*160) Then
                   for dj := 1 to 60 do
                       begin
                           dw := dw + 2;
                           If dw mod 160 = 0 Then Dw := Dw - 160;
                           Memw[Video_seg: dw] := wininfo[di, dj];
                       end;
                end;
         if No then delay(1) else delay(7);
   Until Keypressed or (No and ((y=-10) or (y=35)));
   If Not No Then Restore_screen;
end;
{============================ }

procedure giupdo;
begin
     backup_screen;
     Help;
     Restore_screen;
end;
{=================================== Un load a chain }

procedure  unload(kieu: byte; Clear: Boolean);

begin
     If Clear Then
        Begin
             Cur_job := '   ';
             While HCfg <> Nil Do
                Begin
                    Ccfg := Hcfg;
                    Hcfg := Hcfg^.Next;
                    Dispose(Ccfg);
                End;
             New(HCfg);
             Hcfg^.Next := Nil; Hcfg^.Prev := Nil;
             Hcfg^.Info := '  Note: '; Ccfg := Hcfg;
        End;
     Case kieu of
          80: Begin
                 While H80 <> NIl Do
                    Begin
                       C80 := H80;
                       H80 := H80^.Next;
                       Dispose(C80);
                    End;
                 H80 := Nil; S80 := Nil; C80 := Nil;
              End;
         255: Begin
                 While H255 <> NIl Do
                    Begin
                       C255 := H255;
                       H255 := H255^.Next;
                       Dispose(C255);
                    End;
                 H255 := Nil; S255 := Nil; C255 := Nil;
              End;
     end;
end;
{============================ Password for Supervisor Right }

Function Password: boolean;   { max = 18 }
var
   pass: string[18];
   psi : byte;
   psj : char;
begin
     backup_screen;
     Demo(true);
     box_base := 1; cursor_on; color := 15+8*8;
     zoom(7,17,17,62,Single_frame);
     box(10, 20, 10, 59, Single_bar);
     col := 25; row := 12; write('( To protect Your documents )');
     col := 22; row := 14; write('Enter password:');
     color := 14+8*8; col := 26; row := 9;
     write('S Y S T E M P A S S W O R D');

     color := 62; psi := 0;
     repeat
         col := 38; row := 14; write('                   ');
         col := 38; row := 14; write(Replicate('', psi));
         pass[0] := char(psi);
         psj := char(lo(inkey));
         if psj in ['a'..'z', 'A'..'Z', #8] then
            begin
                 if psj <> #8 then
                    begin
                        if psj in ['a'..'z'] then psj := char(ord(psj)-32);
                        psi := psi + 1;
                        pass[psi] := psj;
                    end
                 else
                    if psi > 0 then psi := psi - 1;
            end;
     until (psi > 18) or (psj = #13) or (psj = #27);
     restore_screen; cursor_off;
     if Pass = 'EMP' then Password := true
     else begin
        Cks := 0;
        For psi := 1 to Ord(Pass[0]) do
            Cks := psi*(Ord(Pass[psi]) div 21)*(Cks+1);
        Password:= false;
     end;
end;
{---- All Compress and Decompress Processes with 12 bit per code ----}

Procedure Compress;
Var
            ch : char;
   Cur_Node,pi : StrNodePtr;
   Root,Oldroot: StrNodePtr;
   {-----------------------------------}

   Procedure ResetPara;
   Var i    : byte;
       Temp : StrNodePtr_R;
   Begin
       Remain  := False;
       r_var   := 0;
       Max_num := 255;
       InBuf_p := 0;
       OutBuf_p:= 0;

       For i:= 0 to 255 do
           Begin
                New(Temp);
                Temp^.Value := i;
                Temp^.Code  := i;
                Temp^.Next  := NIL;
                RootAPtr[i] := Temp;
           End;
       Mark(Root);
   End;
   {------------------------- Init dictionary for 256 charater }

   Procedure RefreshRoot;
   var    i: byte;
       Temp: StrNodePtr_R;
   Begin
       Max_num := 255;
       For i := 0 to 255 do
           begin
                Temp := RootAPtr[i];
                Temp^.Next := Nil
           end;
       Release(Root);
       Mark(Root);
   End;
   {-----------------------------------}

   Function Inchar(var ch: char): boolean;  { General input (Compression) }

   Begin
       if InBuf_p = 0 then
       begin
            Blockread(fIn, Inbuffer, 15000, Cnt);
            InBuf_p := Cnt;
       end;
       if InBuf_p = 0 then Inchar := false
       else
           begin
                ch := Inbuffer[Cnt+1-InBuf_p];
                if ch = 'Û' Then ItemCount := ItemCount + 1;
                dec(InBuf_p);
                Inchar := true;
           end;
   End;
   {-----------------------------------}

  Procedure Outchar(ch: word);        { General output (compression) }
  var
      B_written:  word;
  Begin
      if OutBuf_p >= 15000 then
          begin
               for B_written := 1 to OutBuf_p do
                   OUTbuffer[B_written] := OUTbuffer[B_written] + Cks;
               Size_out := Size_out + OutBuf_p;
               Blockwrite(fOut, OUTbuffer, OutBuf_p, B_written);
               OutBuf_p := 0;
          end;
      if remain = true then
          begin
               remain := false;
               inc(OutBuf_p);
               OUTbuffer[OutBuf_p] := r_var*16+(ch div 256);
          end
      else
          begin
               r_var := ch div 256;
               remain:= true;
          end;
      inc(OutBuf_p);
      OUTbuffer[OutBuf_p] := ch mod 256;
  End;

BEGIN
      Mark(OldRoot);
      ResetPara;

      if not Inchar(ch) then exit;
      Cur_node := RootAPtr[byte(ch)];
      while Inchar(ch) do
      begin
         if max_num = 4095 then
            begin
                 Outchar(Cur_Node^.Code);
                 Outchar(4095);
                 RefreshRoot;
                 Cur_node := RootAPtr[Ord(ch)];
            end
         else
            if Cur_Node^.Next = nil then  { not any string , append !}
               begin
                   {Code current ê (str) : ??}
                   New(pi);
                   Max_num := Max_num + 1;

                   {append new code for the new list}
                   pi^.Value := Ord(ch);
                   pi^.Code  := Max_num;
                   pi^.Alt   := nil;
                   pi^.Next  := nil;

                   Cur_Node^.Next := pi;
                   Outchar(Cur_node^.Code);
                   { K -> ê }
                   Cur_node := RootAPtr[Ord(ch)];
               end
            else  { be able to have such string}
               begin
                   pi := Cur_Node^.Next;
                   while (pi^.Value <> ord(ch)) and (pi^.Alt <> nil) do
                                    pi := pi^.Alt;

                   if pi^.Value <> ord(ch) then { actually not have }
                      begin
                        {Code current ê (str) : ??}
                        {append new code into the end of pi-list}
                        Outchar(Cur_node^.Code);
                        Cur_Node := pi;
                        Max_num  := Max_num + 1;
                        New(pi);
                        pi^.Value := ord(ch);
                        pi^.Code  := Max_num;
                        pi^.Alt   := nil;
                        pi^.Next  := nil;
                        Cur_Node^.Alt := pi;
                        { K -> ê }
                        Cur_node := RootAPtr[Ord(ch)];
                      end
                    else  { have been defined , continue}
                      begin
                        Cur_Node := pi;
                      end
               end;
      end;
      { codes the final symbol if any }
      Outchar(Cur_Node^.Code);
      if remain = true then Outchar(4095);
      Release(OldRoot);
END;
{---------------------------------- General input (Decompression) }

Function Decompress(Dest,tif,Itemget,S_entry,ItemNo: Byte): byte;
         {
               Dest     : 1. To chaine - 2. To File - 3. To array only
               Tif      : Motif
               Itemget  : Expecting entry number to read
               S_entry  : Start entry to read
               ItemNo   : Available entry in this block
         }
Var
  Seg_node, Ofs1              : word;
  Step, abcd                  : Byte;
  SP                          : integer;
  RootD, Cur_NodeD,Tail,Temp1 : CodeTablePtr;
  Finchar                     : char;
  In_Code,Old_Code,Max_Code   : word;

  Function IncharD(var ch: word): boolean;
  Begin
      If (InBuf_p = 0) then
      begin
           Blockread(fIn, OUTbuffer, 15000, Cnt);
           InBuf_p := Cnt;
      end;

      if (InBuf_p = 0)or(Itemcount > ItemNo)or(Itemcount-S_entry >= Itemget)
         then Inchard := false
      else
           begin
                if remain = true then
                   begin
                        remain := false;
                        Outbuffer[Cnt+1-InBuf_p]:=Outbuffer[Cnt+1-InBuf_p]-ID;
                        ch := Outbuffer[Cnt+1-InBuf_p];
                        dec(InBuf_p);
                        ch := r_var*256+ch;
                   end
                else
                   begin
                        remain := true;
                        Outbuffer[Cnt+1-InBuf_p]:=Outbuffer[Cnt+1-InBuf_p]-ID;
                        ch := Outbuffer[Cnt+1-InBuf_p];
                        dec(InBuf_p);

                        If (InBuf_p = 0) then
                           begin
                               Blockread(fIn, OUTbuffer, 15000, Cnt);
                               InBuf_p := Cnt;
                           end;
                        Outbuffer[Cnt+1-InBuf_p]:=Outbuffer[Cnt+1-InBuf_p]-ID;
                        r_var := Outbuffer[Cnt+1-InBuf_p];
                        dec(InBuf_p);
                        ch := (r_var div 16)*256+ch;
                        r_var := r_var mod 16;
                   end;
                Inchard := true;
           end;
  End;
  {-----------------------------------}

  Procedure GetBuf;
  Var
    Gi     : Word;
    st     : string;
    p1_255 : P255;
    P1_80  : P80;

  Begin
    Gi := 1; St := '';
    While Gi <= OutBuf_p Do
    BEGIN
      If NOT (Inbuffer[Gi] IN ['Û', #13]) Then St := St + Inbuffer[Gi]
      Else
        Begin
          If (Inbuffer[Gi] = 'Û') Then
             Begin
                 Inc(Gi);
                 If Step > 0 Then Step := Step - 1;
             End
          Else
             If Step = 0 Then
                Begin
                   St := St + Replicate(' ', 80);
                   If St[1] = ';' Then
                      Begin
                          St[1] := ' ';
                          If St[2] <> ' ' Then
                             Begin
                                  St[2] := ' ';
                                  Hcfg^.Info[1] := '*'; { Not a portion }
                             End;
                          St[0] := #77;  { 78 is old value }
                          New(P1_80); P1_80^.Info := St;
                          P1_80^.Prev := Ccfg; P1_80^.Next := Nil;
                          Ccfg^.Next := P1_80; Ccfg := P1_80;
                      End
                   Else
                   BEGIN
                      If (St[1] = '*') and (St[2] = '*') Then
                         Begin
                              St[4] := '~'; St := #1 + St;
                              abcd  := 96;
                         End
                      Else
                      If (Tif = 80) and (St[1] In ['#', '@', '|']) Then
                         Begin
                             St := '   ' + #4 + '  ~' + #2 + St;
                             St[80]:= St[9];
                             St[10]:= #6;
                             If (St[9] = '|') Then St[9] := ' '
                             Else
                                Begin
                                     abcd := abcd + 1;
                                     St[9] := Char(abcd)
                                End;
                         End;
                      Case Tif Of
                          255: begin
                                  New(p1_255);
                                  If P1_255 <> Nil Then
                                     Begin
                                         P1_255^.Next    := Nil;
                                         P1_255^.Prev    := C255;
                                         P1_255^.Info    := St;
                                         If H255 = Nil Then H255 := P1_255
                                         Else C255^.Next := P1_255;
                                         C255 := P1_255;
                                     End;
                               end;
                          80 : begin
                                  New(p1_80);
                                  If P1_80 <> Nil Then
                                     Begin
                                         P1_80^.Next    := Nil;
                                         P1_80^.Prev    := C80;
                                         P1_80^.Info    := ST;
                                         P1_80^.Info[0] := #77; {78 is old }
                                         If H80 = Nil Then H80 := P1_80
                                         Else C80^.Next := P1_80;
                                         C80 := P1_80;
                                     End;
                               end;
                      End;
                   END;
                End;
          St := '';
          Inc(Gi);
        End;
      Inc(Gi);
    END;

    { Put the string ST back into Inbuffer in case some characters left }
    If Ord(st[0]) = 0 Then OutBuf_p := 0
    Else
      For OutBuf_p := 1 To Ord(st[0]) Do Inbuffer[OutBuf_p] := St[OutBuf_p];
  End;
  {-----------------------------------}

  Procedure OutcharD(kytu: char);       { General output (Decompression) }
  var
      ch : char;
  Begin
      ch := kytu;
      if OutBuf_p = 15000 then
         begin
              Case Dest Of
                 1: Getbuf;
                 2: begin
                       { To File }
                       Blockwrite(fOut, Inbuffer, Outbuf_p, Outbuf_p);
                       OutBuf_p := 0;
                    end
              End;
         end;
      If ch = 'Û' Then Inc(ItemCount);
      Inc(OutBuf_p);
      Inbuffer[OutBuf_p] := ch;
  End;
  {-----------------------------------}

  Procedure MakeTable;                { Reset table }
  Begin
       Max_code := Max_code + 1;
       if Max_Code = 256 then
          begin
               RootD^.Lcode:= Old_code;
               RootD^.Node := Finchar;
               Tail := Rootd;
          end
       else
          begin
               Tail := Tail^.Next;
               Tail^.Lcode := Old_code;
               Tail^.Node  := Finchar;
          end;
  End;

BEGIN
   SP        := 0;
   remain    := false;
   r_var     := 0;
   InBuf_p   := 0;
   OutBuf_p  := 0;
   ItemCount := 0;              { Items received after compressing }
   Step      := S_entry;

   { Make whole chaine }
   Rootd := Nil;
   for Ofs1 := 256 to 4095 do
       begin
            New(Tail);
            Tail^.Next := Nil;
            if Rootd = Nil then
               Rootd := Tail
            else
               Cur_nodeD^.next := Tail;
            Cur_NodeD := Tail;
       end;
   Seg_Node := Seg(Rootd^.Lcode);
   Ofs1     := Ofs(Rootd^.Lcode);

   if not Inchard(Code) then exit;
   OLD_code := Code;
   Finchar  := chr(Code);
   IF Finchar = 'Û' THEN BEGIN
   Outchard(Finchar);
   Max_code := 255;
   While Inchard(Code) do
         begin
              if code = 4095 then
                 begin
                      if not Inchard(Code) then exit;
                      OLD_code := Code;
                      Finchar  := chr(Code);
                      Outchard(Finchar);
                      Max_code := 255;
                      SP       := 0;
                      Tail     := Rootd;
                 end
              else
                 begin
                      In_Code := Code;
                      if Code > Max_code then
                         begin
                              inc(SP);
                              Stack[SP] := Finchar;
                              Code := Old_code;
                         end;
                      while Code > 255 do
                         begin
                              Cur_NodeD := Ptr(Seg_Node,Ofs1+(Code-256)*8);{ *7 if TP5.5 }
                              Code      := Cur_NodeD^.LCode;
                              inc(SP);
                              Stack[SP] := Cur_NodeD^.Node;
                         end;

                      Finchar := chr(code);
                      Outchard(Finchar);
                      While SP > 0 do
                         begin
                              Outchard(Stack[SP]);
                              dec(SP);
                         end;
                      MakeTable;
                      Old_code := In_code;
                 end;
         end;

   If OutBuf_p > 0 then
      Case Dest of
        1: Getbuf;
        2: Blockwrite(fOut, INbuffer, Outbuf_p, Outbuf_p)
      End;
   END;

   { Release all character Codes Table }
   While Rootd <> Nil Do
         Begin
              Tail := Rootd;
              Rootd := Rootd^.Next;
              Dispose(Tail);
         End;
   Decompress := Itemcount - S_entry;
END;
{-----------------------------------------}
                                          { Decompression }
Function D_File(Dest: Byte; dfname: string;
                 which, tif, Items, sitem: Byte): Byte;

         {      Dest   : 3. Array only - 1. To chain -
                       : 2. To file ( Place decompressed data in to file )
                dfname : Data file contains compressed infos
                which  : Block of file will be read if decompress to memory
                Tif    : Motif de la node
                Items  : Number of Item read from file
                sitem  : start item to read.
                         Open Dialog box in case sitem = 0
                Return : Number of entries actually Decompressed }
var
   CItemNo : byte;
   Di, Dj  : Word;
begin
   { CMF support }
   If CmfOK and OnMusic Then
      Begin
           MusicNo := MusicNo + 50;     { A signal }
           Onmusic := False;
           CmfPause;
      End;
   { End of CMF support }

   CItemNo := 0;
   {$I-}
   Assign(fIn, dfname);
   Reset(fIn, 1);
   {$I+}

   If IOResult = 0 then
      Begin
        Blockread(fIn, F_header, Sizeof(Fdata));
        If F_Header.IDname = Author Then
         BEGIN
            Case Dest of
            1: if F_header.EItemNo[which] > 0 Then
               BEGIN
                CItemNo := Items;
                { Total memory for data chain }
                Case Tif of
                   80:;
                  255:;
                End;
                If Size_out + 3900*Sizeof(CodeTablePtr) > MemAvail Then
                  BEGIN
                    Message(12,'Not enough memory. Sorry !',True,True,True);
                    CItemNo := 255;
                  END
                Else
                  BEGIN
                    Di := sitem;
                    If (Di = 0) and (Items = 1) Then
                    Begin
                        Backup_screen;
                        Color := 32;
                        zoom(12,25,20,67,Single_frame);
                        col := 34; row := 14;
                        Write('There are ',F_header.EItemNo[Which]:2, ' exercise(s)');
                        Gotoxy(30,16); Write('for this level. Please enter your');
                        Gotoxy(31,18); Write('desired exercise number:');
                        Row := 18; Col := 56;
                        Geti(Di); Readg;
                        Restore_screen;
                    End;

                   If (EXIT_key = ESC_key) or (Di < 1) or (di > F_header.EItemNo[Which]) Then
                      CItemNo := 0
                   Else
                   BEGIN
                     ID := F_header.CodeID;
                     Message(12, 'Loading...', False, False, False);
                     Unload(Tif, True);        { Free current chain }
                     Size_out := 0;
                     For Dj := 1 To Which - 1 Do
                       Size_out := Size_out + F_header.Esize[Dj]; { step over }
                     Seek(fIn, Sizeof(Fdata) + Size_out);
                     CItemNo :=
                       Decompress(Dest, Tif, CItemNo, DI, F_Header.EItemNo[which]);
                   END;
                  END;
               END;
            2: BEGIN
                { to file }
                For CItemNO := 1 To F_Header.ENumber Do
                Begin
                  Fname := Trim(F_Header.Ename[CItemNO]);
                  {$I-}
                  Assign(fOut, Fname);
                  Rewrite(fOut, 1);
                  {$I+}
                  If IoResult <> 0 Then Continue;

                  ID := Cks;
                  Size_out := 0;
                  For DI := 1 To CItemNo - 1 Do
                    Size_out := Size_out + F_header.Esize[DI]; { step over }

                  Seek(fIn, Sizeof(Fdata) + Size_out);
                  Backup_screen;
                  Message(12, 'Extracting: '+ Fname, False, False, False);
                  if Decompress(Dest, 0, F_Header.EItemNo[CItemNo] + 1, 0, F_Header.EItemNo[CItemNo]) = 0 then
                  begin
                     Restore_screen; Backup_screen;
                     Message(12, 'Wrong Password: '+ Fname, True, False, False);
                  end;
                  Restore_screen;
                  Close(fOut);
                End;
               END;
            3: Begin
                  { to array only }
                  ID := F_header.CodeID;
                  CItemNo := 1;
                  Size_out := 0;
                  For Dj := 1 To Which - 1 Do
                      Size_out := Size_out + F_header.Esize[Dj]; { step over }
                  Seek(fIn, Sizeof(Fdata) + Size_out);
                  Decompress(Dest, Tif, Which, 1, F_Header.EItemNo[which]);
               End;
            End;
         END;
        Close(fIn);
      End;
   if (CItemNo = 0) or (CItemNo = 255) Then
      begin
          if CItemNo = 0 Then
             Message(12, 'No data found !', true, true, true);
          CItemNo := 0
      end;

   { Cmf support }
   If CmfOk and (MusicNo > 50) Then
      Begin
           MusicNo := MusicNo - 50;     { A signal to stop D_file back }
           If D_File(3, MUSIC, MusicNo, 80, 1, 1) > 0 Then
              Begin
                 CmfGoOn;
                 Onmusic := True;
              End;
      End;
   { End of Cmf support }
   D_File := CItemNo;
End;
{---------------------------------}

Function C_file: Boolean;
Var
   dfnum, CI: Byte;
   Tmpw     : word;
Begin
   { CMF support }
   If CmfOK and OnMusic Then
      Begin
           MusicNo := MusicNo + 50;     { A signal }
           Onmusic := False;
           CmfPause;
      End;
   { End of CMF support }

   backup_screen;
   color := 11 + 8*10;
   zoom(7, 20, 16, 60, Single_frame);
   box(10, 23, 10, 57, Single_bar);

   row := 9; col := 32;
   write('Files Compression');

   dfnum := 0;
   While dfnum < Emax Do
         Begin
             fname := Replicate(' ',13);
             row := 12; col := 26;
             Write('#', dfnum+1:2, '. File name: ');
             gets(Fname); readg;
             fname := Trim(Fname);
             if fname = '' Then break
             else
                 Begin
                     dfnum := dfnum + 1;
                     F_header.Ename[dfnum] := fname;
                 End;
         End;

   If dfnum > 0 Then
      Begin
           Fname := Replicate(' ',13);
           row := 14; col := 25;
           Write('Compress To File: ');
           gets(Fname); readg; Fname := Trim(Fname);
           If fname > '' Then
              Begin
                   {$I-}
                   Assign(fOut, fname);
                   Rewrite(fOut, 1);
                   {$I+}
              End
           Else
              dfnum := 0;
      End;

   If (IoResult <> 0) or (dfnum = 0) Then C_file := False
   Else
      Begin
         BlockWrite(fOut, F_header, Sizeof(F_header));

         For CI := 1 To dfnum Do
             Begin
                 Size_out := 0;                  { Increase By Outchar }
                 ItemCount:= 0;                  { Increase By Inchar }
                 OutBuf_p := 0;
                 fname    := F_header.Ename[CI];

                 {$I-}
                 Assign(fIn, Fname);
                 Reset(fIn,1);
                 {$I+}

                 if Ioresult = 0 Then
                    begin
                        Message(12, 'Compressing #'+char(CI+48),False,false,false);
                        Compress;
                        Close(fIn);
                    end;

                 if OutBuf_p > 0 then
                    Begin
                        for Tmpw := 1 to OutBuf_p do
                            OUTbuffer[Tmpw] := OUTbuffer[Tmpw] + Cks;
                        Size_out := Size_out + OutBuf_p;
                        Blockwrite(fOut, OUTbuffer, OutBuf_p, Tmpw);
                    End;

                 With F_Header Do
                    Begin
                        ESize[CI]   := Size_out;
                        EItemNo[CI] := ItemCount - 1;
                    End;
             End;
         For Ci := 1 To 14 do F_header.IDname[CI] := Author[CI];
         F_header.ENumber := dfnum; F_header.CodeID := Cks;
         Seek(fOut, 0);
         BlockWrite(fOut, F_header, Sizeof(F_header));
         Message(12, 'Compression OK!', true, false, false);

         Close(fOut);
         C_file := True;
      End;
   Restore_screen;
   { Cmf support }
   If CmfOk and (MusicNo > 50) Then
      Begin
           MusicNo := MusicNo - 50;     { A signal }
           If D_File(3, MUSIC, MusicNo, 80, 1, 1) > 0 Then
              Begin
                 CmfGoOn;
                 Onmusic := True;
              End;
      End;
   { End of Cmf support }
End;
{---- End of Compress and Decompress Processes ----}

{============================ Menu Process }
Function GetMenu(var pad: byte; var pop: byte): Boolean;

Var
  o_color, o_row, o_col, o_getcolor, o_proc, o_prompt: byte;
  padno, popno, i: byte;

Begin
  O_proc := C_proc; C_proc := 0;
  o_color := color; o_row := row; o_col := col;
  o_getcolor := get_color; o_prompt := prompt_point;
  Backup_screen; box_base := 1; get_color := 95; color := 63; cursor_off;

  padno := 1; popno := 0;
  Repeat
     prompt_point := padno;
     Exit_key1 := Down_key; Exit_key2 := F10_key;

     If (Popno > 0) Then Exit_key := 0
     Else Exit_key := 1;

     row := 0;
     for i := 1 to n do
         begin
             col := padpos[i];
             prompt(padprompt[i]);
         end;
     read_prompt;
     If (Exit_key = Esc_key) or (Exit_key = F10_key) Then Break;

     Backup_screen;
     padno := prompt_point; popno := 1; Exit_key := 1;

     color := 48;
     box(1,padpos[padno],2+padlength[padno],padpos[padno]+padwidth[padno],single_frame);

     row := 1; Col := padpos[padno] + 1;
     prompt_point := popno;
     Exit_key1 := Left_key; Exit_key2 := Right_key;
     For i := 1 To Padlength[padno] Do
         Begin
            Row := Row + 1;
            if (popprompt[padno, i][1] = 'Ä') Then
               Begin
                  color := 48;
                  box(row, col-1, row, col+padwidth[padno]-1,Single_bar);
               End
            else
               Begin
                  color := 63;
                  prompt(popprompt[padno, i]);
               End;
         End;
     read_prompt;

     Case Exit_key of
          Left_key:
               if padno > 1 then
                  padno := padno - 1
               else
                  padno := n;
          Right_key:
               if padno < n then
                  padno := padno + 1
               else
                  padno := 1;
          Esc_key:
               Popno := 0;
          Else
               popno := prompt_point;
     End;
     Restore_screen;
  Until (Exit_key = Enter_key)or(Exit_key = 0)or(Exit_key = F10_key);
  color := o_color; row := o_row; col := o_col;
  get_color := o_getcolor; prompt_point := o_prompt;
  Restore_screen;
  Exit_key1 := ESC_key; Exit_key2 := ESC_key;

  if (PopNo=0) or (((PopNo=4) or (PopNo=3)) and (padno=4)) or
       ((CmfOK) and (PopNo=6) and (padno=3)) then begin
     case PopNo of
     3: if clock then begin
           popprompt[4,3][11] := 'N'; popprompt[4,3][12] := ' ';
           clock := False;
        end
        else begin
           popprompt[4,3][11] := 'F'; popprompt[4,3][12] := 'F';
           clock := True
        end;
     4: If popprompt[4,4][11] = 'N' Then begin
           popprompt[4,4][11] := 'F'; popprompt[4,4][12] := 'F';
        end
        Else begin
           popprompt[4,4][11] := 'N'; popprompt[4,4][12] := ' ';
        end;
     6: If PopPrompt[3,7][11] = 'N' Then Begin
           MusicNo := 1+Random(6);
           If D_File(3, MUSIC, MusicNo, 80, 1, 1)>0 Then Begin
              CMFPlay(Ptr(Seg(Inbuffer[4]),Ofs(Inbuffer[4])));
              popprompt[3,7][11] := 'F'; popprompt[3,7][12] := 'F';
              OnMusic := True;
           End;
        End
        Else Begin
           popprompt[3,7][11] := 'N'; popprompt[3,7][12] := ' ';
           OnMusic := False; MusicNo := 0;
           CMFStop;
        End;
     end;
     GetMenu := False;
  end
  else Begin pad := padno; pop := popno; GetMenu := True; End;
  C_proc := O_proc
End;

{ ====================== Network Support Procedures =========== }
Function  GetNumFromUsername: byte;
var
      ni   : byte;
      ntong: word;
begin
  fname := #2#22#0; fname[0] := #0;
  Net.Sbuf.Msg[0] := #0; Net.Sbuf.Msg[1] := #62;
  asm
      push   es

      mov    ah, 0DCh
      int    021h
      mov    byte ptr fname[3], al

      push   ds
      pop    es
      MOV    AH, 0E3h
      lea    si, fname
      lea    di, Net.Sbuf.Msg
      int    021h

      xor    al, al
      mov    di, offset Net.Sbuf.Msg + 8
      mov    cx, 255
      repne  scasb
      mov    bl, 254
      sub    bl, cl
      mov    byte ptr Net.Sbuf.Msg[7], bl

      pop    es
  end;
  Net.Sbuf.Msg[0] := #64;
  Net.Sbuf.Msg := copy(Net.Sbuf.Msg, 8, ord(Net.Sbuf.Msg[7]));
  ntong := 0;
  for ni := 1 to Ord(Net.Sbuf.Msg[0]) do
      if Net.Sbuf.Msg[ni] in ['0'..'9'] then
         ntong := 10*ntong + Ord(Net.Sbuf.Msg[ni]) - 48;
  GetNumFromUsername := ntong;
end;
{========================== Receive a packet by ipx }

procedure Receive_packet;
var
   ri: byte;
begin
     {======= Receive ECB setting ...}
     Net.Recb.In_use           := 0;
     Net.SIPX.CheckSum         := $FF;
     {RECB.Link_address     := nil;}
     Net.RECB.Event_svc_Routine:= nil;

     Net.RECB.Socket_Number[1] := lo(rsocket);
     Net.RECB.Socket_Number[2] := hi(rsocket);

     Net.RECB.Fragment_Count     := 2;
     Net.RECB.Fragment[1].Address:= @Net.Ripx;
     Net.RECB.Fragment[1].Length := Sizeof(IPXHeader);
     Net.RECB.Fragment[2].Address:= @Net.Rbuf;
     Net.RECB.Fragment[2].Length := Sizeof(Net.Rbuf);

     IPX_Listen_Packet(@Net.RECB);
end;
{========================== Send a packet by ipx }

procedure Send_packet;
var
   si : byte;
begin
     Net.Secb.In_use             := $FF;
     Net.SIPX.CheckSum           := 0;
     Net.SIPX.Transport_Control  := 0;
     Net.Sipx.Length             := Sizeof(IPXHeader)+Sizeof(Net.Sbuf);
     Net.SIPX.Packet_type        := 4;

     Net.SIPX.Dest_Network_socket[1] := lo(rsocket);
     Net.SIPX.Dest_Network_socket[2] := hi(rsocket);

     {SECB.Link_address       := nil;}
     Net.Secb.Event_svc_routine := Nil;
     Net.Secb.Socket_Number[1]  := lo(ssocket);
     Net.Secb.Socket_Number[2]  := hi(ssocket);

     Net.Secb.Fragment_Count        := 2;
     Net.Secb.Fragment[1].Address   := @Net.SIPX;
     Net.Secb.Fragment[1].Length    := Sizeof(IPXHeader);
     Net.Secb.Fragment[2].Address   := @Net.Sbuf;
     Net.Secb.Fragment[2].Length    := Sizeof(Net.Sbuf);

     If Not Net.Sbuf.Ok then
        begin
             { Set value to interface to all bodies }
             for si := 1 to 4 do Net.SIPX.Dest_Network_number[si]:= $FF;
             for si := 1 to 6 do begin
                 Net.SIPX.Dest_Network_node[si]  := $FF;
                 Net.Secb.Immediate_Address[si]  := $FF;
             end;
        end;
     IPX_Send_Packet(@Net.Secb);
     Net.Sbuf.Ok := False; { I'm just looking for you }
end;
{ ====================== End of Network Support Procedures =========== }

Function LgChoose(lesson: byte): Byte;
var
     language: byte;
Begin
     backup_screen;
     color := 31; Demo(True);

     if lesson = 0 then
     begin
        zoom(8,20,16,62,Single_frame);
        box(11,23,11,59,Single_bar);

        row := 10; col := 33; write('Language Testing');
        row := 13;
        prompt_point := 1;
        col := 29; prompt(' English ');
        col := 43; prompt(' Fran‡ais ');
        read_prompt;
     end;

     If (Exit_key <> Esc_key) or (lesson > 0) Then
        Begin
          if lesson = 0 then
             begin
                Language := prompt_point;
                row := 10; col := 33; write(' Testing Levels ');
                row := 13; col := 28; write('                         ');
                col := 26;       prompt(' A level ');
                col := col + 11; prompt(' B level ');
                col := col + 11; prompt(' C level ');
                read_prompt;
                language := 3*(language-1)+prompt_point;
             end
          else language := lesson;
             If (Exit_key <> Esc_key) Then
               Begin
                 Rtime := 0;
                 If D_File(1,PRETEST_DAT,language,80,1, 0) > 0
                 Then Begin
                       C80 := H80; S80 := H80;
                       if ExeDefault = 0 then
                          if Cur_job[3] = 'C' Then Time := 90
                          else Time := 60;
                       if (ExeDefault=0) or (Network = '') then
                          Cur_job:=Copy(' EA EB EC FA FB FC',(language-1)*3+1,3)
                       else  Cur_job := Network;
                       Language := 69; { Signal if Lgchoose is ok }
                      End;
               End;
        End;
     restore_screen;
     Lgchoose := Language;
End;
{---- Make all Non-Depend displaying on screen ----}

{$F+,S-,W-}
Procedure Timeshow; Interrupt;
begin
     GetTime;
     If NotTimeShow Then
     BEGIN
     If CmfOK and OnMusic and (CmfStatus = 0) Then
        CMFPlay(Ptr(Seg(Inbuffer[4]),Ofs(Inbuffer[4])));
     NotTimeShow := False;
     tstr := Cur_job + '               ';
     if C_proc > 0 Then
     BEGIN
     If C_proc < 10 Then
        begin
            str(RTime-1:2, tsso);
            tstr[5] := tsso[1];
            tstr[6] := tsso[2];
            tstr[7] := ':';
            str(159-Second : 3, tsso);
            tstr[8] := tsso[2];
            tstr[9] := tsso[3];

            if Second <> 0 Then SubMin := True
            else
               if SubMin and (RTime > 0) Then
                  begin
                       RTime  := RTime - 1;
                       SubMin := false
                  end;
        end;
     If clock then
        begin
             tstr[15] := ':';
             if Mili_second > 60 Then mem[Video_seg: 127] := 55
                else mem[Video_seg: 127] := 52;
             if hour < 13 Then
                begin str(hour : 2, tsso) ; tstr[18] := 'a'; end
             else
                begin str(hour-12:2, tsso); tstr[18] := 'p' end;
             tstr[13] := tsso[1];
             tstr[14] := tsso[2];
             str(Minute+100:3, tsso);
             tstr[16] := tsso[2];
             tstr[17] := tsso[3];
        end;
     END;
     for ti := 1 to 18 do mem[Video_seg: 96+2*ti] := Ord(tstr[ti]);
     NotTimeShow := True;
     END;
end;
{$F-,S+}

{===================================}
procedure  print(Cmd: byte); forward;
{===================================}

Procedure SheetTest(Help, Show, Nomenu: Boolean);
var
     Old_col, Old_row, Point: Byte;
     P1_80                  : P80;
     Sch                    : char;
     ScrollUp               : word;
     Setpos                 : Integer;

     Procedure  display;
     Begin
        Cursor_OFF;
        Old_col := Col; Old_row := Row;
        P1_80 := S80; Row := 2;
        While (row < 23) and (P1_80 <> Nil) Do
          Begin
            Col := 2;   { 1 is Begin column }
            If Not Show and(P1_80=C80)and(P1_80^.Info[80] In ['#','@','|']) Then
               Begin
                   Color := Color + 25;
                   Write(P1_80^.Info);
                   Color := Color - 25;
               End
            Else
               Write(P1_80^.Info);
            P1_80 := P1_80^.Next;
            Row := Row + 1;
          End;
        Cursor_On; Gotoxy(Old_col, Old_Row);
     End;

     Procedure Ketqua(Indong: Boolean);
     BEGIN
     If Indong then FillChar(Net.SBuf.Ans, Sizeof(BufResult), '?');

     P1_80 := H80; Old_row := 0; Point := 0; Setpos := -3;
     While P1_80 <> Nil Do
         Begin
              { His answer }
              If P1_80^.Info[5] = #222 then
                 Net.SBuf.Ans[Setpos+2] := P1_80^.Info[9];

              If (P1_80^.Info[80] = '@') Then
                 Begin
                   { correct answer }
                   Net.SBuf.Ans[Setpos+3] := P1_80^.Info[9]; { Item note }

                   If P1_80^.Info[5] = #222 Then Point := Point + 1;
                   If Show Then Sch := #2 Else Sch := #6;
                   Repeat
                      P1_80^.Info[10] := Sch;
                      If (P1_80^.Next <> Nil)and((P1_80^.Next)^.Info[80]='|')
                      Then P1_80 := P1_80^.Next;
                   Until (P1_80^.Info[80] <> '|') or (P1_80^.Info[10] = Sch);
                 End
              Else
                 If (P1_80^.Info[1] = #1) Then
                    Begin
                        { New Question }
                        if Setpos < Sizeof(BufResult)-4 then
                           Setpos := Setpos + 4;
                        Net.SBuf.Ans[Setpos] := P1_80^.Info[2]; { Qs Number }
                        Net.SBuf.Ans[Setpos+1] := P1_80^.Info[3];

                        If Old_row > 9 Then
                           P1_80^.Info[2] := Char(48 + Old_row Div 10)
                        Else
                           P1_80^.Info[2] := ' ';
                        P1_80^.Info[3] := Char(48 + Old_row Mod 10);
                        Old_row := Old_row + 1
                    End;
              P1_80 := P1_80^.Next;
         End;

     If Indong Then
       Begin
           Old_Col := Col; Color := Color+48; Col := 1; Row := 1;
           If NoMenu Then Write(' Print Sheet-Test Preview ')
           Else Write(' Note: ', Point,' correct answer(s) for ',
                     Old_row, ' questions in ', Time-Rtime,' minutes ');
           {    Write(' Note: ', Point,' cau tra loi dung tren ',
                     Old_row, ' cau. Thoi gian ', Time-Rtime,' phut. '); }
           col := Old_col; row := Old_row; Color := Color - 48;
       End;

     P1_80 := S80; Row := 2;
     While P1_80 <> C80 Do
           Begin
               Row := Row + 1;
               P1_80 := P1_80^.Next;
           End;
     END;

     Procedure Addline(var a: BufResult);
     var
          Pos : byte;
     Begin
       if InBaiGiai then
       BEGIN
          Setpos := 1; Pos := 12;
          Repeat
                if (Pos = 12) then
                   begin
                        { Help screen to scroll up }
                        ScrollUp := ScrollUp + 1;
                        if ScrollUp > 20 then S80 := S80^.Next;

                        { make new node }
                        New(P1_80); P1_80^.Next := nil;
                        C80^.Next := P1_80; P1_80^.Prev := C80;
                        P1_80^.Info := Replicate(' ', 77);
                        C80 := C80^.Next;
                   end;
                if (Setpos mod 4 = 1) then
                   if (a[Setpos] = '?') then break
                   else
                       begin P1_80^.Info[Pos] :=  ' '; pos := pos + 1 end;

                P1_80^.Info[Pos] := a[Setpos];
                pos := pos + 1; Setpos := Setpos + 1;
                if pos > 76 then pos := 12;
          until False;
       END;
     End;

     Procedure Contact;
     var
       WentOn: Boolean;
       ci, Howlong: Byte;

     BEGIN
     { for reviewing }
     if (H80^.info[1] <> '#') then      { #: is first char of #RegNo }
     If ipx_install THEN
     Begin
        { Network installed OK }
        Unload(80, True);
        WentOn := True;
        ipx_open_socket(ssocket);
        ipx_open_socket(rsocket);

        FillChar(Net, 2*(Sizeof(ECB)+Sizeof(IPXHeader)), #0);
        IPX_get_netnode_address(@Net.Sbuf.NetNo);     { get Network address }

        { Repare message }
        Str(Point:3, Net.Sbuf.Who);
        Str(Old_Row:3, Net.Rbuf.Who);
        Str(Rtime:3, Net.Sbuf.Msg);
        Net.Rbuf.Msg := Net.Rbuf.Msg + ' ' + Net.Sbuf.Who+
                        '/' + Net.Rbuf.Who + '   ' + Net.Sbuf.Msg;
        GetNumFromUserName;
        Net.Sbuf.Msg := Net.Rbuf.Msg + ' '+
                        Copy(Network+'  '+Net.Sbuf.Msg+Replicate(' ',18),1,18);
        Net.Sbuf.Who := Network; NET.Rbuf.Who := Network; Net.Sbuf.Ok := False;

        if Network = 'HOT' then
           begin
               Net.NetWin[19,38] := Net.NetWin[19,38] + 15;{change HOT to WSs}
               Net.NetWin[19,39] := Net.NetWin[19,38] - 4;
               Net.NetWin[19,40] := Net.NetWin[19,38] + 28;
               New(H80); New(C80); New(S80);
               C80^.Info := Net.Sbuf.Msg; C80^.Prev := S80; C80^.Next := Nil;
               H80^.Prev := Nil; H80^.Next := S80;
               H80^.Info := '#RegNo     Ex Full Name                      Result  LTime EMP. Network      ';
               S80^.Info := '========== == ============================== ======= ===== ================= ';
               S80^.Prev := H80; S80^.Next := C80; S80 := H80;
               ScrollUp := 1; Addline(Net.Sbuf.Ans);
               Point    := 1; { Count up received message from WSs }
           end;

        howlong := 249; ci := 55;
        Repeat
          If WentOn and (Net.REcb.In_use = 0) then
            BEGIN
              If (Network <> Net.Rbuf.Who) then
              BEGIN
                { Reply soon }
                { Net.SEcb.Connection_ID      := Net.REcb.Connection_ID; }
                Net.SEcb.immediate_address  := Net.REcb.immediate_address;
                Net.SIpx.dest_network_number:= Net.Rbuf.Netno;
                Net.SIpx.dest_network_node  := Net.Rbuf.Netad;
                Net.SBuf.Ok := True; { I know you, OK ! }

                if Network = 'HOT' then
                   begin
                      Net.Sbuf.Msg := Net.Rbuf.Msg;
                      { Check this one and add new ? }
                      C80 := H80; ScrollUp := 1;
                      while (C80^.Next <> Nil) and ((C80^.Info[1] = ' ') or
                             (C80^.Info <> Net.Rbuf.Msg)) do
                            begin ScrollUp := ScrollUp + 1;
                                  C80 := C80^.Next;
                            end;
                      If C80^.Info <> Net.Rbuf.Msg Then
                         begin
                           { This is a newOne for HOT, add it to list }
                           New(P1_80); P1_80^.Info := Net.Rbuf.Msg;
                           P1_80^.Prev := C80; P1_80^.Next := Nil;
                           C80^.Next := P1_80; C80 := C80^.Next;
                           if ScrollUp > 20 then S80 := S80^.Next;
                           { his result }
                           Addline(Net.Rbuf.Ans); Display; cursor_off;
                           { add Receiced Message count then display }
                           Point := Point + 1;
                           Net.NetWin[16,57]:=(color+82)*256+48 +(Point mod 10);
                           Net.NetWin[16,56]:=(color+82)*256+48 +(Point mod 100) div 10;
                           Net.NetWin[16,55]:=(color+82)*256+48 +(Point div 100);
                         end;
                   end
                else
                   if (Net.Rbuf.OK) and (Net.Sbuf.Msg = Net.Rbuf.Msg) then
                      begin
                        { Msg given back to make sure HOT already knows me, OK }
                        WentOn := False; Key := 26368;  { Don't try any more }
                      end;
                Net.Rbuf.Who := Network;
              END;
              Receive_packet;
            END
          Else delay(1);
          Ipx_breath;

          {Restore Netwin}
          for row := 15 to 20 do
              for col := 19 to 60 do
                  Memw[Video_seg:160*row+2*col] := Net.NetWin[row, col];
          { Ipx_breath; delay(1); change by above lines }

          howlong := howlong + 1;
          if howlong mod 25 = 0 then
             begin
                  Net.NetWin[19,ci] := Net.NetWin[19,ci] - 2;
                  if howlong = 250 then
                     begin
                       Memw[Video_seg:3040+2*ci] := Net.NetWin[19, ci];
                       Ipx_breath; delay(50); Howlong := 1; ci := 46;
                     end
                  else ci := ci + 1;
                  Net.NetWin[19,ci] := Net.NetWin[19,ci] + 2;
             end;

          If (Net.SEcb.in_use = 0) and
             ((Network = 'HOT') or (Net.Sbuf.Ok and WentOn)) then Send_packet
          Else Ipx_breath;

          If Keypressed and WentOn then key := Inkey;
        Until (Not WentOn or (Network = 'HOT')) and (Key = 26368);

        { Stop network jobs }
        IPX_cancel(@Net.RECB);
        IPX_cancel(@Net.SECB);
        IPX_close_socket(Rsocket);
        IPX_close_socket(Ssocket);
     End
     else
        Message(19, 'Non supported IPX protocol !', True, True, True);
     END;
begin
     backup_screen;
     If (H80 = Nil) then
        Begin
             message(12, 'Data not load !', True, true, false);
             Restore_screen;
             EXIT;
        End;
     C_proc := 1;
     color := 31; box_base := 0; box(1,0,23,79,single_frame); cursor_on;
     If Help and (Rtime = 0) Then Rtime := Time;

     if Exedefault > 0 then
     BEGIN
        color := color + 82;
        box(15, 19, 20, 60, single_frame);
        box(18, 19, 18, 60, Single_bar);
        Net.Rbuf.Msg := Replicate(' ',10);
        Net.Sbuf.Msg := Replicate(' ',30);
        Str(ExeDefault:2, Net.Rbuf.Who);
        Repeat
           col:= 24; row := 16; write('S– BD:');     Gets(Net.Rbuf.Msg);
           col:= 20; row := 17; write('H” v… Tˆn:'); Gets(Net.Sbuf.Msg);
           Readg;
        Until (Net.Rbuf.Msg[1]<>' ') and (Net.Sbuf.Msg[1]<>' ');
        row:=24; Col:=37; color:=37; write(' ',Net.Rbuf.Msg,' ',Net.Sbuf.Msg);
        color := color + 76;
        Net.Rbuf.Msg := Net.Rbuf.Msg+' '+Net.Rbuf.Who+' '+ Net.Sbuf.Msg;
        col := 21; row := 19;
        write('Now, looking for HOT:  ÓÔÏÏÏÏÏÏÏÏÏÑÓÔ');
        color := color - 82;
        { Save NetWin }
        for old_row := 15 to 20 do
         for old_col := 19 to 60 do
          Net.NetWin[old_row, old_col]:=Memw[Video_seg:160*old_row+2*old_col];
     END;
     Ketqua(Show Or Nomenu);

     Display; KEY := Exit_KEY;
     While ((KEY <> ESC_KEY)or(ExeDefault > 0)) and (KEY <> 26368) do
        If (Rtime = 0) or (KEY = 28928) then
          begin
             Cursor_off;
             If Rtime = 0 then
                Message(10, 'Time is over !', False, False, True)
             else
                Message(10, 'Time is over !', False, False, False);
             Ketqua(true);
             If (Network = 'HOT') or (Network = 'WSs') then Contact;
             While Key <> 26368 do
             Begin
                 Key := Inkey;
                 if (KEY = ESC_KEY)and(ExeDefault = 0) then KEY := 26368;
             End;
             Cursor_on;
             If Network = 'HOT' then Print(2);
          end
        else
          begin
            If keypressed then
               begin
                  KEY := inkey;
                  case KEY of
                    F1_KEY: giupdo;
                    UP_KEY:
                        begin
                           If (Row > 2)  and (C80^.Prev <> Nil) Then
                              Begin
                                 Row := Row - 1;
                                 C80 := C80^.Prev;
                              End
                           Else
                              If S80^.Prev <> Nil Then
                                 Begin
                                     S80 := S80^.Prev;
                                     C80 := S80;
                                 End;
                           Display;
                        end;

                    DOWN_KEY:
                        begin
                           If (Row < 22) and (C80^.Next <> Nil) Then
                              Begin
                                 Row := Row + 1;
                                 C80 := C80^.Next;
                              End
                           Else
                              If C80^.Next <> Nil Then
                                 Begin
                                     S80 := S80^.Next;
                                     C80 := C80^.Next;
                                 End;
                           Display;
                        end;
                    PgUp_KEY:
                        Begin
                           If Row > 2 Then C80 := S80
                           Else
                              Begin
                                  Row := 21;
                                  While (S80^.Prev <> NIl)and(Row > 0) Do
                                        Begin
                                            Row := Row - 1;
                                            S80 := S80^.Prev;
                                        End;
                                  C80 := S80;
                              End;
                           Row := 2;
                           Display;
                        End;
                    PgDn_KEY:
                        Begin
                           If Row < 22 Then
                              While (Row < 22) and (C80^.Next <> Nil) Do
                                  Begin
                                       Row := Row + 1;
                                       C80 := C80^.Next;
                                  End
                           Else
                              Begin
                                  Row := 2;
                                  While (Row < 22) and (C80^.Next <> NIl) Do
                                        begin
                                            Row := Row + 1;
                                            S80 := S80^.Next;
                                            C80 := C80^.Next;
                                        End;
                                  Row := 22;
                              End;
                           Display;
                        End;
                    CtrlHome_key:
                        Begin
                            Row := 2; S80 := H80; C80 := H80;
                            Display;
                        End;
                    CtrlEnd_key:
                        Begin
                            While C80^.Next <> Nil Do C80 := C80^.Next;
                            S80 := C80; Row := 2;
                            While (Row < 22) and (S80^.Prev <> Nil) Do
                                  Begin
                                      Row := Row + 1;
                                      S80 := S80^.Prev;
                                  End;
                            Display;
                        End;

                    Home_KEY: Gotoxy(1, Row);
                     End_KEY:
                        begin
                            Col := 78;
                            While (Col > 1) and (C80^.Info[Col-1] < #33) Do
                                  Col := Col - 1;
                            Gotoxy(Col, Row);
                        end;
                    RIGHT_KEY:
                        begin
                            col := col + 1;
                            if col > 78 then col := 1;
                            Gotoxy(Col, Row);
                        end;
                    LEFT_KEY:
                        begin
                            col := col - 1;
                            if col < 1 then col := 78;
                            Gotoxy(Col, Row);
                        end;

                    ENTER_KEY, SPACE_BAR:
                        If Not Show and (C80^.Info[80] In ['@', '#']) Then
                        Begin
                            P1_80 := C80;
                            While ((P1_80^.Prev)^.Info[80] In ['@','#','|'])
                                Do P1_80 := P1_80^.Prev;
                            While (P1_80^.Info[80] In ['@','#','|']) Do
                                         Begin
                                             P1_80^.Info[5] := ' ';
                                             P1_80^.Info[6] := ' ';
                                             P1_80 := P1_80^.Next;
                                         End;
                            C80^.Info[5] := #222;
                            C80^.Info[6] := #223;
                            Display;
                            If Help and (C80^.Info[80] In ['#','|']) and
                               (popprompt[4, 4][12] = 'F') Then Bell(3);
                        End;
                    F9_KEY:
                        If (Not Nomenu) and (ExeDefault = 0) Then
                        Begin
                            Cursor_off;
                            If Getmenu(PAD, POP) Then KEY := ESC_KEY
                            Else Cursor_on;
                        End;
                    26368: Key := 28928; { Ctrl+F10 -> Ctrl+Alt+F10 }
                  end;
               end;
          end;
     restore_screen;
     cursor_off; C_proc := 10;
end;
{===================================}

procedure  print(cmd: byte);
Label
   Error_Printing, NoError_Printing;
var
   pf   : text;
   Pch  : char;
   pst  : String[80];
   OH80, Os80, Oc80, PP80       : P80;
   pi, Pj, pline, pcount, Qcount: byte;
   A_answer : array[1..120] of Byte;
   {-----------------------------------}

   Function Outstring: Boolean;
   Var
      PP1_80: P80;
      WstrEr: Boolean;
   Begin
      WstrEr := False;
      If Prompt_point = 1 Then
         Begin
            New(PP1_80);
            If PP1_80 <> Nil Then
               Begin
                   PP1_80^.Next   := Nil;
                   PP1_80^.Prev   := OC80;
                   PP1_80^.Info   := Left(Pst + Replicate(' ', 80), 80);
                   PP1_80^.Info[0]:= #77;  { Old value is 78 }
                   If OH80 = Nil Then OH80 := PP1_80
                   Else OC80^.Next := PP1_80;
                   OC80 := PP1_80;
               End
            Else WstrEr := True;
         End
      Else
         Begin
               {$I-}
               writeln(Pf, Pst);
               {$I+}
               If IoResult <> 0 then WstrEr := True;
         End;
      Outstring := WstrEr;
   End;
begin
     backup_screen;
     If H80 = Nil then
        Begin
             message(12, 'Data not load !', True, true,false);
             Restore_screen;
             EXIT;
        End;
     Goto NoError_Printing;
     Error_Printing: message(12, 'Not enough space. Retry !', True, False, False);
     NoError_Printing:
     if Cmd = 0 then Demo(true);
     color := 49;
     zoom(8, 18, 16, 62, Single_frame);
     box(11, 21, 11, 59, Single_bar);
     row := 10; col := 28;
     write('Print Test-Sheets To ...');
     if Cmd = 0 then
        begin
            prompt_point := 1;
            row := 13; col := 23; prompt('  Preview  ');
            row := 13; col := 35; prompt('  Printer  ');
            row := 13; col := 47; prompt(' Text File ');
            read_Prompt;
        end
     else prompt_point := Cmd;

     if EXIT_KEY <> ESC_KEY then
        If prompt_point = 1 Then pst := ''
        Else
           Begin
               backup_screen;
               If prompt_point = 2 Then pst := 'LPT1' + replicate(' ', 31)
               Else pst := replicate(' ', 35);
               repeat
                  row := 13; col := 23;
                  gets(pst);
                  readg;
                  pst := trim(pst);
                  If (EXIT_KEY <> ESC_KEY) and (Pst[0] > #0) Then
                  Begin
                     {$I-}
                     assign(pf, pst);
                     rewrite(pf);
                     writeln(pf, '');
                     {$I+}
                     pst := 'Not ready' + replicate(' ', 26)
                  End
               until (EXIT_KEY = ESC_KEY) or (Ioresult = 0);

               If (Hcfg^.Info[1]='*')and(pst <>'LPT1') Then
               Begin
                  message(20, 'No licence by EMP. Sorry !', True, False,True);
                  pst := '';
               End;
               restore_screen
           End;

     If EXIT_KEY <> ESC_KEY then
     BEGIN
     message(12, 'Printing...', False, False, False);

     If Pst[0] = #0 Then
        Begin
           prompt_point := 1;
           Oc80 := Nil; OH80 := Nil;
        End;

     If Hcfg^.Next <> Nil Then
        Begin
           Pp80 := Hcfg;
           While Pp80 <> Nil Do
                 Begin
                      Pst := Pp80^.Info;
                      if Outstring then Goto Error_Printing;
                      Pp80:= Pp80^.Next;
                 End;
        End;
     pp80  := H80;
     pline := 0; pcount:= 0; Qcount := 0; Pch := #96;
     while pp80 <> nil do
        begin
             Pline := Pline + 1;
             If Pline > 60 Then
                Begin
                  Pcount := Pcount + 1;
                  Str(Pcount, Pst);
                  Pst:='                                 Page: '+Pst+#12;
                  if Outstring then Goto Error_Printing;
                  Pline := 0
                End;

             pst := pp80^.Info; pi  := Ord(Pst[0]);
             While Pst[pi] = ' ' Do Pi := Pi - 1;
             Pst[0] := Char(pi);
             If pp80^.Info[80] In ['@', '#', '|'] Then
                Begin
                   If Pch < Pst[9] Then Pch := Pst[9];
                   If pp80^.Info[80] = '@' Then
                      A_answer[Qcount]:=Ord(Pst[9]) - 96;
                   If pp80^.Info[80] <> '|' Then pst[10] := '.'
                   Else pst[10] := ' ';
                   for pi := 1 to 8 do pst[pi] := ' '
                End
             Else
                Begin
                   Case Pst[1] of
                      #1: Begin
                              Qcount := Qcount + 1;
                              Pst[1] := ' '; Pst[5] := ' '
                          End;
                      #5: Pst[1] := ' '; { Reading comprehension for exemple }
                   End;
                   for pi := 1 to ord(pst[0]) do
                     if pst[pi] = #4 then
                        pst := Left(pst, pi-1) + '-1 ' + Right(pst, Ord(pst[0])-Pi)+'-0'
                     else
                        if pst[pi] = '~' then
                           pst := Left(pst, pi-1) + '-0 ' + Right(pst, Ord(pst[0])-Pi);
                End;
             if Outstring then Goto Error_Printing;
             PP80 := PP80^.Next
        end;

     If (Cur_Job[2] <> '-') and (Cmd = 0) Then
      BEGIN
        { Print test keys and answer keys }
        Pst := #12+replicate(' ',34) + 'TEST KEY';
        if Outstring then Goto Error_Printing;
        If Pch > 'd' Then pst   := '' Else pst   := '    ';
        For Pi := 1 To QCount do
            begin
               str(pi-1:3, Fname);
               pst := pst + ' ' + Fname + '.';
               for pj := 1 to Ord(Pch) - 96 do Pst := Pst + '[ ]';

               if (pi MOD 4 = 0) or (Pi = Qcount) then
                  begin
                     if Outstring then Goto Error_Printing;
                     If Pch > 'd' Then pst   := '' Else pst   := '    ';
                     if (pi MOD 5) = 0 then
                        if Outstring then Goto Error_Printing;
                  end;
            end;

        Pst := replicate(' ',9)+
                   '(Mark in the box corresponding to your choice)';
        if Outstring then Goto Error_Printing;

        Pst := #12+replicate(' ',34)+'ANSWER KEY';
        if Outstring then Goto Error_Printing;

        If Pch > 'd' Then pst   := '' Else pst   := '    ';
        For Pi := 1 To QCount do
            begin
               str(pi-1:3, Fname);
               pst := pst + ' ' + Fname + '.';
               for pj := 1 to Ord(Pch) - 96 do
               If Pj = A_answer[Pi] Then Pst := Pst + '[x]'
               Else Pst := Pst + '[ ]';

               if (pi MOD 4 = 0) or (Pi = Qcount) then
                  begin
                     if Outstring then Goto Error_Printing;
                     If Pch > 'd' Then pst   := '' Else pst   := '    ';
                     if (pi MOD 5) = 0 then
                        if Outstring then Goto Error_Printing;
                  end;
            end;
      END;
     Pst := '                                 End of Sheets';
     if Outstring then Goto Error_Printing;
     If Prompt_point > 1 Then close(pF);

        { Preview }
        If (Prompt_point = 1) Then
        Begin
            OS80 := H80; H80 := OH80; OH80 := OS80;
            OS80 := S80; OC80:= C80;
            C80  := H80; S80 := H80;
            Qcount := Rtime; Rtime := 99;
            SheetTest(False, False, True);
            Unload(80, False);
            H80 := OH80; C80 := OC80; S80 := OS80;
            Rtime := Qcount;
        End;
     END;
     restore_screen;
end;

{================================== For europeane character typing }

function c_choix(chr: char; nn: byte; var pos: byte; incr: boolean): char;
         { chr  : current character
           nn   : value number of key pressed
           pos  : current position
           incr : increase current position after touch ? }
var      chi, chj: byte;
begin
     for chi := 1 to 8 do
         begin
             for chj := 1 to 6 do
                 if chr = e_set[chi][chj] then break;
             if chj < 6 then break
         end;

     if (chi < 8) and (nn < 6) and (nn > 1) then c_choix := e_set[chi][nn]
     else
        begin
            if incr then pos := pos + 1;
            c_choix := char(nn + 47);
        end;
end;
{===================================}

procedure  Phrase;
var
   Ph1_80      : P80;
   anhphap     : boolean;
   chuoi       : string[66];
   word_cut    : string15;
   jump_ar     : array[0..25] of byte;  { Jump_ar[i] is space from i and i+1 }
   word_ar     : array[1..25] of string32;
   word_No, gi, gj, gk, gl, gm, o_col, o_row: byte;
   {--------------------------}
   procedure toarray;
   var       ti: byte;

   begin
       word_no:= 0; jump_ar[0] := 0; word_cut := '';
       for ti := 1 to ord(chuoi[0]) + 1 do
           if (chuoi[ti] In P_set) or (ti > ord(chuoi[0])) then
              begin
                if (ord(word_cut[0]) > 0) then
                   begin
                      word_no := word_no + 1;
                      word_ar[word_no] := word_cut;
                      jump_ar[word_no] := 1;
                      word_cut := '';
                   end
                else
                   jump_ar[word_no] := jump_ar[word_no] + 1;
              end
           else
              word_cut := word_cut + chuoi[ti];
   end;
   {--------------------------}
begin
   backup_screen;
   if (H80 = Nil) Or (Cur_job <> 'E-F') Then
      begin
         If D_File(1, OTHERS, 1, 80, 1, 1) <= 0 Then
            begin Restore_screen; Exit; end;
         Cur_job := 'E-F';
      end;
   C_proc := 11;
   color := 31;
   zoom(2,3,22,76,single_frame); anhphap := true;
   box(6, 6, 6, 73, Single_bar);
   box(19, 6, 19, 73, Single_bar);
   gotoxy(25, 4); write(char(1) + 'Th…nh ng§ Anh - Ph p - Vi¬t');
   gotoxy(16, 5); write(char(4) + '( Phrases of English - Fran‡ais - Vietnamese )');
   Prompt_point := 1;
   REPEAT
     gotoxy(9, 20); write('     :~ChuyŽn v¬t s ng -*-Enter:~Th¨c hi¬n mžc ch”n     ');
     For Gj := 8 to 18 do
         begin
             Gotoxy(7, Gj); Write(Replicate(' ', 66));
         end;
     Exit_key1 := F9_KEY;
     Ph1_80 := H80; Row := 6; col := 8; GK := 0;
     While Ph1_80 <> Nil Do
       begin
           Ph1_80^.Info := Trim(Ph1_80^.Info);
           if Ph1_80^.Info[1] = '*' then
              begin
                   chuoi := Left(Ph1_80^.Info+ Replicate(' ', 30), 32);
                   If Row > 17 Then
                      begin
                           Row := 7; Col := 40;
                           Gj := 0;
                      end
                   else Row := Row + 1;
                   Gk := GK + 1;
                   if (Gk > 24) Then Break;
                   word_ar[GK] := Chuoi;
                   prompt(word_ar[GK]);
              end;
           Ph1_80 := Ph1_80^.Next;
       end;
     Read_prompt;
     If (Exit_key=ESC_KEY) or ((Exit_key=F9_KEY) and Getmenu(PAD, POP))
        Then Break;
     If EXIT_KEY = ESC_KEY Then
        begin
             EXIT_KEY := Enter_key; Continue
        end;

     Gi := Prompt_point; S80 := H80;
     Repeat
          If S80^.Info[1] = '*' Then Gi := Gi - 1;
          S80 := S80^.Next;
     Until (Gi = 0);
     { S80 point to group of desired proverbs }
     Ph1_80 := S80;
     While (Ph1_80^.next <> Nil) and ((Ph1_80^.next)^.Info[1] <> '*') Do
           Ph1_80 := Ph1_80^.Next;
     S80^.Prev := (Ph1_80^.Prev)^.Prev; { The last one of this group }
     For Gj := 7 to 18 do
         begin
              Gotoxy(7, Gj); Write(Replicate(' ', 66));
         end;
     cursor_on; gotoxy(17, 17); write('Cƒu trà lõi cœa bân:');
     gotoxy(9, 20);
     If AnhPhap Then
        write(':~ChuyŽn Ä*ÄF2:~Gøi î Ä*ÄF3:~Anh-Ph p Ä*ÄF10:~Trø gi£p')
     Else
        write(':~ChuyŽn Ä*ÄF2:~Gøi î Ä*ÄF3:~Ph p-Anh Ä*ÄF10:~Trø gi£p');
     Ph1_80 := S80;
     Repeat
       gotoxy(7, 8);  write(replicate(' ', 66));
       gotoxy(7, 11); write(replicate(' ', 66));
       gotoxy(7, 14); write(replicate(' ', 66));
       if anhphap then
          begin
            gotoxy((80 - Ord(Ph1_80^.Info[0])) Div 2,8);
            write(Ph1_80^.Info);  o_row := 11;
            Chuoi := (Ph1_80^.Next)^.Info;
          end
       else
          begin
            Chuoi  := Ph1_80^.Info;
            gotoxy((80 - Ord((Ph1_80^.Next)^.Info[0])) Div 2,11);
            write((Ph1_80^.Next)^.Info); o_row := 8;
          end;
       gotoxy((80 - Ord(((Ph1_80^.Next)^.Next)^.Info[0])) Div 2 - 1, 14);
       write(char(5) + '(' + ((Ph1_80^.Next)^.Next)^.Info + ')'); { Vietnamese Proverb }
       toarray;
       gotoxy((74 - Ord(chuoi[0])) Div 2, o_row);
       write(#5#222#223#32); o_col := col + jump_ar[0];
       for gi := 1 to ord(chuoi[0]) do
           if chuoi[gi] in p_set then
              write(chuoi[gi])
           else
              write('_');

       gi := 1;  gj := 0; word_cut := '';
       Repeat
          gotoxy(39, 17); write(replicate(' ', 15));
          gotoxy(39, 17); write(word_cut);
          KEY := inkey;
          Case KEY of
             F1_KEY: giupdo;
             F2_KEY:
                    begin
                         KEY := gi + random(word_no - gi + 2);
                         if KEY > word_no then KEY := word_no;
                         gm := 0;
                         for gl := gi  to KEY - 1 do
                               gm := gm + ord(word_ar[gl][0])+jump_ar[gl];
                         gl := random(ord(word_ar[KEY][0]) + 2);
                         if (gl = 0) then gl := 1;
                         if (gl > ord(word_ar[KEY][0])) then
                                         gl := ord(word_ar[KEY][0]);
                         gotoxy(o_col + gm + gl - 1, o_row);
                         color := 25; write(word_ar[KEY][gl]); color := 31
                    end;
             F3_KEY:
                    begin
                         gotoxy(43, 20);
                         if anhphap then
                            begin  anhphap := False;
                                   write('Ph p-Anh');
                            end
                         else
                            begin  anhphap := true;
                                   write('Anh-Ph p');
                            end;
                         gi := word_no + 1;
                    end;
             F9_KEY:
                    begin
                         Cursor_off;
                         If Getmenu(PAD, POP) Then
                            begin
                                KEY     := ESC_KEY;
                                EXIT_KEY := ESC_KEY;
                                Gi := Word_no + 1;
                            end
                         Else
                            begin Cursor_on; Exit_key := Enter_key end;
                    end;
             F10_KEY:
                    if gj < ord(word_ar[gi][0]) then
                       begin
                           gj := gj + 1;
                           word_cut := word_cut + word_ar[gi][gj]
                       end;
             Down_KEY:
                    begin
                        For Gi := 1 To 3 Do Ph1_80 := Ph1_80^.Next;
                        if (Ph1_80 = Nil)or(Ph1_80^.Info[1]='*') Then
                           Ph1_80 := S80;
                        gi := word_no + 1;
                    end;
             Up_KEY:
                    begin
                        if Ph1_80 = S80 Then Ph1_80 := S80^.Prev
                        Else
                           For Gi := 1 To 3 Do Ph1_80 := Ph1_80^.Prev;
                        gi := word_no + 1
                    end;
             Else
                case Char(lo(KEY)) of
                   char(13), ' ':
                       begin
                           if (word_cut = word_ar[gi]) then
                              begin
                                 gotoxy(o_col, o_row);
                                 write(word_cut);
                                 o_col := col + jump_ar[gi];
                                 gi := gi + 1;
                                 if Gi>Word_no Then while not keypressed do ;
                              end
                           else
                              if (word_cut[0] <> char(0)) then
                                 begin sound(777); delay(3); Nosound end;
                           word_cut := ''; gj := 0
                       end;

                   'A'..'Z','a'..'z':
                       if (gj < 15) then
                          begin
                             word_cut := word_cut + char(lo(KEY));
                             gj := gj + 1
                          end;

                   '0'..'9':
                       if (gj < 15) then
                          begin
                             word_cut[gj] := c_choix(word_cut[gj], lo(KEY)-47, gj, true);
                             word_cut[0]  := char(gj)
                          end;

                   char(8):
                       if (gj > 0) then
                          begin
                              gj := gj - 1;
                              word_cut[0] := char(gj)
                          end;
                end;
          End;
       Until (Gi > Word_no) or (KEY = ESC_KEY);
     Until KEY = ESC_KEY;
     Cursor_off;
   Until (Exit_key = ESC_KEY);
   restore_screen; C_proc:= 10;
end;
{=================================== Corssword Game }

procedure  crossword;
var
    inra                  : string[3];
    ask_ar, ans_ar, words : array[1..10] of string15;
    ci, cj, ck, cl, wc, cm: byte;
    direction             : byte;

    {--------------------------}
    procedure  Dowrite(clor: byte);
    var    rei             : byte;
           fstring, bstring: string15;
    begin
        color := clor;
        { horizental checking }
        rei := cj;
        while (rei>1)and(ans_ar[ci][rei-1]<>' ') do rei := rei - 1;
        fstring := ''; bstring := '';

        while (rei<16)and(ans_ar[ci][rei]<>' ') do
            begin
               fstring := fstring+ans_ar[ci][rei];
               bstring := ans_ar[ci][rei]+bstring;
               rei := rei + 1
            end;

        for rei := 1 to wc do
            if (upstring(fstring)=upstring(words[rei])) or
               (upstring(bstring)=upstring(words[rei]))
            then
                begin
                     gotoxy(64, 4+(rei-1)*2);
                     write(words[rei])
                end;

        { vertical checking }
        rei := ci;
        while (rei>1)and(ans_ar[rei-1][cj]<>' ') do
               rei := rei - 1;
        fstring := ''; bstring := '';
        while (rei<11)and(ans_ar[rei][cj]<>' ') do
            begin
               fstring := fstring+ans_ar[rei][cj];
               bstring := ans_ar[rei][cj]+bstring;
               rei := rei + 1
            end;
        for rei := 1 to wc do
            if (upstring(fstring)=upstring(words[rei])) or
               (upstring(bstring)=upstring(words[rei]))
            then
                begin
                     gotoxy(64, 4+(rei-1)*2);
                     write(words[rei])
                end;
    end;
    {--------------------------}

begin
     backup_screen;
     if (H255 = Nil) or (Cur_job <> 'PUZ') Then
        begin
             If D_File(1, OTHERS, 2, 255, 1, 1) <= 0 Then
                begin Restore_screen; Exit; end;
             Cur_job := 'PUZ';
        end;
     C_proc:= 12; C255 := H255;
     color := 31; box_base := 0;
     box(1,0,23,79,single_frame);

     While C255 <> Nil Do
         BEGIN
             color := 31;
             for Ci := 2 to 22 Do
                 begin Gotoxy(1, Ci); Write(Replicate(' ', 76)) end;
             color := 29; box_base := 0;
             box(2,62,22,78,single_frame);
             gotoxy(67, 2); write(' Words ');
             color := 31;
             for ci := 1 to 10 do ans_ar[ci] := replicate(' ', 15);
             for ci := 1 to 10 do
                 ask_ar[ci] := subs(C255^.Info, 1+(ci-1)*15, 15);

             ci := 1+ci*15; row := 2; wc := 0;
             while C255^.Info[ci] <> ' ' do
                   begin
                       cj := ci;
                       while C255^.Info[cj] <> '.' do cj := cj + 1;
                       wc := wc + 1; gotoxy(64, row + 2);
                       words[wc] := subs(C255^.Info, ci, cj - ci);
                       write(words[wc]);  ci := cj + 1
                   end;

             for ci := 1 to 10 do
                 begin
                    gotoxy(2, 1 + ci*2);
                    for cj := 1 to 15 do
                        begin
                           if ask_ar[ci][cj] <> ' ' then write('ÛÛÛ')
                           else   col := col + 3;
                           col := col + 1;
                        end;
                 end;
             for ci := 1 to 10 do
                 begin
                     for cj := 1 to 15 do
                         if ask_ar[ci][cj] <> ' ' then break;
                     if cj <= 15 then break;
                 end;

             KEY := 1; Direction := 0;
             While (KEY <> Enter_KEY) and (KEY <> ESC_KEY) do
                begin
                   if ans_ar[ci][cj] = ' ' then
                      begin
                           inra := 'ÛÛÛ';
                           ck   := 116; cl   := 31;
                      end
                   else
                      begin
                         inra := ' ' + ans_ar[ci][cj] + ' ';
                         ck   := 79; cl   := 116;
                      end;
                   color := ck;
                   gotoxy(2+4*(cj-1), 1 + 2*ci);
                   write(inra);

                   If Key = 0 Then KEY := inkey;  { Process when no char in }
                   if KEY = ESC_KEY then break;
                   if lo(KEY) = 0 then
                    begin
                      color := cl;
                      gotoxy(2+4*(cj-1), 1 + 2*ci);
                      write(inra);
                      case KEY of
                         UP_KEY:
                             begin
                                cm := ci - 1;
                                while (cm > 0) and (ask_ar[cm][cj] = ' ')
                                      do cm := cm - 1;
                                if cm > 0 then ci := cm;
                             end;
                         Down_KEY:
                             begin
                                cm := ci + 1;
                                while (cm < 11) and (ask_ar[cm][cj] = ' ')
                                      do cm := cm + 1;
                                if cm < 11 then ci := cm;
                             end;
                         LEFT_KEY:
                             begin
                                cm := cj - 1;
                                while (cm > 0) and (ask_ar[ci][cm] = ' ')
                                      do cm := cm - 1;
                                if cm > 0 then cj := cm;
                             end;
                         RIGHT_KEY:
                             begin
                                cm := cj + 1;
                                while (cm < 16) and (ask_ar[ci][cm] = ' ')
                                      do cm := cm + 1;
                                if cm < 16 then cj := cm;
                             end;
                         F1_KEY: giupdo;
                         F9_KEY:
                             If Getmenu(Pad, Pop) Then KEY := ESC_KEY;
                      end;
                      If KEY <> ESC_KEY then Key := 0;
                      If Direction > 5 Then Direction := Direction - 6
                      Else Direction := 0;
                    end
                   else
                    If (KEY <> Enter_KEY) and (KEY <> ESC_KEY) Then
                    BEGIN
                      case char(lo(KEY)) of
                        'A'..'Z','a'..'z', ' ':
                           begin
                               Dowrite(31);         { to old color }
                               ans_ar[ci][cj] := char(lo(KEY));
                               Dowrite(24);         { to new color }
                           end;
                        '0'..'9':
                          ans_ar[ci][cj] := c_choix(ans_ar[ci][cj], lo(KEY)-47, cj, false);
                      end;
                      If Direction = 0 Then
                      Begin
                         If ask_ar[ci][cj+1] <> ' ' Then Direction := 1
                         Else
                            If ask_ar[ci+1][cj] <> ' ' Then Direction := 2;
                      End;
                      Case Direction of
                         1: Key := RIGHT_KEY;
                         2: Key := Down_KEY;
                      else  Key := 0;
                      End;
                      Direction := Direction + 6;
                    END;
                end;
             For ci := 1 to 10 do
                 if upstring(ans_ar[ci]) <> upstring(ask_ar[ci]) then break;
             C255 := C255^.Next;
             If KEY = ESC_KEY then break;
         END;
   restore_screen; C_proc:= 10;
end;
{ ----------------------- Dos Testing ---}

procedure InfoTest(Which, ExeNo: Byte; PName: String15);
          {     Which : Block Of File to read
                ExeNo : Exercise du test
                Pname : one of [DOS, FOX, PAS, C++, ...] }
begin
   if (H80 = Nil) Or (Cur_job <> PName) Then
      begin
           Backup_screen;
           Demo(true);
           Rtime := D_File(1, INFORMATIC, Which, 80, 1, ExeNo);
           Restore_screen;
           If Rtime <= 0 Then Exit;
           Cur_job := Pname;
           if ExeDefault = 0 then Time  := 30; { Auto run mode }
           Rtime := 0;
           C80 := H80; S80 := H80;
      end;
   SheetTest(True, False, False); C_proc := 10;
end;
{===================================}

Procedure Music_pause;
Begin
   If CmfOk and OnMusic Then
      Begin
           MusicNo := MusicNo + 50;     { A signal }
           Onmusic := False;
           CmfPause;
      End;
End;
{===================================}

Procedure Music_GoOn;
Begin
   If CmfOk and (MusicNo > 50) Then
      Begin
           MusicNo := MusicNo - 50;     { A signal }
           If D_File(3, MUSIC, MusicNo, 80, 1, 1) > 0 Then
              Begin
                 CmfGoOn;
                 Onmusic := True;
              End;
      End;
End;
{===================================}

Procedure Lich;
label tuc;
type
     tap = set of 0..9;
const
     bangso : array[1..7,1..7] of tap =
     (([0,2,3,4,5,6,7,8,9], [0,2,3,4,5,6,7,8,9], [0,2,3,5,6,7,8,9],
     [0,2,3,5,6,7,8,9], [0,2,3,5,6,7,8,9], [0,1,2,3,4,5,6,7,8,9],
     [0,1,2,3,4,5,6,7,8,9]),

     ([0,4,5,6,8,9], [0,4,5,6,8,9], [], [], [], [0,1,2, 3,4,7,8,9], [0,1,2, 3,4,7,8,9]),
     ([0,4,5,6,8,9], [0,4,5,6,8,9], [], [], [], [0,1,2, 3,4,7,8,9], [0,1,2, 3,4,7,8,9]),

     ([0,2,3,4,5,6,8,9], [0,2,3,4,5,6,8,9], [2,3,4,5,6,8,9],
     [2,3,4,5,6,8,9], [2,3,4,5,6,8,9], [0,1,2,3,4,5,6,7,8,9],
     [0,1,2,3,4,5,6,7,8,9]),

     ([0,2,6,8], [0,2,6,8], [], [], [], [0,1,3,4,5,6,7,8,9], [0,1,3,4,5,6,7,8,9]),
     ([0,2,6,8], [0,2,6,8], [], [], [], [0,1,3,4,5,6,7,8,9], [0,1,3,4,5,6,7,8,9]),

     ([0,2,3,5,6,8,9], [0,2,3,5,6,8,9], [0,2,3,5,6,8,9],[0,2,3,5,6,8,9],
     [0,2,3,5,6,8,9], [0,1,2,3,4,5,6,7,8,9], [0,1,2,3,4,5,6,7,8,9]));
var
   cYear, Year : word;
   cMonth, cDay: byte;
   First : Boolean;
   procedure venen(so, cot: byte);
   var
      i, j: byte;
   begin
     for i := 10 to 16 do
         for j := cot + 1 to Cot + 7 do
             begin
                  if so in bangso[i-9, j-cot] then
                     Mem[Video_seg: i*160+j*2+1] :=
                                Mem[Video_seg: i*160+j*2+1] xor 64;
             end;
   end;

   Function dayofweek(ngay, thang: Byte; nam: Word): byte;
   var
      songay : word;
      i : byte;
   begin
     songay := 0;
     for i := 1 to nam - 1901 do
         if i mod 4 = 0 then songay := songay + 366
         else songay := songay + 365;
     for i := 1 to thang - 1 do
         case  i of
               1,3,5,7,8,10,12: songay := songay + 31;
               4,6,9,11: songay := songay + 30;
               2: if nam mod 4 = 0 then songay := songay + 29
                  else songay := songay + 28;
         end;
     songay := songay + ngay;
     dayofweek := ((songay mod 7 + 2) mod 9) - 1; { thu 2 = 1 , chunhat = 7 }
   end;

   procedure vehinh(thang: byte; nam: Word);
   var
      thu, hang, cot, ngay: byte;
      i : byte;
   begin
    case thang of
         1, 3, 5, 7, 8, 10, 12: ngay := 31;
         4, 6, 9, 11: ngay := 30;
         2: if nam mod 4 = 0 then ngay := 29 else ngay := 28;
    end;
    thu := Dayofweek(1, thang, nam);
    If Thang > 6 Then hang := 6 + ((thang-7) div 3) * 8
    else hang := 6 + ((thang-1) div 3) * 8;
    cot  := 6 + ((thang-1) mod 3) * 23;
         for i := 1 To ngay do
             begin
                  gotoxy(cot+(Thu-1)*3, hang);
                  if (thu = 7) then color := 116
                  else
                     if (nam <> cYear) or (thang <> cMonth) then Color := 112
                     else color := 127;
                  if (nam = cYear)and(thang = cMonth)and(i = cDay) then
                     Color := color + 128;
                  write(i:3);
                  thu := thu + 1;
                  if thu = 8 then
                     begin
                           thu := 1;
                           hang := hang + 1;
                     end;
             end;
   end;
begin
    Backup_screen;
    asm
          mov ah, $2A
          int $21
          mov Word ptr Year, cx
          mov byte ptr cMonth, dh
          mov byte ptr CDay, dl
    end;
    cYear := year;
    If CMonth > 6 Then first := False Else First := True;
    color := 113;
    Zoom(2, 1, 22, 77, single_frame);
    box(5,  5, 12, 27, single_frame); box_base := 0;
    box(5, 28, 12, 50, single_frame); box(5, 51, 12, 73, single_frame);
    box(13, 5, 20, 27, single_frame);
    box(13, 28,20, 50, single_frame); box(13, 51, 20, 73, single_frame);
    gotoxy(5, 4); Color := 94;
    Write('  Mo Tu We Th Fr Sa Su   Mo Tu We Th Fr Sa Su   Mo Tu We Th Fr Sa Su ');

    repeat
          Backup_screen;
          if First Then For Key := 1 to 6 do
             begin
                  gotoxy(15+((key-1) mod 3)*23, 5+(key div 4)*8);
                  color := 117; write('[', key, ']');
                  vehinh(Key, Year)
             end
          else For Key := 7 to 12 do
             begin
                  gotoxy(15+((key-7) mod 3)*23, 5+((key-6) div 4)*8);
                  color := 117; write('[', key, ']');
                  vehinh(Key, Year)
             end;
          venen(year div 1000, 10);venen((year mod 1000) div 100, 26);
          venen((year mod 100) div 10, 44); venen(year mod 10, 60);

          tuc: Key := Inkey;
          case Key of
               F1_key: Giupdo;
               Down_key, Pgdn_key: Begin
                         if Not first then year := year + 1;
                         First := Not First
                    End;
               Up_key, Pgup_Key: Begin
                         if first then year := year - 1;
                         First := Not First
                    End;
               Esc_key:;
               else Goto Tuc;
          end;
          Restore_screen;
    Until Key = Esc_key;
    Restore_screen;
end;
{===================================}

BEGIN
   EMP_VNI_Load; Cks := 0;
   NotTimeshow := True; Clock := false; OnMusic := False;
   C_proc := 10; Rtime := 0; Cur_job := '   ';
   Hcfg := Nil; H80 := Nil; H255 := Nil;
   GetIntVec($1C,Int1CSave); SetIntVec($1C,Addr(TimeShow));
   cursor_off; get_color := 111; box_base := 1; Zoom_mode := 1; filemode := 32;

   { Checking Sound Card }
   If CmfInit(Addr(CmfStatus)) Then
      begin
         CmfOK := True;
         If D_File(3, MUSIC, 5, 80, 1, 1) > 0 Then
                  CMFPlay(Ptr(Seg(Inbuffer[4]),Ofs(Inbuffer[4])));
      end
   else begin
        PopPrompt[3,7][10] := 'N';
        PopPrompt[3,7][11] := 'o';
        PopPrompt[3,7][12] := 'n';
   end;

   Pop := 0; Pad := 0; ExeDefault := 0;
   If ParamCount > 0 then
   BEGIN
      { Title - Footer - Job - Pad - Bar - Lesson - Time in second }
      Cmdline := ParamStr(1);
      For Time:= 2 to ParamCount Do Cmdline := Cmdline +' '+ ParamStr(Time);
      MusicNo := 0; OUTbuffer[308] := Ord(Cmdline[0])+1;
      For Time:= 1 To Ord(Cmdline[0]) do
          if Cmdline[Time] = '/' then
             begin
                 MusicNo := MusicNo + 1;
                 OUTbuffer[300+MusicNo] := Time;
             end;

      If MusicNo < 7 then
        Begin
             { Used only for help }
             BACKUP_SCREEN;
             If CmfOk Then OnMusic := True; { play music indefinitely }
             help;
             If CmfOk Then CmfStop;
             EMP_VNI_Unload; SetIntVec($01C,Int1CSave);
             RESTORE_SCREEN; Cursor_on;
             HALT;
        End;
      { Title - Footer - Pad - Bar - Lesson - Time in second }
      Network := Copy(Cmdline,OUTbuffer[303]+1,OUTbuffer[304]-OUTbuffer[303]-1);
      Val(Trim(Copy(Cmdline, OUTbuffer[304]+1,OUTbuffer[305]-OUTbuffer[304]-1)),
           Pad, Key);
      Val(Trim(Copy(Cmdline, OUTbuffer[305]+1,OUTbuffer[306]-OUTbuffer[305]-1)),
           Pop, Key);
      Val(Trim(Copy(Cmdline, OUTbuffer[306]+1,OUTbuffer[307]-OUTbuffer[306]-1)),
           ExeDefault, Key);
      Val(Trim(Copy(Cmdline, OUTbuffer[307]+1,OUTbuffer[308]-OUTbuffer[307]-1)),
           Time, Key);
      InBaigiai := False;
      If Cmdline[OUTbuffer[308]+1] in ['Y', 'y'] then
         begin clock := true;
               if Cmdline[OUTbuffer[308]+1] = 'Y' then InBaigiai := True;
         end;
   END;
   asm
        mov     ax,3
        int     010h
   end;
   EMP_VNI_load;

   gotoxy(0,0); color := 11; fill_char('°',80*24);
   color := 63;
   if MusicNo < 7 then Write(' Languages   Computer   Games   System         ')
   else
      begin
        Write(' ', Copy(Cmdline, 2,OUTbuffer[302]-2));
        while col < 47 do write(' ');
      end;
   color := 62; Write('   ~  ~  ~  ~    F9: Menu ');

   row := 24; Col := 0; color := 37;
   if MusicNo < 7 then
      write('  Ê¾EMP.11/1996~      TrŸõng ®âi H”c Kinh T‰ Tp.HCM   ~   '+
         'B› M“n Tin H”c   ')
   else
      begin
        Write(' ',Copy(Cmdline,OUTbuffer[302]+1,OUTbuffer[303]-OUTbuffer[302]-1));
        while col < 79 do write(' '); write(' ');
      end;
   col := 1;

   if (Network = 'HOT') or (Network = 'WSs') then
      begin
         Key := GetNumFromUserName;
         if Key > 0 then Exedefault := (Key - 1) mod Exedefault + 1;
      end;

   color := 16;
     { E }
     box( 8, 10, 15, 13, '         ');
     box( 8, 14,  9, 20, '         ');
     box(12, 14, 13, 20, '         ');
     box(16, 10, 17, 20, '         ');
     { - }
     box(12, 25, 13, 27, '         ');
     { M }
     box( 8, 32, 17, 35, '         ');
     box( 9, 34, 11, 36, '         ');
     box(10, 37, 13, 39, '         ');
     box( 9, 40, 11, 42, '         ');
     box( 8, 41, 17, 44, '         ');
     { - }
     box(12, 49, 13, 51, '         ');
     { P }
     box( 8, 56, 17, 59 ,'         ');
     box( 8, 60,  9, 66, '         ');
     box( 9, 64, 12, 67, '         ');
     box(12, 60, 13, 66, '         ');

   if cmfOk then
        begin
           while not keypressed and (ExeDefault = 0) do;
           Cmfstop;    { keep music play demo };
        end;

   {-------------}
   Repeat
     If Pop = 0 Then
        Begin
             Key := Second - 1;
             While Not Keypressed Do
                   if Key = Second Then
                      begin
                           If Minute Mod 3 = 1 Then Demo(False)
                           Else
                               BEGIN
                                   backup_screen;
                                   DEMO(true);
                                   empdemo;
                                   EMP_VNI_load;
                                   restore_screen;
                               END;
                           Key := Second - 1;
                      end;
             Key := inkey;
             Case Key Of      { For Hot Keys }
                  F1_key : Giupdo;
                  F9_key : Getmenu(pad, pop);
                  F10_key: Break;
             End;
        End;

     If (pop > 0) Then
     BEGIN
        Key := Pop;
        Pop:= 0;
        Case Pad Of
           1:                   { Language Pad }
             Case Key Of
              1,2: Begin
                       Key := 69; { Signal if lgchoose is Ok }
                       If (Cur_job[1] <> ' ')or(Not (Cur_job[2] In ['E','F']))
                          Then Key := Lgchoose(ExeDefault);
                       If Key = 69 Then SheetTest(True, False, False);
                   End;
                3: Key := Lgchoose(0);
                4: SheetTest(True, True, False);
                5: print(0);
             End;
           2:
             Case Key Of
                1..6: if (ExeDefault=0) or (Network = '') then
                         InfoTest(key,ExeDefault,Copy('DOSXLSPASFOXC++ASM',(key-1)*3+1,3))
                      else
                         InfoTest(key,ExeDefault,Network);
                7: begin
                     Unload(80, True);
                     Message(12, 'Test changed !', true, true,false)
                   end;
             End;
           3:
             Case Key Of
                1: Phrase;
                2: Crossword;
                3: begin
                       backup_screen;
                       If CmfOk Then
                          Begin
                             OnMusic := False; CmfStop;
                             If D_File(3, MUSIC, 6, 80, 1, 1) > 0 Then
                             Begin
                                  CMFPlay(Ptr(Seg(Inbuffer[4]),Ofs(Inbuffer[4])));
                                  OnMusic := True;
                             End;
                          End;
                       DEMO(true);
                       empdemo;
                       EMP_VNI_load;
                       If CmfOk Then
                          Begin
                             OnMusic := False; CmfStop;
                             If MusicNo > 0 Then
                             If D_File(3, MUSIC, MusicNo, 80, 1, 1)>0 Then
                             Begin
                                  CMFPlay(Ptr(Seg(Inbuffer[4]),Ofs(Inbuffer[4])));
                                  OnMusic := True;
                             End;
                          End;
                       restore_screen;
                   end;
                4: Begin
                       If CmfOk Then
                          Begin
                             OnMusic := False; CmfStop;
                             If D_File(3, MUSIC, 7, 80, 1, 1) > 0 Then
                             Begin
                                  CMFPlay(Ptr(Seg(Inbuffer[4]),Ofs(Inbuffer[4])));
                                  OnMusic := True;
                             End;
                          End;
                       DEMO(False);
                       If CmfOk Then
                          Begin
                             OnMusic := False; CmfStop;
                             If MusicNo > 0 Then
                             If D_File(3, MUSIC, MusicNo, 80, 1, 1)>0 Then
                             Begin
                                  CMFPlay(Ptr(Seg(Inbuffer[4]),Ofs(Inbuffer[4])));
                                  OnMusic := True;
                             End;
                          End;
                   End;
                5: Lich;
                7: ;
             End;
           4:
             Case Key Of
                1: giupdo;
                2: { Exit }
                   EXIT_KEY := F10_KEY;

                5: C_FILE;

                6: begin
                      backup_screen;
                      color := 11 + 8*10;
                      zoom(8, 20, 16, 60, Single_frame);
                      box(11, 23, 11, 57, Single_bar);
                      row := 10; col := 30;  Fname := Replicate(' ', 13);
                      write('Files Decompression');
                      gotoxy(27, 13); write('File name: ');
                      gets(fname); readg;
                      If Exit_key <> ESC_KEY Then
                         D_File(2, Fname, 0, 0, 0, 1);
                      restore_screen;
                   end;

                7: begin
                      if PASSWORD then
                       BEGIN
                        Backup_screen;
                        IF (Cur_Job = 'FTL') or
                           (D_File(1, OTHERS, 3, 80, 1, 1) > 0) THEN
                        BEGIN
                         Cur_Job := 'FTL';
                         color := 31; box_base := 0;
                         Box(1, 0, 23, 79, single_frame);
                         Box(3, 0,  3, 79, single_bar);
                         Box(1, 29,  3, 29, single_pol);
                         ftl.nsinh := Empty_date; ftl.Onsinh := Empty_date;

                         Gotoxy(3, 2);
                         Write('Ng…y h“m nay: ');
                         Getd(ftl.Onsinh); readg;

                         While Exit_key <> ESC_key do
                         BEGIN
                          REPEAT
                          Gotoxy(31, 2);
                          Write('Bân cho bi‰t ng…y sinh (dŸóng l«ch): ');
                          Getd(ftl.nsinh); readg;
                          UNTIL (Exit_key = ESC_Key) or Not
                                ((' ' in [ftl.nsinh.day[1], ftl.nsinh.day[2],
                                         ftl.nsinh.month[1], ftl.nsinh.month[2],
                                         ftl.nsinh.year[1], ftl.nsinh.year[2],
                                         ftl.nsinh.year[3], ftl.nsinh.year[4]])
                                  or (ftl.Onsinh.Year <= ftl.Nsinh.Year));

                          If Exit_key = ESC_Key Then break;
                          row := row + 1; C80 := H80; ftl.PnSinh := ftl.nSinh;

                          While (C80 <> nil) do
                          BEGIN
                            Key := Ord(ftl.Pnsinh.day[1])+Ord(ftl.Pnsinh.day[2])+
                                   Ord(ftl.Pnsinh.month[1])+Ord(ftl.Pnsinh.month[2])+
                                   Ord(ftl.Pnsinh.year[1])+Ord(ftl.Pnsinh.year[2])+
                                   Ord(ftl.Pnsinh.year[3])+Ord(ftl.Pnsinh.year[4])-8*48;
                            Key := Key mod 9; Time := 0;

                            Repeat
                              if C80^.info[1] = '*' then Time := Time + 1
                              else
                                 if Time = Key then
                                    begin
                                      if C80^.info[9] = #127 then
                                         begin
                                            C80^.info[15] := ftl.Pnsinh.Year[1];
                                            C80^.info[16] := ftl.Pnsinh.Year[2];
                                            C80^.info[17] := ftl.Pnsinh.Year[3];
                                            C80^.info[18] := ftl.Pnsinh.Year[4]
                                         end;
                                      row := row + 1; col := 2;
                                      write(Copy(C80^.info, 1, 76));
                                    end;
                              C80 := C80^.next;
                            Until (C80 = nil) or (Time > 8);
                            ftl.PNsinh.year := ftl.Onsinh.year;
                          END;
                         END;
                        END;
                        Restore_screen;
                       END;
                      end;
             End;
        End;
     END;
   Until (Exit_key = F10_key) or (ExeDefault > 0);
   SetIntVec($01C,Int1CSave);
   If CmfOk and OnMusic Then CmfStop;
   cursor_on; EMP_VNI_unload; color := 7; clrscr;
   color := 31; gotoxy(0,0);
   write('EMP.~is looking forward to your success. Bye bye !                             ');
   gotoxy(0,1);
   write(' ( Please runFM.COM~thenEMP.EXE~in case sound card installed inside your PC ) ');
END.