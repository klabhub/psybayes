%PSYTEST_ORIENTATION Test of PSYBAYES for orientation experiment.
%
%  See also PSYBAYES, PSYBAYES_PLOT, PSYTEST.

%--------------------------------------------------------------------------
% Definitions for PSYBAYES
newsession = 1;

if newsession
    % Initialize PSY structure
    psy = [];

    % Specify user-defined psychometric function (as a string)
    psy.psychofun{1} = '@(x,mu,sigma,lambda,gamma) psyfun_yesno(x,mu,sigma,lambda,gamma,@psynormcdf);';
    
    % Define range for stimulus and for parameters of the psychometric function
    % (lower bound, upper bound, number of points)
    
    x = [0.25:0.25:1 1.4:0.4:3 3.5:0.5:5 6:10 12:2:20 22.5:2.5:45];
    x = [-fliplr(x),x];
    
    psy.x = x;           % Stimulus grid in orientation degrees
    psy.range.mu = [-12,12,31];     % Psychometric function mean
    psy.range.sigma = [0.5,45,41];                   % The range for sigma is automatically converted to log spacing
    psy.range.lambda = [0,0.5,21];
    % psy.range.lambda = [0.05-eps,0.05+eps,2];  % This would fix the lapse rate to 0.05

    % Define priors over parameters
    psy.priors.mu = [0,3];              % mean and sigma of (truncated) Student's t prior over MU
    psy.priors.logsigma = [2.05,1.40];  % mean and sigma of (truncated) Student's t prior over log SIGMA (Inf std means flat prior)
    psy.priors.lambda = [1 19];         % alpha and beta parameters of beta pdf over LAMBDA

    % Units -- used just for plotting in axis labels and titles
    psy.units.x = 'deg';
    psy.units.mu = 'deg';
    psy.units.sigma = 'log deg';
    psy.units.lambda = [];
    psy.units.psychofun = {'Normal'};
    
    % Refractory time before presenting same stimulus again
    psy.reftime = 0;        % Expected number of trials (geometric distribution)
    psy.refradius = 0;      % Refractory radius around stimulus (in x units)    
else    
    filename = 'psy.mat';   % Choose your file name
    load(filename,'psy');   % Load PSY structure from file
end

method = 'ent';     % Minimize the expected posterior entropy
vars = [1 1 0];     % Minimize posterior entropy of mean and sigma
% vars = [1 1 1];     % Minimize joint posterior entropy of mean, sigma and lambda
plotflag = 1;       % Plot visualization

%--------------------------------------------------------------------------

% Parameters of simulated observer
mu = 1;
sigma = exp(2.8);
lambda = 0.15;
gamma = [];

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
psychofun = str2func(psy.psychofun{1});

pause;

Ntrials = 500;
EasyRate = 0.0;    % Frequency of easy trials

for iTrial = 1:Ntrials

    if rand < EasyRate
        % Simulate observer's response to an easy trial (only lapse/guessing)
        x = Inf;
        if isempty(gamma)
            r = rand < 1-lambda/2;
        else
            r = rand < 1-lambda*(1-gamma);            
        end
    else
        % Simulate observer's response given stimulus x
        r = rand < psychofun(x,mu,sigma,lambda,gamma);        
    end
    
    % Get next recommended point that minimizes predicted entropy 
    % given the current posterior and response r at x
    tic
    [x, psy] = psybayes(psy, method, vars, x, r);
    toc

    if plotflag
        trueparams = [mu,sigma,lambda];
        psybayes_plot(psy,trueparams);
    end
    
    % Print posterior over distinct psychometric curves
    for k = 1:numel(psy.psychofun)
        if k < numel(psy.psychofun); sep = ', '; else sep = '.  '; end
        fprintf(['%s: %.3f' sep], psy.units.psychofun{k}, psy.psychopost(k));
    end
    drawnow;    
    pause;
end

% Once you are done, clean PSY struct from temporary variables
[~,psy] = psybayes(psy);

% Save PSY struct, can be used in following sessions
% save(filename,'psy');

