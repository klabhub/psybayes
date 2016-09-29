%PSYTEST Test and practical reference of PSYBAYES
%
%  Run PSYTEST for a demo of PSYBAYES.
%  Read the comments to learn the usage of PSYBAYES.
%
%  See also PSYBAYES, PSYBAYES_PLOT.

%--------------------------------------------------------------------------
% Definitions for PSYBAYES
newsession = 1;

if newsession
    % Initialize PSY structure
    psy = [];

    % Set chance level (for PCORRECT psychometric functions)
    psy.gamma = 0.5;        
    % psy.gamma = [];   % Leave it empty for YES/NO psychometric functions

    % You can specify a user-defined psychometric function (as a string)
    psy.psychofun = '@(x,mu,sigma,lambda,gamma) bsxfun(@plus, gamma, bsxfun(@times,1-gamma-lambda,0.5*(1+erf(bsxfun(@rdivide,bsxfun(@minus,mu,x),sqrt(2)*sigma)))));';
    
    % Define range for stimulus and for parameters of the psychometric function
    % (lower bound, upper bound, number of points)
    psy.range.x = [1.5,4.5,61];
    psy.range.mu = [2,4,51];
    psy.range.sigma = [0.05,1,25];      % The range for sigma is automatically converted to log spacing
    psy.range.lambda = [0,0.1,25];
    %psy.range.lambda = [0.05,0.05,1];  % This would fix the lapse rate to 0.05

    % Define priors over parameters
    psy.priors.mu = [3,2];                  % mean and std of (truncated) Gaussian prior over MU
    psy.priors.logsigma = [log(0.5),Inf];   % mean and std of (truncated) Gaussian prior over log SIGMA (Inf std means flat prior)
    psy.priors.lambda = [2 50];             % alpha and beta parameter of beta pdf over LAMBDA

    % Units -- used just for plotting in axis labels and titles
    psy.units.x = 'cm';
    psy.units.mu = 'cm';
    psy.units.sigma = 'cm';
    psy.units.lambda = [];
else    
    filename = 'psy.mat';   % Choose your file name
    load(filename,'psy');   % Load PSY structure from file
end

method = 'ent';     % Minimize the expected posterior entropy
% vars = [1 0 0];   % Minimize posterior entropy of the mean only
vars = [1 1 1];     % Minimize joint posterior entropy of mean, sigma and lambda
plotflag = 1;       % Plot visualization

%--------------------------------------------------------------------------

% Parameters of simulated observer
mu = 3.05;
sigma = 0.2;
lambda = 0.05;
gamma = psy.gamma;

%--------------------------------------------------------------------------
% Start running

string = ['Simulating an observer with MU = ' num2str(mu)];
if ~isempty(psy.units.mu); string = [string ' ' psy.units.mu]; end
string = [string '; SIGMA = ' num2str(sigma)];
if ~isempty(psy.units.sigma); string = [string ' ' psy.units.sigma]; end
string = [string '; LAMBDA = ' num2str(lambda)];
if ~isempty(psy.units.lambda); string = [string ' ' psy.units.lambda]; end
string = [string '.'];
display(string);
display('Press a key to simulate a trial.')

% Get first recommended point under the chosen optimization method
% (last argument is a flag for plotting)
[x,psy] = psybayes(psy, method, vars, [], []);

% Get psychometric function (only for simulating observer's responses)
psychofun = str2func(psy.psychofun);

pause;

Ntrials = 500;

for iTrial = 1:Ntrials
    % Simulate observer's response given stimulus x
    r = rand < psychofun(x,mu,sigma,lambda,gamma);

    % Get next recommended point that minimizes predicted entropy 
    % given the current posterior and response r at x
    tic
    [x, psy] = psybayes(psy, method, vars, x, r);
    toc

    if plotflag
        trueparams = [mu,sigma,lambda];
        psybayes_plot(psy,trueparams);
    end
    
    drawnow;    
    % pause;
end

% Once you are done, clean PSY struct from temporary variables
[~,psy] = psybayes(psy);

% Save PSY struct, can be used in following sessions
% save(filename,'psy');

