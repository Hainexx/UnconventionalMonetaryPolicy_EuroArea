%% Startup

clear all; close all; clc; dbstop if error; 
rng('default');
addpath '/Users/hainex/projects/macro_project/ZeroSignVAR/functions';

%% General program settings
% % Choose a unique model name.
opt.modelName = 'model_gdp';     

% Specify the path to the folder, in which all result files should be saved.
opt.modelPath = strcat(pwd,'/model/');

%% VAR specification and other setup 

% Define labels for the variables in the same order as they enter the VAR.
opt.lVars = {'UMP','Vstoxx','GDP','CPI'};

% USe a vector of constants in the estimation of the VAR (1 = Yes, 0 = No; Default = 1)
opt.hasConstant = 0

% FEVD
opt.isFevdTable = 1

% Historical Decomposition 
opt.isHistDecompTable = 1

opt.isPlotTitle = 1

opt.isPlotCTM = 1
opt.isFevdPlots = 1
opt.isStructShockPlots = 1
opt.isHistDecompPlots = 1

%
% Check also if sign restrictions are fulfilled for the negative of a Q column and transform this column of Q to it’s negative if applicable. If this option is 0 the diagonal of Q will be normalized to have a positive diagonal.
opt.checkNegativeQ = 0 %(Default = 1)

% save results and number od runs
opt.isSaveResults = 1
opt.runNumber = 1

% Define labels for the identified shocks. The number of shock labels has 
% to be equal to the number of variables (i.e. label also residual shocks).
opt.lShocks = {'UMP shock', 'VXSTOX shock', 'GDP shock', 'Price shock'};

% % Define start and end date (MM-DD-YYYY).
opt.startDate = '01-01-2014';
opt.endDate = '01-10-2019';

% Define the lag order.
opt.nLags = 1;   

% Horizon of the IRF
opt.nImpulseHorizon = 36

% Choose the estimation method ('OLS' or 'diffuse'), corresponding to 
% either ordinary least square or Bayesian estimations.
opt.estimationMethod = 'OLS';

% in case of Bayesian estimation 
%opt.nDrawsFromBvar = 1000 %default 1000
%opt.drawFromPosterior = 1 %default 0
%opt.nModelDraws = 100 % this only works if opt.drawFromPosterior = 1
opt.keepAllValid = 1 %default 0
opt.nMatches = 3000  % Default  1,000,000
opt.nTransformationsPerDraw = 10000 %default 1000


%opt.isIRFcum = [1,2,3,4]

opt.narrowCTMSearch = 0 %default 0

% Maximum horizon of sign restrictions (0 = only contemporary, 
% 1 = contemporary + horizon 1, etc.).
opt.nMaxSignHorizon = 2;

%% Import data from spreadsheet
load('data.mat')

%% Convert to output type
y = table2array(data20052019loglevelsHP);

%% Clear temporary variables
clear opts
%%

[t,nVars] = size(y);


%% Sign Restriction Setup


S = zeros(2,nVars*(opt.nMaxSignHorizon + 1),nVars);
Z = zeros(2,nVars*(opt.nMaxSignHorizon + 1),nVars);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SIGN RESTRICTION DEFINITION
% -----------------------------------------------------------------------
% Explanation:
% ===========
% The sign and zero restrictions are implemented using selection matrices 
%   (S for sign restrictions and Z for zero restrictions).
%   S and Z are three dimensional arrays. 

%   - The first dimension is the row of the selection matrix. For each 
%   shock it should be incremented by one for each restriction imposed 
%   to identify the shock starting at 1 for the first restriction.

%   - The second dimension is the column of the selection matrix. It
%   selects the variable on which the restriction should be set as well as
%   the horizon. For example the second variable at horizon 0 is selected
%   with 2, the second variable at horizon 1 is selected with 2 + nVars, 
%   the second variable at horizon 2 is selected with 2 + 2*nVars, and the 
%   second variable at horizon h is selected with 2 + h*nVars, where nVars 
%   is the number of variables in the system.

%   - The third dimension is the number of the shock. For the first shock
%   you want to identify pick 1, for the second 2, and so on.
    
%   - The matrix SN is used to impose a restriction which demands the
%   impulse response to be above or below zero by a certain amount, e.g.,
%   to restrict the contemporaneous response of variable 2 to shock 6 to be
%   above 2 in addition to the sign restriction S(1,2,6) = 1 the
%   restriction SN(1,2,6) = 2 would be set.

% Examples:
% ========
%   First shock: zero restrictions on variables 1 and 2 at horizon 0
%       Z(1,1,1) = 1;
%       Z(2,2,1) = 1;
%   Second shock: negative reaction of variable 1 up to maximum horizon
%     for ii = 1:(nMaxSignHorizon+1) 
%         S(ii,1+nVars*(ii-1),2) = -1;
%     end
%   second shock: positive reaction of variable 4 at horizons 0 and 1
%       S(nMaxSignHorizon+2,4,2);
%       S(nMaxSignHorizon+3,4+nVars,2);
%       Note: As we have already nMaxSignHorizon+1 restrictions imposed
%       for the second shock we have to start at nMaxSignHorizon+2.
%   For shocks without restrictions (residual shocks) nothing has to be
%   done, but they may be normalized.
% -----------------------------------------------------------------------


% MP Shock (Shock 1; zero and sign restrictions)

Z(1,3,1) = 1; % GDP
Z(2,4,1) = 1; % Inflation


% MP Shock (Shock 1; pure sign restrictions)
for ii = 1:(opt.nMaxSignHorizon+1)
    % positive respone of FFR
    S(ii,1+nVars*(ii-1),1) = +1;
    % negative response of inflation
    S(ii+opt.nMaxSignHorizon+1,2+nVars*(ii-1),1) = -1;
end


% Normalizatons
S(1,2,2)=1;
S(1,3,3)=1;
S(1,4,4)=1;


%%% DON'T EDIT NEXT LINE
SN = zeros(size(S));
%%%

signrestrictions