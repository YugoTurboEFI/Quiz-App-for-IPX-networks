{
        Make DaTa files for EMP. test program.
        by: Le Ngoc Thanh.
}
uses EmpIO;
const
   mmm = 7;         {so file}
   nnn = 10;        {so de}
   kkk = 100;       {so cau}
type
   pnode = ^node;
   node = record
                info: string;
                next: pnode;
          end;
var
   sub          : array[1..20] of pnode;
   p, p1        : pnode;
   f            : array[1..mmm] of text;
   fSocau       : array[1..mmm] of integer;
   fName        : array[1..mmm] of string[15];
   fSochon      : array[1..mmm] of integer;
   DeCau        : array[1..nnn, 1..kkk] of integer;
   mm, kk, loop : byte;
   nn, k        : integer;
   fout         : Text;
   i,j,batdau,n : byte;
   t, outto     : string;
   t1,t2,t3     : string[40];
   tong, sodoc  : Longint;
   ghiok        : boolean;

function inval(l: byte; val: integer; f, t: byte): boolean;
var
   iv:          byte;
   trave:       boolean;
begin
   trave := false;
   for iv := f to t do
       if DeCau[l,iv] = val then trave := true;
   inval := trave;
end;

procedure GhiSub;
var
   m, l:        byte;
BEGIN
     { Hoan vi cac cau tra loi }
     for l := 1 to n do
         if sub[l]^.info[0] <> #0 then
            begin
                 m := random(l)+1;
                 if sub[m]^.info[0] <> #0 then
                    begin
                         p1 := sub[l];
                         sub[l] := sub[m];
                         sub[m] := p1;
                    end;
            end;
     { in ra }
     for l := 1 to n do
         begin
              p := sub[l];
              while (p <> nil) do
                    begin
                         writeln(fout, p^.info);
                         p1 := p; p := p^.next; dispose(p1);
                    end;
              end;
     n := 0; sub[1] := nil;
END;

