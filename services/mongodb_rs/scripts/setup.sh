#!/bin/bash

mongo1=$(getent hosts mongodb-rs1 | awk '{ print $1 }')
mongo2=$(getent hosts mongodb-rs2 | awk '{ print $1 }')
mongo3=$(getent hosts mongodb-rs3 | awk '{ print $1 }')



echo "Waiting for startup.."
until mongo --host ${mongo1} --eval 'quit(db.runCommand({ ping: 1 }).ok ? 0 : 2)' &>/dev/null; do
  printf '.'
  sleep 1
done

echo
echo "Started.."
sleep 1

setRs() {
  mongo --host ${mongo1} <<EOF
     var cfg = {
        "_id": "rs0",
        "protocolVersion": 1,
        "members": [
            {
              "_id": 0,
              "host": "${mongo1}",
              "priority": 9
            },
            {
              "_id": 1,
              "host": "${mongo2}"
            },
            {
              "_id": 2,
              "host": "${mongo3}"
            }
        ]
    };

    rs.initiate(cfg, {"force": true });
    rs.reconfig(cfg, {"force": true });
EOF
}

while true; do
   $(mongo --host ${mongo1} --eval 'quit(rs.status().ok ? 0 : 2)' &>/dev/null)

  if [ $? -eq 0 ]; then
    echo "Success"
    exit 0
  fi

  echo

  setRs &>/dev/null || (printf "Set up replica set..." && sleep 1)

done
