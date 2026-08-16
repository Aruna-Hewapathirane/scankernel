unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Dialogs, StdCtrls, ComCtrls, FileUtil;

type

  { TForm1 }

  TForm1 = class(TForm)
    BtnBrowse: TButton;
    BtnScan: TButton;
    EditPath: TEdit;
    ListViewResults: TListView;
    SelectDirDialog: TSelectDirectoryDialog;

    procedure BtnBrowseClick(Sender: TObject);
    procedure BtnScanClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    procedure ScanDirectory(const TargetDir: string);
    procedure ScanCFile(const FilePath: string);
  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

procedure TForm1.BtnBrowseClick(Sender: TObject);
begin
  if SelectDirDialog.Execute then EditPath.Text := SelectDirDialog.FileName;
end;

procedure TForm1.BtnScanClick(Sender: TObject);
begin
  if not DirectoryExists(EditPath.Text) then Exit;
  ListViewResults.Items.Clear;
  ScanDirectory(EditPath.Text);
  ShowMessage('Finished Scanning!');
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  ListViewResults.ViewStyle := vsReport;
  ListViewResults.ShowColumnHeaders := True;
  ListViewResults.RowSelect := True;

  // Set up explicit visual columns and responsive widths directly in code
  ListViewResults.Columns.Clear;
  with ListViewResults.Columns.Add do begin Caption := 'Length'; Width := 80; end;
  with ListViewResults.Columns.Add do begin Caption := 'Full File Path'; Width := 350; end;
  with ListViewResults.Columns.Add do begin Caption := 'Line #'; Width := 70; end;
  with ListViewResults.Columns.Add do begin Caption := 'Function Name / Signature'; Width := 500; end;
end;

procedure TForm1.ScanCFile(const FilePath: string);
var
  Lines: TStringList;
  i, j, Start, Braces, k: Integer;
  Item: TListItem;
  FuncName, CleanLine: string;
begin
  Lines := TStringList.Create;
  try
    Lines.LoadFromFile(FilePath);
    Braces := 0; Start := 0;

    for i := 0 to Lines.Count - 1 do
    begin
      // Opening function brace strictly sits on column 0 in Linux Kernel
      if (Lines[i] = '{') and (Start = 0) then
      begin
        Start := i + 1;
        Braces := 1;

        // FIXED: Dynamic backward-scanner loops up to capture multiline signatures
        FuncName := '';
        if i > 0 then
        begin
          for k := i - 1 downto 0 do
          begin
            CleanLine := Trim(Lines[k]);
            if CleanLine <> '' then
            begin
              if FuncName = '' then FuncName := CleanLine
              else FuncName := CleanLine + ' ' + FuncName;

              // Stop rolling back once we hit the base return type at column 0 (no whitespace/tabs)
              if (Length(Lines[k]) > 0) and (Lines[k][1] <> ' ') and (Lines[k][1] <> #9) then
                break;
            end;

            // Safety escape guard (rare macro anomalies)
            if (i - k) > 15 then break;
          end;
        end;

        continue;
      end;

      if Start > 0 then
      begin
        for j := 1 to Length(Lines[i]) do
        begin
          if Lines[i][j] = '{' then Inc(Braces);
          if Lines[i][j] = '}' then Dec(Braces);
        end;

        if Braces <= 0 then
        begin
          if (i + 1 - Start + 1) >= 200 then
          begin
            Item := TListView(ListViewResults).Items.Add;
            Item.Caption := IntToStr(i + 1 - Start + 1); // Column 1: Length
            Item.SubItems.Add(FilePath);                  // Column 2: Full File Path
            Item.SubItems.Add(IntToStr(Start));           // Column 3: Line Number
            Item.SubItems.Add(FuncName);                  // Column 4: Function Name

            Application.ProcessMessages;
          end;
          Start := 0;
        end;
      end;
    end;
  finally
    Lines.Free;
  end;
end;

procedure TForm1.ScanDirectory(const TargetDir: string);
var
  SR: TSearchRec;
begin
  if FindFirst(TargetDir + '/*', faAnyFile, SR) = 0 then
  begin
    try
      repeat
        if (SR.Name = '.') or (SR.Name = '..') or (SR.Name = '.git') then continue;

        if (SR.Attr and faDirectory) = faDirectory then
          ScanDirectory(TargetDir + '/' + SR.Name)
        else if SameText(ExtractFileExt(SR.Name), '.c') then
          ScanCFile(TargetDir + '/' + SR.Name);
      until FindNext(SR) <> 0;
    finally
      FindClose(SR);
    end;
  end;
end;

end.

