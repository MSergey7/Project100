unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, CPort, StdCtrls, Menus, ComCtrls, Buttons, DateUtils;

type
  TForm1 = class(TForm)
    ComPort1: TComPort;
    Button1: TButton;
    Button2: TButton;
    OpenDialog1: TOpenDialog;
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    BitBtn3: TBitBtn;
    Memo1: TMemo;
    DateTimePicker1: TDateTimePicker;
    DateTimePicker2: TDateTimePicker;
    DateTimePicker3: TDateTimePicker;
    Label1: TLabel;
    Label2: TLabel;
    Button3: TButton;
    Memo2: TMemo;
    Edit1: TEdit;
    Edit2: TEdit;
    Edit3: TEdit;
    Edit4: TEdit;
    Edit5: TEdit;
    Button4: TButton;
    procedure Button1Click(Sender: TObject);
    procedure BitBtn2Click(Sender: TObject);
    procedure BitBtn3Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure Button4Click(Sender: TObject);



  private
    { Private declarations }
  public
    { Public declarations }
  end;

type

TBuf = array[0..1023] of Byte ;

//ïðîáóåì çàïèñàòü âñþ ñòðóêòóðó ôèñêàëêè â îäíó ÇÀÏÈÑÜ
//ïîòîì áóäåì å¸ îáñ÷èòûâàòü è ïå÷àòàòü

FP = record
ZavNom,    // çàâîäñêîé íðîìåð êêì
EklzNom : string;   // íîìåð ÝÊËÇ òåêóùåé

KolFiskaliz,            //Êîëè÷åñòâî ôèñêàëèçàöèé
KolAktivEklz,           //Êîëè÷åñòâî àêòèâèçàöèé ÝÊËÇ
KolSmOtchet : integer;  //Êîëè÷åñòâî îò÷åòîâ
SummaNI : int64   ;      //Íåîáíóëÿåìàÿ ñóììà

Fiskaliz  : array[1..5] of record       //Ñòðóêòóðà ôèñêàëèçàöèè - 5 çàïèñåé  ñ 0000
                           RegistrNomerFis,        //
                           INN                : string;
                           DataFis            : TDateTime ;    //òèï äàòà
                           NomerSmenyFis      : integer;
                           RegistrNomerEklz   : string;
                        end;

AktivEklz : array[1..20] of record      //Ñòðóêòóðà àêòèâèçàöèè - 20 çàïèñåé  ñ
                            NonerFiskaliz     : integer;     //Ê êàêîé ôèñêàëèçàöèè îòíîñèòñÿ ýòà ýêëç
                            RegistrNomerEklz  : string ;
                            DataEklz          : TDateTime;
                            NomerSmenyEklz    : integer ;
                         end;

SmOtchet  : array[1..2469] of record        //Ñòðóêòóðà îò÷åòà - 2469 çàïèñåé
                              NomerSmenyOt    : integer ;
                              DataSmeny       : TDateTime;
                              SummaSmeny      : int64 ;
                           end;
end;

//êâàðòàëû
DateKvart = record
datN : array [1..20] of record
                       s : string ;
                       d : TDateTime;
                       end;
datO : array [1..20] of record
                       s : string ;
                       d : TDateTime;
                       end;
end;


var
  Form1: TForm1;
  File1: TFileStream;
  Buf  : TBuf;
  MyFp : FP   ;
  MyDateKvart   : DateKvart;
  Ndok : integer;
  Nzap : integer;
implementation


{$R *.dfm}

{=============================================================================
Âîçâðàùàåò øåñòíàäöàòèðè÷íîå
ïðåäñòàâëåíèå ÷èñëà}
function GetHexStr(D:byte):string;
var Sh,Sl:String;
    Tmp:byte;
begin
  Tmp:=D and 15;
  Sl:=Chr(48+Tmp+7*(Tmp div 10));
  Tmp:=(D shr 4)and 15;
  Sh:=Chr(48+Tmp+7*(Tmp div 10));
  GetHexStr:=Sh+Sl;
end;

{=============================================================================
Ïðåîáðàçóåò ñòðîêó â âèä ïðèãîäíûé äëÿ ïå÷àòè äëÿ  ïå÷àòè }
function StrToOem(const AnsiStr: string): string;
begin
  SetLength(Result, Length(AnsiStr));
  if Length(Result) <> 0 then
    CharToOem(PChar(AnsiStr), PChar(Result));
end;

{=============================================================================}
//=== Îòäåëÿåì êîïåéêè îò ðóáåé äîáàâëÿåì òî÷êó
function InToStrS(i:int64):string;
var
 s,kop:string; //kop - êîïåéêè
 j:integer;
begin
j:=i mod 100; //ïðèñâàåâàåì êîïåéêè
if j=0 then kop := '.00' else
begin
 if (j mod 10) > 0  then kop:='.0' + IntToStr(j);
 if (j div 10) > 0  then kop:='.' + IntToStr (j);
end;

i:=i div 100; //óäàëÿåì ïîñëåäíèå äâà ðàçðÿäà

s:=IntToStr(i);
s:=s + kop ;
s:='*' + s ;
while (Length(s) < 16)  do          //äîáàâëÿåò òî÷êè â íà÷àëî
       begin
       s:=' '+ s;
       end;

InToStrS:=s;
end;

{=ïåðåïèñûâàåì ================================================================}
//=== Îòäåëÿåì êîïåéêè îò ðóáåé äîáàâëÿåì òî÷êó
function InToStrS_Ref(i:int64; Razr:integer; Razdel: string ):string;
var
 s,kop:string; //kop - êîïåéêè
 j:integer;
begin
j:=i mod 100; //ïðèñâàåâàåì êîïåéêè
if j=0 then kop := '.00' else
begin
 if (j mod 10) > 0  then kop:='.0' + IntToStr(j);
 if (j div 10) > 0  then kop:='.' + IntToStr (j);
end;

i:=i div 100; //óäàëÿåì ïîñëåäíèå äâà ðàçðÿäà

s:=IntToStr(i);
s:=s + kop ;
s:='*' + s ;
while (Length(s) < Razr)  do          //äîáàâëÿåò òî÷êè â íà÷àëî
       begin
       s:= Razdel + s;
       end;

Result:=s
end;


