#!/bin/bash
DATADIR=/opt/eosio/bin/data-dir
BINDIR=/opt/eosio/bin
PROG=nodeos

#!/bin/sh
cd $BINDIR

if [ -f $DATADIR/config.ini ]; then
    echo
  else
    cp config.ini $DATADIR/
fi

if [ -d $DATADIR/contracts ]; then
    echo
  else
    cp -r contracts $DATADIR/
fi

while :; do
    case $1 in
        --config-dir=?*)
            CONFIG_DIR=${1#*=}
            ;;
        *)
            break
    esac
    shift
done

if [ ! "$CONFIG_DIR" ]; then
    CONFIG_DIR="--config-dir=$DATADIR"
else
    CONFIG_DIR=""
fi

# set new generation key file on config.ini
if [ -f $DATADIR/config.ini ]
then
  if [ $( grep "__PUB_KEY__" $DATADIR/config.ini | wc -l ) -ne 0 ]; then
    $BINDIR/cleos create key> /tmp/keyfile
    PUBKEY=$(cat /tmp/keyfile | grep Public | awk '{print $3}')
    PRIVKEY=$(cat /tmp/keyfile | grep Private | awk '{print $3}')
    pkill -9 -ef keosd
    sed -i -e "s/__PUB_KEY__/$PUBKEY/g" -e "s/__PRIV_KEY__/$PRIVKEY/g" $DATADIR/config.ini
    rm -f /tmp/keyfile
  fi
fi

if [ ! -d $DATADIR/blocks ];
then
  exec $BINDIR/${PROG} --data-dir $DATADIR --config-dir $DATADIR --delete-all-blocks --genesis-json $DATADIR/genesis.json "$@" >> $DATADIR/stdout.txt 2>> $DATADIR/stderr.txt
else
  exec $BINDIR/${PROG} --data-dir $DATADIR --config-dir $DATADIR "$@" >> $DATADIR/stdout.txt 2>> $DATADIR/stderr.txt
fi
