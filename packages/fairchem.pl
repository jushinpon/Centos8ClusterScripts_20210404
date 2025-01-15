=b
https://pytorch.org/get-started/locally/
https://fair-chem.github.io/core/install.html

conda install mamba -n base -c conda-forge

建環境
wget https://raw.githubusercontent.com/FAIR-Chem/fairchem/main/packages/env.cpu.yml
conda env create -f env.cpu.yml

conda activate fair-chem

#win系統 cpu 版 no CUDA:
1.安裝pytorch
pip3 install torch==2.4.0 torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu

2.
#安裝fairchem-core

pip install fairchem-core

pip install torch_geometric

pip install pyg_lib torch_scatter torch_sparse torch_cluster torch_spline_conv -f https://data.pyg.org/whl/torch-2.4.0+cpu.html





#----------------------------------------------------------
#簡單測試:
import torch
x = torch.rand(5, 3)
print(x)
#-------------------------------------------------------------
from fairchem.core.models.model_registry import available_pretrained_models
print(available_pretrained_models)
#-------------------------------------------------------------
=cut
use warnings;
use strict;
use Cwd; #Find Current Path


