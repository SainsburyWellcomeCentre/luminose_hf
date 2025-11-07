%% Softcode Handler
function SoftCodeHandler_luminose_hf_sleep(code)
    if code <= 7
        parfeval(@odours_olfactometer_goNogo, 0, code);
    else
        parfeval(@patterns_dmd_goNogo, 0, code);
    end
end