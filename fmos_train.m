%{
FMOS MODULE for Bpod
Preferences (Set variables in Freely Moving Olfactory Search Task)

Written By: Nate Gonzales-Hess (nhess@uoregon.edu)
Last Updated: 4/25/2023
%}

function fmos_train
%%
global BpodSystem

%% Set Reward amounts
LeftValveTime = .15; %In practice, these will be defined by calibrate_h2o
RightValveTime = .15;
InitValveTime = .15;

PortOutDelay = .5;

%% Build ITI list
%min_iti = .1;
%max_iti = .1;
%iti_list = round((max_iti-min_iti) .* rand(1,150) + min_iti);

%% Define parameters
% check this and see how much is necessarry
S = BpodSystem.ProtocolSettings; % Load settings chosen in launch manager into current workspace as a struct called S
%if isempty(fieldnames(S))  % If settings file was an empty struct, populate struct with default settings
%    S.GUI.CurrentBlock = 1; % Training level % 1 = Direct Delivery at both ports 2 = Poke for delivery
%    S.GUI.RewardAmount = 5;  % ul
%    S.GUI.PortOutRegDelay = 0.5; % How long the mouse must remain out before poking back in
%end

%% Define trials
n_HalfTrials = 20;
TrialTypes = [1];

for i = 1:n_HalfTrials-1
   TrialTypes(end+1) = 2;
   TrialTypes(end+1) = 1;
end

%TrialTypes = [ones(1, nLeftTrials) ones(1, nRightTrials)*2];  % 1 = Left, 2 = Right
%TrialTypes = TrialTypes(randperm(length(TrialTypes)));
BpodSystem.Data.TrialTypes = []; % The trial type of each trial completed will be added here.
MaxTrials = length(TrialTypes);%nLeftTrials + nRightTrials + nOmissionTrials;

%% Initialize plots
BpodSystem.ProtocolFigures.OutcomePlotFig = figure('Position', [50 540 500 250],'name','Outcome plot','numbertitle','off', 'MenuBar', 'none', 'Resize', 'off');
BpodSystem.GUIHandles.OutcomePlot = axes('Position', [.075 .3 .89 .6]);
TrialTypeOutcomePlot(BpodSystem.GUIHandles.OutcomePlot,'init',TrialTypes);
%BpodParameterGUI('init', S); % Initialize parameter GUI plugin

%% Main trial loop
for currentTrial = 1:MaxTrials
    
    % Valve Module serial messages, 1 = Odor, 2 = Omission, 3 = Reset
    %LoadSerialMessages('ValveModule1', {['B' 15], ['B' 51], ['B' 0]});  % Left valves
    %LoadSerialMessages('ValveModule2', {['B' 15], ['B' 51], ['B' 0]});  % Right valves
    %LoadSerialMessages('ValveModule3', {['B' 3], ['B' 0]});  % Final Valves
    
    % Determine trial-specific state matrix fields
    switch TrialTypes(currentTrial)
        case 1
            StateOnInitPoke = 'CorrectLeft';
        case 2
            StateOnInitPoke = 'CorrectRight'; 
    end

    % Initialize new state machine description
    sma = NewStateMachine(); 
    
    sma = AddState(sma, 'Name', 'WaitForInitPoke', ...
        'Timer', 0,...
        'StateChangeConditions', {'Port3In', 'InitReward'},...  % Wait for initiation port poke, give water on poke
        'OutputActions', {});

    sma = AddState(sma, 'Name', 'CorrectLeft', ...
        'Timer', 0,...
        'StateChangeConditions', {'Port1In', 'LeftReward'},...  % Wait for left poke
        'OutputActions', {});

    sma = AddState(sma, 'Name', 'CorrectRight', ...
        'Timer', 0,...
        'StateChangeConditions', {'Port2In', 'RightReward'},...  % Wait for right poke
        'OutputActions', {});
    
    sma = AddState(sma, 'Name', 'InitReward', ...
        'Timer', InitValveTime,...
        'StateChangeConditions', {'Tup', 'InitDrinking'},...
        'OutputActions', {'ValveState', 4});  % On init poke give water
    
    sma = AddState(sma, 'Name', 'LeftReward', ...
        'Timer', LeftValveTime,...
        'StateChangeConditions', {'Tup', 'Drinking'},...
        'OutputActions', {'ValveState', 1});  % On left poke give water
    
    sma = AddState(sma, 'Name', 'RightReward', ...
        'Timer', RightValveTime,...
        'StateChangeConditions', {'Tup', 'Drinking'},...
        'OutputActions', {'ValveState', 2,});  % On right poke give water
    
    sma = AddState(sma, 'Name', 'InitDrinking', ...
        'Timer', 10,...
        'StateChangeConditions', {'Tup', StateOnInitPoke, 'Port3Out', 'InitConfirmPortOut'},...  % Wait for mouse to drink in init port
        'OutputActions', {});
        
    sma = AddState(sma, 'Name', 'Drinking', ...
        'Timer', 10,...
        'StateChangeConditions', {'Tup', 'exit', 'Port1Out', 'ConfirmPortOut', 'Port2Out', 'ConfirmPortOut'},...  % Wait for mouse to drink in L or R port
        'OutputActions', {});
    
    sma = AddState(sma, 'Name', 'InitConfirmPortOut', ...
        'Timer', PortOutDelay,...
        'StateChangeConditions', {'Tup', StateOnInitPoke, 'Port3In', 'InitDrinking'},...  % Confirm mouse is out of port, then advance to L or R reward
        'OutputActions', {});
    
    sma = AddState(sma, 'Name', 'ConfirmPortOut', ...
        'Timer', PortOutDelay,...
        'StateChangeConditions', {'Tup', 'exit', 'Port1In', 'Drinking', 'Port2In', 'Drinking'},...
        'OutputActions', {});
    
    %sma = AddState(sma, 'Name', 'ITI', ... 
    %    'Timer', iti_list(currentTrial),...
    %    'StateChangeConditions', {'Tup', 'exit'},...
    %    'OutputActions', {}); 

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
    %disp(iti_list(currentTrial));
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
