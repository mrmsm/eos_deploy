#!/bin/bash
remote_api="http://api.eoseoul.io"
local_api="http://localhost:__HTTP_PORT__"
old_val=0;
sleep_time=5;
while true; do
  HIST=$(curl -s http://${local_api}/v1/chain/get_info | jq .head_block_num);
  FULL=$(curl -s ${remote_api}/v1/chain/get_info | jq .head_block_num);
  SYNC_VAL=$(echo $FULL - $HIST | bc);
  DIFF_VAL=$(echo $old_val - $SYNC_VAL | bc);
  old_val=$SYNC_VAL;
  clear
  echo "
  Data : $(date)
  Delay : $sleep_time sec
  Local  host  : $HIST
  Remote Host  : $FULL
  SYNC WAIT : $SYNC_VAL
   > DIFF LAST CHECK : $DIFF_VAL
  ";
  sleep $sleep_time;
done
