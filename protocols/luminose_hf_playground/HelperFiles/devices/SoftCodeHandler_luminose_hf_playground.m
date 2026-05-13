function SoftCodeHandler_luminose_hf_playground(code)
    fprintf('SoftCode received: %d\n', code);
    if code <= 7
        parfeval(backgroundPool, @olfactometer_hf_playground, 0, code);
    else
        dmd_hf_playground(code);
    end
end