{=============================================================================}
//=== íóëè âïåðåäè ñóììû                                                        //ïåðåäåëàòü íà ïðîáåëû!!!!
function InToStrT(i:integer):string;
var
s:string;
begin
s:=IntToStr(i);
while (Length(s) < 4)  do
       begin
       s:='0'+ s;
       end;
InToStrT:=s;
end;

{=============================================================================}
//=== ïðîáåëû âïåðåäè ñóììû                                                        //ïåðåäåëàòü íà ïðîáåëû!!!!
function InToStrSp(i:integer):string;
var
s:string;
begin
s:=IntToStr(i);
while (Length(s) < 4)  do
       begin
       s:=' '+ s;
       end;
Result := s;
end;

{=============================================================================
Âîçâðàùàåò ÄÀÒÓ â ôîðìàòå 31.12.16  /  óäàëÿåì ñòîëåòèÿ }
function Date8ToStr6(Date1 : TDateTime):string;
var
s, s2 : string;
begin

s := DateToStr(Date1);
s2 := s[1] +
      s[2] +
      s[3] +
      s[4] +
      s[5] +
      s[6] +
      s[9] +
      s[10] ;

Result := s2;
end;

{=============================================================================
Âîçâðàùàåò âðåìÿ â ôîðìàòå 08:12  /  óäàëÿåì ñåêóíäû}
function Time8ToStr6(Time1 : TDateTime):string;
var
s, s2 : string;
begin

s := TimeToStr(Time1);
if Length(s) = 8 then
s2 := s[1] +
      s[2] +
      s[3] +
      s[4] +
      s[5]

else
s2 := '0'  +
      s[1] +
      s[2] +
      s[3] +
      s[4] ;



Result := s2;
end;


 
{=============================================================================
Çàïîëíÿåì êâàðòàëû
}
function InitMyDateKvart(a : integer):string;
var
i : integer;

begin
//2013
MyDateKvart.datN[1].s:='01.01.2013';
MyDateKvart.datO[1].s:='31.03.2013';

MyDateKvart.datN[2].s:='01.04.2013';
MyDateKvart.datO[2].s:='30.06.2013';

MyDateKvart.datN[3].s:='01.07.2013';
MyDateKvart.datO[3].s:='30.09.2013';

MyDateKvart.datN[4].s:='01.10.2013';
MyDateKvart.datO[4].s:='31.12.2013';

//2014
MyDateKvart.datN[5].s:='01.01.2014';
MyDateKvart.datO[5].s:='31.03.2014';

MyDateKvart.datN[6].s:='01.04.2014';
MyDateKvart.datO[6].s:='30.06.2014';

MyDateKvart.datN[7].s:='01.07.2014';
MyDateKvart.datO[7].s:='30.09.2014';

MyDateKvart.datN[8].s:='01.10.2014';
MyDateKvart.datO[8].s:='31.12.2014';

//2015
MyDateKvart.datN[9].s:='01.01.2015';
MyDateKvart.datO[9].s:='31.03.2015';

MyDateKvart.datN[10].s:='01.04.2015';
MyDateKvart.datO[10].s:='30.06.2015';

MyDateKvart.datN[11].s:='01.07.2015';
MyDateKvart.datO[11].s:='30.09.2015';

MyDateKvart.datN[12].s:='01.10.2015';
MyDateKvart.datO[12].s:='31.12.2015';

//2016
MyDateKvart.datN[13].s:='01.01.2016';
MyDateKvart.datO[13].s:='31.03.2016';

MyDateKvart.datN[14].s:='01.04.2016';
MyDateKvart.datO[14].s:='30.06.2016';

MyDateKvart.datN[15].s:='01.07.2016';
MyDateKvart.datO[15].s:='30.09.2016';

MyDateKvart.datN[16].s:='01.10.2016';
MyDateKvart.datO[16].s:='31.12.2016';

//2017
MyDateKvart.datN[17].s:='01.01.2017';
MyDateKvart.datO[17].s:='31.03.2017';

MyDateKvart.datN[18].s:='01.04.2017';
MyDateKvart.datO[18].s:='30.06.2017';

MyDateKvart.datN[19].s:='01.07.2017';
MyDateKvart.datO[19].s:='30.09.2017';

MyDateKvart.datN[20].s:='01.10.2017';
MyDateKvart.datO[20].s:='31.12.2017';


for i:=1 to 20 do MyDateKvart.datN[i].d:= StrToDate(MyDateKvart.datN[i].s);
for i:=1 to 20 do MyDateKvart.datO[i].d:= StrToDate(MyDateKvart.datO[i].s);


Result := '1';
end;






{
    !!!!!   Îòëàäêà  !!!!!
=============================================================================}
function Func_N_odin(s: string): string;
begin                            //ÈÍÈÖÈÀËÈÇÈÐÓÅÌ
//MyFp.ZavNom:='123456';            // Çàâ íîìåð
//MyFp.EklzNom:=12345678;         // íîìåð ÝÊËÇ

//MyFp.KolFiskaliz:=1 ;           //Êîëè÷åñòâî ôèñêàëèçàöèé
//MyFp.KolAktivEklz:=3;           //Êîëè÷åñòâî àêòèâèçàöèé ÝÊËÇ
//MyFp.KolSmOtchet:=10;           //Êîëè÷åñòâî îò÷åòîâ
//MyFp.Fiskaliz[2].RegistrNomerFis:=45;


ShowMessage(s+ ' Ïðèâåò '+ IntToStr(MyFp.KolSmOtchet) );
end;

{
############################################################################################################
############################################################################################################
############################################################################################################
Çàïîëíÿåì MyFP.
}
{
    !!!!!   ×èòàåì çàâ íîìåð ïî àäðåñó 162 äåñÿòè÷íûé  !!!!!

=============================================================================}

function Func_Read_ZavNomer(a: string): string;
var
s1, s2: string;
begin
    File1:=TFileStream.Create(Form1.OpenDialog1.FileName,fmOpenRead);
    File1.Seek(0,soFromBeginning);
    File1.Seek(162,soFromBeginning);  //  Ñìåùåíèå îò íà÷àëà ôàéëà

File1.Read(Buf, 4);

s1 := GetHexStr(Buf[0]) +GetHexStr(Buf[1]) +GetHexStr(Buf[2]) +GetHexStr(Buf[3]) ;
s2 := s1[1] + s1[2] + s1[3] + s1[4] + s1[5] + s1[6] + s1[7] ;
    File1.Free;
    File1:= nil;

