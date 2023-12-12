ARG UBUNTU_VERSION=22.04
ARG CUDA=11.8.0
ARG CUDNN=8
ARG ARCH=

FROM nvidia/cuda${ARCH:+-$ARCH}:${CUDA}-cudnn${CUDNN}-runtime-ubuntu${UBUNTU_VERSION} as base

RUN rm /etc/apt/sources.list.d/*

# See http://bugs.python.org/issue19846
ENV LANG C.UTF-8

RUN apt update && \
    apt install -y --no-install-recommends \
        software-properties-common \
        ca-certificates \
        git \
        wget \
        curl \
        tar \
        unzip \
        locales && \
    apt-get install -y --no-install-recommends \
        python3 \
        python3-pip \
        python3-dev && \
    apt-get install -y --no-install-recommends \
        python3-lxml g++ make && \
    pip --no-cache-dir install --upgrade \
        pip==23.3.1 \
        setuptools \
        wheel && \
    pip install pytest==7.2.1 pip-tools==7.3.0 && \
    rm -rf /var/lib/apt/lists/* /tmp/*

# Install protobuf
RUN cd /tmp && \
    curl -OL https://github.com/google/protobuf/releases/download/v3.19.6/protoc-3.19.6-linux-x86_64.zip && \
    unzip protoc-*.zip -d protoc && \
    mv protoc/bin/* /usr/local/bin/ && \
    mv protoc/include/* /usr/local/include/

ADD ./requirements.txt /tmp/requirements.txt
RUN pip install -r /tmp/requirements.txt
RUN pip install --no-deps lvis==0.5.3  # lvis is unmaintened, we should remove it from dependencies

ADD . /app
WORKDIR /app/research

RUN cd slim && \
    python3 setup.py sdist && \
    pip install dist/slim-0.1.tar.gz

FROM base

RUN protoc object_detection/protos/*.proto --python_out=. 

RUN rm object_detection/metrics/lvis_evaluation_test.py object_detection/metrics/lvis_tools_test.py

# This test fails if included in the rest of the test: not sure why.
# Running it separately still works
RUN py.test object_detection/dataset_tools/create_pascal_tf_record_test.py && \
    py.test object_detection/model_lib_tf2_test.py 

# object_detection/builders/model_builder_test.py : this is a base test file, it should be ignored (it is used in model_builder_tfX_test.py)
RUN py.test object_detection --ignore=object_detection/builders/model_builder_test.py --ignore=object_detection/metrics/lvis_evaluation_test.py --ignore=object_detection/metrics/lvis_tools_test.py --ignore=object_detection/metrics/oid_vrd_challenge_evaluation_utils_test.py --ignore=object_detection/dataset_tools/create_pascal_tf_record_test.py --ignore=object_detection/model_lib_tf2_test.py
