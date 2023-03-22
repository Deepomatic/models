import os
import tensorflow as tf

# Only activate asserts in unit-tests.
# This allows to use ONNX Cuda graphs
# See https://onnxruntime.ai/docs/execution-providers/CUDA-ExecutionProvider.html#using-cuda-graphs-preview
ASSERT_ACTIVE = os.getenv('ASSERT_ACTIVE') == '1'


class NoOpContext:

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        pass

def assert_control_dependencies(conditions):
    if ASSERT_ACTIVE:
        return tf.control_dependencies(conditions)
    else:
        return NoOpContext()