//Form1.Memo1.Text := Form1.Memo1.Text + s1 + #13#10 + s2;
Result:= s2;
end;

{
    !!!!!   ×èòàåì ïî àäðåñó adr1  êîëè÷åñòâî ñèìâîëîâ count1 !!!!!
=============================================================================}
function Func_Read_Stroki(adr1, count1: integer  ): string;

//function Func_N_tri(adr1, count1: integer  ): string;
var
s1, s2: string;
i : integer;
begin
s1:='';
s2:='';

    File1:=TFileStream.Create(Form1.OpenDialog1.FileName,fmOpenRead);
    File1.Seek(0,soFromBeginning);
    File1.Seek(adr1,soFromBeginning);  //  Ñìåùåíèå îò íà÷àëà ôàéëà

File1.Read(Buf, count1);
//s1 := GetHexStr(Buf[0]) +GetHexStr(Buf[1]) +GetHexStr(Buf[2]) +GetHexStr(Buf[3]) ;
//s2 := s1[2] + s1[1] + s1[4] + s1[3] + s1[6] + s1[5] + s1[8] + s1[7] ;

for i:=0 to count1-1 do  s1 := s1 + GetHexStr(Buf[i]) ;    //âû÷èòûâàåì èç Buf ïî îäíîìó áàéòó êîëè÷åñòâîì count1 è ïðåîäðàçóåì â ñòðîêîâóþ
for i:=1 to count1 do  s2:=s2+ s1[i*2]+ s1[i*2-1];         // Ìåíÿåì òåòðàäû ìåñòàìè

    File1.Free;
    File1:= nil;

//Form1.Memo1.Text := Form1.Memo1.Text + #13#10 + s2;
Result:= s2;

end;

{
 =============================================================================}
function Func_Read_NomeraSmeny(adr1: integer  ): integer;
var
s1, s2: string;
i : integer;
begin
s1:='';
s2:='';

    File1:=TFileStream.Create(Form1.OpenDialog1.FileName,fmOpenRead);
    File1.Seek(0,soFromBeginning);
    File1.Seek(adr1,soFromBeginning);  //  Ñìåùåíèå îò íà÷àëà ôàéëà

File1.Read(Buf, 2); //íîìåð âñåãäà äâóõáàéòíûé

i := Buf[1]*256 +Buf[0] ;    //Ïðåîáðàçóåì â äåñÿòè÷íîå ÷èñëî
s2:= InToStrT(i);   //äëÿ îòëàäêè

    File1.Free;
    File1:= nil;

//Form1.Memo1.Text := Form1.Memo1.Text + #13#10 + s2;
Result:= i;
end;



{
×èòàåì  äàòó  ðåãèñòðàñèè àêòèâèçàöèè "ñ ïåðåìåíîé òåòðàä"
 =============================================================================}
function Func_Read_Data(adr1: integer): TDateTime;
var
  s1, s2: string;
  dd, mm, gg : string;
  ddd, mmm, ggg :integer;
  dddd, mmmm, gggg : Word;
  i : integer;
  ReadDate1 : TDateTime;
begin
s1:='';
s2:='';

    File1:=TFileStream.Create(Form1.OpenDialog1.FileName,fmOpenRead);
    File1.Seek(0,soFromBeginning);
    File1.Seek(adr1,soFromBeginning);  //  Ñìåùåíèå îò íà÷àëà ôàéëà

    File1.Read(Buf, 3); //äàòà âñåãäà èç òðåõ áàéò
       //s1 := GetHexStr(Buf[0]) +GetHexStr(Buf[1]) +GetHexStr(Buf[2]) +GetHexStr(Buf[3]) ;
       //s2 := s1[2] + s1[1] + s1[4] + s1[3] + s1[6] + s1[5] + s1[8] + s1[7] ;
    for i:=0 to 2 do  s1 := s1 + GetHexStr(Buf[i]) ;    //âû÷èòûâàåì èç Buf ïî îäíîìó áàéòó êîëè÷åñòâîì count1 è ïðåîäðàçóåì â ñòðîêîâóþ
    s2 := s1[2] + s1[1] + s1[4] + s1[3] + s1[6] + s1[5];

dd:=s2[1] + s2[2]; //äåíü
mm:=s2[3] + s2[4]; //ìåñÿö
gg:=s2[5] + s2[6]; //ãîä

if dd = 'FF' then dd:='01'   ;
if mm = 'FF' then mm:='01'   ;
if gg = 'FF' then gg:='00'   ;


ddd:=StrToInt(dd);
mmm:=StrToInt(mm);
ggg:=StrToInt('20' + gg);      //ãîä äîáàâëÿåì ñòîëåòèÿ

dddd:=ddd;
mmmm:=mmm;
gggg:=ggg;                 //Òðè áëîêà âûøå ïðåîáðàçîâàíèå òèïîâ îò ñòðîêè ê èíòåäæåðó è ê âîðäó. :-)

//ReadDate1:=Date;
ReadDate1:= EncodeDate(gggg, mmmm, dddd);    //ïåðåõîäèì ê òèïó TDateTime

    File1.Free;
    File1:= nil;

Form1.Memo1.Text := Form1.Memo1.Text + #13#10 + s2 + ' - ' + DateToStr(ReadDate1);

//Result:= s2;
Result:=ReadDate1;

end;

{
×èòàåì  äàòó  Z îò÷åòà "áåç ïåðåìåíû òåòðàä"
 =============================================================================}
function Func_Read_DataZ(adr1: integer): TDateTime;
var
  s1, s2: string;
  dd, mm, gg : string;
  ddd, mmm, ggg :integer;
  dddd, mmmm, gggg : Word;
  i : integer;
  ReadDate1 : TDateTime;
begin
s1:='';
s2:='';

    File1:=TFileStream.Create(Form1.OpenDialog1.FileName,fmOpenRead);
    File1.Seek(0,soFromBeginning);
    File1.Seek(adr1,soFromBeginning);  //  Ñìåùåíèå îò íà÷àëà ôàéëà

    File1.Read(Buf, 3); //äàòà âñåãäà èç òðåõ áàéò
       //s1 := GetHexStr(Buf[0]) +GetHexStr(Buf[1]) +GetHexStr(Buf[2]) +GetHexStr(Buf[3]) ;
       //s2 := s1[2] + s1[1] + s1[4] + s1[3] + s1[6] + s1[5] + s1[8] + s1[7] ;
    for i:=0 to 2 do  s1 := s1 + GetHexStr(Buf[i]) ;    //âû÷èòûâàåì èç Buf ïî îäíîìó áàéòó êîëè÷åñòâîì count1 è ïðåîäðàçóåì â ñòðîêîâóþ
    s2 := s1;

