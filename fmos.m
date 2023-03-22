function fmos
%%
global BpodSystem
%A = BpodAnalogIn(BpodSystem.ModuleUSB.AnalogIn1);

%% Set Reward amounts
LeftValveTime = .17; %In practice, these will be defined by calibrate_h2o
RightValveTime = .27;

%% Define parameters
S = BpodSystem.ProtocolSettings; % Load settings chosen in launch manager into current workspace as a struct called S
if isempty(fieldnames(S))  % If settings file was an empty struct, populate struct with default settings
    S.GUI.CurrentBlock = 1; % Training level % 1 = Direct Delivery at both ports 2 = Poke for delivery
    S.GUI.RewardAmount = 5; %ul
    S.GUI.PortOutRegDelay = 0.5; % How long the mouse must remain out before poking back in
end

%% Define trials
nLeftTrials = 0;
nRightTrials = 0;
nOmissionTrials = 0;
nRandomTrials = 100;
MaxTrials = nLeftTrials+nRightTrials+nRandomTrials;
TrialTypes = [ones(1,nLeftTrials) ones(1,nRightTrials)*2 ceil(rand(1,nRandomTrials)*2)];
BpodSystem.Data.TrialTypes = []; % The trial type of each trial completed will be added here.

%% Initialize plots
BpodSystem.ProtocolFigures.OutcomePlotFig = figure('Position', [50 540 1000 250],'name','Outcome plot','numbertitle','off', 'MenuBar', 'none', 'Resize', 'off');
BpodSystem.GUIHandles.OutcomePlot = axes('Position', [.075 .3 .89 .6]);
TrialTypeOutcomePlot(BpodSystem.GUIHandles.OutcomePlot,'init',TrialTypes);
BpodNotebook('init'); % Initialize Bpod notebook (for manual data annotation)
BpodParameterGUI('init', S); % Initialize parameter GUI plugin

%% Main trial loop
for currentTrial = 1:MaxTrials
    S = BpodParameterGUI('sync', S); % Sync parameters with BpodParameterGUI plugin
    switch TrialTypes(currentTrial) % Determine trial-specific state matrix fields
        case 1
            StateOnInitPoke = 'GoLeft';
        case 2
            StateOnInitPoke = 'GoRight'; 
    end

    sma = NewStateMachine(); % Initialize new state machine description

    sma = AddState(sma, 'Name', 'WaitForInitPoke', ...
    'Timer', 0,...
    'StateChangeConditions', {'Port2In', StateOnInitPoke},...
    'OutputActions', {});

    sma = AddState(sma, 'Name', 'GoLeft', ...
        'Timer', 0,...
        'StateChangeConditions', {'SoftCode1', 'CorrectLeft', 'SoftCode3', 'NoReward'},...
        'OutputActions', {}); 
    
    sma = AddState(sma, 'Name', 'GoRight', ...
    'Timer', 0,...
    'StateChangeConditions', {'SoftCode1', 'NoReward', 'SoftCode3', 'CorrectRight'},...
    'OutputActions', {}); 

    sma = AddState(sma, 'Name', 'CorrectLeft', ...
        'Timer', 0,...
        'StateChangeConditions', {'Port1In', 'LeftReward', 'Port3In', 'NoReward'},...
        'OutputActions', {'ValveModule1', 1, 'ValveModule2', 255, 'ValveModule3', 255}); 

    sma = AddState(sma, 'Name', 'CorrectRight', ...
        'Timer', 0,...
        'StateChangeConditions', {'Port1In', 'NoReward', 'Port3In', 'RightReward'},...
        'OutputActions', {'ValveModule1', 2 'ValveModule2', 255, 'ValveModule3', 255}); 

    sma = AddState(sma, 'Name', 'NoReward', ... % add pseudorandom ITI into timer?
        'Timer', 0,...
        'StateChangeConditions', {'Tup', 'exit'},...
        'OutputActions', {}); 

    sma = AddState(sma, 'Name', 'LeftReward', ...
        'Timer', LeftValveTime,...
        'StateChangeConditions', {'Tup', 'Drinking'},...
        'OutputActions', {'ValveState', 1, 'ValveModule1', 0, 'ValveModule2', 255, 'ValveModule3', 255}); 
    
    sma = AddState(sma, 'Name', 'RightReward', ...
        'Timer', RightValveTime,...
        'StateChangeConditions', {'Tup', 'Drinking'},...
        'OutputActions', {'ValveState', 4, 'ValveModule1', 0, 'ValveModule2', 255, 'ValveModule3', 255});
    
    sma = AddState(sma, 'Name', 'Drinking', ...
        'Timer', 10,...
        'StateChangeConditions', {'Tup', 'exit', 'Port1Out', 'ConfirmPortOut', 'Port3Out', 'ConfirmPortOut'},...
        'OutputActions', {});
    
    sma = AddState(sma, 'Name', 'ConfirmPortOut', ...
        'Timer', S.GUI.PortOutRegDelay,...
        'StateChangeConditions', {'Tup', 'exit', 'Port1In', 'Drinking', 'Port3In', 'Drinking'},...
        'OutputActions', {});

    T = BpodTrialManager;
    %SendStateMachine(sma);
    %RawEvents = RunStateMachine;
    T.startTrial(sma)
    RawEvents = T.getTrialData;
    if ~isempty(fieldnames(RawEvents)) % If trial data was returned
        BpodSystem.Data = AddTrialEvents(BpodSystem.Data,RawEvents); % Computes trial events from raw data
        BpodSystem.Data = BpodNotebook('sync', BpodSystem.Data); % Sync with Bpod notebook plugin
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
