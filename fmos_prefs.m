%{
FMOS MODULE for Bpod
Preferences (Set variables in Freely Moving Olfactory Search Task)

Written By: Nate Gonzales-Hess (nhess@uoregon.edu)
Last Updated:
%}

%%
%RESEARCHER INPUTS
experimenter = 'Amanda';  % Your full name
trainer = 'none';  % Who is training you? (if applicable -- if no one, put 'none') 
mouse_id = 'test';  % mouse subject number
sex = 'F';  % Sex of mouse
initial_weight = '22.30';  % Weight of mouse in grams
group_name = '100-0';  % What experiment are you running? 
% (OPTIONS: trainer1, trainer2, 100-0, 80-20, 60-40, 90-10_interleaved, abs-conc, non-spatial, nostril-occlusion, doi, dig, iti_intervals) 
% IMPORTANT: trainer1 and trainer2 are run through separate codes (labeled trainer% 1 and trainer% 2)...everything else runs in MASTERCODE
sniffing = 'yes';  % Is the sniff wire plugged in? (yes, no) 
percentinvial= '0.001';  % What percent concentration of odorant is in the odor vial (should be written on the label) 
occluded_nostril = 'none';  % Is a nostril occluded? (none, left, right, left-sham, right-sham)
wcL = 'NA';  % Left water port calibration (how many microliters per reward?)
wcR = 'NA';  % Right water port calibration
wcIP = 'NA';  % Initiation water port calibration
odortype = 'NA';  % Odor identity (pinene, octanol, amyl acetate, methyl salicate, etc.)
iti_delay = 0;  % Setting initial variable for ITI to not error during trainers 1 and 2 (should this be here?)

%%
%FOR ITI INTERVALS EXPERIMENT ONLY%
min_iti = 1;
max_iti = 25;
percent_of_controls = 0.2;  % please write in decimal form (i.e. 0.2 = 20%)
drug_dose = 'NA';  % for DOI experiments, what is the dose (mg/kg) injected? 0 for vehicle
side_bias = 0;  % set to 0 for left and right trials, set to 1 for only right trials, set to 2 for only left trials 
% Odor vials! Current Key: 6 = blank, 7 = Benzaldehyde (.1%), 8 = 2-PE (0.01%)
odor_vial = 8;  % main odor (7 = Benzaldehyde), 8 = 2PE^^^^ <-what's this?
alternate_vial = 7;  % Alternate odor in 90-10 interleaved!!! Make sure it is different than odor_vial
blank_vial = 6;

% Only for non-spatial experiments
% non_spatial_condition = 'odor_identity' 
% OPTIONS: odor_concentration or odor_identity

%%
%SET UP (Can we move this to another file?)
%Data Paths
base_dir = "D:/FMOS-Bpod/data/";  % Root of data path (below, data compilation file location)
%Timing
count_requirement = 4;  % How many frames in one quadrant registers response? 
iti_correct = 4; iti_incorrect = 10;  % Inter-trial intervals
timeout_delay = 5*60;  % How long does the timeout between trials?
%Online Tracking
y_min = 0;  % Rig coordinates in pixels
y_max = 720; 
x_min = 0; 
x_max = 1210; 
x_sections = 3;  % How many partitions? 
y_sections = 2;  
%Valve Designations
left_valve = 2; 
right_valve = 1; 
rightport = 1; 
leftport = 2; 
nosepokeport = 4; 
MFC_air = 1; 
MFC_n2 = 2;

%%
%NI USB-6009 DATA COLLECTION (Will be swapped for Bpod Analogue Input)
samplingrate = 800; buffersize = 25; channel_num = 6 %number of channels
%Name Channels (this is how the files will be saved in the datapath)
ch0 = 'sniff'; ch1 = 'rightnosepoke'; ch2 = 'leftnosepoke'; ch3 = 'initnosepoke'; ch4 = 'camera_GPIO_trigger'

%%
%%Bpod & AnalogueIn1 COM Ports
BpodPort='\\\\.\\COM7'; analogueInPort = '\\\\.\\COM4';

%%
%CONSTANTS

%SESSION LENGTH
if ismember(group_name, {'trainer1', 'trainer2', 'trainer2_non-spatial'})
    sessionlength_min = 30; % In minutes
    
elseif ismember(group_name, {'100-0', '90-10', '80-20', '60-40', '90-10_alt', '90-10_interleaved', 'iti_intervals'})
    sessionlength_min = 40; % In minutes
    
elseif ismember(group_name, {'interleaved', 'abs-conc', 'non-spatial', 'nostril-occlusion', 'mineral-oil', 'thresholding'})
    sessionlength_min = 40; % In minutes

elseif ismember(group_name, {'doi', 'dig'})
    sessionlength_min = 60; % In minutes
end
 
sessionlength_sec = sessionlength_min * 60;

%%
%Maybe move all spatial decision boundaries to bonsai?
%Online Tracking
%num_sections = x_sections*y_sections; 
%section  = [np.nan]*num_sections; 
%section_center = [np.nan]*num_sections; 

%%Bpod & AnalogueIn1 COM Ports COMMUNICATION
%Bpod = serial.Serial(BpodPort,115200,timeout==1); 
%AnalogueIn1 = serial.Serial(analogueInPort,115200,timeout==1);
