#!/usr/bin/env bash

set -x

SCRIPT_DIR=$(cd $(dirname ${BASH_SOURCE[0]}); pwd)
#touch /app/jupyter.log
#not working
#cd /app && source venv/bin/activate && jupyter notebook --port 8084 > /dev/null 2>&1 | tee -a /app/jupyter.log &
cd /app && source venv/bin/activate && jupyter notebook --port 8084 &
cd /app && source venv/bin/activate && sleep 10  && jupyter notebook list > notebook_list.txt

sleep 10

cd /


python  -m SimpleHTTPServer 8080 || python3.9 -m http.server 8080
