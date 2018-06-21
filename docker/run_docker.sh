#!/bin/bash

DOCKER_HUB="mrmsm/eos_docker"

echo_f ()
{
  message=${1:-"[ Failed ]"}
  printf "\033[1;31m%s\033[0m\n" "$message"
}
echo_s ()
{
  message=${1:-"[ Success ]"}
  printf "\033[1;32m%s\033[0m\n" "$message"
}
echo_fx ()
{
  message=${1:-"[ Failed ]"}
  printf "\033[1;31m%s\033[0m\n" "$message"
  exit 1;
}
echo_ret () {
  echo -ne "$1"
  [ $2 -eq 0 ] && echo_s || echo_f
}
echo_ret_exit () {
  echo -ne "$1"
  [ $2 -eq 0 ] && echo_s || echo_fx
}

if [ $(id -u) -eq 0 ]; then
  _sudo=""
else
  _sudo="sudo "
fi

# Check Docker installed
$_sudo which docker >/dev/null 2>&1
echo_ret_exit " -- Docker install check : " $?

# Check Jq installed
$_sudo which jq >/dev/null 2>&1
if [ $? -eq 1 ]; then
  echo "This script need to JQ binary"
  # Check OS Type
  case "$OSTYPE" in
   darwin*)
        echo "## Run to this ##"
        echo " >> wget https://github.com/stedolan/jq/releases/download/jq-1.5/jq-osx-amd64"
        echo " >> chmod +x jq-osx-amd64; sudo mv jq-osx-amd64 /usr/local/bin/jq"
        exit 1
        ;;
    linux*)
        echo "## Run to this ##"
        echo " >> wget https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64"
        echo " >> chmod +x jq-linux64; sudo mv jq-linux64 /usr/local/bin/jq"
        exit 1
        ;;
         *)
        echo "unknown: $OSTYPE"; exit 1 ;;
  esac
fi

cnt=1;
dc_repo=[]; 
for INF in $(curl -s https://hub.docker.com/v2/repositories/$DOCKER_HUB/tags/ | jq -r ".results[] | .name"); 
do 
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
read -p "* Connect EOS Main Network? [Y] :" _net_flag
_net_flag=${_net_flag:-"Y"}

#read -p "* Is this Boot node?? [N]" _chk
#_chk=${_chk:-"N"}
#if [ $(echo $_chk | tr '[:lower:]' '[:upper:]') == "Y" ]; then
#   _nodename="boot"
#else
   while true; do
     read -p "* Please input producer name [eoseoulfulln] : " _nodename
     _nodename=${_nodename:-"eoseoulfulln"}
     if [ $(echo $_nodename | wc -c) -eq 13 ]; then 
       break;
     else
       echo " !! Producer name must be 12 characters and only use a-z, 1-5 chars"
     fi
   done
#fi

while true; do
  _default_path="$(pwd)/$_nodename"
  read -p "* Set eos_data directory [$_default_path] : " set_data_dir
  set_data_dir=${set_data_dir:-"$_default_path"}
  if [ -d $set_data_dir ]; then
    echo " >> $set_data_dir directory is exists."
    read -p "* Do you want to remove nodeos data in here? [Y]" _chk
    _chk=${_chk:-"Y"}
    if [ $(echo $_chk | tr '[:lower:]' '[:upper:]') == "Y" ]; then
      $_sudo rm -rf $set_data_dir
      break;
    fi
  else
    break; 
  fi
done

read -p "* Input HTTP RPC bind Port [default : 8888] : " _http_port
_http_port=${_http_port:-"8888"}

read -p "* Input P2P bind Port [default : 9876] : " _p2p_port
_p2p_port=${_p2p_port:-"9876"}

mkdir -p $set_data_dir
$_sudo docker run --rm -it --name nodetest $DOCKER_HUB:${dc_repo[$ch_ver]} cleos create key > $set_data_dir/$_nodename.bpkey
echo_ret_exit " -- Peer private key generate : " $?

PUB_KEY=$(cat $set_data_dir/${_nodename}.bpkey | grep "Public" | awk '{print $3}' | sed "s///g")
PRIV_KEY=$(cat $set_data_dir/${_nodename}.bpkey | grep "Private" | awk '{print $3}' | sed "s///g")

if [ ! -f template/config.sample ]; then 
  echo " ERROR : config.sample file is not exists"
  exit 1
fi
sed -e "s/__PRIVKEY__/$PRIV_KEY/g" -e "s/__PUBKEY__/$PUB_KEY/g" -e "s/__BPNAME__/$_nodename/g" < template/config.sample > $set_data_dir/config.ini

if [ ! -f template/genesis.sample ]; then 
  echo " ERROR : genesis.sample file is not exists"
  exit 1
fi

if [ $_net_flag == "Y" ]; then
  cp -a template/genesis.mainnet $set_data_dir/genesis.json
else
  genesis_date=$(date +"%Y-%m-%dT00:00:00.000")
  sed -e "s/__PRIVKEY__/$PRIV_KEY/g" -e "s/__PUBKEY__/$PUB_KEY/g" -e "s/__INIT_DATE__/$genesis_date/g" < template/genesis.sample > $set_data_dir/genesis.json
fi

cp -a template/run.sh $set_data_dir/run.sh
chmod +x $set_data_dir/run.sh

$_sudo docker run -d --name $_nodename  -v $set_data_dir:/opt/eosio/bin/data-dir -p $_http_port:8888 -p $_p2p_port:9876 $DOCKER_HUB:${dc_repo[$ch_ver]} /opt/eosio/bin/data-dir/run.sh  2>/dev/null
echo_ret_exit " -- Docker Run : " $?

echo "================================================================================"
$_sudo docker ps -a
echo "================================================================================"
echo " Quick Command"
echo "================================================================================"
echo " - Docker Stop    : docker stop $_nodename"
echo " - Docker Remove  : docker rm -f $_nodename"
echo " - Docker Restart : docker restart $_nodename"
echo " - edit to config : vi $set_data_dir/config.ini ( need to restart )"
echo "================================================================================"