dd:=s2[1] + s2[2]; //äåíü
mm:=s2[3] + s2[4]; //ìåñÿö
gg:=s2[5] + s2[6]; //ãîä

if dd = 'FF' then dd:='01'   ;
if mm = 'FF' then mm:='01'   ;
if gg = 'FF' then gg:='00'   ;


ddd:=StrToInt(dd);
mmm:=StrToInt(mm);
ggg:=StrToInt('20' + gg);      //ãîä äîáàâëÿåì ñòîëåòèÿ

dddd:=ddd;
mmmm:=mmm;
gggg:=ggg;                 //Òðè áëîêà âûøå ïðåîáðàçîâàíèå òèïîâ îò ñòðîêè ê èíòåäæåðó è ê âîðäó. :-)

//ReadDate1:=Date;
ReadDate1:= EncodeDate(gggg, mmmm, dddd);    //ïåðåõîäèì ê òèïó TDateTime

    File1.Free;
    File1:= nil;

//Form1.Memo1.Text := Form1.Memo1.Text + #13#10 + s2 + ' - ' + DateToStr(ReadDate1);

//Result:= s2;
Result:=ReadDate1;

end;


{
 =============================================================================}
function Func_Read_AktNomeraFisk(adr1: integer  ): integer;
var
s1, s2: string;
i : integer;
begin
s1:='';
s2:='';

    File1:=TFileStream.Create(Form1.OpenDialog1.FileName,fmOpenRead);
    File1.Seek(0,soFromBeginning);
    File1.Seek(adr1,soFromBeginning);  //  Ñìåùåíèå îò íà÷àëà ôàéëà

File1.Read(Buf, 1); //íîìåð âñåãäà äâóõáàéòíûé

i := Buf[0] ;    //Ïðåîáðàçóåì â äåñÿòè÷íîå ÷èñëî
s2:= IntToStr(i);   //äëÿ îòëàäêè

    File1.Free;
    File1:= nil;

Form1.Memo1.Text := Form1.Memo1.Text + #13#10 + s2;
Result:= i;
end;

{
÷èòàåì ñìåííûå ñóììû
 =============================================================================}
function Func_Read_SummySm(adr1: integer  ): int64;
var
s1, s2: string;
i : int64;
begin
s1:='';
s2:='';

    File1:=TFileStream.Create(Form1.OpenDialog1.FileName,fmOpenRead);
    File1.Seek(0,soFromBeginning);
    File1.Seek(adr1,soFromBeginning);  //  Ñìåùåíèå îò íà÷àëà ôàéëà

File1.Read(Buf, 6); //

//for j:=0 to 5 do  if Buf[j]=255 then Buf[j]:=0; //ïðîâåðêà íà FF è ïðèñâàåâàåì íîëü


i := Buf[0] + Buf[1]*256 + Buf[2]*256*256 + Buf[3]*256*256*256 + Buf[4]*256*256*256*256 + Buf[5]*256*256*256*256*256;    //Ïðåîáðàçóåì â äåñÿòè÷íîå ÷èñëî
if i=281474976710655 then i:=0;

s2:= IntToStr(i);   //äëÿ îòëàäêè

    File1.Free;
    File1:= nil;

//Form1.Memo1.Text := Form1.Memo1.Text + #13#10 + s2;                               //çàêîììåíòèðîâàòü !!!
Result:= i;
end;

{
Ïîäñ÷èòûâàåì êîëè÷åñòâî ôèñêàëèçàöèé ïî çàïîëíåíé ñòðóêòóðå  MyFP
 =============================================================================}
function Func_Calc_KolFisk(a : integer ): integer;
var
 i: integer;
begin
 i:=0;
  while ((MyFP.Fiskaliz[i+1].RegistrNomerFis <> 'FFFFFFFF')  or (i = 4)) do  i:=i+1;      //ïðîâåðêà íà FF   "ïóñòîé"

  Form1.Memo1.Text := Form1.Memo1.Text + #13#10 + IntToStr(i);   //äëÿ îòëàäêè
  Result:= i;
end;

{
Ïîäñ÷èòûâàåì êîëè÷åñòâî Àêòèâèçàöèé ïî çàïîëíåíé ñòðóêòóðå  MyFP
 =============================================================================}
function Func_Calc_KolAktEKLZ(a : integer ): integer;
var
 i: integer;
begin
 i:=0;
  while ((MyFP.AktivEklz[i+1].RegistrNomerEklz <> 'FFFFFFFFFF') or (i = 19)) do  i:=i+1;      //ïðîâåðêà íà FF   "ïóñòîé"

  Form1.Memo1.Text := Form1.Memo1.Text + #13#10 + IntToStr(i);   //äëÿ îòëàäêè
  Result:= i;
end;

{
Ïîäñ÷èòûâàåì êîëè÷åñòâî Ñìåííûõ îò÷åòîâ ïî çàïîëíåíé ñòðóêòóðå  MyFP
 =============================================================================}
function Func_Calc_KolSmOtchet(a : integer ): integer;
var
 i: integer;
begin
 i:=0;
  while ((MyFP.SmOtchet[i+1].NomerSmenyOt <> 65535) or (i = 2468)) do  i:=i+1;      //ïðîâåðêà íà FF   "ïóñòîé"


  Form1.Memo1.Text := Form1.Memo1.Text + #13#10 + IntToStr(i);   //äëÿ îòëàäêè
  Result:= i;
end;

{
Ïîäñ÷èòûâàåì Ñóììó Ñìåííûõ îò÷åòîâ ïî çàïîëíåíé ñòðóêòóðå  MyFP
 =============================================================================}
function Func_Calc_SummaNI(a : integer ): int64;
var
 i: integer;
 S: int64;
begin
 S:=0;

For i:=1 to MyFP.KolSmOtchet  do
begin
S:= S + MyFP.SmOtchet[i].SummaSmeny      ;

