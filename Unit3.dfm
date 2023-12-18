object Form3: TForm3
  Left = 0
  Top = 0
  BorderStyle = bsSingle
  Caption = 'Example Pipe in Delphi'
  ClientHeight = 558
  ClientWidth = 853
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  PixelsPerInch = 96
  TextHeight = 13
  object Edit1: TEdit
    Left = 8
    Top = 24
    Width = 193
    Height = 21
    TabOrder = 0
    TextHint = 'example.com'
  end
  object Memo1: TMemo
    Left = 248
    Top = 24
    Width = 281
    Height = 513
    TabOrder = 1
  end
  object Button1: TButton
    Left = 8
    Top = 51
    Width = 75
    Height = 25
    Caption = 'findomain'
    TabOrder = 2
    OnClick = Button1Click
  end
  object Memo2: TMemo
    Left = 535
    Top = 24
    Width = 281
    Height = 513
    TabOrder = 3
  end
  object Button2: TButton
    Left = 126
    Top = 51
    Width = 75
    Height = 25
    Caption = 'nmap'
    TabOrder = 4
    OnClick = Button2Click
  end
end
