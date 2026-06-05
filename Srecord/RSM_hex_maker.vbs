'********************************************************
'Урок VBScript №10:
'Работа с текстовыми документами - TextStream.
'file_3.vbs
'********************************************************
Option Explicit

Const PROJ_NAME_KEY = "proj_name"
Const PROJ_VERSION_KEY = "proj_version"
Const HEX_SEGMENT_CMD_PREFIX = ":02000004"
Const HEX_ADDRESS_CMD_PREFIX = ":10"
Const HEX_ADDRESS_CMD_SUFFIX = "000"
Const DATA_OFFSET_IN_HEX_FILE = 10
Const CRC_OFFSET_IN_HEX_FILE = 42
Const RESULT_HEX_FILE_NAME_SEPARATOR = "_"
Const RESULT_HEX_FILE_VER_SEPARATOR = "_v_"
Const RESULT_HEX_FILE_EXT = ".hex"
Const FOLDER_SEPARATOR = "\"

Dim str_current_path, objShellApp, objFolder, objFolderItems, objFile
Dim objWshShell
Dim objFSO, objFileMap, objFileHex
Dim str_in, strNameHex, strResultProjectName
Dim segment_name, address_name, offset_name
Dim segment_version, address_version, offset_version
Dim pos, char_in

Dim Debug
Debug = 1
REM ********************* Current folder ********************************
Set objWshShell = WScript.CreateObject("WScript.Shell")
str_current_path =  objWshShell.CurrentDirectory
REM ********************* Find *.map file *******************************
Set objShellApp = CreateObject("Shell.Application")
Set objFolder = objShellApp.NameSpace(str_current_path)
Set objFolderItems = objFolder.Items()
objFolderItems.Filter 64, "*.map"
If objFolderItems.Count = 1 Then
REM ********************* Found Single *.map File ***********************

    strResultProjectName = ""
    Set objFSO = CreateObject("Scripting.FileSystemObject")
    Set objFileMap = objFSO.OpenTextFile(objFolderItems.Item(0).Path, 1) ' open *.map

If Debug > 0 Then MsgBox "*.map Found:"+objFolderItems.Item(0).Name End If

    Do Until objFileMap.AtEndOfStream                                 ' пока наступит конец файла
       str_in = objFileMap.ReadLine                                   ' Считываем строку
       If (InStr(1,str_in,PROJ_NAME_KEY) <> 0) Then
          Exit Do                                                     ' proj_name found
       End If
    Loop
    If objFileMap.AtEndOfStream = False Then
    REM ***************** Found proj_name address in *.map file *********
        segment_name = UCase(HEX_SEGMENT_CMD_PREFIX + Mid(str_in, 3, 4))                                ' segment switch command in *.hex file
        address_name = UCase(HEX_ADDRESS_CMD_PREFIX + Mid(str_in, 7, 3) + HEX_ADDRESS_CMD_SUFFIX)       ' data command in *.hex file
        offset_name = Mid(str_in, 10, 1)                                                                ' offset in data command line of *.hex file
If Debug > 0 Then MsgBox "Name Segment: "+segment_name End If
If Debug > 0 Then  MsgBox "Name Address: "+address_name End If
If Debug > 0 Then  MsgBox "Name Offset: "+offset_name End If
    End If
    objFileMap.Close ' закрываем
    Set objFileMap = objFSO.OpenTextFile(objFolderItems.Item(0).Path, 1)
    Do Until objFileMap.AtEndOfStream                                 ' пока наступит конец файла
       str_in = objFileMap.ReadLine                                   ' Считываем строку
       If (InStr(1,str_in,PROJ_VERSION_KEY) <> 0) Then
          Exit Do                                                     ' proj_name found
       End If
    Loop
    If objFileMap.AtEndOfStream = False Then
    REM ***************** Found proj_name address in *.map file *********
        segment_version = UCase(HEX_SEGMENT_CMD_PREFIX + Mid(str_in, 3, 4))                             ' segment switch command in *.hex file
        address_version = UCase(HEX_ADDRESS_CMD_PREFIX + Mid(str_in, 7, 3) + HEX_ADDRESS_CMD_SUFFIX)    ' data command in *.hex file
        offset_version = Mid(str_in, 10, 1)                                                             ' offset in data command line of *.hex file
If Debug > 0 Then MsgBox "Version Segment: "+segment_version End If
If Debug > 0 Then MsgBox "Version Address: "+address_version End If
If Debug > 0 Then  MsgBox "Version Offset: "+offset_version End If
    End If
    objFileMap.Close ' закрываем
    REM **************** Find In *.hex File *****************************
    strNameHex = objFolderItems.Item(0).Path
    strNameHex = Replace(strNameHex, ".map", ".hex")
