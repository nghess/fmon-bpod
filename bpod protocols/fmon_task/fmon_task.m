%{
FMON Task Module for Bpod
Preferences (Set variables in Freely Moving Olfactory Navigation Task)

Written By: Nate Gonzales-Hess (nhess@uoregon.edu)
Last Updated: 7/7/2023
%}

function fmon_task
%% Initialize Bpod
global BpodSystem
S = BpodSystem.ProtocolSettings; % Load settings chosen in launch manager into current workspace as a struct called S

%% Start Bonsai
%Clear Bpod TCP Socket
BpodSystem.BonsaiSocket = [];

% Run Bonsai connect Python Script
[~,~] = system('start C:\ProgramData\Anaconda3\python.exe D:\fmon-bpod\connect_gui.py');

% Connect to Bonsai
BpodSystem.BonsaiSocket = TCPCom(11235);

%% Set Timer
% Get duration from GUI, or use default of 40 minutes.
if evalin('base', 'exist(''session_duration'', ''var'')')
    session_duration = evalin('base', 'session_duration');
else
    session_duration = 40;
end
%Initialize session timer.
t = timer;
t.StartDelay = session_duration*60;  % time in seconds
t.TimerFcn = @(~,~)timeUp(session_duration);  % timeUp is defined at end of this file
start(t);

%% Set Reward amounts
% Read variables from workspace, supplied by fmon_prefs GUI.
% If Variables don't exist, set to defaults (.1 seconds)
if evalin('base', 'exist(''LeftValveTime'', ''var'')')
    LeftValveTime = evalin('base', 'LeftValveTime');
else
    LeftValveTime = 0.1;
end

if evalin('base', 'exist(''RightValveTime'', ''var'')')
    RightValveTime = evalin('base', 'RightValveTime');
else
    RightValveTime = 0.1;
end

% Time to wait before lick port out is confirmed
PortOutDelay = .5;

%% Define trials
nLeftTrials = 100;
nRightTrials = 100;
pctOmission = .1;
nOmissionTrials = round((nLeftTrials + nRightTrials) * pctOmission);  % Some percentage of trials are omission trials.
nOmissionDiff = round(0.5 * nOmissionTrials);  % Half of the omission trials, to substract from left and right trials.
TrialTypes = [ones(1, nLeftTrials-nOmissionDiff) ones(1, nRightTrials-nOmissionDiff)*2 ones(1, nOmissionTrials)*3];  % 1 = Left, 2 = Right, 3 = Omission

% Ensure that trial type never repeats more than maxRepeats times
maxRepeats = 3; % maximum repeat limit

% A function to check if any element repeats more than maxRepeats times
checkRepeats = @(v, m) any(conv(double(diff(v) == 0), ones(1, m), 'valid') == m);

% Randomly permute vector until no element repeats more than maxRepeats times
while true
    vec_perm = TrialTypes(randperm(length(TrialTypes)));
    if ~checkRepeats(vec_perm, maxRepeats)
        break
    end
end

assignin('base', 'vec_perm', vec_perm);

TrialTypes = vec_perm;
BpodSystem.Data.TrialTypes = []; % The trial type of each trial completed will be added here.
MaxTrials = length(TrialTypes);%nLeftTrials + nRightTrials + nOmissionTrials;

%% Build ITI list
% Read variables from workspace, supplied by fmon_prefs GUI.
if evalin('base', 'exist(''min_iti'', ''var'')')
    min_iti = evalin('base', 'min_iti');
else
    min_iti = 1;
end

if evalin('base', 'exist(''max_iti'', ''var'')')
    max_iti = evalin('base', 'max_iti');
else
    max_iti = 5;
end
% Build ITI list
iti_list = round((max_iti-min_iti) .* rand(1,length(TrialTypes)) + min_iti);

%% Initialize plots
BpodSystem.ProtocolFigures.OutcomePlotFig = figure('Position', [50 540 1000 250],'name','Outcome plot','numbertitle','off', 'MenuBar', 'none', 'Resize', 'off');
BpodSystem.GUIHandles.OutcomePlot = axes('Position', [.075 .3 .89 .6]);
TrialTypeOutcomePlot(BpodSystem.GUIHandles.OutcomePlot,'init',TrialTypes);
%BpodParameterGUI('init', S); % Initialize parameter GUI plugin

