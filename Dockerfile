FROM tensorflow/tensorflow:1.15.0-py3 as base

RUN apt update && \
    apt install -y --no-install-recommends git unzip tar g++ make python3 python3-dev python3-pip && \
    pip3 install pytest==4.6.4 \
                 contextlib2==0.5.5 \
                 lxml==4.3.4 \
                 pandas==0.24.2 \
                 scipy==1.2.2 \
                 Pillow>=1.0 \
                 Matplotlib>=2.1 \
                 Cython>=0.28.1

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
    pip3 install dist/pycocotools-2.0.tar.gz


ADD research /app
WORKDIR /app

RUN protoc object_detection/protos/*.proto --python_out=. && \
    cd slim && \
    python setup.py sdist && \
    pip3 install dist/slim-0.1.tar.gz

# Do not use --ignore pytest flag: it will make tests crash. Instead, we remove unwanted files
RUN py.test object_detection/dataset_tools/create_pascal_tf_record_test.py && \
    rm object_detection/dataset_tools/create_pascal_tf_record_test.py && \
    rm object_detection/builders/dataset_builder_test.py && \
    rm object_detection/inference/detection_inference_test.py && \
    rm object_detection/models/ssd_resnet_v1_fpn_feature_extractor_test.py

FROM base

RUN py.test object_detection
