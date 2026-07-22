function olfactometer_hf_MTS(odour_valves, duty_cycles, olfConstants)
% olfactometer_hf_MTS  Runs on a dedicated persistent parfeval worker (see
% luminose_hf_MTS.m's pool warm-up). odour_valves/duty_cycles are resolved
% and passed in by SoftCodeHandler_luminose_hf_MTS.m in the client process;
% this function only performs the blocking hardware call. olfModel is
% intentionally worker-local and lazily created once, then reused for the
% rest of the session by every call that lands on this same worker.

    global olfModel

    logFile = fullfile(fileparts(mfilename('fullpath')), 'olfactometer_hf_MTS_log.txt');

    try

    if isempty(olfModel)
        olfModel = OlfactometerModel(olfConstants, true);
    end

    if isempty(odour_valves)
        return; % warm-up call: only used to lazily create olfModel above
    end

    if duty_cycles == 0
        duty_cycles = olfModel.get_odour_dutycycles(odour_valves);
    end
    olfModel.play_valve_sequence(odour_valves, duty_cycles);

    catch ME
        olf_log(logFile, 'ERROR valves=%s: %s  at %s line %d', ...
            mat2str(odour_valves), ME.message, ME.stack(1).name, ME.stack(1).line);
    end
end

function olf_log(logFile, fmt, varargin)
    fid = fopen(logFile, 'a');
    if fid < 0, return; end
    fprintf(fid, '[%s] ', datestr(now, 'HH:MM:SS'));
    fprintf(fid, fmt, varargin{:});
    fprintf(fid, '\n');
    fclose(fid);
end
