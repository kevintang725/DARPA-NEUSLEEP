clc;clear all;close all;


addpath(genpath('figures'))
cd figures\

datanum = 4;
cond = [0.7, 0.85, 1, 1.15];
for i = 1:datanum
    filename = append('TensileStress__PEDOTPSS_AMPS_1_',num2str(cond(i)),'.mat');
    a{i} = load(filename,'YModulus');
    bardata{i} = [mean(cell2mat(a{1,i}.YModulus)), std(cell2mat(a{1,i}.YModulus))];
    bchart = bar(i,bardata{1,i}(1)); hold on;
    bchart.FaceColor = [0 0 1];
    er = errorbar(i,bardata{1,i}(1),bardata{1,i}(2),bardata{1,i}(2)); hold on; er.Color = [0 0 0]; hold on;
end

hold off;

save('YModulus_summary.mat',"bardata");
