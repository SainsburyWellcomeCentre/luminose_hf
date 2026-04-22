%% Softcode Handler
function SoftCodeHandler_luminose_hf_playground(code)
    if code <= 7
        parfeval(@olfactometer_hf_playground, 0, code);
    else
        parfeval(@dmd_hf_playground, 0, code);
    end
end