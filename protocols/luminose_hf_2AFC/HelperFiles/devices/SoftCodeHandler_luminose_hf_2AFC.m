%% Softcode Handler
function SoftCodeHandler_luminose_hf_2AFC(code)
    if code <= 7
        parfeval(@olfactometer_hf_2AFC, 0, code);
    else
        parfeval(@dmd_hf_2AFC, 0, code);
    end
end