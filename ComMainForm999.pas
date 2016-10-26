unit ComMainForm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ExtCtrls, CPort, CPortCtl, ComCtrls, Buttons, DB,
     ADODB, DBCtrls, Mask, DateUtils, Menus ;

type
  TForm1 = class(TForm)
    ComPort: TComPort;
    Memo: TMemo;
    Button_Settings: TButton;
    Label5: TLabel;
    OpenDialog1: TOpenDialog;
    SaveDialog1: TSaveDialog;
    Button3: TButton;
    Button4: TButton;
    Button12: TButton;
    TrackBar1: TTrackBar;
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    BitBtn3: TBitBtn;
    TrackBar2: TTrackBar;
    Edit1: TEdit;
    Label1: TLabel;
    Edit2: TEdit;
    Label2: TLabel;
    Edit3: TEdit;
    Label3: TLabel;
    Edit4: TEdit;
    Label4: TLabel;
    Button1: TButton;
    Button2: TButton;
    Button5: TButton;
    Edit5: TEdit;
    Label6: TLabel;
    Edit6: TEdit;
    RadioGroup1: TRadioGroup;
    Edit7: TEdit;
    Label7: TLabel;
    RadioGroup2: TRadioGroup;
    Edit8: TEdit;
    Label8: TLabel;
    DateTimePicker1: TDateTimePicker;
    Edit9: TEdit;
    Edit10: TEdit;
    Button6: TButton;
    Button7: TButton;
    Button8: TButton;
    Timer1: TTimer;
    Button9: TButton;
    MaskEdit1: TMaskEdit;
    Label9: TLabel;
    MaskEdit2: TMaskEdit;
    Label10: TLabel;
    Edit11: TEdit;
    Label11: TLabel;
    Label12: TLabel;
    TrackBar3: TTrackBar;
    procedure Button_SettingsClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button12Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormPaint(Sender: TObject);
    procedure TrackBar1Change(Sender: TObject);
    procedure BitBtn1Click(Sender: TObject);
    procedure BitBtn2Click(Sender: TObject);
    procedure TrackBar2Change(Sender: TObject);
    procedure BitBtn3Click(Sender: TObject);
    procedure MemoChange(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Edit8Click(Sender: TObject);
    procedure Edit2Change(Sender: TObject);
    procedure Edit3Change(Sender: TObject);
    procedure Edit4Change(Sender: TObject);
    procedure Edit5Change(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button6Click(Sender: TObject);
    procedure Button7Click(Sender: TObject);
    procedure Button8Click(Sender: TObject);
    procedure Button9Click(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure Edit11Change(Sender: TObject);
    procedure TrackBar3Change(Sender: TObject);
    procedure HotKey1Change(Sender: TObject);

//    procedure Button1Click(Sender: TObject);

  private
    { Private declarations }
  public
    { Public declarations }
  end;

type
TBuf = array[0..1023] of Byte ;

    function InToStrS(i:integer):string; //Отделяем копейки от рублей
    function InToStrT(i:integer):string;//Добавляем точки в начало
    function NDS_Go(i:string):integer;  //Считаем Ндс включенный в цену
var
  Form1: TForm1;
  s,s_oem, s_temp , spr                 : string ;
  i1, i2, i3, i4, i5, i6, Flag : integer;   // контроль открытия файла
  FileHandle1, FileHandle2     : integer ;
  counter_kol, counter_kol_2   : integer ;
  File1, File2                 : TFileStream;
  Buf, Buf_Inp, Buf_Out, Buf_File : TBuf ;


  implementation
{$R *.DFM}


function AADD(S1: String ;L1 : Integer ): String;
var
i: integer;
s: String;
begin
For i:=1 to Length(S1) do

if ((i <= L1) and       //длина не больше L1
(((ord(S1[i])>47) and   //минимум "0"
((ord(S1[i])< 58)))))   //максимум "9"
then  s:=s + S1[i];

AADD:=s;
end;


function Rand(i:integer):integer;
var
j,k:integer;
hours, mins, secs, milliSecs : Word;

begin
Randomize ;
DecodeTime(now, hours, mins, secs, milliSecs);

if random(100)<50 then k:=-1 else k:=1   ;
RandSeed:= milliSecs;
j:=random(i)*k ;
Rand:=j;
end;

//============================================================================
//============================================================================
function Date_01(L1 : Integer ): String; //если 1 то "ДД/ММ/ГГ/" , 2 то "ДД.ММ.ГГ."
var
s: String;
begin
if L1 = 1 then
           begin
           s:=DateToStr(form1.DateTimePicker1.Date)[1] +
              DateToStr(form1.DateTimePicker1.Date)[2] + '/' +
              DateToStr(form1.DateTimePicker1.Date)[4] +
              DateToStr(form1.DateTimePicker1.Date)[5] + '/' +
              DateToStr(form1.DateTimePicker1.Date)[9] +
              DateToStr(form1.DateTimePicker1.Date)[10]

           end
           ;
if L1 = 2 then
           begin
           s:=DateToStr(form1.DateTimePicker1.Date)[1] +
              DateToStr(form1.DateTimePicker1.Date)[2] + '.' +
              DateToStr(form1.DateTimePicker1.Date)[4] +
              DateToStr(form1.DateTimePicker1.Date)[5] + '.' +
              DateToStr(form1.DateTimePicker1.Date)[9] +
              DateToStr(form1.DateTimePicker1.Date)[10]
           end
           ;



Date_01:=s;
end;
//============================================================================









procedure TForm1.Button_SettingsClick(Sender: TObject);
begin
  ComPort.ShowSetupDialog;
end;

{=============================================================================}
 function StrToOem(const AnsiStr: string): string;
begin
  SetLength(Result, Length(AnsiStr));
  if Length(Result) <> 0 then
    CharToOem(PChar(AnsiStr), PChar(Result));
end;

{=============================================================================}
procedure Print_2102(Spr: string );
var
i : integer ;
begin
Form1.ComPort.Open;
if Form1.ComPort.Connected then
  begin
   Buf[0]:= Form1.TrackBar1.Position and 255 ;
   Buf[1]:= Length(Spr);
   For i:= 0 to Length(Spr) do Buf[i + 2]:= Byte(Spr[i+1]);
   Form1.ComPort.Write(Buf,Length(Spr) + 2 );
  end;
Sleep(100);
Form1.ComPort.Close;
end;

{=============================================================================}


//кнопка About
procedure TForm1.Button3Click(Sender: TObject);
begin
ShowMessage('Программа ПРИНТ 2102 V 2.5_beta'+
#13#10+ 'Разработал :  Revers_M@mail.ru' +
#13#10+ 'Доводка ПО 2102 : ctokkm@bk.ru' +
#13#10+ '27.02.2006г.' +
#13#10+ '03.04.2007г.' +
#13#10+ '27.04.2007г.' +
#13#10+ '1102ф-1002100 - 1390299' +
#13#10+ '2102ф-1001200 - 1391799' +
#13#10+ '2102к-1045100 - 1488599' +
#13#10+ '      7004000 - 7091199' 

);
end;



//=+=КНОПКА ПЕЧАТИ
procedure TForm1.Button4Click(Sender: TObject);
//var
//i, y1, y2, y3 : integer;
begin
//i:=0, y1:=0; y2:=0; y3:=0; S_temp:='';

//while i < Form1.Memo.Lines.Count do
//begin
//  while y2 < 16 do
//   begin
//   s_temp := Form1.Memo.Lines[y3];

//   y2:=y2+1;
//   end;
//s_temp:='12345abcdef_абвгдеж_';

s_temp:=Form1.Memo.Text ;


If Length(s_temp) <= 255 then
  begin
   Spr:=StrToOem(s_temp);
//   ShowMessage(' Нажмите "ИТОГ" на экране ( - - - - - )');
if Spr = '' then Spr := #13#10 ;

   PRINT_2102(Spr);

  end
else ShowMessage('ЭТО Beta Версия уменьшите размер до 255 символов');

//i:= i+1 ;

//end;


//s:=Form1.Memo.Text;
//s_oem:=StrToOem(s);
//Form1.Label1.Caption:=s_oem;
//Form1.Label1.Caption:= Form1.Label1.Caption + '____' + IntToStr(Length(s_oem));



end;




//Кнопка Clear Memo
procedure TForm1.Button12Click(Sender: TObject);
begin
 Form1.Memo.Text:='';
end;



procedure TForm1.FormCreate(Sender: TObject);
begin
  Form1.Width := 315 ;
  ComPort.LoadSettings(stRegistry, 'HKEY_LOCAL_MACHINE\Software\Dejan');
  Form1.DateTimePicker1.Date:=Date;
  Form1.DateTimePicker1.Time:=Time;
  counter_kol :=0;
  counter_kol_2 :=0;

end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
 if ComPort.Connected then ComPort.Close ;
  ComPort.StoreSettings(stRegistry, 'HKEY_LOCAL_MACHINE\Software\Dejan');
end;

procedure TForm1.FormPaint(Sender: TObject);
var
   R1 : TRect;
   i  : Word;
   W  : Real;
 begin
   W:=Height/128;
   If W=0 then W:=1;
   for i:=1 to 128 do begin
     R1 := Rect(0,Height-Trunc((i-1)*W),Width,Height-Trunc(i*W));

     Canvas.Brush.Color := RGB(0,150,i*2);


//     Canvas.FillRect(R1);
   end;

end;
procedure TForm1.TrackBar1Change(Sender: TObject);
begin
Form1.Button4.Caption:='ПЕЧАТЬ  ' + IntToStr(Form1.TrackBar1.Position);
end;

procedure TForm1.BitBtn1Click(Sender: TObject);
begin
Form1.OpenDialog1.Filter:='Файлы чеков (*.che)|*.che|ВСЕ Файлы (*.*)|*.*';
Form1.OpenDialog1.Title:='Cозранить как ...';
Form1.OpenDialog1.DefaultExt:='che';
Form1.OpenDialog1.HistoryList.Clear;

if Form1.OpenDialog1.Execute then
   begin
    Form1.Memo.Lines.LoadFromFile(Form1.OpenDialog1.FileName);
   end;
end;

procedure TForm1.BitBtn2Click(Sender: TObject);
begin
Form1.SaveDialog1.Filter:='Файлы чеков (*.che)|*.che|ВСЕ Файлы (*.*)|*.*';
Form1.SaveDialog1.Title:='Сохранить пример  ...';
Form1.SaveDialog1.DefaultExt:='che';
Form1.SaveDialog1.HistoryList.Clear;

if Form1.SaveDialog1.Execute then
 begin
 Form1.Memo.Lines.SaveToFile(Form1.SaveDialog1.FileName);
 end;
end;
procedure TForm1.TrackBar2Change(Sender: TObject);
begin
Form1.BitBtn3.Caption:='Промотать ' + IntToStr(Form1.TrackBar2.Position + 1);
end;

procedure TForm1.BitBtn3Click(Sender: TObject);
var
i: integer;
begin
spr:='';
for i:=0 to Form1.TrackBar2.Position do
begin
spr:=spr +#13#10 ;
end;
//ShowMessage(' Нажмите "ИТОГ" на экране ( - - - - - )');
PRINT_2102(spr);
end;

procedure TForm1.MemoChange(Sender: TObject);
begin
//if Length(Form1.Memo.Text) > 250   then
//begin
//Form1.Memo.SelStart:=250;
////Form1.Memo.SelLength:= Length(Form1.Memo.Text);

//end;

end;
//=========== Формируем чеки начало =========================================
// 924-01


//= 889-02

procedure TForm1.Button2Click(Sender: TObject);
begin
if Form1.RadioGroup2.ItemIndex = 0 then
  begin
  Form1.Memo.Text:= Form1.Memo.Text + #13#10+ #13#10+ #13#10+ #13#10 ;

  Form1.Memo.Text:= Form1.Memo.Text + Form1.Edit10.Text + #13#10  ;
  Form1.Memo.Text:= Form1.Memo.Text + Form1.Edit9.Text + #13#10  ;
  Form1.Memo.Text:= Form1.Memo.Text + Form1.Edit6.Text + #13#10  ;
  Form1.Memo.Text:= Form1.Memo.Text + Form1.Edit1.Text  + #13#10 ;
  Form1.Memo.Text:= Form1.Memo.Text + date_01(2)  + #13#10 ;
  Form1.Memo.Text:= Form1.Memo.Text + 'ОП.0 К.N ' + Form1.Edit2.Text + #13#10 ;
  Form1.Memo.Text:= Form1.Memo.Text + 'ИНН ' + Form1.Edit3.Text + #13#10 ;
  Form1.Memo.Text:= Form1.Memo.Text + '1СК ' + InToStrS(StrToInt(Form1.Edit5.Text)) + #13#10 ;
  if Form1.RadioGroup1.ItemIndex = 1 then
  begin
   Form1.Memo.Text:= Form1.Memo.Text + 'НДС ......18.00%'+ #13#10 ;
   Form1.Memo.Text:= Form1.Memo.Text + 'В.Н.'+ InToStrS(NDS_Go(Form1.Edit5.Text)) + #13#10 ;
  end;
  Form1.Memo.Text:= Form1.Memo.Text + '................'  + #13#10 ;
  Form1.Memo.Text:= Form1.Memo.Text + 'ИТОГ'+ InToStrS(StrToInt(Form1.Edit5.Text)) + #13#10 ;
  Form1.Memo.Text:= Form1.Memo.Text + IntToStr(13 + Rand(3)) +':'
  + IntToStr(30+ Rand(19)) +'Ф ЧЕК'+ IntToStr(7 + Rand(7))+ #13#10 ;

  Form1.Memo.Text:= Form1.Memo.Text + Form1.Edit7.Text + #13#10 ;
  end
else
  begin    // ОТЧЕТ С ГАШЕНИЕМ
  Form1.Memo.Text:= Form1.Memo.Text + #13#10+ #13#10 ;
  Form1.Memo.Text:= Form1.Memo.Text + Form1.Edit6.Text + #13#10  ;
  Form1.Memo.Text:= Form1.Memo.Text + Form1.Edit1.Text  + #13#10 ;     // заголовок
  Form1.Memo.Text:= Form1.Memo.Text + date_01(2)  + #13#10 ;
  Form1.Memo.Text:= Form1.Memo.Text + ' К.N ' + Form1.Edit2.Text + #13#10 ;
  Form1.Memo.Text:= Form1.Memo.Text + 'ИНН ' + Form1.Edit3.Text + #13#10 ;

//  Form1.Memo.Text:= Form1.Memo.Text + '1СК ' + InToStrS(StrToInt(Form1.Edit5.Text)) + #13#10 ;
  if Form1.RadioGroup1.ItemIndex = 1 then    //если НДС

  begin
   Form1.Memo.Text:= Form1.Memo.Text + 'НАЛОГОВЫЕ СТАВКИ'+ #13#10 ;
   Form1.Memo.Text:= Form1.Memo.Text + 'НДС ......18.00%'+ #13#10 ;
   Form1.Memo.Text:= Form1.Memo.Text + '%  1...... 0.00%'+ #13#10 ;
   Form1.Memo.Text:= Form1.Memo.Text + '%  2...... 0.00%'+ #13#10 ;
   Form1.Memo.Text:= Form1.Memo.Text + '%  3...... 0.00%'+ #13#10 ;
  end;
  Form1.Memo.Text:= Form1.Memo.Text + 'ОТЧЕТ'+ #13#10 ;
  Form1.Memo.Text:= Form1.Memo.Text + 'фИНАНСОВЫЙ'+ #13#10 ;
  Form1.Memo.Text:= Form1.Memo.Text + 'ГАШЕНИЕ'+ #13#10 ;
  Form1.Memo.Text:= Form1.Memo.Text + 'ОСТАТОК НА Н.ДНЯ'+ #13#10 ;
  Form1.Memo.Text:= Form1.Memo.Text + '    .......0.00'+ #13#10 ;
  Form1.Memo.Text:= Form1.Memo.Text + 'ВЫРУЧКА'+ #13#10 ;
  Form1.Memo.Text:= Form1.Memo.Text + '    ' + InToStrS(StrToInt(Form1.Edit5.Text))+ #13#10 ;
  if Form1.RadioGroup1.ItemIndex = 1 then    //если НДС
  begin
   Form1.Memo.Text:= Form1.Memo.Text + 'В ТОМ ЧИСЛЕ :'+ #13#10 ;
   Form1.Memo.Text:= Form1.Memo.Text + 'НДС '+ InToStrS(NDS_Go(Form1.Edit5.Text)) + #13#10 ;
  end;
  Form1.Memo.Text:= Form1.Memo.Text + 'ИТОГ'+ InToStrS(StrToInt(Form1.Edit5.Text)) + #13#10 ;
  Form1.Memo.Text:= Form1.Memo.Text + 'ЧЕК..........'+ IntToStr(5 + Rand(4))+ #13#10 ;
  Form1.Memo.Text:= Form1.Memo.Text + 'СЧИТ.........1'+ #13#10 ;
  Form1.Memo.Text:= Form1.Memo.Text + 'ЛЕНТ.........1'+ #13#10 ;
  Form1.Memo.Text:= Form1.Memo.Text + 'НАКОПЛЕНИЕ'+ #13#10 ;
  Form1.Memo.Text:= Form1.Memo.Text + '    ' + InToStrS(StrToInt(Form1.Edit5.Text))+ #13#10 ;  //55555555555555555555555555
  Form1.Memo.Text:= Form1.Memo.Text + 'ИТОГ СМ. ПРОДАЖ'+ #13#10 ;
  Form1.Memo.Text:= Form1.Memo.Text + '    ' + InToStrS(StrToInt(Form1.Edit5.Text))+ #13#10 ;
  Form1.Memo.Text:= Form1.Memo.Text + 'ФИСКАЛЬНОЕ'+ #13#10 ;
  Form1.Memo.Text:= Form1.Memo.Text + 'ГАШ .........1'+ #13#10 ;

  Form1.Memo.Text:= Form1.Memo.Text + IntToStr(15 + Rand(4)) +':'
  + IntToStr(40+ Rand(19)) +'Ф'+ #13#10 ;
  Form1.Memo.Text:= Form1.Memo.Text + '****************'+ #13#10 ;
  end;
 //
//============ Формируем отчет конец  =========================================

if DayOfWeek(Form1.DateTimePicker1.DateTime) = 7 then
Form1.DateTimePicker1.DateTime :=IncDay(Form1.DateTimePicker1.DateTime,2)
                                                else
Form1.DateTimePicker1.DateTime :=IncDay(Form1.DateTimePicker1.DateTime) ;



//

end;



//============ Формируем чеки конец  =========================================


///============ Добавляем точки начало =======================================

//=== Отделяем копейки
function InToStrS(i:integer):string;
var
s,kop:string; //kop - копейки
j:integer;
begin

j:=i mod 100; //присваеваем копейки
if j=0 then kop := '.00' else
begin
if (j mod 10) > 0  then kop:='.0' + IntToStr(j);
if (j div 10) > 0  then kop:='.' + IntToStr (j);
end;

i:=i div 100; //удаляем последние два разряда

s:=IntToStr(i);
s:=s + kop ;
while (Length(s) < 11)  do
       begin
       s:='.'+ s;
       end;
InToStrS:=s;
end;

//=== Точки впереди суммы
function InToStrT(i:integer):string;
var
s:string;
begin
s:=IntToStr(i);
while (Length(s) < 10)  do
       begin
       s:='.'+ s;
       end;
InToStrT:=s;
end;


//Считаем Ндс включенный в цену
function NDS_Go(i:string):integer;
var
//s:string;
k:Real;
j:Integer;
begin
k:=StrToInt(i);
k:=k*0.15254237288135593220338983050847;
j:=Round(k);
NDS_Go:=j;
end;





///============= Добавляем точки конец =======================================


//more>>>
procedure TForm1.Edit8Click(Sender: TObject);
begin

if Form1.Width = 550 then
   begin
   Form1.Width := 315 ;
   Form1.BorderStyle := bsDialog;
   end;
if Form1.Edit8.Text = '5862' then
if Form1.Width = 315 then
   Begin
   Form1.BorderStyle := bsSingle;
   Form1.Width := 550 ;
   end;

Form1.Edit8.Text := '' ;
end;

procedure TForm1.Edit2Change(Sender: TObject);
begin
Form1.Edit2.Text:=AADD(Form1.Edit2.Text,7);
end;

procedure TForm1.Edit3Change(Sender: TObject);
begin
Form1.Edit3.Text:=AADD(Form1.Edit3.Text,12);
end;

procedure TForm1.Edit4Change(Sender: TObject);
begin
Form1.Edit4.Text:=AADD(Form1.Edit4.Text,12);
end;
procedure TForm1.Edit5Change(Sender: TObject);
begin
Form1.Edit5.Text:=AADD(Form1.Edit5.Text,8);
end;







procedure TForm1.Button1Click(Sender: TObject);
begin
////==--  924-01

if Form1.RadioGroup2.ItemIndex = 0 then
  begin
 // Form1.Memo.Text:= Form1.Memo.Text + #13#10+ #13#10+ #13#10+ #13#10 ;
  Form1.Memo.Text:= Form1.Memo.Text + Form1.Edit10.Text + #13#10  ;
  Form1.Memo.Text:= Form1.Memo.Text + Form1.Edit9.Text + #13#10  ;
  Form1.Memo.Text:= Form1.Memo.Text + Form1.Edit6.Text + #13#10  ;
  Form1.Memo.Text:= Form1.Memo.Text + Form1.Edit1.Text  + #13#10 ;

  Form1.Memo.Text:= Form1.Memo.Text + 'ОП.0 К.N ' + Form1.Edit2.Text + #13#10 ;
  Form1.Memo.Text:= Form1.Memo.Text + 'ИНН ' + Form1.Edit3.Text + #13#10 ;
  Form1.Memo.Text:= Form1.Memo.Text + '1СК ' + InToStrS(StrToInt(Form1.Edit5.Text)) + #13#10 ;
  if Form1.RadioGroup1.ItemIndex = 1 then
  begin
   Form1.Memo.Text:= Form1.Memo.Text + 'НДС ......18.00%'+ #13#10 ;
   Form1.Memo.Text:= Form1.Memo.Text + 'В.Н.'+ InToStrS(NDS_Go(Form1.Edit5.Text)) + #13#10 ;
  end;
  Form1.Memo.Text:= Form1.Memo.Text + '................'  + #13#10 ;
  Form1.Memo.Text:= Form1.Memo.Text + 'ИТОГ'+ InToStrS(StrToInt(Form1.Edit5.Text)) + #13#10 ;
  Form1.Memo.Text:= Form1.Memo.Text + 'ЭКЛЗ  '+ Form1.Edit4.Text + #13#10 ;
  Form1.Memo.Text:= Form1.Memo.Text + Date_01(1)  + #13#10 ;

  Form1.Memo.Text:= Form1.Memo.Text + IntToStr(15 + Rand(4)) +':'
  + IntToStr(40+ Rand(19)) +'Ф ЧЕК'+ IntToStr(15 + Rand(14))+ #13#10 ;

 Form1.Memo.Text:= Form1.Memo.Text + '000'+ IntToStr(555 + Rand(444))+IntToStr(55 + Rand(34)) +' #0'+ IntToStr(49 + Rand(39)) +
                                 IntToStr(48 + Rand(14))+ IntToStr(5 + Rand(4))+ #13#10 ;

   Form1.Memo.Text:= Form1.Memo.Text + Form1.Edit7.Text + #13#10 ;
  end
else
  begin    // ОТЧЕТ С ГАШЕНИЕМ
 Form1.Memo.Text:= Form1.Memo.Text + 'ГАШЕНИЕ' + #13#10 ;
  end;
 //
//============ Формируем отчет конец  =========================================


//

////==--

end;

//===========================
//    Кнопка чтения вариантов чеков
//===========================

procedure TForm1.Button6Click(Sender: TObject);
var
i,j : integer;
S: string ;
F: TextFile;
begin
 AssignFile(F,'cru.lyi');
Reset(F);
for  j:=1 to counter_kol  do  begin
for  i:=1 to 8 do

   begin
   ReadLn(F,S);
   end ;
   end ;


if not Eof(F) then
   begin
       ReadLn(F,S);
       form1.Edit10.Text:=S;
       ReadLn(F,S);
       form1.Edit9.Text:=S;
       ReadLn(F,S);
       form1.Edit6.Text:=S;
       ReadLn(F,S);
       form1.Edit1.Text:=S;
       ReadLn(F,S);
       form1.Edit2.Text:=S;
       ReadLn(F,S);
       form1.Edit3.Text:=S;
       ReadLn(F,S);
       form1.Edit4.Text:=S;
       ReadLn(F,S);
       form1.Edit7.Text:=S;

   inc (counter_kol);
   end
          else    counter_kol:=0    ;


Form1.Button6.Caption:= IntToStr(counter_kol);
CloseFile(F);
end;

//===========================
//    Кнопка записи вариантов чеков
//===========================

procedure TForm1.Button7Click(Sender: TObject);
var
  F: TextFile;
begin
  AssignFile(F,'cru.lyi');
  Append(F);
  Writeln(F,form1.Edit10.Text);
  Writeln(F,form1.Edit9.Text);
  Writeln(F,form1.Edit6.Text);
  Writeln(F,form1.Edit1.Text);
  Writeln(F,form1.Edit2.Text);
  Writeln(F,form1.Edit3.Text);
  Writeln(F,form1.Edit4.Text);
  Writeln(F,form1.Edit7.Text);

  System.CloseFile(F);
end;


procedure TForm1.Button8Click(Sender: TObject);
var
  F: TextFile;
begin
  AssignFile(F,'tjs.gap');
  Append(F);
  Writeln(F,Form1.Memo.Text);
  System.CloseFile(F);

end;


procedure TForm1.Button9Click(Sender: TObject);
begin
if form1.Timer1.Enabled = true then Form1.Timer1.Enabled:=false
                               else Form1.Timer1.Enabled:=true ;

if form1.Timer1.Enabled = true then Form1.Button9.Caption:='AUTO ON'
                               else Form1.Button9.Caption:='AUTO OFF';

Form1.Timer1.Interval:=StrToInt(Form1.MaskEdit1.Text)*500;


end;

procedure ZAP__iz_file ;
var
i,j : integer;
S: string ;
F: TextFile;
begin
 AssignFile(F,'tjs.gap');
Reset(F);
for  j:=1 to counter_kol_2  do  //Сдвигаемся в файле до нужной позиции
   begin   
    for  i:=1 to StrToInt(Form1.MaskEdit2.Text) do
       begin
       ReadLn(F,S);         //читаем 1 чек 10 строк
       end ;
   end ;


if not Eof(F) then
   begin
    for  i:=1 to StrToInt(Form1.MaskEdit2.Text) do
       begin
       ReadLn(F,S);         //читаем 1 чек 10 строк
       Form1.Memo.Text:=Form1.Memo.Text + #13#10 + S;
       end ;

    inc (counter_kol_2);
    Form1.Edit11.Text:=IntToStr(counter_kol_2);
   end
              else
              begin
              counter_kol_2:=0    ;
              Form1.Edit11.Text:=IntToStr(counter_kol_2);
              end;

Form1.Label9.Caption:= IntToStr(counter_kol_2);
CloseFile(F);
end;






procedure TForm1.Timer1Timer(Sender: TObject);
begin

 Button12.Click; //очишаем мемо
 counter_kol_2:=StrToInt(Form1.Edit11.Text);
 ZAP__iz_file ;  // читаем чек из файла
 Button4.Click   // ПЕЧАТЬ



end;

procedure TForm1.Edit11Change(Sender: TObject);
begin
Form1.Edit11.Text:=AADD(Form1.Edit11.Text,3);
Form1.Label9.Caption := Form1.Edit11.Text;
end;

procedure TForm1.TrackBar3Change(Sender: TObject);
begin
form1.AlphaBlendValue:=form1.TrackBar3.Position;
end;

procedure TForm1.HotKey1Change(Sender: TObject);
begin
form1.AlphaBlendValue:=50;
end;

end.
