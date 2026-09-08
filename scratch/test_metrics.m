% test_metrics.m
clc; clear;
m1 = load('D:\SIH-26038\results\baseline_metrics.mat');
disp('Baseline:');
disp(m1.accuracy); disp(m1.macroF1); disp(m1.qwk);

m2 = load('D:\SIH-26038\results\mild_weighted_bestval\mild_weighted_bestval_metrics.mat');
disp('Mild:');
disp(m2.accuracy); disp(m2.macroF1); disp(m2.qwk);

m3 = load('D:\SIH-26038\results\medium_weighted_bestval\medium_weighted_bestval_metrics.mat');
disp('Medium:');
disp(m3.accuracy); disp(m3.macroF1); disp(m3.qwk);

m4 = load('D:\SIH-26038\results\strong_weighted_bestval\strong_weighted_bestval_metrics.mat');
disp('Strong:');
disp(m4.accuracy); disp(m4.macroF1); disp(m4.qwk);
