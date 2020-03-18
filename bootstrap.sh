#!/bin/bash
setup_chain="eos-mainnet"

basedir=$(/usr/bin/dirname $(realpath $0))""
snapshot_url="https://snapshots-main.eossweden.org/snapshots/aca376/1.8/latest"

if [ $(id -u) -ne 0 ]; then
  echo "This script is need root permission. Please run with sudo commands"
  exit 2
fi

check_bin() { 
    which $1 > /dev/null 2>&1
    if [ $? -eq 1 ]; then
	echo "$1 is not found. Please install $1 package"
	exit 1
    fi
}

# Check Binary
check_bin jq
check_bin wget
check_bin curl
check_bin docker

PUBLIC_IP==$(wget -O - http://ifconfig.me 2>/dev/null)

# Get Docker image tag
cnt=1;
dc_repo=[];
for INF in $(curl -s https://hub.docker.com/v2/repositories/mrmsm/eos_docker/tags/ | jq -r ".results[] | .name" | grep -v "latest" | sort -r -k 1);do
  dc_repo[$cnt]=$INF;
  ((cnt++))
done

echo "============================================="
echo " Docker Image List"
echo "============================================="
for((x=1;x<${#dc_repo[@]};x++));do
  echo " $x : ${dc_repo[$x]}"
done
echo "============================================="
read -p "* Choose Docker image number [default : 1] : " ch_ver
ch_ver=${ch_ver:-"1"}
docker_image_tag=${dc_repo[$ch_ver]}

# Set Base directory
echo "EOS mainnet base directory : ${basedir}/${setup_chain}"
read -p "Are you setup here? [Y/n]" _chkval
_chkval=${_chkval:-"Y"}

case "${_chkval}" in
    N|n)
    exit 1;
    ;;
    Y|y)
    _prefix=$basedir/$setup_chain
    ;;
esac

if [ -d $_prefix ]; then
  echo " >> $_prefix directory is exists"
  read -p " Are you want to remove exists directory? [Y/n]" _chkval
  _chkval=${_chkval:-"Y"}
  if [ $(echo $_chkval | tr '[:lower:]' '[:upper:]') == "Y" ]; then
    rm -rf $_prefix
  fi
fi

mkdir -p $_prefix/{data/blocks,log,config}

while true; do
  read -p "* Please input producer name [eoseouldotio] : " _nodename
  _nodename=${_nodename:-"eoseouldotio"}
  if [ $(echo $_nodename | wc -c) -eq 13 ]; then
    break;
  else
    echo " !! Producer name must be 12 characters and only use a-z, 1-5 chars"
  fi
done

read -p "* Input HTTP RPC bind Port [default : 8888] : " _http_port
_http_port=${_http_port:-"8888"}

read -p "* Input P2P bind Port [default : 9876] : " _p2p_port
_p2p_port=${_p2p_port:-"9876"}

docker run --rm -it --name eos_key_gen mrmsm/eos_docker:$docker_image_tag cleos create key --to-console  >$_nodename.bpkey
PUB_KEY=$(cat $_nodename.bpkey | grep "Public" | awk '{print $3}')
PRIV_KEY=$(cat $_nodename.bpkey | grep "Private" | awk '{print $3}')
cat $_nodename.bpkey
rm -f $_nodename.bpkey

if [ ! -f $basedir/template/$setup_chain/config.ini ] ; then
  echo "ERROR : Config.ini template file is not exists."
  echo "Check : $basedir/template/$setup_chain/config.ini"
  exit 1;
fi

sed -e "s/__PRODUCER_NAME__/$_nodename/g" -e "s/__PUB_KEY__/$PUB_KEY/g" -e "s/__PRIV_KEY__/$PRIV_KEY/g" -e "s/__PUBLIC_IP__/$PUBLIC_IP/g" -e "s/__P2P_PORT__/$_p2p_port/g" -e "s/__HTTP_PORT__/$_http_port/" < $basedir/template/$setup_chain/config.ini > $_prefix/config/config.ini 
cp -a $basedir/template/$setup_chain/genesis.json $_prefix/config/

sed -e "s/__DOCKER_RELEASE__/$docker_image_tag/g" -e "s#__SNAPSHOT_URL__#$snapshot_url#g" -e "s/__PRODUCER_NAME__/$_nodename/g" -e "s#__PREFIX__#$_prefix#g" < $basedir/template/docker_run.sh > $_prefix/docker_run.sh

sed -e "s/__PRODUCER_NAME__/$_nodename/g" <  $basedir/template/cleos.sh > $_prefix/cleos.sh
sed -e "s/__HTTP_PORT__/$_http_port/g" <  $basedir/template/sync_check.sh > $_prefix/sync_check.sh

cp -a $basedir/template/run.sh $_prefix/run.sh

chmod 0700 $_prefix/run.sh
chmod 0700 $_prefix/docker_run.sh
chmod 0700 $_prefix/cleos.sh
chmod 0700 $_prefix/sync_check.sh

echo "################ Bootstrap finish ##################"
echo " > Next step"
echo "####################################################"
echo " cd $_prefix"
echo " ./docker_run.sh snapshot_recovery"
echo " # ... 5 min after..."
echo " ./sync_check.sh"
echo "####################################################"
echo " If the node is fully synchronized, stop and remove the docker container and restart run_docker.sh. If the docker container is not deleted and restarted, it will attempt to recover to Snapshot during the restart process."

