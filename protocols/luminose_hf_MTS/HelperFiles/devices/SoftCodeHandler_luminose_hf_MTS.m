%% Softcode Handler
function SoftCodeHandler_luminose_hf_MTS(code)
    if code <= 7
        parfeval(@olfactometer_hf_MTS, 0, code);
    else
        dmd_hf_MTS(code);  % synchronous — libisloaded fails on thread workers
    end
end
