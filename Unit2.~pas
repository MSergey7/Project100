unit Unit2;

interface

uses

  Classes;

type

            TMyThread = class(TThread) //Новый класс

            private

            answer:Integer;

            protected

            procedure ShowResult;

            procedure Test5;

            procedure Execute; override;

            end;

implementation

uses

            SysUtils, Unit1;


//Процедура для вывода информации из потока

//.1.
//=============================================================================
procedure TMyThread.Test5;
var
 str_temp: string;
 i: integer;
begin
 try

   Form1.ComPort1.Open;
   if Form1.ComPort1.Connected then
    begin
      str_temp:='!абвгдежзиКЛмнопр';
      //Print_Op_100(str_temp);
      for i:=0 to Form1.Memo2.lines.count - 1 do
         begin
          Unit1.Print_Op_100_mod(Form1.Memo2.Lines[i]);
          Sleep(150) ;
         end;
    end;

    Form1.ComPort1.Close;

 finally end;

end;


procedure TMyThread.ShowResult;

begin
//            Form1.Edit1.Text:=IntToStr(answer);

end;



//Длинная процедура

procedure TMyThread.Execute;
var
i:Integer;
begin

    Synchronize(ShowResult);
    Synchronize(Test5);

end;



end.
