# luminose_hf
### Codebase for head-fixed mouse behaviour with patterned optogenetics and odour delivery.

## Installation:
Make sure you have installed [git](https://git-scm.com/downloads). Requires [MATLAB](https://uk.mathworks.com/help/install/ug/install-products-with-internet-connection.html) with the following add-ons found in the add-on explorer:
1. [Data Acquisition Toolbox](https://uk.mathworks.com/help/daq/index.html?s_tid=CRUX_lftnav) for olfactometer control
2. [Signal Processing Toolbox](https://uk.mathworks.com/help/signal/index.html?s_tid=srchtitle_support_results_1_signal%2520processing%2520toolbox)
3. [DSP System Toolbox](https://uk.mathworks.com/help/dsp/index.html?s_tid=srchtitle_support_results_1_dsp%2520system%2520toolbox)
4. [Image Processing Toolbox](https://uk.mathworks.com/help/images/index.html?s_tid=srchtitle_support_results_1_image%2520processing%2520toolbox)
   
### Dependencies:
1. [Bpod_gen2](https://github.com/sanworks/Bpod_Gen2)
2. [DMDController](https://github.com/SainsburyWellcomeCentre/DMDController) for DMD control
5. [Bonsai](https://bonsai-rx.org/docs/articles/installation.html) for synchronized camera acquisition with [PointGrey](https://bonsai-rx.org/pointgrey/index.html), [Scripting.Expressions](https://bonsai-rx.org/docs/api/Bonsai.Scripting.Expressions.html), [Reactive](https://bonsai-rx.org/docs/api/Bonsai.Reactive.html), [Dsp](https://bonsai-rx.org/docs/api/Bonsai.Dsp.html), [Vision](https://bonsai-rx.org/docs/api/Bonsai.Vision.html) packages installed.  

### Instructions:
1. Install all dependencies to a parent directory in your local system.
2. Clone this repository:
   ```
   cd <parent directory>
   git clone https://github.com/SainsburyWellcomeCentre/luminose.git
   ```
3. Add all folders and sub-folders of parent directory to MATLAB path.

## Usage:
1. Edit config file in luminose_hf/luminose_config.yml with correct constants
2. Launch Bpod
   ```
   Bpod(<COM#>)
   ```
3. Launch desired protocol on Bpod GUI.
## Notes:
1. Protocols require the Bpod Hifi module for sound and rotary encoder module for treadmill movement.
