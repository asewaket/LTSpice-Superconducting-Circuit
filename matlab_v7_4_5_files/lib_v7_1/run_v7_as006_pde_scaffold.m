%RUN_V7_AS006_PDE_SCAFFOLD Backward-compatible AS006 v7.1 entry point.
%
% The main workflow is now device-general. This script is intentionally kept
% so older notes and commands that run `run_v7_as006_pde_scaffold` still work.

clear;
clc;

run_v71_device_pde_scaffold('AS006');
