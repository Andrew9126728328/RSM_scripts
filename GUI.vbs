' ***********************************************************
' Метод popup
' Создание диалогового Popup окна ' pорup_okno.vbs
' *************************************************************
Option Explicit
Dim msg, title, timeout, result
Dim WshShell, my_msg
msg = "Нажмите на кнопу"
title = "Метод Poрuр"
' Создаем экземпляр класса WScript.Shell
Set WshShell = WScript.CreateObject("WScript.Shell")
' Выводим popup окно
result =  WshShell.Popup(msg, 5, title, vbOKCancel + vbInformation)
' Определяем, на что нажал пользователь
Select case result
      case 1
            my_msg = "Кликнуто на OK " & "(Код: " & result & ")"
      case 2
            my_msg = "Кликнуто на Отмена " & "(Код: " & result & ")"
      case else
             my_msg = "Пользователь ничего не нажал " & "(Код: " & result & ")"
End Select
MsgBox my_msg
'Источник: http://scriptcoding.ru/2013/06/25/wscript-shell-popup/ Внимание! Права на публикацию материалов сайта находятся под охраной © http://matrixblog.ru