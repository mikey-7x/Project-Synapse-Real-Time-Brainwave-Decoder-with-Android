from setuptools import setup, find_packages

setup(
    name="abd57",
    version="1.0.0",
    author="Yogesh R. Chauhan",
    description="Project Synapse: Real-Time Brainwave Decoder using EEG, TensorFlow, Arduino & Android",
    long_description=open("README.md").read(),
    long_description_content_type="text/markdown",
    url="https://github.com/mikey-7x/Project-Synapse",
    packages=find_packages(),
    install_requires=[
        "numpy==1.24.3",
        "pandas",
        "scipy",
        "joblib",
        "scikit-learn",
        "tensorflow==2.13.1",
    ],
    classifiers=[
        "Programming Language :: Python :: 3",
        "License :: Other/Proprietary License",
        "Operating System :: OS Independent",
    ],
    python_requires='>=3.10',
)
