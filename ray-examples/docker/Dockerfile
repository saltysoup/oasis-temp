FROM raycluster:ray2.48.0-py3.12.11-cu12.6 

# additional binaries for rdma
RUN sudo apt update -y && sudo apt upgrade -y && sudo apt install libnl-3-200 libnl-route-3-200 -y

RUN pip install torch>=2.7.1 torchvision>=0.22.1 torchaudio>=2.7.1
