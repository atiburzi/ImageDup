unit ImageDup.Resource;

interface

uses
  System.SysUtils, System.Classes, Vcl.BaseImageCollection, Vcl.ImageCollection, System.ImageList, Vcl.ImgList,
  Vcl.VirtualImageList;

type
  TDataModuleResources = class(TDataModule)
    ImageCollection: TImageCollection;
    VirtualImageList32: TVirtualImageList;
    VirtualImageList16: TVirtualImageList;
    VirtualImageList24: TVirtualImageList;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  DataModuleResources: TDataModuleResources;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

end.
