#!/bin/bash
_release="__DOCKER_RELEASE__"
snapshot_url="__SNAPSHOT_URL__"
node_name="__PRODUCER_NAME__"
data_dir="__PREFIX__"


if [ $# -lt 1 ]; then
  echo "Usage : $0 [start|stop|snapshot_recovery|remove]"]
  exit 1
fi

_sub_cmd=$(echo $1 | tr '[:upper:]' '[:lower:]')

snapshot_recovery() {
    mkdir -p ${data_dir}/data/snapshots/
    #sudo wget $snapshot_url -O snapshot-latest.tar.gz
    #tar xvfz ${data_dir}/snapshot-latest.tar.gz --directory=${data_dir}/data/snapshots/
    _snapshot=$(basename $(ls -t ${data_dir}/data/snapshots/snapshot*.bin | head -n 1))
    if [ -f ${data_dir}/data/snapshots/$_snapshot ]; then
      rm -f ${data_dir}/data/state/*
      rm -f ${data_dir}/data/blocks/reversible/*
      sudo docker run --ulimit nofile=90000:90000 -d --name $node_name -v ${data_dir}:/opt/eosio/bin/data-dir --network=host mrmsm/eos_docker:${_release} /opt/eosio/bin/data-dir/run.sh --snapshot /opt/eosio/bin/data-dir/data/snapshots/${_snapshot}
    else
      echo "## Snapshot file not exists. Please check snapshot directory or snapshot download url"
    fi
}


case $_sub_cmd in
    start)
	sudo docker run --ulimit nofile=90000:90000 -d --name $node_name -v ${data_dir}:/opt/eosio/bin/data-dir --network=host mrmsm/eos_docker:${_release} /opt/eosio/bin/data-dir/run.sh
	;;
    stop)
	sudo docker stop -t 10000 ${node_name}
	;;
    snapshot_recovery)
	snapshot_recovery
	;;
    remove)
	sudo docker stop -t 10000 ${node_name}
	sudo docker rm -f ${node_name}
	;;
    *)
        echo "Usage : $0 [start|stop|snapshot_recovery|remove]"]
	;;

esac