//  Form1.Memo1.Text :=  Form1.Memo1.Text + #13#10 + IntToStr(i)+'-' + IntToStr(MyFP.SmOtchet[i].SummaSmeny)+' - ' + IntToStr(S);   //äëÿ îòëàäêè
end;

 Form1.Memo1.Text :=  Form1.Memo1.Text + #13#10 +  IntToStr(S);   //äëÿ îòëàäêè
  Result:= S;
end;



{
Ïîäñ÷èòûâàåì Ñóììó Ñìåííûõ îò÷åòîâ â äèàïàçîíå íîìåðîâ ïî ñòðóêòóðå  MyFP
 =============================================================================}
function Func_Calc_SummaNom(NRep1, NRep2 : integer ): int64;
var
Nom1, Nom2, i: integer;
 Sum: int64;
begin
 Sum:=0;
// Nom1:=0;
// Nom2:=0;
 Nzap:=0;
 //MyFP.KolSmOtchet;

if NRep1 <= MyFP.KolSmOtchet then Nom1:=NRep1 else Nom1 :=0   ;
if NRep2 <= MyFP.KolSmOtchet then Nom2:=NRep2 else Nom2 := MyFP.KolSmOtchet ;


if Nom1 <> 0 then     //ñîñòàâíîå óñëîâèå ïðîâåðÿåì ãðàíèöè äèàïîçîíîâ íîìåðîâ !!!//íå òåñòèðîâàíî!!!
if Nom1 <= Nom2 then
 begin
      for i:=Nom1 to Nom2  do
         begin
         Sum:= Sum + MyFP.SmOtchet[i].SummaSmeny      ;
           //  Form1.Memo1.Text :=  Form1.Memo1.Text + #13#10 + IntToStr(i)+'-' + IntToStr(MyFP.SmOtchet[i].SummaSmeny)+' - ' + IntToStr(S);   //äëÿ îòëàäêè
         inc(Nzap);

         end;
  end;
;
Form1.Memo1.Text :=  Form1.Memo1.Text + #13#10 +  IntToStr(Sum);   //äëÿ îòëàäêè
Result:= Sum;
end;



{
Ïîäñ÷èòûâàåì Ñóììó Ñìåííûõ îò÷åòîâ â äèàïàçîíå Äàò. ïî ñòðóêòóðå  MyFP
 =============================================================================}
function Func_Calc_SummaDate(Date1, Date2 : TDateTime ): int64;
var
 i: integer;
 Sum: int64;
begin
 Sum:=0;
 Nzap:=0;
 //MyFP.KolSmOtchet;

 for i:=1 to MyFP.KolSmOtchet do
             begin
              if ((MyFP.SmOtchet[i].DataSmeny >= Date1) and (MyFP.SmOtchet[i].DataSmeny <= Date2))
                then
                    begin
                    Sum:= Sum + MyFP.SmOtchet[i].SummaSmeny      ;
                   //  Form1.Memo1.Text :=  Form1.Memo1.Text + #13#10 + IntToStr(i)+'-' + IntToStr(MyFP.SmOtchet[i].SummaSmeny)+' - ' + IntToStr(S);   //äëÿ îòëàäêè
                    inc(Nzap);
                    end
             end;


//             Form1.Memo1.Text :=  Form1.Memo1.Text + #13#10 +  IntToStr(Nzap)+'-'+  IntToStr(Sum)+ #13#10;   //äëÿ îòëàäêè
Result:= Sum;
end;




{
Âûñ÷èòûâàåì Àêòóàëüíûé(ïîñëåäíèé) íîìåð ÝÊËÇ ïî çàïîëíåíé ñòðóêòóðå  MyFP
 =============================================================================}
function Func_Calc_EklzNom(a : integer ): string;
var
 s: string;
begin

if MyFP.Fiskaliz[MyFP.KolFiskaliz].NomerSmenyFis > MyFP.AktivEklz[MyFP.KolAktivEklz].NomerSmenyEklz
  then s:=MyFP.Fiskaliz[MyFP.KolFiskaliz].RegistrNomerEklz
  else s:=MyFP.AktivEklz[MyFP.KolAktivEklz].RegistrNomerEklz;

 Form1.Memo1.Text :=  Form1.Memo1.Text + #13#10 +  s;   //äëÿ îòëàäêè
 Result:= s;
end;


{ //ÍÅ ÈÑÏÎËÜÇÓÅÌ !!! ñ÷èòàòü áóäåì ïî äðóãîìó
 Ðàñ÷åò íîìåðà ñìåíû íà÷àëà ïîäñ÷åòà ïðè ôèñ.îò÷åòå ïî äàòàì.// ïî çàïîëíåíé ñòðóêòóðå  MyFP
 =============================================================================}
function Func_Calc_Nom_To_Date1(Date1 : TDateTime ): integer;
var
 i, maxZ, flag1: integer;
begin
 i:=1;
 flag1:=0;
 maxZ:=MyFP.KolSmOtchet;

while flag1=0 do
 begin
 if  i > maxZ then
               begin
                flag1:=1  ;
                i:=0;
               end

              else
               begin
               if MyFP.SmOtchet[i].DataSmeny >= Date1
                 then  flag1:=1
                 else  inc(i);

               end;

 end  ;



 Form1.Memo1.Text :=  Form1.Memo1.Text + #13#10 +  IntToStr(i);   //äëÿ îòëàäêè
 Result:= i;
end;


{
Îáíóëÿåì ñòðóêòóðó  MyFP
 =============================================================================}
function InitMyFP(a : integer ): integer;
var
 i: integer;

begin
//1.
MyFp.ZavNom := '';

//2.
for i:=1 to 5 do      //çäåñü çàïîëíÿåì ôèñêàëèçàöèè
 begin
 MyFP.Fiskaliz[i].RegistrNomerFis := 'FFFFFFFF';
 MyFP.Fiskaliz[i].INN := 'FFFFFFFFFFFF';
 MyFP.Fiskaliz[i].DataFis:=0;    //
 MyFP.Fiskaliz[i].NomerSmenyFis:=0;
 MyFP.Fiskaliz[i].RegistrNomerEklz := 'FFFFFFFFFF';
 end;

//3.
for i:=1 to 20 do    //çäåñü çàïëíÿåì àêòèâèçàöèè ÝÊËÇ
 begin
 MyFP.AktivEklz[i].NonerFiskaliz:=0 ;
 MyFP.AktivEklz[i].RegistrNomerEklz:='FFFFFFFFFF' ;
 MyFP.AktivEklz[i].DataEklz:=0 ;
 MyFP.AktivEklz[i].NomerSmenyEklz:=0  ;
 end;

