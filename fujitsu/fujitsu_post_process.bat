@echo off
SetLocal EnableDelayedExpansion
:: Get input file from arguments (call: fujitsu_post_process.bat input_file)
set INFILE=%1
echo File: %INFILE%
::pause
:: Start address of Fujitsu flash memory
set /a MEMORYBEGIN=0xfe0000
:: End address of Fujitsu flash memory
set /a MEMORYEND=0xffffff
:: Start of infoblock in flash (in signature.c file string: #pragma segment CONST=signature,attr=CONST,locate=0xfe0002)
set /a INFOBLOCK=0xfe0002
:: Lenth of build data record in infoblock
set /a BUILDDATALENTH=16
:: Lenth of build time record in infoblock
set /a BUILDTINELENTH=16
:: Lenth of CRC record in infoblock
set /a CRCLENTH=4
:: Lenth of Vendor record in infoblock
set /a VENDORLENTH=16
:: Lenth of Product record in infoblock
set /a PRODUCTLENTH=32
:: Lenth of Version record in infoblock
set /a VERSIONLENTH=16
:: End address location of build date and time
set /a BUILDDATETIMEEND=%INFOBLOCK%+%BUILDDATALENTH%+%BUILDTINELENTH%
:: End address location of build date and time and CRC
set /a BUILDDATETIMECRCEND=%BUILDDATETIMEEND%+%CRCLENTH%
:: Address of CRC store
set /a CRCADDRESS=%BUILDDATETIMEEND%
:: Address of Version record
set /a VERSIONADDRESS=%BUILDDATETIMECRCEND%+%VENDORLENTH%+%PRODUCTLENTH%
:: End address location of Version
set /a VERSIONEND=%BUILDDATETIMECRCEND%+%VENDORLENTH%+%PRODUCTLENTH%+%VERSIONLENTH%
::pause
:: Get file name
for %%f in ("%INFILE%") do set FILENAME=%%~nf
:: Set file name for date time build tmp
set FILEBUILDTMP=%FILENAME%_build.tmp
:: Set file name for firmware tmp
set FILEFMWTMP=%FILENAME%_fmw.tmp
:: Set file name for CRC tmp
set FILECRCTMP=%FILENAME%_crc.tmp
:: Set file name for version tmp
set FILEVERSIONTMP=%FILENAME%_ver.tmp
:: Set final file name
set FILEFINAL=%FILENAME%_final.tmp
::pause
::============================================================================================================
:: Move data time build to separate file (date and time are not included in the CRC calculation)
srec_cat -disable-sequence-warning %INFILE% -crop %MEMORYBEGIN% %BUILDDATETIMEEND% -Output %FILEBUILDTMP%
::pause
:: Success check
if not exist %FILEBUILDTMP% (
    echo Target %FILEBUILDTMP% not found
    exit
)
::============================================================================================================
:: Calculate firmware CRC & Store into CRC place
srec_cat -disable-sequence-warning %INFILE% -fill 0x00 %MEMORYBEGIN% %MEMORYEND% -crop %BUILDDATETIMECRCEND% %MEMORYEND% -CRC32_Little_Endian %CRCADDRESS% -CCITT -Output %FILEFMWTMP%
::pause
:: Success check
if not exist %FILEFMWTMP% (
    echo Target %FILEFMWTMP% not found
    exit
)
::============================================================================================================
:: Merge to output file
srec_cat %FILEBUILDTMP% %FILEFMWTMP% -Output %FILEFINAL%
:: Success check
if not exist %FILEFINAL% (
    echo Target %FILEFINAL% not found
    exit
)
::============================================================================================================
::pause
:: Move crc to separate file
srec_cat %FILEFINAL% -crop %CRCADDRESS% %BUILDDATETIMECRCEND% -Output %FILECRCTMP%
:: Success check
if not exist %FILECRCTMP% (
    echo Target %FILECRCTMP% not found
    exit
)
:: Swap crc little endian -> big endian
srec_cat %FILECRCTMP% -offset -%CRCADDRESS% -byte-swap 4 -o %FILECRCTMP%
::pause
:: Success check
if not exist %FILECRCTMP% (
    echo Target %FILECRCTMP% not found
    exit
)
:: Read CRC aka string
set /a c=0
for /f %%A IN (%FILECRCTMP%) do (
  if !c!==1 set "CRC=%%A"
  set /a c+=1
)
:: Extract CRC from string
set CRC=%CRC:~8,8%
echo CRC Found = 0x%CRC%
::============================================================================================================
:: Extract bulild date
srec_cat %FILEBUILDTMP% -crop %MEMORYBEGIN% %BUILDDATETIMEEND% -offset -%MEMORYBEGIN% -Output %FILEBUILDTMP% -binary
::pause
:: Success check
if not exist %FILEBUILDTMP% (
    echo Target %FILEBUILDTMP% not found
    exit
)
:: Read Build aka string
set /p BUILDSTRING=<%FILEBUILDTMP%
set DAY=%BUILDSTRING:~6,2%
set DAY=%DAY: =%
set MONTH=%BUILDSTRING:~2,3%
set YEAR=%BUILDSTRING:~9,4%
echo Build Day = %DAY%
echo Build Month = %MONTH%
echo Build Year = %YEAR%
::============================================================================================================
:: Move version to separate file
srec_cat %FILEFINAL% -crop %VERSIONADDRESS% %VERSIONEND% -offset -%VERSIONADDRESS% -Output %FILEVERSIONTMP% -binary
::pause
:: Success check
if not exist %FILEVERSIONTMP% (
    echo Target %FILEVERSIONTMP% not found
    exit
)
:: Read it to variable
set /p VERSIONFROMFILE=<%FILEVERSIONTMP%
:: Replace . -> _
set VERSION=%VERSIONFROMFILE:.=_%
echo Version Found = %VERSION%
::============================================================================================================
:: Create output file name and copy to
set OUTPUTFILE=%FILENAME%
:: Add Version
set OUTPUTFILE=%OUTPUTFILE%_v_%VERSION: =%
:: Add CRC
set OUTPUTFILE=%OUTPUTFILE%_crc_%CRC%
:: Add Build
set OUTPUTFILE=%OUTPUTFILE%_%DAY%
set OUTPUTFILE=%OUTPUTFILE%_%MONTH%
set OUTPUTFILE=%OUTPUTFILE%_%YEAR%
:: Add Ext
set OUTPUTFILE=%OUTPUTFILE%.mhx
copy %FILEFINAL% %OUTPUTFILE%
::pause
:: Success check
if not exist %OUTPUTFILE% (
    echo Target %OUTPUTFILE% not found
    exit
)
::============================================================================================================
:: Kill all tmp files
del %FILEBUILDTMP%
del %FILEFMWTMP%
del %FILEFINAL%
del %FILECRCTMP%
del %FILEVERSIONTMP%
::pause