%% Main trial loop
for currentTrial = 1:MaxTrials
    
    % Valve Module serial messages, 1 = Odor, 2 = Omission, 3 = Reset
    LoadSerialMessages('ValveModule1', {['B' 15], ['B' 51], ['B' 0]});  % Left valves
    LoadSerialMessages('ValveModule2', {['B' 15], ['B' 51], ['B' 0]});  % Right valves
    LoadSerialMessages('ValveModule3', {['B' 3], ['B' 0]});  % Final Valves
    
    % Determine trial-specific state matrix fields
    switch TrialTypes(currentTrial)
        case 1
            StateOnInitPoke = 'GoLeft';
            OdorantState = 'OdorLeft';
        case 2
            StateOnInitPoke = 'GoRight'; 
            OdorantState = 'OdorRight';
        case 3
            StateOnInitPoke = 'Omission'; 
            OdorantState = 'OdorOmit';
    end

    % Initialize new state machine description
    sma = NewStateMachine(); 
    
    % State definitions    
    sma = AddState(sma, 'Name', 'Reset', ...
        'Timer', .5,...
        'StateChangeConditions', {'Tup', OdorantState},...
        'OutputActions', {'ValveModule1', 3, 'ValveModule2', 3, 'ValveModule3', 2});  % Reset all valves to 0V
    
    sma = AddState(sma, 'Name', 'OdorLeft', ...
        'Timer', 1,...
        'StateChangeConditions', {'Tup', 'WaitForInitPoke'},...
        'OutputActions', {'ValveModule1', 1, 'ValveModule2', 2});  % Left odor, right omission

    sma = AddState(sma, 'Name', 'OdorRight', ...
        'Timer', 1,...
        'StateChangeConditions', {'Tup', 'WaitForInitPoke'},...
        'OutputActions', {'ValveModule1', 2, 'ValveModule2', 1});  % Left omission, right odor

    sma = AddState(sma, 'Name', 'OdorOmit', ...
        'Timer', 1,...
        'StateChangeConditions', {'Tup', 'WaitForInitPoke'},...
        'OutputActions', {'ValveModule1', 2, 'ValveModule2', 2});  % Bilateral omission

    sma = AddState(sma, 'Name', 'WaitForInitPoke', ...
        'Timer', 0,...
        'StateChangeConditions', {'Port3In', StateOnInitPoke},...  % Wait for initiation port poke
        'OutputActions', {});

    sma = AddState(sma, 'Name', 'GoLeft', ...
        'Timer', 0,...
        'StateChangeConditions', {'SoftCode1', 'CorrectLeft', 'SoftCode3', 'NoReward'},...
        'OutputActions', {'ValveModule3', 1});  % Final valves open
    
    sma = AddState(sma, 'Name', 'GoRight', ...
        'Timer', 0,...
        'StateChangeConditions', {'SoftCode1', 'NoReward', 'SoftCode3', 'CorrectRight'},...
        'OutputActions', {'ValveModule3', 1});  % Final valves open

    sma = AddState(sma, 'Name', 'Omission', ...
        'Timer', 0,...
        'StateChangeConditions', {'SoftCode1', 'NoReward', 'SoftCode3', 'NoReward'},...  % Reward on either side
        'OutputActions', {'ValveModule3', 1});  % Final valves open

    sma = AddState(sma, 'Name', 'CorrectLeft', ...
        'Timer', 0,...
        'StateChangeConditions', {'Port1In', 'LeftReward', 'Port2In', 'NoReward'},...
        'OutputActions', {'ValveModule1', 3, 'ValveModule2', 3, 'ValveModule3', 2});  % On decision, reset all valves

    sma = AddState(sma, 'Name', 'CorrectRight', ...
        'Timer', 0,...
        'StateChangeConditions', {'Port1In', 'NoReward', 'Port2In', 'RightReward'},...
        'OutputActions', {'ValveModule1', 3, 'ValveModule2', 3, 'ValveModule3', 2});  % On decision, reset all valves

    sma = AddState(sma, 'Name', 'NoReward', ... 
        'Timer', 0,...
        'StateChangeConditions', {'Port1In', 'ITI', 'Port2In', 'ITI', 'Port3In', 'ITI'},...
        'OutputActions', {'ValveModule1', 3, 'ValveModule2', 3, 'ValveModule3', 2}); % On decision, reset all valves
    
    sma = AddState(sma, 'Name', 'LeftReward', ...
        'Timer', LeftValveTime,...
        'StateChangeConditions', {'Tup', 'Drinking'},...
        'OutputActions', {'ValveState', 1});  % On left poke give water
    
    sma = AddState(sma, 'Name', 'RightReward', ...
        'Timer', RightValveTime,...
        'StateChangeConditions', {'Tup', 'Drinking'},...
        'OutputActions', {'ValveState', 2,});  % On right poke give water
    
    sma = AddState(sma, 'Name', 'Drinking', ...
        'Timer', 5,...
        'StateChangeConditions', {'Tup', 'ITI', 'Port1Out', 'ConfirmPortOut', 'Port2Out', 'ConfirmPortOut'},... 
        'OutputActions', {});
    
    sma = AddState(sma, 'Name', 'ConfirmPortOut', ...
        'Timer', PortOutDelay,...
        'StateChangeConditions', {'Tup', 'ITI', 'Port1In', 'Drinking', 'Port2In', 'Drinking'},...
        'OutputActions', {});
    
    sma = AddState(sma, 'Name', 'ITI', ... 
        'Timer', iti_list(currentTrial),...
        'StateChangeConditions', {'Tup', 'exit'},...
        'OutputActions', {}); 

    T = BpodTrialManager;
    %SendStateMachine(sma);
    %RawEvents = RunStateMachine;
    T.startTrial(sma)
    RawEvents = T.getTrialData;
    if ~isempty(fieldnames(RawEvents)) % If trial data was returned
        BpodSystem.Data = AddTrialEvents(BpodSystem.Data,RawEvents); %  Computes trial events from raw data
        BpodSystem.Data.TrialSettings(currentTrial) = S; % Adds the settings used for the current trial to the Data struct (to be saved after the trial ends)
        BpodSystem.Data.TrialTypes(currentTrial) = TrialTypes(currentTrial); % Adds the trial type of the current trial to data
        UpdateOutcomePlot(TrialTypes, BpodSystem.Data);
        SaveBpodSessionData; % Saves the field BpodSystem.Data to the current data file
    end
    HandlePauseCondition; % Checks to see if the protocol is paused. If so, waits until user resumes.
    if BpodSystem.Status.BeingUsed == 0
        return
    end