//4.
for i:=1 to 2469 do    //Ñìåííûå îò÷åòû îò 1 äî 2469 øò
 begin
 MyFP.SmOtchet[i].NomerSmenyOt:=65535 ;
 MyFP.SmOtchet[i].DataSmeny:=0 ;
 MyFP.SmOtchet[i].SummaSmeny:=0  ;
 end;

//5.
MyFP.KolFiskaliz:= 0;

//6.
MyFP.KolAktivEklz:=0 ;

//7.
MyFP.KolSmOtchet:=0  ;

//8.
MyFP.SummaNI:=0 ;

//9.
MyFP.EklzNom := 'FFFFFFFFFF';

Result:=1;
end;



{
 !!! Êíîïêà çàãðóçèòü Ñòðóêòóðó MyFP !!!
=============================================================================}
procedure TForm1.Button1Click(Sender: TObject);
var
i: integer;
 begin
Form1.OpenDialog1.Filter:='Ôàéëû ôèñêàëêè Îðèîí 100Ê (*.bin)|*.bin|ÂÑÅ Ôàéëû (*.*)|*.*';
Form1.OpenDialog1.Title:='Ñôîðìèðîâàòü îò÷åò èç ôàéëà : ...';
Form1.OpenDialog1.DefaultExt:='bin';
Form1.OpenDialog1.HistoryList.Clear;

 if Form1.OpenDialog1.Execute then
   begin
//0.
//InitMyFP(1);

//1.
MyFp.ZavNom := Func_Read_ZavNomer('×èòàåì çàâ íîìåð'); //ðàáîòàåò

//2.
Form1.Memo1.Text := Form1.Memo1.Text + #13#10 + 'Ôèñêàëèçàöèè :'+ #13#10 ;
for i:=1 to 5 do      //çäåñü çàïîëíÿåì ôèñêàëèçàöèè
 begin
 MyFP.Fiskaliz[i].RegistrNomerFis := Func_Read_Stroki((27*i-27),4);
 MyFP.Fiskaliz[i].INN := Func_Read_Stroki((27*i-27)+7,6);
 MyFP.Fiskaliz[i].DataFis:=Func_Read_Data((27*i-27)+13);    //
 MyFP.Fiskaliz[i].NomerSmenyFis:=Func_Read_NomeraSmeny((27*i-27)+16) ;
 MyFP.Fiskaliz[i].RegistrNomerEklz := Func_Read_Stroki((27*i-27)+18,5);
 end;

//3.
Form1.Memo1.Text := Form1.Memo1.Text + #13#10 + 'Àêòèâèçàöèè ÝÊËÇ :'+ #13#10 ;
for i:=1 to 20 do    //çäåñü çàïëíÿåì àêòèâèçàöèè ÝÊËÇ
 begin
 MyFP.AktivEklz[i].NonerFiskaliz:=Func_Read_AktNomeraFisk(32267+(13*i-13))  ;
 MyFP.AktivEklz[i].RegistrNomerEklz:=Func_Read_Stroki(32267+(13*i-13)+1,5) ;
 MyFP.AktivEklz[i].DataEklz:=Func_Read_Data(32267+(13*i-13)+6) ;
 MyFP.AktivEklz[i].NomerSmenyEklz:=Func_Read_NomeraSmeny(32267+(13*i-13)+9)   ;
 end;

//4.
Form1.Memo1.Text := Form1.Memo1.Text + #13#10 + 'Z Îò÷åòû :'+ #13#10 ;
for i:=1 to 2469 do    //Ñìåííûå îò÷åòû îò 1 äî 2469 øò
 begin
 MyFP.SmOtchet[i].NomerSmenyOt:=Func_Read_NomeraSmeny(170+(13*i-13)+ 0) ;
 MyFP.SmOtchet[i].DataSmeny:=Func_Read_DataZ(170+(13*i-13)+ 2)  ;
 MyFP.SmOtchet[i].SummaSmeny:=Func_Read_SummySm(170+(13*i-13)+ 5)  ;
 end;

//5.
MyFP.KolFiskaliz:= Func_Calc_KolFisk(1);

//6.
MyFP.KolAktivEklz:=Func_Calc_KolAktEKLZ(1) ;

//7.
MyFP.KolSmOtchet:=Func_Calc_KolSmOtchet(1)  ;

//8.
MyFP.SummaNI:=Func_Calc_SummaNI(1) ;

//9.
MyFP.EklzNom:=Func_Calc_EklzNom(1) ;

   end;
end;


procedure TForm1.BitBtn2Click(Sender: TObject);
begin
  Form1.ComPort1.ShowSetupDialog;
end;

procedure TForm1.BitBtn3Click(Sender: TObject);
begin
//Form1.OnClose(Sender: TObject);
HALT;
end;



procedure TForm1.FormCreate(Sender: TObject);
begin

ComPort1.LoadSettings(stRegistry, 'HKEY_LOCAL_MACHINE\Software\Dejan');
  Form1.DateTimePicker1.Date:=Date;
  Form1.DateTimePicker1.Time:=Time;
  Form1.DateTimePicker2.Date:=Date;
  Form1.DateTimePicker2.Time:=Time;
  Ndok:= 1 ;
 

end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
 if ComPort1.Connected then ComPort1.Close ;
  ComPort1.StoreSettings(stRegistry, 'HKEY_LOCAL_MACHINE\Software\Dejan');
end;
{
############################################################################################################
############################################################################################################
############################################################################################################
Ôîðìèðóåì îò÷åòû.
}


{
X-îò÷åò.  /Ôîðìèðóåì X-îò÷åò ïðè ïîìîùè çàïîëíåíîé ñòðóêòóðû MyFP
 =============================================================================}
function Rep_X(a : integer ): string;
var
 s: string;
begin
//MyFP.SummaNI:=12345678901;

