%% Softcode Handler
function SoftCodeHandler_luminose_hf_goNogo(code)
    if code <= 7
        parfeval(@olfactometer_hf_goNogo, 0, code);
    else
        dmd_hf_goNogo(code);  % synchronous — libisloaded fails on thread workers
    end
end