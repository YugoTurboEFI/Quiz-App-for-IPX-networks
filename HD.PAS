{ * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
  *     Remark Infos for this Source Code  ƒƒ  EMP.2000                     *
  *     Author:  Le Ngoc Thanh                                              *
  *     From:    The University of Economics - Informatics Department       *
  *     Purpose: Supporting Program for EMP.EXE test.                       *
  *     Product: HD.EXE                                                     *
  * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
program Force;
uses    EMPIO, IPX;
{$M 16384, 0, 655360}
const
   ssocket   = $7777;           { for sending }
   rsocket   = $5555;           { for receiving }
   H1:string = '#RegNo     Ex Full Name                      Result  LTime EMP. Network';
   H2:string = '========== == ============================== ======= ===== =================';
   bang: Array[1..6] of string =
     ('⁄ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒø',
      '≥    Sñ BD:          ~                  ≥',
      '≥Hî vÖ Tàn:                            ~≥',
      '√ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ¥',
      '≥                                        ≥',
      '¿ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒŸ');
   phim: Array[1..10] of word =
      (F1_KEY,F2_KEY,F3_KEY,F4_KEY,F5_KEY,F6_KEY,F7_KEY,F8_KEY,F9_KEY,F10_KEY);

type
   string80  = string[80];
   string10  = string[10];
   P80       = ^Str80;
   Str80     = record
                    No   : word;
                    Info : string80;
                    Key  : string10;
                    Next, Prev : P80;
               end;
   BufResult = Array[1..401] of char;
var
   Key, fcount, i, k : word;
   Howlong,oRow,oCol : Byte;
   _Col,_Row,oldcolor: byte;
   H80, C80, S80, t80: P80;

   { for network jobs, Use OUTbuffer for network jobs }
   Ripx, Sipx: IPXheader;
   Recb, Secb: ECB;
   Rbuf, Sbuf: record
                     Who  : string[3]; { WSs, HOT }
                     Ok   : boolean;   { True = answer from HOT in case success }
                     NetNo: byte4;
                     Netad: byte6;
                     Netim: byte6;
                     Msg  : String80;
                     Ans  : BufResult;
               end;
   Ftxt      : TEXT;
   FB        : file;
   fname     : string[6];
   fext      : string[4];
   st        : string;
   SdF, SdL  : word;
   stype     : byte;
   F7TEST    : boolean;
   A         : array[1..4] of string Absolute RIpx;
   tt, lt    : boolean;

{=================================== Bell }
procedure Message(mesrow: byte; info : string; Wait,Clear: Boolean);
begin
     if clear then Backup_screen;
     oRow := row; oCol := col;
     color := 79;
     col := (80 - ord(info[0])) div 2; row := mesrow;
     Zoom(row-2,col-7,row+2,col+ord(info[0])+7,single_frame);
     color := 78; write(info);
     If Wait Then begin
        While Not Keypressed Do ; Exit_key := Inkey;
     end;
     color := 31; gotoxy(oCol, oRow);
     if clear then Restore_screen;
end;

{=================================== Get the first char of HD.txt }
Function Get_HDFC: char;
begin
   {$I-}
   assign(FB, 'HD.TXT'); reset(FB, 1);
   {$I+}
   if (IoResult <> 0) then Get_HDFC := 'F'
   else begin
      BlockRead(FB, st, 1); Close(FB);
      Get_HDFC := st[0];
   end;
end;

{=================================== HOT process }
procedure ClearList;
begin
     While H80 <> Nil do begin
           C80 := H80; H80 := H80^.next;
           Dispose(C80);
     end;
     H80 := Nil; S80 := Nil; C80 := Nil;
     Scroll(3,1,19,78,17); SdL := 0;
     gotoxy(7, 21); write(0:4); gotoxy(1,3);
end;

{=================================== Write all to file }
procedure WriteOffFile;
begin
     Writeln(Ftxt, ' ');
     Write(Ftxt, ' Total: ', SdF, ' of ', SdL, ' Student(s) in ');
     case stype of
     0: Writeln(Ftxt, 'non-sorted list.');
     1: Writeln(Ftxt, 'sorted-by-RegNo list.');
     2: Writeln(Ftxt, 'sorted-by-Class list.');
     3: Writeln(Ftxt, 'sorted-by-NetworkUserName list.');
     end;
     if H80 <> Nil Then BEGIN
        Writeln(Ftxt, ' ', H1); Writeln(Ftxt, ' ', H2);
        t80 := H80;
        While t80 <> NIl Do
        Begin
          Writeln(Ftxt, ' ', t80^.Info);
          t80 := t80^.Next;
        End;
     END;
     Close(Ftxt);
end;

Procedure Addline(var a: BufResult);
var
   Pos, getPos : byte;
Begin
     getPos := 1; Pos := 12; st := Replicate(' ', 77);
     Repeat
           if (getPos mod 4 = 1) then
              if (a[getPos] = '?') then begin
                 if (Pos <> 12) then writeln(Ftxt, st); break
              end
              else
                  begin st[Pos] :=  ' '; pos := pos + 1 end;

           st[Pos] := a[getPos];
           pos := pos + 1; getPos := getPos + 1;
           if pos > 76 then begin
              writeln(Ftxt, st);
              pos := 12; st := Replicate(' ', 77);
           end;
     until False;
End;

Procedure  Display;
Begin
     oCol := Col; oRow := Row;
     t80 := S80; Row := 3;
     While (row < 20) and (t80 <> Nil) Do
     Begin
          Col := 1;
          Write(t80^.Info);
          t80 := t80^.Next;
          Row := Row + 1;
     End;
     Gotoxy(oCol, oRow);
End;

{========================== Receive a packet by ipx }
procedure Receive_packet;
var
     ri: byte;
begin
     {======= Receive ECB setting ...}
     Recb.In_use           := $FF;
     SIPX.CheckSum         := 0;
     RECB.Event_svc_Routine:= Nil;

     RECB.Socket_Number[1] := lo(rsocket);
     RECB.Socket_Number[2] := hi(rsocket);

     RECB.Fragment_Count     := 2;
     RECB.Fragment[1].Address:= @Ripx;
     RECB.Fragment[1].Length := Sizeof(IPXHeader);
     RECB.Fragment[2].Address:= @Rbuf;
     RECB.Fragment[2].Length := Sizeof(Rbuf);

     IPX_Listen_Packet(@RECB);
end;
{========================== Send a packet by ipx }

procedure Send_packet;
var
     si : byte;
begin
     Secb.In_use             := $FF;
     SIPX.CheckSum           := 0;
     SIPX.Transport_Control  := 0;
     SIPX.Length             := Sizeof(IPXHeader)+Sizeof(Sbuf);
     SIPX.Packet_type        := 4;

     SIPX.Dest_Network_socket[1] := lo(rsocket);
     SIPX.Dest_Network_socket[2] := hi(rsocket);

     {SECB.Link_address       := nil;}
     Secb.Event_svc_routine := Nil;
     Secb.Socket_Number[1]  := lo(ssocket);
     Secb.Socket_Number[2]  := hi(ssocket);

     Secb.Fragment_Count      := 2;
     Secb.Fragment[1].Address := @SIPX;
     Secb.Fragment[1].Length  := Sizeof(IPXHeader);
     Secb.Fragment[2].Address := @Sbuf;
     Secb.Fragment[2].Length  := Sizeof(Sbuf);

     If Not Sbuf.Ok then
        begin
             { Set value to interface to all bodies }
             for si := 1 to 4 do SIPX.Dest_Network_number[si]:= $FF;
             for si := 1 to 6 do begin
                 SIPX.Dest_Network_node[si]  := $FF;
                 Secb.Immediate_Address[si]  := $FF;
             end;
        end;
     IPX_Send_Packet(@Secb);
     Sbuf.Ok := False; { I'm just looking for you }
end;
{ ====================== End of Network Support Procedures =========== }
function Expand(l: byte; s: string10): string10;
var
   ss: string10;
   i : byte;
begin
   ss[0] := chr(l);
   i := Ord(s[0]);
   while (i>0) and (s[i] = ' ') do i := i - 1;
   if i > l then i := l;
   while (i>0) do begin
         ss[l] := s[i]; i := i - 1;
         if s[i+1] = ' ' then Continue;
         l := l - 1;
   end;
   while (l>0) do begin
         ss[l] := '0'; l := l - 1;
   end;
   Expand := ss;
end;

function MkKey(s: string10; SbyF: boolean): string10;
var
   mi, mj: byte;
begin
   mj := 0;
   for mi := 1 to Ord(s[0]) do
       if Not (s[mi] in ['0'..'9']) then begin
          s[mi] := UpCase(s[mi]);
          if mj = 0 then mj := mi;
       end;
   if mj = 0 then MkKey := s
   else
     if SbyF then
        MkKey := Expand(5,copy(s,1,mj-1))+Expand(5,copy(s,mj,5))
     else
        MkKey := Expand(5,copy(s,mj,5))+Expand(5,copy(s,1,mj-1));
end;

procedure Sort(mode: byte);
var
   t1: string80;
   t2: string10;
begin
   if (stype <> mode) and (S80 <> Nil) then BEGIN
     Backup_screen; color := 79; box(11,32,13,46,single_frame);
     gotoxy(34,12); write('Waiting ...'); color := 31;
     t80 := H80;
     while (t80 <> Nil) do begin
           case mode of
             1,2: t80^.Key := MkKey(copy(t80^.Info, 1, 10), mode = 1);
             3: t80^.Key := copy(t80^.Info, 65, 10);
           end;
           t80 := t80^.next;
     end;
     S80 := H80;
     while S80^.next <> Nil do begin
        t80 := S80^.next;
        while t80 <> Nil do begin
           if (t80^.key < S80^.key) then begin
              t1 := S80^.info; t2 := S80^.Key;
              S80^.info := t80^.info; S80^.key := t80^.key;
              t80^.info := t1; t80^.key := t2;
           end;
           t80 := t80^.next;
        end;
        S80 := S80^.next;
     end;
     stype := mode; S80 := H80; Row := 3; Col := 1;
     Restore_screen; Display;
   END;
end;

{ ====================== Data file =========== }
Function New_F1: boolean;
begin
     stype := 0; SdF := 0;       { non sorted list }
     str(fCount, st); fCount := fcount + 1;
     st := fname + st + fext;
     oCol := Col; oRow := Row; Color := 111;
     gotoxy(24, 22); write(Left(st+'          ', 12)); Color := 31;
     gotoxy(oCol, oRow);
     {$I-}
     assign(Ftxt, st);
     rewrite(Ftxt); writeln(Ftxt, H1); writeln(Ftxt, H2);
     {$I+}
     New_f1 := Ioresult = 0;
end;

{=================================== end of HOT process }
label hihi;
begin
  _row := row; _col := col; Backup_screen;
  EMP_VNI_LOAD; clrscr; zoom_mode := 1;
  IF ParamCount = 1 then
  BEGIN
    If ParamStr(1) = '/?' then begin
       gotoxy(0,row+1); Write('C†ch s¶ dûng HD.EXE:');
       gotoxy(5,row+1); Write('HD.EXE /?        : Xem hüÙng dÊn s¶ dûng HD.EXE.');
       gotoxy(5,row+1); Write('HD.EXE           : HüÙng dÊn lÖm bÖi thi trÈc nghi¨m.');
       gotoxy(5,row+1); Write('HD.EXE /HOT      : Thu bÖi tràn m‚ng s¶ dûng nghi th§c IPX.');
       gotoxy(5,row+1); Write('HD.EXE <tÁp tin> : X¢a dß li¨u thi trÈc nghi¨m trong <tÁp tin>');
       Inkey;
    end
    else
     If ParamStr(1) = '/HOT' then begin
       If not ipx_install THEN begin
           i := 26368;
           Message(12, 'Non supported IPX protocol !', True, False);
       end
       else BEGIN
        { Network installed OK }
        row := 24; Col := 0; color := 37; get_color := 111;
        write('   æEMP.01/2000~      Trüıng Æ‚i Hîc Kinh Tâ Tp.HCM   ~   '+
            'Bõ Mìn Tin Hîc   ');
        color := 31;
        Box(0,0,23,79,single_frame); Box(20, 0, 20, 79, Single_bar);
        Box(20, 17, 23, 17, Single_pol); gotoxy(2,22); write('”‘œœœœœœœœœ—”‘');
        gotoxy(19,21); Write('SÈp xâp danh s†ch:F1~Sñ B†o danh -F2~LÙp -F3~NetUserName');
        gotoxy(19,22); Write('Lüu:              F4~Lüu kât qu‡ -F5~New List -*-F7~TEST');
        gotoxy(1,1); Write(H1); gotoxy(1,2); Write(H2);
        st := 'CA1.KQ      '; gotoxy(24,22); Gets(st); Readg;
        if Exit_Key = ENTER_KEY then BEGIN
        i := 1; st := Trim(st);
        while (i <= ord(st[0])) and not (st[i] IN ['0'..'9','.']) do
              i:=i+1;
        if i - 1 > 6 then fname := copy(st, 1, 6)
        else fname := copy(st, 1, i-1);
        howlong := i; if st[i] <> '.' then i := i+1;
        while (i <= ord(st[0])) and (st[i] IN ['0'..'9']) do
              i:=i+1;
        Val(copy(st, Howlong, i-Howlong), fcount, key);
        if (i <= ord(st[0])) and (st[i] = '.') then fext := copy(st, i, 4)
        else fext := '';

        ipx_open_socket(ssocket);
        ipx_open_socket(rsocket);
        FillChar(RECB, Sizeof(ECB), #0);
        FillChar(SECB, Sizeof(ECB), #0);
        FillChar(RIpx, Sizeof(IPXHeader), #0);
        FillChar(SIpx, Sizeof(IPXHeader), #0);
        IPX_get_netnode_address(@Sbuf.NetNo);     { get Network address }
        Sbuf.Who := 'HOT'; Sbuf.Ok := false;
        H80 := Nil; ClearList; F7TEST := true;
        howlong := 0; i := 13; Cursor_On; filemode := 2;
        if New_F1 then begin
           Repeat
             if RECB.In_Use = 0 then begin
                if RBuf.Who = 'WSs' then begin
                   SEcb.immediate_address  := REcb.immediate_address;
                   SIpx.dest_network_number:= Rbuf.Netno;
                   SIpx.dest_network_node  := Rbuf.Netad;
                   SBuf.Ok := True; { I know you, OK ! }

                   Sbuf.Msg := Rbuf.Msg;
                   { Check this one and add new ? }
                   t80 := H80;
                   while (t80^.Next <> Nil) and (t80^.Info <> Rbuf.Msg) do
                         t80 := t80^.Next;
                   If t80^.Info <> Rbuf.Msg Then begin
                      SdL := SdL+1; SdF := SdF+1; stype := 0;
                      { This is a newOne for HOT, add it to list }
                      New(t80); t80^.Info := Rbuf.Msg;
                      t80^.Prev := C80; t80^.Next := Nil; t80^.No := SdL;
                      if H80 = Nil then begin H80 := t80; S80 := H80; end
                      else C80^.Next := t80;
                      C80 := t80; if SdL > 17 then S80 := S80^.next;
                      { his result }
                      Writeln(Ftxt, Rbuf.Msg);
                      Addline(Rbuf.Ans); Display;
                      oCol := Col; oRow := Row;
                      gotoxy(7, 21); write(SdL:4);
                      gotoxy(oCol, oRow);
                   end;
                   Rbuf.Who := 'HOT';
                end;
                Receive_packet;
             end
             Else
              If Keypressed then begin
                 key := Inkey;
                 case Key of
                      26368:    Break;
                      F1_KEY:   Sort(1);        { SOBD }
                      F2_KEY:   Sort(2);        { LOP }
                      F3_KEY:   Sort(3);        { NetName }
                      F4_KEY:   if (SdF > 0) then Begin
                                  WriteOffFile; New_F1;
                                end;
                      F5_KEY:   ClearList;
                      F7_KEY:   begin
                                   oRow := Row; oCol := Col; gotoxy(74,22);
                                   F7TEST := Not F7TEST;
                                   if F7TEST then begin
                                      st[0] := '*'; write('TEST');
                                   end
                                   else begin st[0] := 'F'; write('STOP'); end;
                                   {$I-}
                                   assign(FB, 'HD.TXT'); reset(FB,1);
                                   {$I+}
                                   if IoResult = 0 then begin
                                      BlockWrite(FB, st, 1); close(FB);
                                   end;
                                   gotoxy(oCol,oRow);
                                end;
                      LEFT_KEY: if col > 1 then gotoxy(col-1, row)
                                else gotoxy(78, row);
                      RIGHT_KEY:if col < 78 then gotoxy(col+1, row)
                                else gotoxy(1, row);
                      UP_KEY:   if row > 3 then gotoxy(col, row-1)
                                else
                                 if (S80 <> Nil) and (S80^.No > 1) Then begin
                                    S80 := S80^.prev; Display;
                                 end;
                      DOWN_KEY: if row < 19 then gotoxy(col, row+1)
                                else
                                 if (S80 <> Nil)and(SdL-S80^.No>16) then begin
                                    S80 := S80^.next; Display;
                                 end;
                      PGUP_KEY: begin
                                   oRow := 17;
                                   while (oRow > 0)and(S80^.No > 1) do begin
                                         S80 := S80^.Prev; oRow := oRow-1;
                                   end;
                                   if oRow > 0 then Row := 3;
                                   Display;
                                end;
                      PGDN_KEY: begin
                                   oRow := 0;
                                   while (oRow<17)and(SdL-S80^.No>16) do begin
                                         S80 := S80^.Next; oRow := oRow+1;
                                   end;
                                   if oRow < 17 then Row := 19;
                                   Display;
                                end;
                 end;
              end
              Else
                If SECB.In_use = 0 then Send_Packet
                Else begin
                  howlong := howlong + 1;
                  if howlong = 50 then
                     begin
                       if i < 14 then Mem[Video_Seg:3520+i*2] := 207;
                       if i = 14 then i := 4 else i := i + 1;
                       if i < 14 then Mem[Video_Seg:3520+i*2] := 209;
                       Howlong := 1; delay(20);
                     end;
                end;
           Until (false);
           WriteOffFile; ClearList;
        end
        Else Message(12, 'Can not write to current drive !', True, False);
        { Stop network jobs }
        IPX_cancel(@RECB);
        IPX_cancel(@SECB);
        IPX_close_socket(Rsocket);
        IPX_close_socket(Ssocket);
        END;
       END;
     end
      else begin
           filemode := 1;
           {$I-}
           Assign(FB, ParamStr(1)); Reset(FB, 1);
           {$I+}
           if Ioresult = 0 then begin
              BlockWrite(FB, A, 512, k); Close(FB);
              Message(12, 'The file '+ParamStr(1)+' is deleted.', true, false);
           end
           else begin
              i := 26368;
              Message(12, 'Error: '+ParamStr(1)+' can''t be deleted !', true, false);
           end;
      end;
  END
  else BEGIN
    tt := true; lt := true;
    oldcolor := color; color := 15;
    filemode := 32;
    {$I-}
    assign(Ftxt, 'HD.TXT');
    reset(Ftxt);
    {$I+}
    if IoResult <> 0 then begin
                hihi:
                key := F10_KEY;
                a[1] := 'VO VAN A';
                a[2] := '1/1/1980';
                a[4] := 'K24-1';
                a[3] := '01';
       end
    else
       begin
                readln(Ftxt, a[1]);
                a[4] := copy(a[1], 2, 2);
                val(a[4], key, i);
                if i <> 0 then begin
                   close(Ftxt);
                   goto hihi;
                end;
                key := phim[key];
                readln(Ftxt, a[1]);
                readln(Ftxt, a[2]);
                readln(Ftxt, a[4]);
                readln(Ftxt, a[3]);
                close(Ftxt);
                i := ord(a[1][0]);
                if (a[1][i] = '.') then a[1] := copy(a[1], 1, i-1)
                else begin
                     tt := false; a[2] := copy(a[2], 1, ord(a[2][0])-1);
                end;
                i := ord(a[4][0]);
                if (a[4][i] = '.') then a[4] := copy(a[4], 1, i-1)
                else begin
                     lt := false; a[3] := copy(a[3], 1, ord(a[3][0])-1);
                end;
       end;
    gotoxy(0, 2); write(#1'Ph‰n hüÙng dÊn dÖnh cho th° sinh:');
    gotoxy(3, 3); write('Khi c¢ hi¨u l¨nh bÈt ≠‰u bÖi thi, th° sinh ph‡i gí thìng tin cúa mçnh gòm');
    gotoxy(3, 4); write('M· lÙp, Sñ b†o danh, Hî tàn, NgÖy sinh vÖo hõp nhÁp c¢ d‚ng nhü sau:');
    gotoxy(0,12); write(#1'V° dû:~');
    gotoxy(3,13); write('Th° sinh',#1, a[1], '~sinh ngÖy',#1, a[2]);
                  if a[4]>'' then write(',~hîc lÙp',#1,a[4]);
    gotoxy(3,14); if a[4]='' then write('c¢ sñ b†o danh')
                  else write('c¢ sñ b†o danh (hoÌc sñ th§ t® theo lÙp)');
                  write(#1, a[3], '~thç nõi dung nhÁp nhü tràn.');
    gotoxy(0,16); write(#1'Lüu Ó:');
    gotoxy(3,17); write('- Khìng ch•a kho‡ng trÈng ≠‰u möi dïng nhÁp. Cuñi möi dïng, gí ph°m',#1'ENTER.');
    gotoxy(3,18); write('- Trong khi lÖm bÖi: Æé tr‡ lıi cho mõt cÉu hëi, dóng c†c ph°m mùi tàn di');
    gotoxy(3,19); write('  chuyén v¨t s†ng ≠ân mõt trong c†c ≠†p †n (a,b,c,...) cúa cÉu hëi ≠¢ vÖ gí');
    gotoxy(3,20); write('  ph°mENTER.~C¢ thé lÖm l‚i thao t†c nÖy ≠é chîn ≠†p †n kh†c cho cÉu hëi.');
    gotoxy(3,21); write('-'#3'Khìng ≠ü¯c thao t†c tràn m†y khi chüa c¢ hi¨u l¨nh cúa gi†m th´ coi thi.');
    gotoxy(4,22); write(#3'Hât giı lÖm bÖi, khìng ≠ü¯c tÈt m†y. Th° sinh ph‚m qui sÑ b´ ≠iém 0.');

    color := 113;
    for i := 1 to 6 do begin gotoxy(18, 5+i); write(BANG[i]); end;
    color := 111;
    gotoxy(29, 7);
    if lt then write(a[3], a[4]) else write(a[4], a[3]);
    gotoxy(29, 8);
    if tt then write(a[2], ' ', a[1]) else write(a[1], ' ', a[2]);
    i := key+1;
    Repeat
          case Get_HDFC of
               'F': if keypressed then i := Inkey else Delay(50);
               '*': i := key;
          end;
    Until (i = key) or (i = 26368);
  END;
  EMP_VNI_UnLoad; color := oldcolor; restore_screen; gotoxy(_col, _row);
  If i = 26368 Then Halt(1) Else Halt(0);
end.