s:='';
s:=s + Form1.Edit1.Text + #13#10 ;
s:=s + Form1.Edit2.Text + #13#10 ;
s:=s + Form1.Edit3.Text + #13#10 ;
s:=s + Form1.Edit4.Text + #13#10 ;
s:=s + Form1.Edit5.Text + #13#10 + #13#10;
s:=s + '    ÎÒ×ÅÒ' + #13#10 ;
s:=s + '   ÑÌÅÍÍÛÉ' + #13#10 + #13#10 ;
s:=s + 'ÍÅÒ ÐÅÃÈÑÒÐÀÖÈÉ' + #13#10 ;
s:=s + '  ÎÒ×ÅÒ ÏÓÑÒ' + #13#10 + #13#10 ;
s:=s + 'ÍÅÎÁÍÓË. ÈÒÎÃ' + #13#10 ;
s:=s + InToStrS(MyFP.SummaNI) + #13#10 ;             //ïå÷àòàåì ÍÈ
s:=s + 'ÄÊ ¹         ' + IntToStr(Ndok) + #13#10;    //ïå÷àòàåì íîìåð äîêóìåíòà

inc(Ndok);

s:=s + Time8ToStr6(Form1.DateTimePicker2.Time)   ;    //îòäåëÿåì ñåêóíäû

s:=s + '   ' + Date8ToStr6(Form1.DateTimePicker1.Date)+ #13#10 ; //óäàëÿåì ñòîëåòèÿ èç äàòû
s:=s + 'ÎÐÈÎÍ ¹' + MyFP.ZavNom + #13#10 ;
s:=s + 'ÈÍÍ ' + MyFP.Fiskaliz[MyFP.KolFiskaliz].INN + #13#10 ;
s:=s + 'ÝÊËÇ ' + MyFP.EklzNom + #13#10 ;
s:=s + ' <ÏÔÏ ' + MyFP.Fiskaliz[MyFP.KolFiskaliz].RegistrNomerFis +'>' + #13#10 ;
s:=s + '\\\\\\\\\\\\\\\\' + #13#10 ;
s:=s + #13#10 + #13#10 + #13#10;

//  Result:= '';
  Result:= s;
end;

{
F-îò÷åò. Âñïîìîãàòåëüíàÿ ôóíêöèÿ .âñå ôèñêàëèçàöèè - àêòèâèçàöèè ïî çàïîëíåíîé ñòðóêòóðû MyFP
 =============================================================================}
function Rep_F(a : integer ): string;
var
 i, j: integer;
 s: string;
begin

for i:= 1 to MyFP.KolFiskaliz do
begin
 //çàïîëíÿåì ôèñêàëèçàöèþ
 if i=1 then s:=s + '  ÔÈÑÊÀËÈÇÀÖÈß' + #13#10 else  s:=s + ' ÏÅÐÅÐÅÃÈÑÒÐÀÖÈß' + #13#10  ;
 s:=s + 'Ð.¹     ' + MyFP.Fiskaliz[i].RegistrNomerFis + #13#10  ;
 s:=s + 'ÈÍÍ ' + MyFP.Fiskaliz[i].INN + #13#10  ;
 s:=s + 'ÄÀÒÀ   ' + Date8ToStr6(MyFP.Fiskaliz[i].DataFis) + '.'+ #13#10 ;
 s:=s + '¹ ÇÀÊ.ÑÌÅÐÛ ' +  InToStrT(MyFP.Fiskaliz[i].NomerSmenyFis) + #13#10 + #13#10  ;
 //çàïîëíÿåì àêòèâèçàöèþ êîòîðàÿ ñîâìåøåíà ñ ôèñêàëèçàöèåé
      s:=s + 'ÀÊÒÈÂÈÇÀÖÈß ÝÊËÇ' + #13#10 ;
      s:=s + 'ÝÊËÇ ' + MyFP.Fiskaliz[i].RegistrNomerEklz + #13#10 ;
      s:=s + 'ÄÀÒÀ   ' + Date8ToStr6( MyFP.Fiskaliz[i].DataFis) + '.' + #13#10 ;
      s:=s + '¹ ÇÀÊ.ÑÌÅÍÛ ' + InToStrT(MyFP.Fiskaliz[i].NomerSmenyFis) + #13#10 + #13#10 ;

 for j:= 1 to MyFP.KolAktivEklz do
    if MyFP.AktivEklz[j].NonerFiskaliz = (i-1) then
      begin
   //çàïîëíÿåì àêòèâèçàöèþ
      s:=s + 'ÀÊÒÈÂÈÇÀÖÈß ÝÊËÇ' + #13#10 ;
      s:=s + 'ÝÊËÇ ' + MyFP.AktivEklz[j].RegistrNomerEklz + #13#10 ;
      s:=s + 'ÄÀÒÀ   ' + Date8ToStr6(MyFP.AktivEklz[j].DataEklz) + '.' + #13#10 ;
      s:=s + '¹ ÇÀÊ.ÑÌÅÍÛ ' + InToStrT(MyFP.AktivEklz[j].NomerSmenyEklz) + #13#10 + #13#10 ;
      end

end ; //çàïîëíèëè ôèñêàëèçàöèè - àêòèâèçàöèè

  Result:= s;
end;


{
F-îò÷åò.  /Ôîðìèðóåì Ôèñêàëüíûé  îò÷åò  ïî íîìåðàì ïðè ïîìîùè çàïîëíåíîé ñòðóêòóðû MyFP
 =============================================================================}
function Rep_F_Nom_Kr(N1, N2 : integer ): string;
var
// i, j: integer;
 s: string;
begin
//MyFP.SummaNI:=12345678901;

s:='';
s:=s + '!' + Form1.Edit1.Text + #13#10 ;
s:=s + '!' + Form1.Edit2.Text + #13#10 ;
s:=s + '!' + Form1.Edit3.Text + #13#10 ;
s:=s + '!' + Form1.Edit4.Text + #13#10 ;
s:=s + '!' + Form1.Edit5.Text + #13#10 + #13#10;
s:=s + '!' + '    ÎÒ×ÅÒ' + #13#10 ;
s:=s + '!' + '   ÔÈÑÊÀËÜÍÛÉ' + #13#10 + #13#10 ;
s:=s + '  Ñ  '  + InToStrT(N1) + #13#10 ;
s:=s + '  ÏÎ ' + InToStrT(N2) + #13#10 + #13#10 ;
s:=s + '!ÐÅÃÈÑÒÐÀÖÈÈ ÊÊÌ' + #13#10 ;
s:=s + '\\\\\\\\\\\\\\\\' + #13#10 ;

s:=s + Rep_F(1) ;