If Debug > 0 Then MsgBox "*.hex Name: "+strNameHex End If
    Set objFileHex = objFSO.OpenTextFile(strNameHex, 1)               ' Open *.hex
    Do Until objFileHex.AtEndOfStream                                 ' пока наступит конец файла
       str_in = UCase(objFileHex.ReadLine)                            ' Считываем строку
       If (InStr(1,str_in,segment_name) <> 0) Then                    ' proj_name segment found
If Debug > 0 Then MsgBox "Name Segment Found In Hex File" End If
          Do Until objFileHex.AtEndOfStream                           ' пока наступит конец файла
             str_in = UCase(objFileHex.ReadLine)                      ' Считываем строку
             If (InStr(1,str_in,address_name) <> 0) Then              ' proj_name address found
If Debug > 0 Then MsgBox "Name Address Found In Hex File" End If
                  Exit Do
             End If
          Loop
          Exit Do
       End If
    Loop
    If objFileHex.AtEndOfStream = True Then
If Debug > 0 Then MsgBox "Name Segment Not Found In Hex File" End If
    Else
        pos = DATA_OFFSET_IN_HEX_FILE + CByte("&H" + offset_name)*2                 ' position in data line of *.hex file.
        char_in = Mid(str_in, 26, 2)
        Do Until objFileHex.AtEndOfStream                             ' пока наступит конец файла
           char_in = CByte("&H" + Mid(str_in, pos, 2))                ' read two character from pos
           If char_in = 0 Then                                        ' end of string?
              Exit Do
           End If
           strResultProjectName = strResultProjectName + Chr(char_in) ' append character to result project name
           pos = pos + 2
           If pos >= CRC_OFFSET_IN_HEX_FILE Then                      ' wrap
              str_in = UCase(objFileHex.ReadLine)                     ' Jump to new line
              pos = DATA_OFFSET_IN_HEX_FILE
           End If
        Loop
        objFileHex.Close ' закрываем
        Set objFileHex = objFSO.OpenTextFile(strNameHex, 1)               ' Open *.hex
        Do Until objFileHex.AtEndOfStream                                 ' пока наступит конец файла
           str_in = UCase(objFileHex.ReadLine)                            ' Считываем строку
           If (InStr(1,str_in,segment_version) <> 0) Then                 ' proj_version segment found
If Debug > 0 Then MsgBox "Version Segment Found In Hex File" End If
             Do Until objFileHex.AtEndOfStream                           ' пока наступит конец файла
                str_in = UCase(objFileHex.ReadLine)                      ' Считываем строку
                If (InStr(1,str_in,address_version) <> 0) Then           ' proj_version address found
If Debug > 0 Then MsgBox "Version Address Found In Hex File" End If
                  Exit Do
                End If
             Loop
             Exit Do
           End If
       Loop
       strResultProjectName = strResultProjectName + RESULT_HEX_FILE_VER_SEPARATOR
       If objFileHex.AtEndOfStream = True Then
If Debug > 0 Then MsgBox "Version Segment Not Found In Hex File" End If
       Else
           pos = DATA_OFFSET_IN_HEX_FILE + CByte("&H" + offset_version)*2              ' position in data line of *.hex file.
           char_in = Mid(str_in, 26, 2)
           Do Until objFileHex.AtEndOfStream                             ' пока наступит конец файла
              char_in = CByte("&H" + Mid(str_in, pos, 2))                ' read two character from pos
              If char_in = 0 Then                                        ' end of string?
                 Exit Do
              End If
              strResultProjectName = strResultProjectName + Chr(char_in) ' append character to result project name
              pos = pos + 2
              If pos >= CRC_OFFSET_IN_HEX_FILE Then                      ' wrap
                 str_in = UCase(objFileHex.ReadLine)                     ' Jump to new line
                 pos = DATA_OFFSET_IN_HEX_FILE
              End If
           Loop
           strResultProjectName = Replace(strResultProjectName, " ", RESULT_HEX_FILE_NAME_SEPARATOR)
           strResultProjectName = Replace(strResultProjectName, "-", RESULT_HEX_FILE_NAME_SEPARATOR)
           strResultProjectName = Replace(strResultProjectName, ".", RESULT_HEX_FILE_NAME_SEPARATOR)
           strResultProjectName = strResultProjectName + RESULT_HEX_FILE_EXT
           strResultProjectName = objFSO.GetAbsolutePathName(".") + FOLDER_SEPARATOR + strResultProjectName
If Debug > 0 Then MsgBox "Project Name: "+strResultProjectName End If
           If objFSO.FileExists(strResultProjectName) = True Then          ' Result File Exist?
              objFSO.DeleteFile(strResultProjectName)                      ' Kill old file
           End If
           objFSO.CopyFile strNameHex, strResultProjectName                ' Create new *.hex file with new name
       End If
       objFileHex.Close ' закрываем
    End If
REM *********************************************************************
End If
