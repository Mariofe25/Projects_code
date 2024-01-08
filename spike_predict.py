#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Thu Aug 11 20:18:26 2022

@author: mariofernandez

Import python packages

"""
import os#, sys
os_path = 'D:/Users/Mario/Cascade-master'
 # if 'Cascade-master' in os.getcwd():
 #     sys.path.append( os.path.abspath('..') ) # add parent directory to path for imports
 #     os.chdir('..')  # change to main directory
 # print('Current working directory: {}'.format( os.getcwd() ))

os.chdir(os_path)
from cascade2p import checks
checks.check_packages()

import numpy as np
import scipy.io as sio
import ruamel.yaml as yaml

from cascade2p import cascade # local folder
from cascade2p.utils import  calculate_noise_levels ##plot_noise_matched_ground_truth

"""
Get the traces paths

"""
path = 'E:/PAC/tseries/no-uncaging/ns_dF_traces/IP3R2ko'
files = [f for f in os.listdir(path) if f.endswith('.mat')]

cascade.download_model( 'update_models',verbose = 1)

yaml_file = open('Pretrained_models/available_models.yaml')
X = yaml.load(yaml_file, Loader=yaml.Loader)
list_of_models = list(X.keys())

frame_rate = 10 # in Hz

for file in files:  
    print("Spike prediction for dF_traces of " + file.replace('_dF_traces.mat',''))
    traces = sio.loadmat(os.path.join(path,file))['dF_traces']
    traces = traces[:,30:-30:]
    
    print('Number of neurons in dataset:', traces.shape[0])
    print('Number of timepoints in dataset:', traces.shape[1])
    
    noise_levels = calculate_noise_levels(traces,frame_rate)
    
    
    model_name = 'Global_EXC_10Hz_smoothing50ms_causalkernel'
    cascade.download_model( model_name,verbose = 1)
    spike_prob = cascade.predict( model_name, traces)
     
    folder = "E:/PAC/tseries/no-uncaging/spike_predicitions/IP3R2ko"
    save_path = os.path.join(folder, 'full_prediction_'+ os.path.basename(file))
    sio.savemat(save_path, {'spike_prob':spike_prob})

print('Done!')



