%% 
clc
clear all
close all

%%
connStr = 'USB0::0xF4ED::0xEE3A::SDS1EDEC5R1189::INSTR';
channel = 1;
[vDiv, tDiv, offs, sCount, sRate] = determineAcquisitionSettings(connStr, channel);