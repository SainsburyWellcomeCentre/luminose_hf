%% Softcode Handler
function SoftCodeHandler_luminose_hf_2AFC(code)
    if code <= 7
        parfeval(@odours_olfactometer_2AFC, 0, code);
    else
        parfeval(@patterns_dmd_2AFC, 0, code);
    end
end