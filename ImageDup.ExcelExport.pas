unit ImageDup.ExcelExport;

interface

uses
  System.Generics.Collections, ImageDup.Groups;

procedure ExportGroupsToXlsx(const FileName: string;
  const Groups: TArray<TImageGroup>;
  const SelectedFiles: TDictionary<string, Boolean>);

implementation

uses
  System.SysUtils, System.Classes, System.IOUtils, System.Zip;

resourcestring
  rsDimensionsFmt='%d x %d';
  rsNo='no';
  rsYes='yes';
  rsExcelGroupColumn='Group';
  rsExcelFileColumn='File';
  rsExcelFileNameColumn='Filename';
  rsExcelFilePathColumn='File path';
  rsExcelPixelsColumn='Pixels';
  rsExcelBytesColumn='Bytes';
  rsExcelDateTimeColumn='Date and time';
  rsExcelQualityColumn='Quality';
  rsExcelSelectedColumn='Selected';
  rsExcelRelationshipColumn='Relationship';
  rsExcelReference='Reference';
  rsExcelIdentical='Identical to reference';
  rsExcelDifferent='Different from reference';
  rsDateTimeFormat='yyyy-mm-dd hh:nn:ss';


function XmlEscape(const Value: string): string;
begin
  Result := StringReplace(Value, '&', '&amp;', [rfReplaceAll]);
  Result := StringReplace(Result, '<', '&lt;', [rfReplaceAll]);
  Result := StringReplace(Result, '>', '&gt;', [rfReplaceAll]);
  Result := StringReplace(Result, '"', '&quot;', [rfReplaceAll]);
  Result := StringReplace(Result, '''', '&apos;', [rfReplaceAll]);
end;

procedure AddInlineCell(Builder: TStringBuilder; const CellReference,
  Value: string; StyleIndex: Integer = 0);
begin
  Builder.Append('<c r="').Append(CellReference).Append('"');
  if StyleIndex > 0 then
    Builder.Append(' s="').Append(StyleIndex).Append('"');
  Builder.Append(' t="inlineStr"><is><t xml:space="preserve">');
  Builder.Append(XmlEscape(Value));
  Builder.Append('</t></is></c>');
end;

procedure AddNumberCell(Builder: TStringBuilder; const CellReference,
  Value: string; StyleIndex: Integer = 0);
begin
  Builder.Append('<c r="').Append(CellReference).Append('"');
  if StyleIndex > 0 then
    Builder.Append(' s="').Append(StyleIndex).Append('"');
  Builder.Append('><v>').Append(Value).Append('</v></c>');
end;

procedure AddXml(Archive: TZipFile; const ArchiveName, Content: string);
var
  Stream: TStringStream;
begin
  Stream := TStringStream.Create(Content, TEncoding.UTF8);
  try
    Archive.Add(Stream, ArchiveName);
  finally
    Stream.Free;
  end;
end;

function BuildSheet(const Groups: TArray<TImageGroup>;
  const SelectedFiles: TDictionary<string, Boolean>): string;
const
  Columns: array[0..9] of string = ('A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J');
var
  Builder: TStringBuilder;
  Headers: array[0..9] of string;
  Group: TImageGroup;
  Member: TGroupMember;
  GroupIndex, MemberIndex, ReferenceIndex, ReferenceClass, Row, Column,
    TotalRows: Integer;
  IsSelected: Boolean;
  Relationship: string;
begin
  Headers[0] := rsExcelGroupColumn;
  Headers[1] := rsExcelFileColumn;
  Headers[2] := rsExcelFileNameColumn;
  Headers[3] := rsExcelFilePathColumn;
  Headers[4] := rsExcelPixelsColumn;
  Headers[5] := rsExcelBytesColumn;
  Headers[6] := rsExcelDateTimeColumn;
  Headers[7] := rsExcelQualityColumn;
  Headers[8] := rsExcelSelectedColumn;
  Headers[9] := rsExcelRelationshipColumn;
  TotalRows := 1;
  for Group in Groups do
    Inc(TotalRows, Length(Group.Members));
  Builder := TStringBuilder.Create(Length(Groups) * 2048 + 4096);
  try
    Builder.Append('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
    Builder.Append('<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">');
    Builder.Append('<dimension ref="A1:J').Append(TotalRows).Append('"/>');
    Builder.Append('<sheetViews><sheetView workbookViewId="0"><pane ySplit="1" topLeftCell="A2" activePane="bottomLeft" state="frozen"/></sheetView></sheetViews>');
    Builder.Append('<cols><col min="1" max="1" width="11" customWidth="1"/>');
    Builder.Append('<col min="2" max="2" width="62" customWidth="1"/>');
    Builder.Append('<col min="3" max="3" width="30" customWidth="1"/>');
    Builder.Append('<col min="4" max="4" width="48" customWidth="1"/>');
    Builder.Append('<col min="5" max="5" width="18" customWidth="1"/>');
    Builder.Append('<col min="6" max="6" width="15" customWidth="1"/>');
    Builder.Append('<col min="7" max="7" width="22" customWidth="1"/>');
    Builder.Append('<col min="8" max="10" width="18" customWidth="1"/></cols>');
    Builder.Append('<sheetData><row r="1" ht="24" customHeight="1">');
    for Column := 0 to High(Headers) do
      AddInlineCell(Builder, Columns[Column] + '1', Headers[Column], 1);
    Builder.Append('</row>');
    Row := 2;
    for GroupIndex := 0 to High(Groups) do
    begin
      Group := Groups[GroupIndex];
      ReferenceIndex := ReferenceMemberIndex(Group);
      if ReferenceIndex >= 0 then
        ReferenceClass := Group.Members[ReferenceIndex].ExactClass
      else
        ReferenceClass := -1;
      for MemberIndex := 0 to High(Group.Members) do
      begin
        Member := Group.Members[MemberIndex];
        IsSelected := False;
        if Assigned(SelectedFiles) then
          SelectedFiles.TryGetValue(Member.Info.FileName, IsSelected);
        if MemberIndex = ReferenceIndex then
          Relationship := rsExcelReference
        else if Member.ExactClass = ReferenceClass then
          Relationship := rsExcelIdentical
        else
          Relationship := rsExcelDifferent;
        Builder.Append('<row r="').Append(Row).Append('">');
        AddNumberCell(Builder, 'A' + IntToStr(Row), IntToStr(GroupIndex + 1));
        AddInlineCell(Builder, 'B' + IntToStr(Row), Member.Info.FileName);
        AddInlineCell(Builder, 'C' + IntToStr(Row),
          ExtractFileName(Member.Info.FileName));
        AddInlineCell(Builder, 'D' + IntToStr(Row),
          ExcludeTrailingPathDelimiter(ExtractFilePath(Member.Info.FileName)));
        AddInlineCell(Builder, 'E' + IntToStr(Row),
          Format(rsDimensionsFmt, [Member.Info.Width, Member.Info.Height]));
        AddNumberCell(Builder, 'F' + IntToStr(Row), IntToStr(Member.Info.Bytes));
        AddInlineCell(Builder, 'G' + IntToStr(Row),
          FormatDateTime(rsDateTimeFormat, Member.Info.Modified));
        AddNumberCell(Builder, 'H' + IntToStr(Row),
          FloatToStr(Member.QualityScore, TFormatSettings.Invariant));
        if IsSelected then
          AddInlineCell(Builder, 'I' + IntToStr(Row), rsYes)
        else
          AddInlineCell(Builder, 'I' + IntToStr(Row), rsNo);
        AddInlineCell(Builder, 'J' + IntToStr(Row), Relationship);
        Builder.Append('</row>');
        Inc(Row);
      end;
    end;
    Builder.Append('</sheetData>');
    if Row > 2 then
      Builder.Append('<autoFilter ref="A1:J').Append(Row - 1).Append('"/>');
    Builder.Append('</worksheet>');
    Result := Builder.ToString;
  finally
    Builder.Free;
  end;
end;

procedure ExportGroupsToXlsx(const FileName: string;
  const Groups: TArray<TImageGroup>;
  const SelectedFiles: TDictionary<string, Boolean>);
const
  ContentTypes = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
    '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">' +
    '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>' +
    '<Default Extension="xml" ContentType="application/xml"/>' +
    '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>' +
    '<Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>' +
    '<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>' +
    '</Types>';
  RootRelationships = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
    '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">' +
    '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>' +
    '</Relationships>';
  Workbook = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
    '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">' +
    '<sheets><sheet name="ImageDup" sheetId="1" r:id="rId1"/></sheets></workbook>';
  WorkbookRelationships = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
    '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">' +
    '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>' +
    '<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>' +
    '</Relationships>';
  Styles = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
    '<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">' +
    '<fonts count="2"><font><sz val="11"/><name val="Calibri"/></font><font><b/><color rgb="FFFFFFFF"/><sz val="11"/><name val="Calibri"/></font></fonts>' +
    '<fills count="3"><fill><patternFill patternType="none"/></fill><fill><patternFill patternType="gray125"/></fill><fill><patternFill patternType="solid"><fgColor rgb="FF1769AA"/><bgColor indexed="64"/></patternFill></fill></fills>' +
    '<borders count="1"><border><left/><right/><top/><bottom/><diagonal/></border></borders>' +
    '<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>' +
    '<cellXfs count="2"><xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/><xf numFmtId="0" fontId="1" fillId="2" borderId="0" xfId="0" applyFont="1" applyFill="1" applyAlignment="1"><alignment horizontal="center"/></xf></cellXfs>' +
    '<cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles>' +
    '<dxfs count="0"/><tableStyles count="0" defaultTableStyle="TableStyleMedium2" defaultPivotStyle="PivotStyleLight16"/>' +
    '</styleSheet>';
var
  Archive: TZipFile;
begin
  if TFile.Exists(FileName) then
    TFile.Delete(FileName);
  Archive := TZipFile.Create;
  try
    Archive.Open(FileName, zmWrite);
    AddXml(Archive, '[Content_Types].xml', ContentTypes);
    AddXml(Archive, '_rels/.rels', RootRelationships);
    AddXml(Archive, 'xl/workbook.xml', Workbook);
    AddXml(Archive, 'xl/_rels/workbook.xml.rels', WorkbookRelationships);
    AddXml(Archive, 'xl/styles.xml', Styles);
    AddXml(Archive, 'xl/worksheets/sheet1.xml',
      BuildSheet(Groups, SelectedFiles));
  finally
    Archive.Free;
  end;
end;

end.


