unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, CPort, StdCtrls, Menus, ComCtrls, Buttons, DateUtils, Unit2;

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
    Button5: TButton;
    TrackBar1: TTrackBar;
    BitBtn4: TBitBtn;
    BitBtn5: TBitBtn;
    RichEdit1: TRichEdit;
    procedure Button1Click(Sender: TObject);
    procedure BitBtn2Click(Sender: TObject);
    procedure BitBtn3Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure Button4Click(Sender: TObject);
    procedure TrackBar1Change(Sender: TObject);
    procedure BitBtn4Click(Sender: TObject);
    procedure BitBtn5Click(Sender: TObject);


    procedure BitBtn1Click(Sender: TObject);
    
//


  private
    { Private declarations }
  public
    { Public declarations }
  end;

type

TBuf = array[0..1023] of Byte ;

//������� �������� ��� ��������� �������� � ���� ������
//����� ����� � ����������� � ��������

FP = record
ZavNom,    // ��������� ������ ���
EklzNom : string;   // ����� ���� �������
DataEklz : TDateTime; //���� ����������� ������� ����

KolFiskaliz,            //���������� ������������
KolAktivEklz,           //���������� ����������� ����
KolSmOtchet : integer;  //���������� �������
SummaNI : int64   ;      //������������ �����

Fiskaliz  : array[1..5] of record       //��������� ������������ - 5 �������  � 0000
                           RegistrNomerFis,        //
                           INN                : string;
                           DataFis            : TDateTime ;    //��� ����
                           NomerSmenyFis      : integer;
                           RegistrNomerEklz   : string;
                        end;

AktivEklz : array[1..20] of record      //��������� ����������� - 20 �������  �
                            NonerFiskaliz     : integer;     //� ����� ������������ ��������� ��� ����
                            RegistrNomerEklz  : string ;
                            DataEklz          : TDateTime;
                            NomerSmenyEklz    : integer ;
                         end;

SmOtchet  : array[1..2469] of record        //��������� ������ - 2469 �������
                              NomerSmenyOt    : integer ;
                              DataSmeny       : TDateTime;
                              SummaSmeny      : int64 ;
                           end;
end;

//��������
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
  Buf, Buf_Out, Buf_Inp  : TBuf;
  MyFp : FP   ;
  MyDateKvart   : DateKvart;
  Ndok : integer;
  Nzap : integer;
  FileNameTemp: string;

procedure Print_Op_100_mod(StrPrint: string );

implementation


{$R *.dfm}

//.1.
{=============================================================================
���������� �����������������
������������� �����}
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

//.2.
{=============================================================================
����������� ������ � ��� ��������� ��� ������ ���  ������ }
function StrToOem(const AnsiStr: string): string;
begin
  SetLength(Result, Length(AnsiStr));
  if Length(Result) <> 0 then
    CharToOem(PChar(AnsiStr), PChar(Result));
end;

//.3.
{=============================================================================}
//=== �������� ������� �� ����� ��������� �����
function InToStrS(i:int64):string;
var
 s,kop:string; //kop - �������
 j:integer;
begin
j:=i mod 100; //����������� �������
if j=0 then kop := '.00' else
begin
 if (j mod 10) > 0  then kop:='.0' + IntToStr(j);
 if (j div 10) > 0  then kop:='.' + IntToStr (j);
end;

i:=i div 100; //������� ��������� ��� �������

s:=IntToStr(i);
s:=s + kop ;
s:='*' + s ;
while (Length(s) < 16)  do          //��������� ����� � ������
       begin
       s:=' '+ s;
       end;

InToStrS:=s;
end;

//.4.
{=������������ ================================================================}
//=== �������� ������� �� ����� ��������� �����
function InToStrS_Ref(i:int64; Razr:integer; Razdel: string ):string;
var
 s,kop:string; //kop - �������
 j:integer;
begin
j:=i mod 100; //����������� �������
if j=0 then kop := '.00' else
begin
 if (j mod 10) > 0  then kop:='.0' + IntToStr(j);
 if (j div 10) > 0  then kop:='.' + IntToStr (j);
end;

i:=i div 100; //������� ��������� ��� �������

s:=IntToStr(i);
s:=s + kop ;
s:='*' + s ;
while (Length(s) < Razr)  do          //��������� ����� � ������
       begin
       s:= Razdel + s;
       end;

Result:=s
end;

//.5.
{=============================================================================}
//=== ���� �������  �����                                                        //���������� �� �������!!!!
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

//.6.
{=============================================================================}
//=== ������� ������� �����                                                        //���������� �� �������!!!!
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

//.7.
{=============================================================================
���������� ���� � ������� 31.12.16  /  ������� �������� }
function Date8ToStr6(Date1 : TDateTime; Sep : string):string;
var
s, s2 : string;
begin

s := DateToStr(Date1);
{
s2 := s[1] +
      s[2] +
      s[3] +
      s[4] +
      s[5] +
      s[6] +
      s[9] +
      s[10] ;
 }
s2 := s[1] +
      s[2] +
      Sep  +
      s[4] +
      s[5] +
      Sep  +
      s[9] +
      s[10] ;

Result := s2;
end;

//.8.
{=============================================================================
���������� ����� � ������� 08:12  /  ������� �������}
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

//.9.
//=============================================================================
//WriteBuf
//����� ������� ������� � ���� � ������.
//Buf: TBuf; ���c�� ����
//N: integer  ���������� ����
procedure WriteBuf(Buf:TBuf; N:integer); //
var
i:integer;
begin
 try
 for i:=0 to N-1 do
 begin
  sleep(3);
//  HexToStr(55);
  Form1.ComPort1.Write(Buf[i], 1);      //���������� �������
 end;
 finally
 end;
end;


//.10.
{=============================================================================}
procedure Print_Op_100(StrPrint: string );
var
i : integer ;
Spr: string ;
begin
 try

if StrPrint = '' then StrPrint := '      ' ; //#13#10 ;

Spr:=StrToOem(AnsiLowerCase(StrPrint));

for i:= 0 to 17 do Buf_Out[i]:= $20 ;

Form1.ComPort1.Open;
if Form1.ComPort1.Connected then
  begin

   Buf_Out[0]:= $99 ;
   if  Spr[1]<> '!' then Spr:= Spr[1] + Spr;

   for i:= 1 to Length(Spr) do Buf_Out[i]:= Byte(Spr[i]);
   Form1.ComPort1.Write(Buf_Out, 18);
  end;
