#################################Stage 01 as builder ###############################################

FROM centos:centos8 as builder

RUN mkdir /app

# spilt paddlespeech_success.venv.tar.gz  -b 200M
# COPY /pkgs/paddlespeech_success.venv.tar.gz  /app
COPY pkgs/bigfilesample  /app/bigfilesample

RUN cd /app/ && find .


#####################################Main stage build for image ###########################################
FROM centos
#FROM centos:8

RUN cd /etc/yum.repos.d/
RUN sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*
RUN sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*

RUN yum -y install java

# for jupyter notebook
RUN yum install -y sqlite-devel.x86_64

RUN yum install -y which net-tools vim  &&\
    yum  install -y git &&\
    yum install -y wget

RUN yum install make -y &&\
    yum install gcc openssl-devel bzip2-devel libffi-devel zlib-devel -y

RUN set -x && wget https://www.openssl.org/source/openssl-1.1.1g.tar.gz &&\
    tar -xvf openssl-1.1.1g.tar.gz &&\
    cd openssl-1.1.1g &&\
     ./config shared --openssldir=/usr/local/openssl --prefix=/usr/local/openssl && make && make install &&\
    rm -rf ../openssl-1.1.1g.tar.gz

RUN openssl  version > /openssl.version.log


RUN yum install xz-devel -y

RUN set -x && curl https://www.python.org/ftp/python/3.9.1/Python-3.9.1.tgz --output /tmp/Python-3.9.1.tgz &&\
    cd /tmp &&\
    tar xzf Python-3.9.1.tgz  &&\
    cd /tmp/Python-3.9.1   &&\
    ./configure --enable-optimizations  &&\
    make altinstall &&\
    rm -r /tmp/Python-3.9.1.tgz

WORKDIR /tmp
RUN yum -y install epel-release
RUN curl https://bootstrap.pypa.io/get-pip.py --output get-pip.py
RUN python3.9 get-pip.py && python3.9 -m pip install --upgrade pip
RUN set -x &&  echo "virtualenv" > requirements.txt &&\
    echo "boto3==1.15.11" >> requirements.txt &&\
    pip install -r requirements.txt

# check the ssl
RUN python3.9 -c 'import ssl'

RUN mkdir /app

RUN pip3 install virtualenv &&\
    cd /app && virtualenv venv || echo "virtualenv exist"

COPY /script/*.sh  /app

#COPY --from=builder /app/paddle_py_lib /app/venv/paddle
COPY --from=builder /app/bigfilesample/ /app/bigfilesample

RUN set -x && cd /app/bigfilesample && cat x* > bigfilesample.config

COPY requirements.txt /app/jupyter-requirements.txt

RUN set -x  && cd /app && ls -rtla && source venv/bin/activate &&\
    pip3 install -r jupyter-requirements.txt


RUN mkdir -p /app/notebook
RUN mkdir -p /root/.jupyter && touch /root/.jupyter/migrated
#COPY /pkgs/jupyter_notebook_config.json /root/.jupyter
COPY /pkgs/jupyter_notebook_config.py /root/.jupyter



#gcc: error trying to exec 'cc1plus': execvp: No such file or directory
RUN yum install -y gcc-c++


COPY --from=builder /app/bigfilesample /app

COPY requirements.txt /app/

RUN cd /app && source venv/bin/activate && pip3 install paddlepaddle==2.5.1



#https://stackoverflow.com/questions/71027006/assertionerror-inside-of-ensure-local-distutils-when-building-a-pyinstaller-exe
#downgrade to lower version to avoid build issue
RUN cd /app && source venv/bin/activate &&  pip3 install setuptools==59.8.0


#RUN chmod 777 /app/test_script.sh &&  /app/test_script.sh || echo  "fail to gen"

#RUN  source /app/venv/bin/activate && paddlespeech tts --am fastspeech2_canton   --voc hifigan_csmsc  --lang canton  --spk_id 10           --input "大家好啊，北京上海深圳广州程序员很多"                 --output /app/test_voice03.wav                 --use_onnx True

ENV PATH="${PATH}:/usr/local/bin/"

EXPOSE 8015 8080 8083  8084 9000 10000
WORKDIR /

VOLUME ["/app/notebook"]

ENTRYPOINT ["bash", "/app/start_notebook.sh"]
#ENTRYPOINT ["python", "-m", "SimpleHTTPServer", "8080"]
#ENTRYPOINT ["python3.9", "-m", "http.server", "8080"]

# https://docs.docker.com/get-started/publish-your-own-image/
# start localhost:8080
#docker exec -it paddle-vs sh
#http://localhost:8080/app/test_voice02.wav