end

function UpdateOutcomePlot(TrialTypes, Data)
    global BpodSystem
    Outcomes = zeros(1,Data.nTrials);
    for x = 1:Data.nTrials
        if ~isnan(Data.RawEvents.Trial{x}.States.Drinking(1))
            Outcomes(x) = 1;
        else
            Outcomes(x) = 3;
        end
    end
    TrialTypeOutcomePlot(BpodSystem.GUIHandles.OutcomePlot,'update',Data.nTrials+1,TrialTypes,Outcomes);

%% Execute when time is up:
function timeUp(duration)
    disp(num2str(duration) + " minutes have elapsed! The session has ended.");  % Print to console, maybe make this an alert

    BpodSystem.BonsaiSocket = [];
    RunProtocol('Stop');  % Stop the protocol   
    [~,~] = system('start C:\ProgramData\Anaconda3\python.exe D:\fmon-bpod\disconnect_gui.py'); % Stop Bonsai
    %session_data = BpodSystem.Data;
    SaveBpodSessionData();  % Save Session Data to Bpod data folder
    %deleteTimers();
    disp('running data output script');
    run('D:\fmon-bpod\fmon_data_output.m'); % Run data processing script
    
function deleteTimers()
    % Find all timers
    allTimers = timerfindall;
    % Loop through all timers
    for i = 1:length(allTimers)
        % Stop each timer
        stop(allTimers(i));

        % Reset each timer property as needed
        allTimers(i).StartDelay = 0; % Reset start delay to 0
        % Add code here to reset other timer properties as needed
    end
    % Kill them all
    delete(allTimers);