Sleep(100);
Form1.ComPort1.Close;

 finally
 end;
end;
///

//.10.
{=============================================================================}
procedure Print_Op_100_mod(StrPrint: string );
var
i : integer ;
Spr: string ;
begin

if StrPrint = '' then StrPrint := '      ' ; //#13#10 ;
Spr:=StrToOem(AnsiLowerCase(StrPrint));
for i:= 0 to 17 do Buf_Out[i]:= $20 ;
Buf_Out[0]:= $99 ;
if  Spr[1]<> '!' then Spr:= Spr[1] + Spr;
for i:= 1 to Length(Spr) do Buf_Out[i]:= Byte(Spr[i]);
Form1.ComPort1.Write(Buf_Out, 18);

end;
///


//.11.
{=============================================================================
��������� ��������
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



//.12.
//=============================================================================
//MemoPrint
//�������� ������ ������ � RichEdit-e
//
//Srt_Color: integer;1-������� , 2-�������
//
procedure MemoPrint(Str1: string ; Srt_Color: integer );
var n, m: Integer;
begin
n:=Length(Form1.RichEdit1.Text); // ���������� ����� ������
m:=Length(Str1);
Form1.RichEdit1.Lines.Add(Str1);    //��������� ������ (��������������� )
Form1.RichEdit1.SelStart:= n; // ������������� ������ ���������
Form1.RichEdit1.SelLength:= m; // ������������� ����� ��������� ��� ������� � ���� ������ (0x55h --> '55 ')
 if Srt_Color = 1 then Form1.RichEdit1.SelAttributes.Color:=clRed   ;// ... � �������� �����
 if Srt_Color = 2 then Form1.RichEdit1.SelAttributes.Color:=clGreen ;  // ... � �������� �����
// Form1.RichEdit1.Lines.Add(''); // ������ ������, ���� ��������� ���������
end;

//.13.
{=============================================================================}
//=== �������� � ��� �����
function PrintFPToRich(i:integer):string;
var
s:string;
begin
;
;
MemoPrint('ABCD', 1);
MemoPrint('�����', 2);



Result := s;
end;

{=============================================================================}
{=============================================================================}
{=============================================================================}
{=============================================================================}
{
    !!!!!   �������  !!!!!
=============================================================================}
function Func_N_odin(s: string): string;
begin                            //��������������
//MyFp.ZavNom:='123456';            // ��� �����
//MyFp.EklzNom:=12345678;         // ����� ����

//MyFp.KolFiskaliz:=1 ;           //���������� ������������
//MyFp.KolAktivEklz:=3;           //���������� ����������� ����
//MyFp.KolSmOtchet:=10;           //���������� �������
//MyFp.Fiskaliz[2].RegistrNomerFis:=45;


ShowMessage(s+ ' ������ '+ IntToStr(MyFp.KolSmOtchet) );
end;

{
################################################################################
################################################################################
################################################################################

                          ��������� MyFP.


===============================================================================}
//     !!!!!   ������ ��� ����� �� ������ 162 ����������  !!!!!
function Func_Read_ZavNomer(a: string): string;
var
s1, s2: string;
begin
    File1:=TFileStream.Create(Form1.OpenDialog1.FileName,fmOpenRead);
    File1.Seek(0,soFromBeginning);
    File1.Seek(162,soFromBeginning);  //  �������� �� ������ �����

File1.Read(Buf, 4);

s1 := GetHexStr(Buf[0]) +GetHexStr(Buf[1]) +GetHexStr(Buf[2]) +GetHexStr(Buf[3]) ;
s2 := s1[1] + s1[2] + s1[3] + s1[4] + s1[5] + s1[6] + s1[7] ;
    File1.Free;
    File1:= nil;

//Form1.Memo1.Text := Form1.Memo1.Text + s1 + #13#10 + s2;
Result:= s2;
end;

{
    !!!!!   ������ �� ������ adr1  ���������� �������� count1 !!!!!
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
    File1.Seek(adr1,soFromBeginning);  //  �������� �� ������ �����

File1.Read(Buf, count1);
//s1 := GetHexStr(Buf[0]) +GetHexStr(Buf[1]) +GetHexStr(Buf[2]) +GetHexStr(Buf[3]) ;
//s2 := s1[2] + s1[1] + s1[4] + s1[3] + s1[6] + s1[5] + s1[8] + s1[7] ;

for i:=0 to count1-1 do  s1 := s1 + GetHexStr(Buf[i]) ;    //���������� �� Buf �� ������ ����� ����������� count1 � ����������� � ���������
for i:=1 to count1 do  s2:=s2+ s1[i*2]+ s1[i*2-1];         // ������ ������� �������

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
    File1.Seek(adr1,soFromBeginning);  //  �������� �� ������ �����

File1.Read(Buf, 2); //����� ������ �����������

i := Buf[1]*256 +Buf[0] ;    //����������� � ���������� �����
s2:= InToStrT(i);   //��� �������

    File1.Free;
    File1:= nil;

//Form1.Memo1.Text := Form1.Memo1.Text + #13#10 + s2;
Result:= i;
end;



{
������  ����  ����������� ����������� "� ��������� ������"
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
    File1.Seek(adr1,soFromBeginning);  //  �������� �� ������ �����

    File1.Read(Buf, 3); //���� ������ �� ���� ����
       //s1 := GetHexStr(Buf[0]) +GetHexStr(Buf[1]) +GetHexStr(Buf[2]) +GetHexStr(Buf[3]) ;
       //s2 := s1[2] + s1[1] + s1[4] + s1[3] + s1[6] + s1[5] + s1[8] + s1[7] ;
    for i:=0 to 2 do  s1 := s1 + GetHexStr(Buf[i]) ;    //���������� �� Buf �� ������ ����� ����������� count1 � ����������� � ���������
    s2 := s1[2] + s1[1] + s1[4] + s1[3] + s1[6] + s1[5];

dd:=s2[1] + s2[2]; //����
mm:=s2[3] + s2[4]; //�����
gg:=s2[5] + s2[6]; //���

if dd = 'FF' then dd:='01'   ;
if mm = 'FF' then mm:='01'   ;
if gg = 'FF' then gg:='00'   ;


ddd:=StrToInt(dd);
mmm:=StrToInt(mm);
ggg:=StrToInt('20' + gg);      //��� ��������� ��������

dddd:=ddd;
mmmm:=mmm;
gggg:=ggg;                 //��� ����� ���� �������������� ����� �� ������ � ��������� � � �����. :-)

//ReadDate1:=Date;
ReadDate1:= EncodeDate(gggg, mmmm, dddd);    //��������� � ���� TDateTime

    File1.Free;
    File1:= nil;

Form1.Memo1.Text := Form1.Memo1.Text + #13#10 + s2 + ' - ' + DateToStr(ReadDate1);

//Result:= s2;
Result:=ReadDate1;

end;

{
������  ����  Z ������ "��� �������� ������"
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
    File1.Seek(adr1,soFromBeginning);  //  �������� �� ������ �����

    File1.Read(Buf, 3); //���� ������ �� ���� ����
       //s1 := GetHexStr(Buf[0]) +GetHexStr(Buf[1]) +GetHexStr(Buf[2]) +GetHexStr(Buf[3]) ;
       //s2 := s1[2] + s1[1] + s1[4] + s1[3] + s1[6] + s1[5] + s1[8] + s1[7] ;
    for i:=0 to 2 do  s1 := s1 + GetHexStr(Buf[i]) ;    //���������� �� Buf �� ������ ����� ����������� count1 � ����������� � ���������
    s2 := s1;

dd:=s2[1] + s2[2]; //����
mm:=s2[3] + s2[4]; //�����
gg:=s2[5] + s2[6]; //���

if dd = 'FF' then dd:='01'   ;
if mm = 'FF' then mm:='01'   ;
if gg = 'FF' then gg:='00'   ;


ddd:=StrToInt(dd);
mmm:=StrToInt(mm);
ggg:=StrToInt('20' + gg);      //��� ��������� ��������

dddd:=ddd;
mmmm:=mmm;
gggg:=ggg;                 //��� ����� ���� �������������� ����� �� ������ � ��������� � � �����. :-)

//ReadDate1:=Date;
ReadDate1:= EncodeDate(gggg, mmmm, dddd);    //��������� � ���� TDateTime

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
    File1.Seek(adr1,soFromBeginning);  //  �������� �� ������ �����

File1.Read(Buf, 1); //����� ������ �����������

i := Buf[0] ;    //����������� � ���������� �����
s2:= IntToStr(i);   //��� �������

    File1.Free;
    File1:= nil;

Form1.Memo1.Text := Form1.Memo1.Text + #13#10 + s2;
Result:= i;
end;

{
������ ������� �����
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
    File1.Seek(adr1,soFromBeginning);  //  �������� �� ������ �����

File1.Read(Buf, 6); //

//for j:=0 to 5 do  if Buf[j]=255 then Buf[j]:=0; //�������� �� FF � ����������� ����


i := Buf[0] + Buf[1]*256 + Buf[2]*256*256 + Buf[3]*256*256*256 + Buf[4]*256*256*256*256 + Buf[5]*256*256*256*256*256;    //����������� � ���������� �����
if i=281474976710655 then i:=0;

s2:= IntToStr(i);   //��� �������

    File1.Free;
    File1:= nil;

//Form1.Memo1.Text := Form1.Memo1.Text + #13#10 + s2;                               //���������������� !!!
Result:= i;
end;

{
������������ ���������� ������������ �� ��������� ���������  MyFP
 =============================================================================}
function Func_Calc_KolFisk(a : integer ): integer;
var
 i: integer;
begin
 i:=0;
  while ((MyFP.Fiskaliz[i+1].RegistrNomerFis <> 'FFFFFFFF')  or (i = 4)) do  i:=i+1;      //�������� �� FF   "������"

  Form1.Memo1.Text := Form1.Memo1.Text + #13#10 + IntToStr(i);   //��� �������
  Result:= i;
end;

{
������������ ���������� ����������� �� ��������� ���������  MyFP
 =============================================================================}
function Func_Calc_KolAktEKLZ(a : integer ): integer;
var
 i: integer;
begin
 i:=0;
  while ((MyFP.AktivEklz[i+1].RegistrNomerEklz <> 'FFFFFFFFFF') or (i = 19)) do  i:=i+1;      //�������� �� FF   "������"

  Form1.Memo1.Text := Form1.Memo1.Text + #13#10 + IntToStr(i);   //��� �������
  Result:= i;
end;

{
������������ ���������� ������� ������� �� ��������� ���������  MyFP
 =============================================================================}
function Func_Calc_KolSmOtchet(a : integer ): integer;
var
 i: integer;
begin
 i:=0;
  while ((MyFP.SmOtchet[i+1].NomerSmenyOt <> 65535) or (i = 2468)) do  i:=i+1;      //�������� �� FF   "������"


  Form1.Memo1.Text := Form1.Memo1.Text + #13#10 + IntToStr(i);   //��� �������
  Result:= i;
end;

{
������������ ����� ������� ������� �� ��������� ���������  MyFP
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

//  Form1.Memo1.Text :=  Form1.Memo1.Text + #13#10 + IntToStr(i)+'-' + IntToStr(MyFP.SmOtchet[i].SummaSmeny)+' - ' + IntToStr(S);   //��� �������
end;

 Form1.Memo1.Text :=  Form1.Memo1.Text + #13#10 +  IntToStr(S);   //��� �������
  Result:= S;
end;



{
������������ ����� ������� ������� � ��������� ������� �� ���������  MyFP
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


if Nom1 <> 0 then     //��������� ������� ��������� ������� ���������� ������� !!!//�� �����������!!!
if Nom1 <= Nom2 then
 begin
      for i:=Nom1 to Nom2  do
         begin
         Sum:= Sum + MyFP.SmOtchet[i].SummaSmeny      ;
           //  Form1.Memo1.Text :=  Form1.Memo1.Text + #13#10 + IntToStr(i)+'-' + IntToStr(MyFP.SmOtchet[i].SummaSmeny)+' - ' + IntToStr(S);   //��� �������
         inc(Nzap);

         end;
  end;
;
Form1.Memo1.Text :=  Form1.Memo1.Text + #13#10 +  IntToStr(Sum);   //��� �������
Result:= Sum;
end;



{
������������ ����� ������� ������� � ��������� ���. �� ���������  MyFP
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
                   //  Form1.Memo1.Text :=  Form1.Memo1.Text + #13#10 + IntToStr(i)+'-' + IntToStr(MyFP.SmOtchet[i].SummaSmeny)+' - ' + IntToStr(S);   //��� �������
                    inc(Nzap);
                    end
             end;


//             Form1.Memo1.Text :=  Form1.Memo1.Text + #13#10 +  IntToStr(Nzap)+'-'+  IntToStr(Sum)+ #13#10;   //��� �������
Result:= Sum;
end;



{
��� ������� ������ �� ����� ������ ������ � �������
 =============================================================================}
function Rep_F_Date_Smen(Date1, Date2 : TDateTime ): string;
var
 i: integer;
s: string ;

begin
 Nzap:=0;
 //MyFP.KolSmOtchet;

 for i:=1 to MyFP.KolSmOtchet do
             begin
              if ((MyFP.SmOtchet[i].DataSmeny >= Date1) and (MyFP.SmOtchet[i].DataSmeny <= Date2))
                then
                    begin
                     s:= s +  Date8Tostr6(MyFP.SmOtchet[i].DataSmeny,'.') + '  '+ InToStrSp(MyFP.SmOtchet[i].NomerSmenyOt)+ #13#10 ; //     ;
                     s:= s +  InToStrS_Ref(MyFP.SmOtchet[i].SummaSmeny, 16, ' ') + #13#10;
                   //  Form1.Memo1.Text :=  Form1.Memo1.Text + #13#10 + IntToStr(i)+'-' + IntToStr(MyFP.SmOtchet[i].SummaSmeny)+' - ' + IntToStr(S);   //��� �������
                    inc(Nzap);
                    end
             end;


//             Form1.Memo1.Text :=  Form1.Memo1.Text + #13#10 +  IntToStr(Nzap)+'-'+  IntToStr(Sum)+ #13#10;   //��� �������
Result:= s;
end;




{
����������� ����������(���������) ����� ���� �� ��������� ���������  MyFP
 =============================================================================}
function Func_Calc_EklzNom(a : integer ): string;
var
 s: string;
begin

if MyFP.Fiskaliz[MyFP.KolFiskaliz].NomerSmenyFis > MyFP.AktivEklz[MyFP.KolAktivEklz].NomerSmenyEklz
  then s:=MyFP.Fiskaliz[MyFP.KolFiskaliz].RegistrNomerEklz
  else s:=MyFP.AktivEklz[MyFP.KolAktivEklz].RegistrNomerEklz;

 Form1.Memo1.Text :=  Form1.Memo1.Text + #13#10 +  s;   //��� �������
 Result:= s;
end;

{
����������� ���� ����������� ����������-���������-������������ ���� �� ��������� ���������  MyFP
 =============================================================================}
function Func_Calc_EklzData(a : integer ): TDateTime;
var
 s: TDateTime;
begin

if MyFP.Fiskaliz[MyFP.KolFiskaliz].NomerSmenyFis > MyFP.AktivEklz[MyFP.KolAktivEklz].NomerSmenyEklz
  then s:=MyFP.Fiskaliz[MyFP.KolFiskaliz].DataFis
  else s:=MyFP.AktivEklz[MyFP.KolAktivEklz].DataEklz;

// Form1.Memo1.Text :=  Form1.Memo1.Text + #13#10 +'���� ���� = '+  Date8Tostr6(s,'.');   //��� �������
 Result:= s;
end;


{ //�� ���������� !!! ������� ����� �� �������
 ������ ������ ����� ������ �������� ��� ���.������ �� �����.// �� ��������� ���������  MyFP
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



 Form1.Memo1.Text :=  Form1.Memo1.Text + #13#10 +  IntToStr(i);   //��� �������
 Result:= i;
end;


{
�������� ���������  MyFP
 =============================================================================}
function InitMyFP(a : integer ): integer;
var
 i: integer;

begin
//1.
MyFp.ZavNom := '';

//2.
for i:=1 to 5 do      //����� ��������� ������������
 begin
 MyFP.Fiskaliz[i].RegistrNomerFis := 'FFFFFFFF';
 MyFP.Fiskaliz[i].INN := 'FFFFFFFFFFFF';
 MyFP.Fiskaliz[i].DataFis:=0;    //
 MyFP.Fiskaliz[i].NomerSmenyFis:=0;
 MyFP.Fiskaliz[i].RegistrNomerEklz := 'FFFFFFFFFF';
 end;

//3.
for i:=1 to 20 do    //����� �������� ����������� ����
 begin
 MyFP.AktivEklz[i].NonerFiskaliz:=0 ;
 MyFP.AktivEklz[i].RegistrNomerEklz:='FFFFFFFFFF' ;
 MyFP.AktivEklz[i].DataEklz:=0 ;
 MyFP.AktivEklz[i].NomerSmenyEklz:=0  ;
 end;

//4.
for i:=1 to 2469 do    //������� ������ �� 1 �� 2469 ��
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
 !!! ������ ��������� ��������� MyFP !!!
=============================================================================}
procedure TForm1.Button1Click(Sender: TObject);
var
i: integer;
 begin
Form1.OpenDialog1.Filter:='����� �������� ����� 100� (*.bin)|*.bin|��� ����� (*.*)|*.*';
Form1.OpenDialog1.Title:='������������ ����� �� ����� : ...';
Form1.OpenDialog1.DefaultExt:='bin';
Form1.OpenDialog1.HistoryList.Clear;

 if Form1.OpenDialog1.Execute then
   begin
//0.
InitMyFP(1);

//1.
MyFp.ZavNom := Func_Read_ZavNomer('������ ��� �����'); //��������

//2.
Form1.Memo1.Text := Form1.Memo1.Text + #13#10 + '������������ :'+ #13#10 ;
for i:=1 to 5 do      //����� ��������� ������������
 begin
 MyFP.Fiskaliz[i].RegistrNomerFis := Func_Read_Stroki((27*i-27),4);
 MyFP.Fiskaliz[i].INN := Func_Read_Stroki((27*i-27)+7,6);
 MyFP.Fiskaliz[i].DataFis:=Func_Read_Data((27*i-27)+13);    //
 MyFP.Fiskaliz[i].NomerSmenyFis:=Func_Read_NomeraSmeny((27*i-27)+16) ;
 MyFP.Fiskaliz[i].RegistrNomerEklz := Func_Read_Stroki((27*i-27)+18,5);
 end;

//3.
Form1.Memo1.Text := Form1.Memo1.Text + #13#10 + '����������� ���� :'+ #13#10 ;
for i:=1 to 20 do    //����� �������� ����������� ����
 begin
 MyFP.AktivEklz[i].NonerFiskaliz:=Func_Read_AktNomeraFisk(32267+(13*i-13))  ;
 MyFP.AktivEklz[i].RegistrNomerEklz:=Func_Read_Stroki(32267+(13*i-13)+1,5) ;
 MyFP.AktivEklz[i].DataEklz:=Func_Read_Data(32267+(13*i-13)+6) ;
 MyFP.AktivEklz[i].NomerSmenyEklz:=Func_Read_NomeraSmeny(32267+(13*i-13)+9)   ;
 end;

//4.
Form1.Memo1.Text := Form1.Memo1.Text + #13#10 + 'Z ������ :'+ #13#10 ;
for i:=1 to 2469 do    //������� ������ �� 1 �� 2469 ��
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

//10.
MyFP.DataEklz:= Func_Calc_EklzData(1) ;

   end;

PrintFPToRich(1);
end;

{
################################################################################
################################################################################
################################################################################

               ^|^|^           ��������� MyFP.            ^|^|^
===============================================================================}


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
 InitMyDateKvart(1);

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
��������� ������.
}


{
X-�����.  /��������� X-����� ��� ������ ���������� ��������� MyFP
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
s:=s + '    �����' + #13#10 ;
s:=s + '   �������' + #13#10 + #13#10 ;
s:=s + '��� �����������' + #13#10 ;
s:=s + '  ����� ����' + #13#10 + #13#10 ;
s:=s + '�������. ����' + #13#10 ;
s:=s + InToStrS(MyFP.SummaNI) + #13#10 ;             //�������� ��
s:=s + '�� _         ' + IntToStr(Ndok) + #13#10;    //�������� ����� ���������

inc(Ndok);

s:=s + Time8ToStr6(Form1.DateTimePicker2.Time)   ;    //�������� �������

s:=s + '   ' + Date8ToStr6(Form1.DateTimePicker1.Date, '.')+ #13#10 ; //������� �������� �� ����
s:=s + '����� _' + MyFP.ZavNom + #13#10 ;
s:=s + '��� ' + MyFP.Fiskaliz[MyFP.KolFiskaliz].INN + #13#10 ;
s:=s + '���� ' + MyFP.EklzNom + #13#10 ;
s:=s + ' <��� ' + MyFP.Fiskaliz[MyFP.KolFiskaliz].RegistrNomerFis +'>' + #13#10 ;
s:=s + '\\\\\\\\\\\\\\\\' + #13#10 ;
s:=s + #13#10 + #13#10 + #13#10;

//  Result:= '';
  Result:= s;
end;

{
F-�����. ��������������� ������� .��� ������������ - ����������� �� ���������� ��������� MyFP
 =============================================================================}
function Rep_F(a : integer ): string;
var
 i, j: integer;
 s: string;
begin

for i:= 1 to MyFP.KolFiskaliz do
begin
 //��������� ������������
 if i=1 then s:=s + '  ������������' + #13#10 else  s:=s + ' ���������������' + #13#10  ;
 s:=s + '�._     ' + MyFP.Fiskaliz[i].RegistrNomerFis + #13#10  ;
 s:=s + '��� ' + MyFP.Fiskaliz[i].INN + #13#10  ;
 s:=s + '����   ' + Date8ToStr6(MyFP.Fiskaliz[i].DataFis, '.') + '.'+ #13#10 ;
 s:=s + '_ ���.����� ' +  InToStrT(MyFP.Fiskaliz[i].NomerSmenyFis) + #13#10 + #13#10  ;
 //��������� ����������� ������� ��������� � �������������
      s:=s + '����������� ����' + #13#10 ;
      s:=s + '���� ' + MyFP.Fiskaliz[i].RegistrNomerEklz + #13#10 ;
      s:=s + '����   ' + Date8ToStr6( MyFP.Fiskaliz[i].DataFis, '.') + '.' + #13#10 ;
      s:=s + '_ ���.����� ' + InToStrT(MyFP.Fiskaliz[i].NomerSmenyFis) + #13#10 + #13#10 ;

 for j:= 1 to MyFP.KolAktivEklz do
    if MyFP.AktivEklz[j].NonerFiskaliz = (i-1) then
      begin
   //��������� �����������
      s:=s + '����������� ����' + #13#10 ;
      s:=s + '���� ' + MyFP.AktivEklz[j].RegistrNomerEklz + #13#10 ;
      s:=s + '����   ' + Date8ToStr6(MyFP.AktivEklz[j].DataEklz, '.') + '.' + #13#10 ;
      s:=s + '_ ���.����� ' + InToStrT(MyFP.AktivEklz[j].NomerSmenyEklz) + #13#10 + #13#10 ;
      end

end ; //��������� ������������ - �����������

  Result:= s;
end;


{
F-�����.  /��������� ����������  �����  �� ������� ��� ������ ���������� ��������� MyFP
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
s:=s + '!' + '    �����' + #13#10 ;
s:=s + '!' + '   ����������' + #13#10 + #13#10 ;
s:=s + '  �  '  + InToStrT(N1) + #13#10 ;
s:=s + '  �� ' + InToStrT(N2) + #13#10 + #13#10 ;
s:=s + '!����������� ���' + #13#10 ;
s:=s + '\\\\\\\\\\\\\\\\' + #13#10 ;

s:=s + Rep_F(1) ;

s:=s + '���.���������� ' + IntToStr(5 - MyFP.KolFiskaliz ) + #13#10 + #13#10 ;
s:=s + '���.�������.  ' + IntToStr(20 - MyFP.KolAktivEklz ) + #13#10 + #13#10;
s:=s + '\\\\\\\\\\\\\\\\' + #13#10 ;
Func_Calc_SummaNom(1, 2500); //�������!!! ������ ��������� ����������� � �������
s:=s + '���.      '  + InToStrSp(Nzap) + #13#10 ;

s:=s + '!����'  + InToStrS_Ref(Func_Calc_SummaNom(1, 2500),12,' ') + #13#10 + #13#10 ;


s:=s + '�� _         ' + IntToStr(Ndok) + #13#10;    //�������� ����� ���������

inc(Ndok);
s:=s + Time8ToStr6(Form1.DateTimePicker2.Time)  ;    //�������� �������

s:=s + '   ' + Date8ToStr6(Form1.DateTimePicker1.Date, '.') + #13#10 ; //������� �������� �� ����
s:=s + '����� _' + MyFP.ZavNom + #13#10 ;
s:=s + '��� ' + MyFP.Fiskaliz[MyFP.KolFiskaliz].INN + #13#10 ;
//s:=s + '���� ' + MyFP.EklzNom + #13#10 ;
s:=s + ' <��� ' + MyFP.Fiskaliz[MyFP.KolFiskaliz].RegistrNomerFis +'>' + #13#10 ;
s:=s + '\\\\\\\\\\\\\\\\' + #13#10 ;
s:=s + #13#10 + #13#10 + #13#10;

  Result:= s;
end;


{
F-�����.  /��������� ����������  �����  �� ����� ��� ������ ���������� ��������� MyFP
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
s:=s + '!' + '    �����' + #13#10 ;
s:=s + '!' + '   ����������' + #13#10 + #13#10 ;
s:=s + '   �  '  + Date8ToStr6(DAT1, '.') + #13#10 ;
s:=s + '   �� ' + Date8ToStr6(DAT2, '.') + #13#10 + #13#10 ;
s:=s + '!����������� ���' + #13#10 ;
s:=s + '\\\\\\\\\\\\\\\\' + #13#10 ;

s:=s + Rep_F(1) ;

s:=s + '���.���������� ' + IntToStr(5 - MyFP.KolFiskaliz ) + #13#10 + #13#10 ;
s:=s + '���.�������.  ' + IntToStr(20 - MyFP.KolAktivEklz ) + #13#10 + #13#10;
s:=s + '\\\\\\\\\\\\\\\\' + #13#10 ;

Func_Calc_SummaDate(DAT1, DAT2); //�������!!! ������ ��������� ����������� � �������

s:=s + '���.      '  + InToStrSp(Nzap) + #13#10 ;
s:=s + '!����'  + InToStrS_Ref(Func_Calc_SummaDate(DAT1, DAT2),12,' ') + #13#10 + #13#10 ;
s:=s + '�� _         ' + IntToStr(Ndok) + #13#10;    //�������� ����� ���������

inc(Ndok);
s:=s + Time8ToStr6(Form1.DateTimePicker2.Time)  ;    //�������� �������

s:=s + '   ' + Date8ToStr6(Form1.DateTimePicker1.Date, '.') + #13#10 ; //������� �������� �� ����
s:=s + '����� _' + MyFP.ZavNom + #13#10 ;
s:=s + '��� ' + MyFP.Fiskaliz[MyFP.KolFiskaliz].INN + #13#10 ;
//s:=s + '���� ' + MyFP.EklzNom + #13#10 ;
s:=s + ' <��� ' + MyFP.Fiskaliz[MyFP.KolFiskaliz].RegistrNomerFis +'>' + #13#10 ;
s:=s + '\\\\\\\\\\\\\\\\' + #13#10 ;
s:=s + #13#10 + #13#10 + #13#10;

  Result:= s;
end;


{
F-������ ����������� � 2013 �� 2017.  /��������� ����������  ������  �� ����� ��� ������ ���������� ��������� MyFP
 =============================================================================}
function Rep_F_Date_Kvart(DAT1, DAT2 : TDateTime ): string;
var
 i: integer;
 DAT1_T, DAT2_T : TDateTime;
 s: string;
begin
 DAT1_T := 0 ;
 DAT2_T := 0 ;

for i:=1 to 20  do
   begin
  {1} if not((MyDateKvart.datN[i].d < DAT1)and (MyDateKvart.datO[i].d < DAT1) or (MyDateKvart.datN[i].d > DAT2 ) and (MyDateKvart.datO[i].d > DAT2 )) //�������� ������ �� �������� � ������� ������� �������� for
        then
            begin
              if (MyDateKvart.datN[i].d <= DAT1) and (MyDateKvart.datO[i].d >= DAT1) and (MyDateKvart.datN[i].d < DAT2 ) and (MyDateKvart.datO[i].d < DAT2 )//   ������ �������� ����� ������
                then
                  begin
                   DAT1_T:=DAT1 ;
                   DAT2_T:=MyDateKvart.datO[i].d ;
                  end;
              if (MyDateKvart.datN[i].d <= DAT1) and (MyDateKvart.datO[i].d >= DAT1) and (MyDateKvart.datN[i].d <= DAT2 ) and (MyDateKvart.datO[i].d >= DAT2 )  //������ �������� ��� ����
                then
                  begin
                   DAT1_T:=DAT1 ;
                   DAT2_T:=DAT2 ;
                  end;

              if (MyDateKvart.datN[i].d > DAT1) and (MyDateKvart.datO[i].d > DAT1) and (MyDateKvart.datN[i].d < DAT2 ) and (MyDateKvart.datO[i].d < DAT2 ) //������� ������ ��������� �������
                then
                  begin
                   DAT1_T:=MyDateKvart.datN[i].d ;
                   DAT2_T:=MyDateKvart.datO[i].d ;
                  end;

              if (MyDateKvart.datN[i].d > DAT1) and (MyDateKvart.datO[i].d > DAT1) and (MyDateKvart.datN[i].d <= DAT2 ) and (MyDateKvart.datO[i].d >= DAT2 ) //������� ������ ��������� �������
                then
                  begin
                   DAT1_T:=MyDateKvart.datN[i].d ;
                   DAT2_T:=DAT2 ;
                  end;

//  s:=s +  #13#10 + IntToStr(i)+ '  '+ Date8ToStr6(DAT1_T, '.')+ '-' + Date8ToStr6(DAT2_T, '.')  + #13#10 ;
  s:=s +  Rep_F_Date_Kr(DAT1_T, DAT2_T)  + #13#10 + #13#10;

  {1} end;  //����� for

end;

Result :=s;
end;


{
F-�����.  /��������� ����������  �����  �� �����  ������ ��� ������ ���������� ��������� MyFP
 =============================================================================}
function Rep_F_Date_Poln(DAT1, DAT2 : TDateTime ): string;
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
s:=s + '!' + '    �����' + #13#10 ;
s:=s + '!' + '   ����������' + #13#10 + #13#10 ;
s:=s + '   �  '  + Date8ToStr6(DAT1, '.') + #13#10 ;
s:=s + '   �� ' + Date8ToStr6(DAT2, '.') + #13#10 + #13#10 ;
s:=s + '!����������� ���' + #13#10 ;
s:=s + '\\\\\\\\\\\\\\\\' + #13#10 ;
s:=s + Rep_F(1) ;
s:=s + '���.���������� ' + IntToStr(5 - MyFP.KolFiskaliz ) + #13#10 + #13#10 ;
s:=s + '���.�������.  ' + IntToStr(20 - MyFP.KolAktivEklz ) + #13#10 + #13#10;
s:=s + '!����   _ ��. ��'  + #13#10;
s:=s + '!\\\\\\\\\\\\\\\\' + #13#10 ;
s:=s + Rep_F_Date_Smen(DAT1, DAT2) + #13#10;
//Func_Calc_SummaDate(DAT1, DAT2); //�������!!! ������ ��������� ����������� � �������.// ��� ���������
s:=s + '���.      '  + InToStrSp(Nzap) + #13#10 ;
s:=s + '!����'  + InToStrS_Ref(Func_Calc_SummaDate(DAT1, DAT2),12,' ') + #13#10 + #13#10 ;
//
s:=s + '�� _         ' + IntToStr(Ndok) + #13#10;    //�������� ����� ���������
inc(Ndok);
s:=s + Time8ToStr6(Form1.DateTimePicker2.Time)  ;    //�������� �������
s:=s + '   ' + Date8ToStr6(Form1.DateTimePicker1.Date, '.') + #13#10 ; //������� �������� �� ����
s:=s + '����� _' + MyFP.ZavNom + #13#10 ;
s:=s + '��� ' + MyFP.Fiskaliz[MyFP.KolFiskaliz].INN + #13#10 ;
//s:=s + '���� ' + MyFP.EklzNom + #13#10 ;
s:=s + ' <��� ' + MyFP.Fiskaliz[MyFP.KolFiskaliz].RegistrNomerFis +'>' + #13#10 ;
s:=s + '\\\\\\\\\\\\\\\\' + #13#10 ;
s:=s + #13#10 + #13#10 + #13#10;
  Result:= s;
end;



{
EKLZ-�����.  /��������� ����������  �����  �� ����� ��� ������ ���������� ��������� MyFP
 =============================================================================}
function Rep_EKL_Date_Kr(DAT1, DAT2 : TDateTime ): string;
var
// i, j: integer;
 s: string;
begin

s:='';
s:=s + #13#10 + #13#10;
s:=s + '   �����-100�   ' + #13#10 ;
s:=s + '���      ' + MyFP.ZavNom + #13#10 ;
s:=s + '��� '  + MyFP.Fiskaliz[MyFP.KolFiskaliz].INN + #13#10 ;
s:=s + '���� ' + MyFP.EklzNom +' '+ #13#10 ;
s:=s + '����� �������   ' + #13#10 ;
s:=s + '����:  ' + Date8ToStr6(DAT1,'/') + '-' + #13#10 ;
s:=s + '       ' + Date8ToStr6(DAT2,'/') + ' ' + #13#10 ;
s:=s + '����� �� ������ ' + #13#10;
s:=s + '�������         ' + #13#10;
s:=s + InToStrS_Ref(Func_Calc_SummaDate(DAT1, DAT2),16,' ') + #13#10 ;
s:=s + '�������         ' + #13#10 ;
s:=s + '           *0.00' + #13#10 ;
s:=s + '�����. �������' + #13#10 ;
s:=s + '           *0.00' + #13#10 ;
s:=s + '�����. �������' + #13#10 ;
s:=s + '           *0.00' + #13#10 ;
s:=s + '\\\\\\\\\\\\\\\\' + #13#10;

  Result:= s;
end;



{
EKLZ-������ ����������� � 2013 �� 2017.  /��������� ������ ���� �� ��������� ��� ������ ���������� ��������� MyFP
 =============================================================================}
function Rep_EKL_Date_Kvart(DAT1, DAT2 : TDateTime ): string;
var
 i: integer;
 DAT1_T, DAT2_T : TDateTime;
 s: string;
begin
 DAT1_T := 0 ;
 DAT2_T := 0 ;
for i:=1 to 20  do
   begin
  {1} if not((MyDateKvart.datN[i].d < DAT1)and (MyDateKvart.datO[i].d < DAT1) or (MyDateKvart.datN[i].d > DAT2 ) and (MyDateKvart.datO[i].d > DAT2 )) //�������� ������ �� �������� � ������� ������� �������� for
        then
            begin
              if (MyDateKvart.datN[i].d <= DAT1) and (MyDateKvart.datO[i].d >= DAT1) and (MyDateKvart.datN[i].d < DAT2 ) and (MyDateKvart.datO[i].d < DAT2 )//   ������ �������� ����� ������
                then
                  begin
                   DAT1_T:=DAT1 ;
                   DAT2_T:=MyDateKvart.datO[i].d ;
                  end;
              if (MyDateKvart.datN[i].d <= DAT1) and (MyDateKvart.datO[i].d >= DAT1) and (MyDateKvart.datN[i].d <= DAT2 ) and (MyDateKvart.datO[i].d >= DAT2 )  //������ �������� ��� ����
                then
                  begin
                   DAT1_T:=DAT1 ;
                   DAT2_T:=DAT2 ;
                  end;

              if (MyDateKvart.datN[i].d > DAT1) and (MyDateKvart.datO[i].d > DAT1) and (MyDateKvart.datN[i].d < DAT2 ) and (MyDateKvart.datO[i].d < DAT2 ) //������� ������ ��������� �������
                then
                  begin
                   DAT1_T:=MyDateKvart.datN[i].d ;
                   DAT2_T:=MyDateKvart.datO[i].d ;
                  end;

              if (MyDateKvart.datN[i].d > DAT1) and (MyDateKvart.datO[i].d > DAT1) and (MyDateKvart.datN[i].d <= DAT2 ) and (MyDateKvart.datO[i].d >= DAT2 ) //������� ������ ��������� �������
                then
                  begin
                   DAT1_T:=MyDateKvart.datN[i].d ;
                   DAT2_T:=DAT2 ;
                  end;

//  s:=s +  #13#10 + IntToStr(i)+ '  '+ Date8ToStr6(DAT1_T, '.')+ '-' + Date8ToStr6(DAT2_T, '.')  + #13#10 ;
  s:=s +  Rep_EKL_Date_Kr(DAT1_T, DAT2_T)  + #13#10 + #13#10;

  {1} end;  //����� for

end;

Result :=s;
end;



{
F-�����. ��������������� ������� .��� ������������ - ����������� �� ���������� ��������� MyFP
 =============================================================================}
function Rep_Zakr_EKL(a : integer ): string;
var
 s: string;
begin
 s:='';
 s:=s + #13#10 + #13#10 + #13#10 ;
 s:=s + '  ����� ����    ' + #13#10  ;
 s:=s + '    ������      ' + #13#10 + #13#10 + #13#10  ;
  Result:= s;
end;



{������ "������� ����� ������"}
procedure TForm1.Button2Click(Sender: TObject);
begin
 ;;
Form1.Memo2.Text:='';
Form1.Memo2.Text:=Form1.Memo2.Text + Rep_X(1);                 // �������� X-�����
Form1.Memo2.Text:=Form1.Memo2.Text + Rep_F_Nom_Kr(1, 2500);   // �������� ���-����� �������� ����
if MyFP.KolFiskaliz > 1 then Form1.Memo2.Text:=Form1.Memo2.Text + Rep_F_Date_Kr(MyFP.Fiskaliz[MyFp.KolFiskaliz].DataFis, DateTimePicker2.Date);   // �������� ���-����� �������� ���
Form1.Memo2.Text:=Form1.Memo2.Text + Rep_F_Date_Kr(DateTimePicker3.Date, DateTimePicker2.Date);   // �������� ���-����� �������� ���
Form1.Memo2.Text:=Form1.Memo2.Text + Rep_F_Date_Kvart(DateTimePicker3.Date, DateTimePicker1.Date);   //  �������� ���-����� ������������� � ��������� ���
Form1.Memo2.Text:=Form1.Memo2.Text + Rep_EKL_Date_Kr( MyFP.DataEklz, DateTimePicker1.Date);   //  �������� EKLZ-�����  ������� � ��������� ���
Form1.Memo2.Text:=Form1.Memo2.Text + Rep_EKL_Date_Kvart(MyFP.DataEklz, DateTimePicker1.Date);   //  �������� EKLZ-����� � ��������� ���
Form1.Memo2.Text:=Form1.Memo2.Text + Rep_Zakr_EKL(1);
Form1.Memo2.Text:=Form1.Memo2.Text + Rep_F_Date_Poln(DateTimePicker3.Date, DateTimePicker1.Date);   //  �������� ���-����� ������ � ��������� ���

 ;;
end;



procedure TForm1.TrackBar1Change(Sender: TObject);
begin
Form1.BitBtn4.Caption:='���. ������� ' + IntToStr(Form1.TrackBar1.Position);
end;


procedure TForm1.BitBtn4Click(Sender: TObject);
begin
try
 if Form1.ComPort1.Connected = false then Form1.ComPort1.Open    ; // ��������� ��� ����

Buf_Out[0]:= $66;
Buf_Out[1]:= Form1.TrackBar1.Position - 1;

 WriteBuf(Buf_Out, 2);


 if Form1.ComPort1.Connected = true then Form1.ComPort1.Close    ; // ��������� ��� ����
finally
end;
end;

procedure TForm1.BitBtn5Click(Sender: TObject);
begin
try
 if Form1.ComPort1.Connected = false then Form1.ComPort1.Open    ; // ��������� ��� ����
Buf_Out[0]:= $77;
WriteBuf(Buf_Out, 1);
 if Form1.ComPort1.Connected = true then Form1.ComPort1.Close    ; // ��������� ��� ����
finally
end;
end;


{������ ����}
procedure TForm1.Button4Click(Sender: TObject);
var
i, count : integer;
begin


try
 if Form1.ComPort1.Connected = false then Form1.ComPort1.Open    ; // ��������� ��� ����

for i:=0 to 9 do
begin

Buf_Out[0]:= $99;
Buf_Out[1]:= $33;
Buf_Out[2]:= i + $30;
Buf_Out[3]:= $61;
Buf_Out[4]:= $61;
Buf_Out[5]:= $41;
Buf_Out[6]:= $41;
Buf_Out[7]:= $41;
Buf_Out[8]:= $41;
Buf_Out[9]:= $61;
Buf_Out[10]:= $61;
Buf_Out[11]:= $20;
Buf_Out[12]:= $20;
Buf_Out[13]:= $20;
Buf_Out[14]:= $31;
Buf_Out[15]:= $32;
Buf_Out[16]:= $33;
Buf_Out[17]:= $34;

count := 18   ;


WriteBuf(Buf_Out, count);

  sleep(150 + (TrackBar1.Position * 10));
end;

 if Form1.ComPort1.Connected = true then Form1.ComPort1.Close    ; // ��������� ��� ����
finally
end;
end;

{
//SimpleString := AnsiLowerCase('The Cat Sat On The MAT');  � ������� ��������
procedure TForm1.Button6Click(Sender: TObject);
var
str_temp: string;
i: integer;
begin

str_temp:='!����������������';
//Print_Op_100(str_temp);

for i:=0 to Memo2.lines.count - 1 do Print_Op_100(Memo2.Lines[i]);



end;

 ������ ������ (������ ������� � ��������� �����)
procedure TForm1.Button7Click(Sender: TObject);
var
 str_temp: string;
 i: integer;
begin
 try

   Form1.ComPort1.Open;
   if Form1.ComPort1.Connected then
    begin
      str_temp:='!����������������';
      //Print_Op_100(str_temp);
      for i:=0 to Memo2.lines.count - 1 do
         begin
          Print_Op_100_mod(Memo2.Lines[i]);
          Sleep(150) ;
         end;
    end;

    Form1.ComPort1.Close;

 finally end;
end;
}


procedure TForm1.BitBtn1Click(Sender: TObject);
var
 MyThread: TMyThread;
begin
 MyThread:=TMyThread.Create(False);
 //http://www.bdrc.ru/publ/2-1-0-36


end;

end.



