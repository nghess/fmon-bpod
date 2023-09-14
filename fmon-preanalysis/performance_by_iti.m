%% Pull Out ITI's and Performance for a mouse


% need to remove omissions
time = zeros(session_data.nTrials, 1);
correct = zeros(session_data.nTrials, 1);
trial_types = session_data.TrialTypes;

for ii = 1:session_data.nTrials
    time(ii) = round(session_data.RawEvents.Trial{1, ii}.States.ITI(2) - session_data.RawEvents.Trial{1, ii}.States.ITI(1));
    
    if ~isnan(session_data.RawEvents.Trial{1, ii}.States.CorrectLeft) | ~isnan(session_data.RawEvents.Trial{1, ii}.States.CorrectRight)
        correct(ii) = 1;
    else
        correct(ii) = 0;
    end
end

%% Separate Out Trial Types

l_trials_idx = find(trial_types == 1);
r_trials_idx = find(trial_types == 2);
r_left_idx = find(trial_types == 3);
r_omit_idx = find(trial_types == 4);

%% Loop through trials and count only if event was triggered (is not NaN)


%% Make a script to go through each mouse/session and grab the info



%% Logistic Regression

% Create synthetic data
rng('default'); % For reproducibility
n = 100; % Number of samples
%time = linspace(0, 10, n)';
%correct = randi([0, 1], n, 1);

% Fit logistic regression model for L trials
[b, dev, stats] = glmfit(time, correct, 'binomial', 'link', 'logit');

% Generate new time points for prediction
time_new = linspace(0, max(time), 300)';

% Get predicted probabilities
yhat = glmval(b, time_new, 'logit');

% Plotting
figure;

% Scatter plot of original data
scatter(time, correct, 'MarkerEdgeColor', [0 0 0]);

hold on;

% Plot the fitted logistic curve
plot(time_new, yhat, 'r', 'LineWidth', 2);

xlabel('ITI Duration');
ylabel('Probability of Correct Decision');
legend('Observed Data', 'Fitted Curve', 'Location', 'Best');
grid on;

hold off;
