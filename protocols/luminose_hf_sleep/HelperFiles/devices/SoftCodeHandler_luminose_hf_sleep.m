function SoftCodeHandler_luminose_hf_sleep(code)
    if code == 0, return; end
    parfeval(@dmd_hf_sleep, 0, code);
end