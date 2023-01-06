FROM tensorflow/tensorflow:2.3.2-gpu as base

RUN rm /etc/apt/sources.list.d/cuda.list
RUN rm /etc/apt/sources.list.d/nvidia-ml.list

RUN apt update && \
    apt install -y --no-install-recommends software-properties-common ca-certificates git wget curl tar locales libgl1-mesa-glx && \
    pip install pip --upgrade && \
    pip install pytest==4.6.4 contextlib2==0.5.5 lxml==4.3.4 cython==0.29.22 && \
    rm -rf /var/lib/apt/lists/* /tmp/*

# Install protobuf
RUN cd /tmp && \
    curl -OL https://github.com/google/protobuf/releases/download/v3.5.1/protoc-3.5.1-linux-x86_64.zip && \
    unzip protoc-3.5.1-linux-x86_64.zip -d protoc3 && \
    mv protoc3/bin/* /usr/local/bin/ && \
    mv protoc3/include/* /usr/local/include/

# Install PyCOCO tools
RUN cd /tmp && \
    git clone https://github.com/cocodataset/cocoapi.git && \
    cd cocoapi/PythonAPI && \
    mv ../common ./ && \
    sed "s/\.\.\/common/common/g" setup.py > setup.py.updated && \
    cp -f setup.py.updated setup.py && \
    rm setup.py.updated && \
    sed "s/\.\.\/common/common/g" pycocotools/_mask.pyx > _mask.pyx.updated && \
    cp -f _mask.pyx.updated pycocotools/_mask.pyx && \
    rm _mask.pyx.updated && \
    sed "s/import matplotlib\.pyplot as plt/import matplotlib\nmatplotlib\.use\(\'Agg\'\)\nimport matplotlib\.pyplot as plt/g" pycocotools/coco.py > coco.py.updated && \
    cp -f coco.py.updated pycocotools/coco.py && \
    rm coco.py.updated && \
    cd ../.. && \
    rm -rf dist && \
    mkdir -p dist && \
    tar -czf dist/pycocotools-2.0.tar.gz -C cocoapi/ PythonAPI/ && \
    pip install dist/pycocotools-2.0.tar.gz


ADD ./requirements.txt /tmp/requirements.txt
RUN pip install -r /tmp/requirements.txt
RUN pip install --no-deps tf-models-official==2.4.0  # this would install tf 2.4

ADD research /app
WORKDIR /app

RUN protoc object_detection/protos/*.proto --python_out=. && \
    cd slim && \
    python setup.py sdist && \
    pip install dist/slim-0.1.tar.gz

## Do not use --ignore pytest flag: it will make tests crash. Instead, we remove unwanted files
# RUN py.test object_detection/dataset_tools/create_pascal_tf_record_test.py && \
#     rm object_detection/dataset_tools/create_pascal_tf_record_test.py

FROM base

# object_detection/builders/model_builder_test.py : this is a base test file, it should be ignored (it is used in model_builder_tfX_test.py)
# RUN py.test object_detection --ignore=object_detection/builders/model_builder_test.py
RUN py.test object_detection/builders/dataset_builder_test.py -k test_read_dataset_unreachable_resource
