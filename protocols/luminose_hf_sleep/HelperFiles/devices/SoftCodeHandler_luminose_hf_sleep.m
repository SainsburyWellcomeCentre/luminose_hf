%% Softcode Handler
function SoftCodeHandler_luminose_hf_sleep(code)
    parfeval(@dmd_hf_sleep, 0, code);
end