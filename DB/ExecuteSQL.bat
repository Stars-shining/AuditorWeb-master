REM Set Variables
rem SET SRV=10.20.66.204
rem SET DB=APManager
rem SET FLAG=REMOTE
rem SET USER=sa
rem SET PASSWORD=123!@#qwe
rem SET SQLDir=D:\TestSQLsCript\DB
rem SET SQLCMD=C:\Program Files\Microsoft SQL Server\100\Tools\Binn\SQLCMD.exe

D: 
cd %SQLDir% 
for /R %%s in (*) do "C:\Program Files\Microsoft SQL Server\100\Tools\Binn\SQLCMD.exe" -S 10.20.66.204 -d APManager -U sa -P 123!@#qwe -i %%s

pause