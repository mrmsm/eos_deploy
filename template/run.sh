#!/bin/bash
BASEDIR=/opt/eosio/bin/data-dir
DATADIR=${BASEDIR}/data
CONFDIR=${BASEDIR}/config
LOGDIR=${BASEDIR}/log
#BINDIR=/opt/eosio/bin
BINDIR=/usr/bin
PROG=nodeos

#!/bin/sh
cd /opt/eosio/bin

[ ! -d $DATADIR ] && mkdir ${DATADIR}
[ ! -d $CONFDIR ] && mkdir ${CONFDIR}
[ ! -d $LOGDIR ] && mkdir ${LOGDIR}

if [ -f $CONFDIR/config.ini ]; then
    echo
  else
    cp /config.ini $CONFDIR/config.ini
fi

if [ -d $DATADIR/contracts ]; then
    echo
  else
    cp -r /contracts $DATADIR/contracts
fi

while :; do
    case $1 in
		clean)
			rm -rf $DATADIR $LOGDIR
			;;
        --config-dir=?*)
            CONFIG_DIR=${1#*=}
            ;;
        *)
            break
    esac
    shift
done

# set new generation key file on config.ini
if [ -f $CONFDIR/config.ini ]
then
  if [ $( grep "__PUB_KEY__" $CONFDIR/config.ini | wc -l ) -ne 0 ]; then
    $BINDIR/cleos create key> /tmp/keyfile
    PUBKEY=$(cat /tmp/keyfile | grep Public | awk '{print $3}')
    PRIVKEY=$(cat /tmp/keyfile | grep Private | awk '{print $3}')
    pkill -9 -ef keosd
    sed -i -e "s/__PUB_KEY__/$PUBKEY/g" -e "s/__PRIV_KEY__/$PRIVKEY/g" $CONFDIR/config.ini
    rm -f /tmp/keyfile
  fi
fi

if [ ! -d $DATADIR/blocks ];
then
  exec $BINDIR/${PROG} --data-dir $DATADIR --config-dir $CONFDIR --delete-all-blocks --genesis-json ${CONFDIR}/genesis.json "$@" >> $LOGDIR/stdout.txt 2>> $LOGDIR/stderr.txt
else
 exec $BINDIR/${PROG} --data-dir $DATADIR --config-dir $CONFDIR  "$@" >> $LOGDIR/stdout.txt 2>> $LOGDIR/stderr.txt
 #exec $BINDIR/${PROG} --data-dir $DATADIR --config-dir $CONFDIR --snapshot $DATADIR/snapshots/snapshot-107656980.bin "$@" >> $LOGDIR/stdout.txt 2>> $LOGDIR/stderr.txt
fi