begin
  Backup_screen; EMP_VNI_LOAD; filemode := 32;
  Randomize;
  loop := 0;
  t1   := '         Thi Tin H”c ®âi CŸóng          ';
  t2   := '          Thõi gian: 30 ph£t            ';
  t3   := '              ®‹ s–:                    ';

  Exit_key1 := Enter_key; Exit_key2 := Enter_key;
  write('S– m¤c ­› kh c nhau (s– tçp tin, < 8) cœa ­‹ thi: '); readln(mm);
  if (mm > mmm) then mm:=mmm;

  color := 31; get_color := 63; Box_Base := 1;
  row := 23-((24-2*mm-8) div 2);
  Box(23-row, 13, row+1, 66, Single_frame);
  col := 18; write('Emp.~:Tâo b› ­‹ thi tréc nghi¬m cho EMP.EXE~');
  REPEAT
     str(loop+1, outto);
     outto := left('DETHI.CA' + outto + '   ', 11);
     row := 22-row;
     for i := 1 to mm do
     begin
          str(i,t);
          fname[i] := 'MUC'+t+'.TXT   ';
          col := 18; row := row + 2;
          write('Tçp tin ', i, ': '); gets(fName[i]);
          col := 42; write('S– cƒu: '); geti(fSochon[i]);
     end;
     col := 18;row := row+2; write('S– ­‹: '); geti(nn);
     col := 32;write(#1'Tçp tin k‰t quà:~'); gets(outto);
     col := 15;row := row+2; write('Tiˆu ­‹ 1:'); gets(t1);
     col := 15;row := row+1; write('Tiˆu ­‹ 2:'); gets(t2);
     col := 15;row := row+1; write('Tiˆu ­‹ 3:'); gets(t3);
     readg;
     if Exit_key <> Enter_key then
        begin
             EMP_VNI_UNLOAD; Cursor_on;
             Restore_screen;
             if (loop = 0) then Halt(1) else Halt(0);
        end;
     loop := loop + 1;
     if (nn > nnn) then nn := nnn;
     row := row+2; col := 19; write('Pass1:', replicate('þ', 40));
     tong:= 0; kk := 0;
     for i := 1 to mm do
     begin
          fSocau[i] := 0;
          {$I-}
          assign(f[i], fname[i]);
          reset(f[i]);
          {$I+}
          if IoResult = 0 then
          BEGIN
               while not eof(f[i]) do
               begin
                 readln(f[i], t);
                 if (t[0] <> #0) and (t[1] = '*') and (t[2] = '*') then
                    begin fSocau[i] := fSocau[i]+1; tong := tong+1; end;
               end;
          END;
          if (fSocau[i] > 0) then kk := kk+fSochon[i];
          if (kk > kkk) then
             begin
                 fSochon[i] := fSochon[i] - (kk-kkk);
                 kk := kkk;
             end;
          col := 56; row := (23-2*mm-8) div 2 + i*2; write('/',fSocau[i]);
     end;

     batdau := 0; row := 23-((25-2*mm-8) div 2);
     for i := 1 to mm do
     if fSocau[i] > 0 then
     begin
         {so cau lay tu moi bo de vao 1 de}
         for j := 1 to nn do
           for k := 1 to fSochon[i] do
           begin
                repeat
                      DeCau[j,k+batdau] := Random(fSocau[i])+1;
                until not inval(j,Decau[j,k+batdau],batdau+1,batdau+k-1) or
                      (fSocau[i] < fSochon[i]);
                col := 25;
                write(replicate('Û',((j-1)*(batdau+fSochon[i])+k+batdau)div(nn*kk)*40));
           end;
         batdau := batdau + fSochon[i];
     end;
     {$I-}
     assign(fout, outto);
     rewrite(fout);
     {$I+}
     if IoResult = 0 then
     BEGIN
       sodoc := 0; tong := tong*nn;
       col := 19; row := 23-((25-2*mm-8) div 2);
       write('Pass2:', replicate('þ', 40));
       for i := 1 to nn do
       BEGIN
        writeln(fout, 'Û');
        writeln(fout, ';- This mark will protect your document');
        writeln(fout, Replicate(' ', 17), #1,t1,'~');
        writeln(fout, Replicate(' ', 17), #5,t2,'~');
        writeln(fout, Replicate(' ', 17), #4,Rtrim(t3),#1,i,'~');
        { Lay tu mm bo de }
        batdau := 0;
        for j := 1 to mm do
          if fSocau[j] > 0 then
          begin
             reset(f[j]); ghiok := false; k := 0; {so cau ghi ra}
             n := 0; sub[1] := nil;
             while not eof(f[j]) do
             begin
                readln(f[j], t);
                if (t[1] in ['@','|','#']) or ((t[0] = #0)and(sub[1]<>nil))
                 then
                  begin
                     if (ghiOK) then
                     BEGIN
                     if (t[1] in ['@','#']) or (t[0] = #0) then
                        begin
                             n := n + 1; new(p); Sub[n] := p;
                        end
                     else
                        begin
                             new(p^.next); p := p^.next;
                        end;
                     p^.next := nil;
                     p^.info := t;
                     END;
                  end
                else
                  BEGIN
                   if (t[0] <> #0) and (t[1] = '*') and (t[2]='*') then
                   begin
                     if (n > 0) and ghiok then GhiSub;
                     k := k + 1; sodoc := sodoc + 1;
                     ghiok := inval(i, k, batdau+1, batdau+fSochon[j]);
                     col := 25; write(replicate('Û', (sodoc*40) div tong));
                   end;
                   if ghiOk then writeln(fout, t);
                  END;
             end;
             if (n > 0) and ghiok then GhiSub;
             batdau := batdau + fSochon[j];
          end
       END;
       writeln(fout, 'Û');
       close(fout);
     END;
     for i := 1 to mm do if (fSocau[i] > 0) then close(f[i]);
     col := 19;
     write('Ch”n',kk:4,' cƒu t¥',tong div nn:6,' cƒu cho mši ­‹ thi.     ');
  UNTIL false;
end.
