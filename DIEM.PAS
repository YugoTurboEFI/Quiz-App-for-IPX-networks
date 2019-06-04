program DIEM_FROM_EMP_PROGRAM;
Type  String12 = string[12];
      phs = ^hs;
      hs  = Record
               key:   String12;
               info:  string[44];
               f:     String12;
               diem:  real;
               next:  phs;
            End;
Var
     fname  : Array[1..150] of String12;
     s      : String;
     i, FNo : byte;
     p,p1,p2: phs;
     F, Fo  : TEXT;
     t,t1,t2: word;
     stype  : byte;

function Expand(l: byte; s: string12): string12;
var
   ss: string12;
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

function MkKey(s: string12; SbyF: boolean): string12;
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
        MkKey := Expand(6,copy(s,1,mj-1))+Expand(6,copy(s,mj,6))
     else
        MkKey := Expand(6,copy(s,mj,6))+Expand(6,copy(s,1,mj-1));
end;

BEGIN
     if (ParamCount < 2) or (ParamCount > 3) then begin
        writeln('Syntax: DIEM <FileType> <OutputFile> [F | N (sort by First portion | NetUser) ]');
        halt(1);
     end;
     stype := 0;
     if ParamStr(3) = 'F' then stype := 1
     else if ParamStr(3) = 'N' then stype := 2;
     Fname[1] := ParamStr(1)+chr(0);   { file type in wildcard expression }
     i := 1; FNo := 0;
     ASM
        mov     ah,$1a
        lea     dx,s
        inc     dx         {skip the byte of length of string}
        int     $21        {set DTA}

        mov     ah,$4e     {file first}
        xor     cx,cx      {Normal file}          ÿÿ
        lea     dx,Fname
        inc     dx         {skip the byte of string length}
        int     $21
        jnc     @mf
        mov     Byte Ptr i,0
     @mf:
     End;
     While  (i > 0)And(FNo<150) Do
        Begin
             FNo  := FNo + 1;
             fName[FNo] := '';
             i := $1e+1;                   {Offset of filename in s}
             while (Ord(s[i]) <> 0) Do
                   Begin
                        fName[FNo] := fName[FNo] + s[i];
                        i  := i + 1
                   End;
             ASM
                mov     ah,$4f  {File next}
                xor     cx,cx
                lea     dx,s
                inc     dx
                int     $21
                jnc     @mf
                mov     Byte ptr i,0
             @mf:
             End;
        End;
     If FNo = 0 Then
        Begin
             writeln('No such files found.');
             halt(1);
        End;
     p := NIL;
     s := ParamStr(2);
     writeln;
     writeln('We have ',FNo,' File(s) processed to output file: ', s);
     {$I-}
     assign(Fo, s); rewrite(fo);
     {$I+}
     if IoResult <> 0 then begin
          writeln('Can not save to file ', s);
          halt(1);
     end;
     for i := 1 to FNo do begin
         write('  ', copy(FName[i]+'            ', 1, 12));
         {$I-}
         assign(F, FName[i]);
         reset(f);
         {$I+}
         if IoResult <> 0 then begin
              writeln(', Can''t read from this file.');
              continue;
         end;
         for t := 1 to 70 do begin
             readln(F, s);
             if eof(F) or (s[1] = '#') then break;
         end;
         if eof(F) or (t = 70) then begin
              writeln(', not a test-result file from EMP.');
              continue;
         end;
         while not eof(F) do begin
               readln(F, s);
               if (s='') or (s[1] in ['=',' ']) then continue;
               val(copy(s, 46, 3), t1, t); val(copy(s, 50, 3), t2, t);
               if (t2 = 0) then begin
                  write(', is in wrong format.');
                  asm
                     mov        ah, 0
                     int        016h
                  end;
                  break;
               end;
               new(p2);
               if (p2 = Nil) then begin
                  close(f); close(fo);
                  writeln('Heap overflow !'); halt(1);
               end;
               case stype of
                    0,1: p2^.key  := MkKey(copy(s, 1, 10), stype = 1);
                    2:   p2^.key  := copy(s, 65, 10);
               end;
               p2^.info := copy(s, 1, 44); p2^.f := Fname[i];
               p2^.diem := 10*t1/t2;
               t := 44;
               while p2^.info[t] = ' ' do begin
                     p2^.info[t] := '.'; t := t - 1;
               end;
               if (p=Nil) then begin p := p2; p2^.next := nil; end
               else begin
                    if p^.key > p2^.key then begin
                       p2^.next := p; p := p2;
                    end
                    else begin
                       p1 := p;
                       while (p1^.next<>Nil)and((p1^.next)^.key<=p2^.key) do
                          p1 := p1^.next;
                       p2^.next := p1^.next;
                       p1^.next := p2;
                    end;
               end;
         end;
         writeln; close(F);
     end;
     t := 0; t1 := 0; t2 := 0;
     while p <> Nil do begin
          if t mod 50 = 0 then begin
             writeln(fo, #12'                                                  Page: ', t div 50 + 1);
             writeln(fo, '========== == ============================= ====  ===========');
             writeln(fo, '#RegNo     Ex Full Name                     Mark  Print from');
             writeln(fo, '========== == ============================= ====  ===========');
{
	                 'Class     #Reg Full Name                     BirthDate  Ex Ans/Tot Mark Emp.ID  \r\n"
			 '========= ==== ============================= ========== == ======= ==== ======= \r\n");
}
          end;
          if stype = 2 then
             writeln(Fo, p^.info, p^.diem:4:0, '  ', p^.key)
          else
             writeln(Fo, p^.info, p^.diem:4:0, '  ', p^.f);
          if p^.diem+0.5 < 5 then begin
             t1 := t1 + 1;
             if p^.diem+0.5 < 4 then t2 := t2 + 1;
          end;
          p1 := p; p := p^.next; dispose(p1); t := t + 1;
     end;
     writeln(fo, '========== == ============================= ====  ===========');
     writeln(fo, 'Total: ', t:5, ' student(s).');
     writeln(fo, 'Under 5: ', t1:3, ' (=',t1*100/t:0:0, '%)');
     writeln(fo, 'Under 4: ', t2:3, ' (=',t2*100/t:0:0, '%)');
     close(Fo);
     writeln('Total: ',t,' Student(s) from ',fNo,' file(s) of type ',ParamStr(1));
END.