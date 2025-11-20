%clear space
clc;clear;
addpath('/Users/wuxiaoyan/Downloads/spm12-main/');
% addpath('C:\Users\xiaoywu\Downloads\spm_25.01.02\spm');
% load data
path = pwd;
load('data.mat');

% setup parameter structures
load('ModelList.mat');

% model fitting
NumMoltiiStart = 200;
NumMaxTry = 500;
core = 24;
p = parpool(core);
for m = 1:length(ModelList)
    model = ModelList(m).model;
    param = ModelList(m).param;
    results(m) = optimizeParallelVersionNew(model,param,data,NumMoltiiStart,NumMaxTry);
    disp(['Model:',num2str(m)]);
end
delete(p);

modelnames = {'M0: Baseline','M1: RL','M2: GPR','M3: RL+GPR'};
for m = 1:length(results)
    results(m).ModelName = modelnames(m);
end

results = ForModelComparison(results);
save('results.mat','results');

% figure for model comparison
figure;
detaAICc = [results.mean_detaAICc];
% colors =[0.796078431372549,0.090196078431373,0.541176470588235];
colors = '#7570b3';
bar(detaAICc,'FaceColor',colors,'EdgeColor','none','BarWidth',0.5);
box off
xticklabels(modelnames);
xtickangle(45);
ylabel('△AICc');
