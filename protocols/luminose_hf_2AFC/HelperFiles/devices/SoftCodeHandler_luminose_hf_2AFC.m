%% Softcode Handler
function SoftCodeHandler_luminose_hf_2AFC(code)
    if code <= 7
        parfeval(@olfactometer_hf_2AFC, 0, code);
    else
        dmd_hf_2AFC(code);  % synchronous — libisloaded fails on thread workers
    end
end