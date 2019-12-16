cd ~/Projects/FOLDOC/scaleway
export UNISON=.
u='unison -sshcmd=ssh foldoc'
$u -batch
ssh denis@foldoc make --directory=/var/www/foldoc.org
$u -batch || $u
