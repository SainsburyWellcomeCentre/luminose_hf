% once and for all: status  int32 The error code returned by the function in
% the event of an error or warning. A value of 0 indicates success. A positive
% value indicates a warning. A negative value indicates an error.

clear all
close all
clear global
if ~libisloaded('nicaiu') % checks if library is loaded
    hfile = ['C:\Programme\National Instruments\NI-DAQ\DAQmx ANSI C Dev\include\NIDAQmx.h'];
    loadlibrary('nicaiu.dll', hfile, 'mfilename', 'mxproto')
    % mxproto contains the function prototypes
end

% required constants (see NIDAQmx.h)
% Terminal Configuration
DAQmx_Val_Cfg_Default=int32(-1);        %%Default
DAQmx_Val_RSE=int32(10083);             %%RSE
DAQmx_Val_NRSE=int32(10078);            %%NRSE
DAQmx_Val_Diff=int32(10106);            %%Differential
DAQmx_Val_PseudoDiff=int32(12529);      %%Pseudodifferential
% Units
DAQmx_Val_Volts=int32(10348);           %%Volts
DAQmx_Val_FromCustomScale=int32(10065); %%From Custom Scale
% Active Edge
DAQmx_Val_Rising=int32(10280);          %%Rising
DAQmx_Val_Falling=int32(10171);         %%Falling
% Sample Mode
DAQmx_Val_FiniteSamps=int32(10178);     %%Finite Samples
DAQmx_Val_ContSamps=int32(10123);       %%Continuous Samples
DAQmx_Val_HWTimedSinglePoint=int32(12522);%%Hardware Timed Single Point
% Fill Mode
DAQmx_Val_GroupByChannel=uint32(0);     %%Group by Channel
DAQmx_Val_GroupByScanNumber=uint32(1);  %%Group by Scan Number

% either load task already created using Measurement & Automation Explorer (MAX)
% or create new task
TaskLoad=0;
if TaskLoad
    taskh1=libpointer('uint32Ptr',0);
    [a,b,c]=calllib('nicaiu','DAQmxLoadTask','VoltageTask',taskh1);
    %%[int32, string, uint32Ptr] DAQmxLoadTask(string, uint32Ptr)
    %%int32 DAQmxLoadTask (const char taskName[], TaskHandle *taskHandle);
else
    taskh1=libpointer('uint32Ptr',0);
    taskname='SampleTask';
    [a,b,taskh1] = calllib('nicaiu','DAQmxCreateTask',taskname,taskh1); % erzeuge Task taskh1
    %%[int32, string, uint32Ptr] DAQmxCreateTask(string, uint32Ptr)
    %%int32 DAQmxCreateTask (const char taskName[], TaskHandle
    %%*taskHandle);
    taskh1=libpointer('uint32Ptr',taskh1);

    minVal=double(-5);maxVal=double(5);
    [a,b,c,d] = calllib('nicaiu','DAQmxCreateAIVoltageChan',get(taskh1,'Value'),...
        'Dev1/ai0','ai0_an_6221',DAQmx_Val_Diff,minVal,maxVal,DAQmx_Val_Volts,'');
    %%[int32, string, string, string] DAQmxCreateAIVoltageChan(uint32, string,
    %%      string, int32, double, double, int32, string)
    %%int32 DAQmxCreateAIVoltageChan (TaskHandle taskHandle, const char
    %%      physicalChannel[], const char nameToAssignToChannel[], 
    %%      int32 terminalConfig, float64 minVal, float64 maxVal, int32 units, 
    %%      const char customScaleName[]);
end

rate=double(1000);activeEdge=DAQmx_Val_Rising;
sampleMode=DAQmx_Val_FiniteSamps;
SamplesToAcquire=uint64(1000);
[a,b]=calllib('nicaiu','DAQmxCfgSampClkTiming',get(taskh1,'Value'),'OnboardClock',...
    rate,activeEdge,sampleMode,SamplesToAcquire);
%%[int32, string] DAQmxCfgSampClkTiming(uint32, string, double, int32, int32, uint64)
%%int32 DAQmxCfgSampClkTiming (TaskHandle taskHandle, const char source[], 
%%      float64 rate, int32 activeEdge, int32 sampleMode, uInt64 sampsPerChanToAcquire);

a=calllib('nicaiu','DAQmxStartTask',get(taskh1,'Value'));
%%int32 DAQmxStartTask(uint32)
%%int32 DAQmxStartTask (TaskHandle taskHandle);

fillMode=DAQmx_Val_GroupByChannel;
bufferSize=uint32(1000);
data=zeros(1000,1);
timeout=-1; %double(10.0); % maximum waiting time before timeout (in secs)
dataptr = libpointer('doublePtr',zeros(1000,1));
read=libpointer('int32Ptr',0);
reserved=libpointer('uint32Ptr',[]);
[a,b,c,d]=calllib('nicaiu','DAQmxReadAnalogF64',get(taskh1,'Value'),int32(1000),...
    timeout,fillMode,dataptr,uint32(1000),...
    read,reserved);
%%[int32, doublePtr, int32Ptr, uint32Ptr] DAQmxReadAnalogF64(uint32, int32,...
%%      double, uint32, doublePtr, uint32,
%%      int32Ptr, uint32Ptr)
%%int32 DAQmxReadAnalogF64 (TaskHandle taskHandle, int32 numSampsPerChan,
%%      float64 timeout, bool32 fillMode, float64 readArray[], uInt32 arraySizeInSamps,
%%      int32 *sampsPerChanRead, bool32 *reserved);

a=calllib('nicaiu','DAQmxStopTask',get(taskh1,'Value'));
%%int32 DAQmxStopTask(uint32)
%%int32 DAQmxStopTask (TaskHandle taskHandle);

a=calllib('nicaiu','DAQmxClearTask',get(taskh1,'Value'));
%%int32 DAQmxClearTask(uint32)
%%int32 DAQmxClearTask (TaskHandle taskHandle);

%unloadlibrary 'nicaiu'; % unload library

% plot data
figure
plot(b);