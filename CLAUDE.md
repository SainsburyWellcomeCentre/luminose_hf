# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

MATLAB codebase for head-fixed mouse behavioural experiments combining Bpod task control, DMD-based patterned optogenetic stimulation, NI-DAQ odour delivery, and optional Bonsai video acquisition.

## Running experiments

All entry points are MATLAB functions launched from within the Bpod GUI:

```matlab
% 1. Start Bpod (with appropriate COM port)
Bpod('COM3')

% 2. Select a protocol from the Bpod GUI
% Available protocols: luminose_hf_goNogo, luminose_hf_2AFC,
%                      luminose_hf_playground, luminose_hf_sleep
```

## Hardware testing

```matlab
% Test DMD pattern generation and BMP export
luminose = LuminoseConstants();
dmdModel = DMDmodel(luminose.dmd);
img_stack = dmdModel.generate_pattern(patterns.test);
dmdModel.save_images(img_stack, "path/to/testimages");

% Test olfactometer
% Run: olfactometer/test_olfactometer.m
```

## Configuration

All rig-specific settings live in `luminose_config.yaml`. Required top-level sections: `paths`, `bpod`, `olfactometer`, `dmd`, `bonsai`. `LuminoseConstants` validates these on construction and also adds key folders to the MATLAB path.

The hardcoded default config path in `LuminoseConstants.m:36` is `C:\Users\harrislab\luminose_hf\luminose_config.yaml` — update this when deploying to a different rig.

## Architecture

### Configuration layer
- `LuminoseConstants.m` — handle class; loads `luminose_config.yaml`, resolves paths, exposes `.f`, `.bpod`, `.olfactometer`, `.dmd`, `.bonsai` structs. Always instantiate this as `luminose = LuminoseConstants()` at the top of a protocol.

### Hardware models
- `olfactometer/OlfactometerModel.m` — manages NI-DAQ sessions, generates per-odour valve timing matrices, and sequences delivery. Constructed with `OlfactometerModel(luminose.olfactometer, triggered)`.
- `dmd/DMDmodel.m` (external: `DMDController`) — wraps the DMD hardware; `generate_pattern()` builds image stacks, `save_images()` writes deduplicated BMPs, `pre_stored_pattern()` / `start_pattern()` stream sequences to the device. **DMD integration in protocols is not yet implemented** — the handler files (`dmd_hf_*.m`), GUI params, and soft code routing are scaffolded but not operational.

### Protocol structure

Each protocol under `protocols/` follows the same layout:

```
protocols/luminose_hf_<name>/
  luminose_hf_<name>.m          # Entry point: init → GUI → trial loop
  HelperFiles/
    devices/
      dmd_hf_<name>.m           # SoftCode handler for DMD sequences
      olfactometer_hf_<name>.m  # SoftCode handler for odour delivery
    gui/
      GUIparams_hf_<name>.m     # Declares S.GUI.* defaults and S.GUIMeta.* metadata
      LuminoseParameterGUI_hf_<name>.m  # Renders and syncs the parameter GUI
    plots/
      live*.m                   # Per-trial live plot updates
    trials/
      getNextTrialType_hf_<name>.m  # Trial selection with optional bias correction
      computeBias_hf_<name>.m       # Computes lick/response bias over recent trials
```

The trial loop pattern is consistent across protocols: `getNextTrialType` → build Bpod state machine → `SendStateMachine` / `RunStateMachine` → update custom data fields → update live plots → repeat.

### Shared GUI utilities (`gui/`)
Reusable widgets used by the playground parameter screen and other protocols:
- `DrawTrialStructure.m` — renders cue/stim/response/ITI timeline
- `DrawOptoStim.m` — previews single-pulse or paired-pulse optogenetic timing
- `OdourBottleClicked.m`, `generateBottleImage.m`, `getOdourMapping.m` — odour bottle selector controls
- `StartButtonPressed.m` — locks GUI controls and sets the `StartPressed` appdata flag

### Global variables
Protocols use MATLAB globals: `BpodSystem` (Bpod), `S` (GUI parameter struct), `luminose` (LuminoseConstants instance), `olfModel` (OlfactometerModel instance).

## Conventions

- Use `luminose = LuminoseConstants()` rather than hardcoded paths anywhere in protocol code.
- Hardware-specific logic belongs in model classes or `HelperFiles/devices/`, not in the main protocol script.
- Protocol-specific GUI defaults go in the protocol's `GUIparams_*.m`; shared GUI widgets go in the top-level `gui/`.
- Soft codes ≤ 7 route to the olfactometer handler; codes ≥ 8 are reserved for DMD (not yet active). The DMD handler files use a lazy-rebuild pattern (`ensureIndexedSequence`) where sequences are only recreated when parameters change.
- Olfactometer valve numbering: back odour valves are channels 3–8 and 11–16; clean air valves are 1, 2, 9, 10.
