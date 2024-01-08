# -*- coding: utf-8 -*-
"""
Created on Sun Oct 29 21:35:32 2023

@author: mariofer
"""
import os
import numpy as np
import torch
import skimage.io as skio
os_path = 'D:/Users/Mario/SUPPORT'

os.chdir(os_path)


from model.SUPPORT import SUPPORT
from src.utils.dataset import DatasetSUPPORT_test_stitch
from src.test import validate

  # dir_path  = "D:/Users/Mario/Data/Ca_ast"
  # model_file = "D:/Users/Mario/SUPPORT/results/saved_models/TrainCaAST_bp_100/model_99.pth"
  # output_path = "D:/Users/Mario/Data/Denoised"

def denoise_calcium(noise_path,model_path,output_path):
    noisy_files = [os.path.join(root, file) for root, dirs, files in os.walk(noise_path) for file in files]
    #file_names = [os.path.basename(path) for path in noisy_files]
    patch_size = [61, 128, 128]
    patch_interval = [1, 64, 64]
    batch_size = 16
    bs_size = 1
    
    model = SUPPORT(in_channels=61, mid_channels=[32, 64, 128, 256, 512], depth=5,
                    blind_conv_channels=64, one_by_one_channels=[32, 16], \
                        last_layer_channels=[64, 32, 16], bs_size=bs_size, bp=True).cuda()
    
    model.load_state_dict(torch.load(model_path))
    
    
    
    for noisy_file in noisy_files:
        demo_tif = torch.from_numpy(skio.imread(noisy_file).astype(np.float32)).type(torch.FloatTensor)
        demo_tif = demo_tif[:, :, :]
        
        print("Denoising " + os.path.basename(noisy_file))
    
        testset = DatasetSUPPORT_test_stitch(demo_tif, patch_size=patch_size,
                                         patch_interval=patch_interval)
        testloader = torch.utils.data.DataLoader(testset, batch_size=batch_size)
        denoised_stack = validate(testloader, model)
    
        # Convert the  float32 array to uint16 
        normalized_data = (denoised_stack - np.min(denoised_stack)) / \
        (np.max(denoised_stack) - np.min(denoised_stack))
        max_uint16 = np.iinfo(np.uint16).max
        data = (normalized_data * max_uint16).astype(np.uint16)
    
        # Save
        output_file = os.path.join(output_path,'Denoised_' + os.path.basename(noisy_file))
        skio.imsave(output_file, data[:, :, :], metadata={'axes': 'TYX'})
