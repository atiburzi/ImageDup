unit ImageDup.Resource;

interface

uses
  System.SysUtils, System.Classes, Vcl.ImageCollection,
  Vcl.VirtualImageList, System.ImageList, Vcl.ImgList, Vcl.BaseImageCollection;

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
