FROM tensorflow/tensorflow:1.12.0-devel as base

RUN pip install pytest==4.6.4 contextlib2==0.5.5 lxml==4.3.4

# Install protobuf
RUN cd /tmp && \
    curl -OL https://github.com/google/protobuf/releases/download/v3.5.1/protoc-3.5.1-linux-x86_64.zip && \
    unzip protoc-3.5.1-linux-x86_64.zip -d protoc3 && \
    mv protoc3/bin/* /usr/local/bin/ && \
    mv protoc3/include/* /usr/local/include/

# Install PyCOCO tools
RUN cd /tmp && \
    git clone https://github.com/Deepomatic/cocoapi.git && \
    cd cocoapi/PythonAPI && \
    git checkout c03543f50d75a4a33b05e364c3e6c392e9d08f88 && \
    mv ../common ./ && \
    sed "s/\.\.\/common/common/g" setup.py > setup.py.updated && \
    cp -f setup.py.updated setup.py && \
    rm setup.py.updated && \
    sed "s/\.\.\/common/common/g" pycocotools/_mask.pyx > _mask.pyx.updated && \
    cp -f _mask.pyx.updated pycocotools/_mask.pyx && \
    rm _mask.pyx.updated && \
    cd ../.. && \
    rm -rf dist && \
    mkdir -p dist && \
    tar -czf dist/pycocotools-2.0.tar.gz -C cocoapi/ PythonAPI/ && \
    pip install dist/pycocotools-2.0.tar.gz


ADD research /app
WORKDIR /app

RUN protoc object_detection/protos/*.proto --python_out=. && \
    cd slim && \
    python setup.py sdist && \
    pip install dist/slim-0.1.tar.gz

# Do not use --ignore pytest flag: it will make tests crash. Instead, we remove unwanted files
RUN py.test object_detection/dataset_tools/create_pascal_tf_record_test.py && \
    rm object_detection/dataset_tools/create_pascal_tf_record_test.py && \
    rm object_detection/builders/dataset_builder_test.py && \
    rm object_detection/inference/detection_inference_test.py && \
    rm object_detection/models/ssd_resnet_v1_fpn_feature_extractor_test.py

FROM base

RUN py.test object_detection