s:=s + 'ÎÑÒ.ÏÅÐÅÐÅÃÈÑÒ ' + IntToStr(5 - MyFP.KolFiskaliz ) + #13#10 + #13#10 ;
s:=s + 'ÎÑÒ.ÀÊÒÈÂÈÇ.  ' + IntToStr(20 - MyFP.KolAktivEklz ) + #13#10 + #13#10;
s:=s + '\\\\\\\\\\\\\\\\' + #13#10 ;
Func_Calc_SummaNom(1, 2500); //êîñòûëè!!! çàïèñè ñ÷èòàþòñÿ îäíîâðåìåíî ñ èòîãàìè
s:=s + 'ÇÀÏ.      '  + InToStrSp(Nzap) + #13#10 ;

s:=s + '!ÈÒÎÃ'  + InToStrS_Ref(Func_Calc_SummaNom(1, 2500),12,'*') + #13#10 + #13#10 ;


s:=s + 'ÄÊ ¹         ' + IntToStr(Ndok) + #13#10;    //ïå÷àòàåì íîìåð äîêóìåíòà

inc(Ndok);
s:=s + Time8ToStr6(Form1.DateTimePicker2.Time)  ;    //îòäåëÿåì ñåêóíäû

s:=s + '   ' + Date8ToStr6(Form1.DateTimePicker1.Date) + #13#10 ; //óäàëÿåì ñòîëåòèÿ èç äàòû
s:=s + 'ÎÐÈÎÍ ¹' + MyFP.ZavNom + #13#10 ;
s:=s + 'ÈÍÍ ' + MyFP.Fiskaliz[MyFP.KolFiskaliz].INN + #13#10 ;
//s:=s + 'ÝÊËÇ ' + MyFP.EklzNom + #13#10 ;
s:=s + ' <ÏÔÏ ' + MyFP.Fiskaliz[MyFP.KolFiskaliz].RegistrNomerFis +'>' + #13#10 ;
s:=s + '\\\\\\\\\\\\\\\\' + #13#10 ;
s:=s + #13#10 + #13#10 + #13#10;

  Result:= s;
end;


{
F-îò÷åò.  /Ôîðìèðóåì Ôèñêàëüíûé  îò÷åò  ïî ÄÀÒÀÌ ïðè ïîìîùè çàïîëíåíîé ñòðóêòóðû MyFP
 =============================================================================}
function Rep_F_Date_Kr(DAT1, DAT2 : TDateTime ): string;
var
// i, j: integer;
 s: string;
begin
//MyFP.SummaNI:=12345678901;

s:='';
s:=s + '!' + Form1.Edit1.Text + #13#10 ;
s:=s + '!' + Form1.Edit2.Text + #13#10 ;
s:=s + '!' + Form1.Edit3.Text + #13#10 ;
s:=s + '!' + Form1.Edit4.Text + #13#10 ;
s:=s + '!' + Form1.Edit5.Text + #13#10 + #13#10;
s:=s + '!' + '    ÎÒ×ÅÒ' + #13#10 ;
s:=s + '!' + '   ÔÈÑÊÀËÜÍÛÉ' + #13#10 + #13#10 ;
s:=s + '   Ñ  '  + Date8ToStr6(DAT1) + #13#10 ;
s:=s + '   ÏÎ ' + Date8ToStr6(DAT2) + #13#10 + #13#10 ;
s:=s + '!ÐÅÃÈÑÒÐÀÖÈÈ ÊÊÌ' + #13#10 ;
s:=s + '\\\\\\\\\\\\\\\\' + #13#10 ;

s:=s + Rep_F(1) ;

s:=s + 'ÎÑÒ.ÏÅÐÅÐÅÃÈÑÒ ' + IntToStr(5 - MyFP.KolFiskaliz ) + #13#10 + #13#10 ;
s:=s + 'ÎÑÒ.ÀÊÒÈÂÈÇ.  ' + IntToStr(20 - MyFP.KolAktivEklz ) + #13#10 + #13#10;
s:=s + '\\\\\\\\\\\\\\\\' + #13#10 ;

Func_Calc_SummaDate(DAT1, DAT2); //êîñòûëè!!! çàïèñè ñ÷èòàþòñÿ îäíîâðåìåíî ñ èòîãàìè

s:=s + 'ÇÀÏ.      '  + InToStrSp(Nzap) + #13#10 ;
s:=s + '!ÈÒÎÃ'  + InToStrS_Ref(Func_Calc_SummaDate(DAT1, DAT2),12,'*') + #13#10 + #13#10 ;
s:=s + 'ÄÊ ¹         ' + IntToStr(Ndok) + #13#10;    //ïå÷àòàåì íîìåð äîêóìåíòà

inc(Ndok);
s:=s + Time8ToStr6(Form1.DateTimePicker2.Time)  ;    //îòäåëÿåì ñåêóíäû

s:=s + '   ' + Date8ToStr6(Form1.DateTimePicker1.Date) + #13#10 ; //óäàëÿåì ñòîëåòèÿ èç äàòû
s:=s + 'ÎÐÈÎÍ ¹' + MyFP.ZavNom + #13#10 ;
s:=s + 'ÈÍÍ ' + MyFP.Fiskaliz[MyFP.KolFiskaliz].INN + #13#10 ;
//s:=s + 'ÝÊËÇ ' + MyFP.EklzNom + #13#10 ;
s:=s + ' <ÏÔÏ ' + MyFP.Fiskaliz[MyFP.KolFiskaliz].RegistrNomerFis +'>' + #13#10 ;
s:=s + '\\\\\\\\\\\\\\\\' + #13#10 ;
s:=s + #13#10 + #13#10 + #13#10;

  Result:= s;
end;



procedure TForm1.Button2Click(Sender: TObject);
begin
 ;;
Form1.Memo2.Text:='';
Form1.Memo2.Text:=Form1.Memo2.Text + Rep_X(1);                 // ïå÷àòàåì X-îò÷åò
Form1.Memo2.Text:=Form1.Memo2.Text + Rep_F_Nom_Kr(1, 2500);   // çàäàåì äèàïàçîí ñìåí äëÿ ïå÷àòè
Form1.Memo2.Text:=Form1.Memo2.Text + Rep_F_Date_Kr(DateTimePicker3.Date, DateTimePicker2.Date);   // çàäàåì äèàïàçîí äàò


 ;;
end;



procedure TForm1.Button4Click(Sender: TObject);
begin
InitMyDateKvart(1);
//Func_Calc_SummaDate(Form1.DateTimePicker3.Date, Form1.DateTimePicker1.Date)

end;

end.
