"""Setup script for object_detection."""
import os
from pkg_resources import parse_requirements
from setuptools import find_packages
from setuptools import setup

with open(os.path.join(os.path.dirname(__file__), '..', 'requirements.in'), 'r') as f:
    requirements = list(map(str, parse_requirements(f)))

setup(
    name='object_detection',
    version='2.13',
    install_requires=requirements,
    include_package_data=True,
    packages=[p for p in find_packages() if p.startswith('object_detection')],
    description='Tensorflow Object Detection Library',
)
