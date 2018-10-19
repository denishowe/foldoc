cd %~dp0..\scaleway
call pa
set UNISON=.
.\unison.exe -batch foldoc
rem "c:\program files\putty\plink.exe"
ssh.exe denis@foldoc make --directory=/var/www/foldoc.org
.\unison.exe -batch foldoc || start unison foldoc
echo Done
attrib +R ..\foldoc\Dictionary
