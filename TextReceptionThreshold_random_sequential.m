function TextReceptionThreshold_random_sequential(varargin)

% INPUTS:
% - textString [string/char]: text to be desplayed. Default = empty string;
% - debugMode [boolean]: 1 = yes (small screen, possibility to interact
%       with comand window, etc), 0 = no ('frozen'). Default = 1;
% - outputDir [string]: folder where results should be saved. Default:
%       folder where the script is located;
% - nMaskerBars [integer between 2 and 50]: number of 'black rectangles'
%       (masker) to display. Default: 20;
% - nOffsets [integer]: resolution (step size) of makser bar offset, range
%       = [-barWidth/2 barWidth/2]. If odd, mean value (=0): maskers are
%       centered, if <1/2:offset to the left and vice versa. If even, never
%       centered. Offest value is taken at random. Random behaviour can be
%       regulated by setSeed. Default: 0 (centered, NO offset).
% - closeAfterNsec [integer}: wait N seconds then close the screen. If 0,
%       never close. Default: 0 (never close). If function is running in a
%       loop and no value is specified, screens will be overlayed (avoid).
% - ptMaskingStart [integer]: percent masking 1st image. Default: 10.
% - ptMaskingEnd [integer]: percent masking last image. Default: 90.
% - ptMaskingStepSize [integer]: size of ptMasking increase between start and end.
%       Default: 6;
% - flipAfterNsec [integer]: waiting time before flipping in seconds.
%       Default: 5;
%
% Can be expanded in various ways, including:
% - textSizeRatio [integer between 1 and 10]: masker height/text height ratio.
%       Default = 3.
% - fontType [string]
% - distractor string (embedded in masker) for 'informational masking'
% (Currently none of this is included)
%
% OUTPUTS:
% None specified. Let me know if you want any
%
% Thomas Houweling, 30/06/2022


%% PARSE INPUT

% default path:
BWD=which('TextReceptionThreshold.m');
i=find(filesep==BWD);
BWD=BWD(1:i(end));

% default parameters:
options = struct(...
    'textString', '',...
    'debugMode', 1,...
    'outputDir', BWD,...
    'ptMaskingStart', 10,...
    'ptMaskingEnd', 90,...
    'ptMaskingStepSize', 6,...
    'nMaskerBars', 20, ...
    'nOffsets', 0, ...
    'flipAfterNsec', 5);
%     'closeAfterNsec', 0);
%     'textSizeRatio', 3, ...
%     'ptMasking', 50,...

% read parameter/value inputs
optionNames = fieldnames(options);

% count arguments
nArgs = length(varargin);
if round(nArgs/2)~=nArgs/2
    error('TextReceptionThreshold:impossibleNameValuePair',...
        'TextReceptionThreshold needs propertyName/propertyValue pairs')
end

% overwrite defults
pair = reshape(varargin,2,[]);
for i = 1:nArgs/2
    IX = strcmpi(pair{1,i},optionNames); % find match parameter names
    if any(IX)
        % if matching parameter, do the overwrite
        options.(optionNames{IX}) = pair{2,i}; %cell2mat(pair(i,2)); % pair{1,2};
    else % if not, throw error
        error('TextReceptionThreshold:unknownOption',...
            '%s is not a recognized parameter name',pair{1})
    end
end


%% check and assign input
% required inputs
assert(ischar(options.textString), ...
    'TextReceptionThreshold:invalidText', ...
    'textString must be a character vector.')
% assert(islogical(options.debugMode), ...
%     'TextReceptionThreshold:invalidDebugMode', ...
%     'debugMode must be logical.');
assert(ismember(options.debugMode, [0 1]), ...
    'TextReceptionThreshold:invalidDebugMode', ...
    'debugMode must be logical.');
assert(ischar(options.outputDir), ...
    'TextReceptionThreshold:invalidOutputDir', ...
    'outputDir must be a character vector.');
% assert(mod(options.ptMasking, 1) == 0, ...
%     'TextReceptionThreshold:invalidPtMaksing', ...
%     '%s: ptMasking must be an integer');
assert(mod(options.ptMaskingStart, 1) == 0, ...
    'TextReceptionThreshold:invalidPtMaksingStart', ...
    '%s: ptMaskingStart must be an integer');
assert(mod(options.ptMaskingEnd, 1) == 0, ...
    'TextReceptionThreshold:invalidPtMaksingEnd', ...
    '%s: ptMaskingEnd must be an integer');
assert(mod(options.ptMaskingStepSize, 1) == 0, ...
    'TextReceptionThreshold:invalidPtMaksingStepSize', ...
    '%s: ptMaskingStepSize must be an integer');
assert(mod(options.nMaskerBars, 1) == 0, ...
    'TextReceptionThreshold:invalidNbars', ...
    '%s: nMaskerBars must be an integer');
assert(options.nMaskerBars > 1, ...
    'TextReceptionThreshold:nBarsTooLow', ...
    '%s: nMaskerBars must be > 1');
assert(options.nMaskerBars < 51, ...
    'TextReceptionThreshold:nBarsTooHigh', ...
    '%s: nMaskerBars must be <= 50');
assert(mod(options.nOffsets, 1) == 0, ...
    'TextReceptionThreshold:invalidNoffsets', ...
    '%s: nOffsets must be an integer');
% assert(mod(options.setSeed, 1) == 0, ...
%     'TextReceptionThreshold:invalidSeed', ...
%     '%s: setSeed must be an integer');
% assert(mod(options.closeAfterNsec, 1) == 0, ...
%     'TextReceptionThreshold:invalidNsecs', ...
%     '%s: closeAfterNsec must be an integer');
% assert(mod(options.textSizeRatio, 1) == 0, ...
%     'TextReceptionThreshold:invalidTextSizeRatio', ...
%     '%s: textSizeRatio must be an integer');
% assert(options.textSizeRatio > 0, ...
%     'TextReceptionThreshold:textSizeRatioTooLow', ...
%     '%s: nMaskerBars must be > 0');
% assert(options.textSizeRatio < 11, ...
%     'TextReceptionThreshold:textSizeRatioTooHigh', ...
%     '%s: textSizeRatio must be <= 10');



%% *************************** PTB setup ******************************* %%
% initialise PTB
% try

cfg = [];

PsychDefaultSetup(0);
Screen('Preference', 'SkipSyncTests', 1);

% CHECK FIX THIS FOR ACCURATE TIMESTAMPING!!
% if options.debugMode
%     PsychDefaultSetup(0);
%     Screen('Preference', 'SkipSyncTests', 1);
% else
%     PsychDefaultSetup(1);
%     Screen('Preference', 'SkipSyncTests', 0);
% end

screens = Screen('Screens');
screenNumber = max(screens);
black = BlackIndex(screenNumber);
white = WhiteIndex(screenNumber);

if options.debugMode
    [window, windowRect] = PsychImaging('OpenWindow', screenNumber, black, [0 0 2000 1500]);
else
    [window, windowRect] = PsychImaging('OpenWindow', screenNumber, black);
    HideCursor;
end

cfg.screen.screenNumber=screenNumber;
cfg.screen.window=window;
cfg.screen.windowRect=windowRect;


%% ******************************* TRT ********************************* %%
% I had the instructions in another file. Might be easiest if you write
% your own as you please (in my case stimuli were only digits)
% TRT_instructions(cfg);

thisFont = char('Ariel');
% Set the blend funciton for the screen
Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
Screen('TextSize', window, round(windowRect(4)/7));
Screen('TextFont', window, thisFont);

thinRect = [0 0 windowRect(3) windowRect(4)/3];
% centeredRect = CenterRectOnPointd(thinRect, xCenter, yCenter);
centeredRect = CenterRectOnPointd(thinRect, windowRect(3)/2, windowRect(4)/2);

% 'informational masking' option (distractor text embedded in maskers):
% distractorStr='read between the lines';
% [dX, dY, distractorTextBounds, distractorWordBounds] = DrawFormattedText(window, distractorStr, 'center', 'center', white,[],[],[],[],[],centeredRect);
% [~, ~, textbounds] = DrawFormattedText(window, thisCharStr, 'center', 'center', white);

% draw black rects
nBlackRects=options.nMaskerBars;
thinRectArea=thinRect(3)*thinRect(4);

steps = options.ptMaskingStart:options.ptMaskingStepSize:options.ptMaskingEnd;
nSteps = length(steps);

imageArray_full = cell([nSteps 1]);
imageArray_rect = cell([nSteps 1]);

for j = 1:nSteps
    
    totAreaToCover=thinRectArea*steps(j)/100;
    totAreaBlackRect=totAreaToCover/nBlackRects;
    horizSideBlackRect=round(totAreaBlackRect/thinRect(4));
    horizInBetween = round((thinRect(3)-(horizSideBlackRect*nBlackRects)) / (nBlackRects-1));
    
    % maybe longer to acomodate for rounding!
    blackRect = [0 0 horizSideBlackRect thinRect(4)];
    
    if options.nOffsets > 0
        shift = linspace(-fix(horizSideBlackRect/2),fix(horizSideBlackRect/2),options.nOffsets);
        %     rng(options.setSeed,'twister');
        shiftIDX=randperm(options.nOffsets,1);
    end
    
    squareYpos = round((windowRect(2)+windowRect(4))/2);
    squareXpos = [ ];
    for i = 1:nBlackRects
        if options.nOffsets > 0
            xPos(i) = (round(horizSideBlackRect/2) + ((i-1)*horizSideBlackRect) + ((i-1)*horizInBetween)) + shift(shiftIDX);
        else
            xPos(i) = (round(horizSideBlackRect/2) + ((i-1)*horizSideBlackRect) + ((i-1)*horizInBetween));
        end
        squareXpos = [squareXpos xPos(i)];
    end
    
    for i = 1:nBlackRects
        allRects(:, i) = CenterRectOnPointd(blackRect, squareXpos(i), squareYpos);
    end
    
    if allRects(1,1) > horizInBetween
        addRectXPos = xPos(1) - (horizSideBlackRect + horizInBetween);
        addRectL = CenterRectOnPointd(blackRect, addRectXPos, squareYpos);
    end
    
    if (windowRect(3) - allRects(3,end)) > horizInBetween
        addRectXPos = xPos(end) + horizSideBlackRect + horizInBetween;
        addRectR = CenterRectOnPointd(blackRect, addRectXPos, squareYpos);
    end
    
    if ~exist('addRectL','var') && ~exist('addRectR','var')
        rects2crop = allRects;
    elseif exist('addRectL','var') && ~exist('addRectR','var')
        rects2crop = [addRectL' allRects];
    elseif ~exist('addRectL','var') && exist('addRectR','var')
        rects2crop = [allRects addRectR'];
    elseif exist('addRectL','var') && exist('addRectR','var')
        rects2crop = [addRectL' allRects addRectR'];
    end
    
    clear addRectL addRectR squareXpos squareYpos xPos allRects
    
    if rects2crop(1,1) < 0
        rects2crop(1,1) = 0;
    end
    if rects2crop(3,end) > windowRect(3)
        rects2crop(3,end) = windowRect(3);
    end
    
    % for i = 1:size(rects2crop,2)
    %     imageArray{i}=Screen('GetImage', window, rects2crop(:, i));
    % end
    
    % draw white rect
    Screen('FillRect', window, white, centeredRect);
    % Screen('Flip',window);
    
    
    for i = 1:size(rects2crop,2)
        imageArray{i}=Screen('GetImage', window, rects2crop(:, i));
    end
    
    % draw wtext if any
    if ~isempty(options.textString)
        Screen('FillRect', window, white, centeredRect);
        [tx, ty, targetTextBounds, targetWordBounds] = DrawFormattedText(...
            window, options.textString, 'center', 'center', white,[],[],[],[],[],centeredRect);
    end
    
    % insert text snapshots
    for i = 1:size(imageArray,2)
        Screen('PutImage', window, imageArray{i}, rects2crop(:, i))
    end
    
    % flip to screen
    Screen('Flip',window);
    
    imageArray_full{j}=Screen('GetImage', window);
    imageArray_rect{j}=Screen('GetImage', window, centeredRect);
    
    
    if options.flipAfterNsec > 0
        WaitSecs(options.flipAfterNsec)
        Screen('Flip', window);
    end
end

save([BWD 'example_fullScreen.mat'], 'imageArray_full', 'imageArray_rect');













if options.debugMode == 0
    ShowCursor;
end

% rng('default'); % reset random number generator

%% README: main body of function of 'original' test

% I had my word stimuli in spelled form in a text file. I think it would be
% easiest if you do he same with your stimuli.

% FID = fopen([cfg.BWD 'digitSpellingTRT.txt']);
% spelledDigits = textscan(FID,'%s');
% fclose(FID);
% spelledDigits{1}(1:7) = 'null'...'sechs'
% spelledDigits{1}(8:9) = 'acht','neun'


% There would also be the option to play around with some fonts but it
% might be irrelevant in this context. Otherwise, let me know!
% -----------------------------------------
% load([BWD 'fontsTRT.mat'], 'theseFonts');
% -----------------------------------------


%   /---------------------------------------------------------------------/
%  /-------------------------- PROCEDURES: ------------------------------/
% /---------------------------------------------------------------------/
% | In the original script, the test started at 70% masking. Upon incorrect
% | response, % masking is decreased by 6 and a new trial start. Upon
% | correct response, the 'calibration' (not scored) phase ends and the
% | actual test starts. The test involves a 1-up/1-down staircase procedure
% | with decreasing step sizes from 6 to 3%. Scores are assigned to trial
% | triplets on the basis of best of 3 (e.g. first 2 trials correct: 'trial
% | triplet' ends before 3rd presentation and correct score is assigned to
% | triplet). Test ends after 5 REVERSALS or after 30 trials (excluding
% | calibration).
% -----------------------------------------------------------------------

% I leave this here commented out in case it can be useful, although there
% are a number of parameters to be specified for this to work.
% There is also the option to send triggers for EEG recording via parallel
% port, but one would need to check port ID, etc. before using it.



% nMaxt0Trials=12;
% TRTstruct.t0.trialScore=NaN([1 nMaxt0Trials]);
% TRTstruct.t0.expResp=NaN([nMaxt0Trials 3]);
% ptMasking=70;
% seed=cfg.subject+cfg.session+cfg.EEGflag;
% %
% % define structure for saving output
% TRTstruct=struct('Info',[],'Data',[]);
%
% TRTstruct.Info.startTimeSecs = NaN;
% TRTstruct.Info.endTimeSecs = NaN;
% TRTstruct.Info.durationSecs = NaN;
% TRTstruct.Info.Ntrials=NaN;
% TRTstruct.Info.Npresentations=NaN;
%
% TRTstruct.Data.ptMaskingTrial=NaN([30 1]);
% TRTstruct.Data.tripletID=cell([30 3]);
% TRTstruct.Data.responseGiven=cell([30 3]);
% TRTstruct.Data.correctPres=NaN([30 3]);
% TRTstruct.Data.correctTrial=NaN([30 1]);
% TRTstruct.Data.nextStepSize=cell([30 1]);
% TRTstruct.Data.nextReversalN=cell([30 1]);
% TRTstruct.Data.RTUnmaskedPt=NaN;
% TRTstruct.Data.RTMaskedPt=NaN;
%
% IDXt0=randperm(9,3);
%
% t0_correct = 0;
%
% while ~t0_correct
%
% %     trialCheck=NaN([nMaxTrials nMaxPres4Trial]);
% %     SEED=NaN([nMaxTrials nMaxPres4Trial]);
%
%     for trial=1:nMaxt0Trials
%
%         TRTstruct.t0.ptMasking(trial)=ptMasking;
%
%         if trial == nMaxt0Trials
%             showGreetings(cfg);
%             continue
%         end
%
%             clear dig resp expResp
%
%             TRTstruct.t0.ptMaskingTrial(trial)=ptMasking;
%
%             expResp=NaN([3 1]);
%
%             for i=1:length(IDXt0)
%                 if IDXt0(i) == 1
%                     expResp(i) = 0;
%                 elseif IDXt0(i) == 2
%                     expResp(i) = 1;
%                 elseif IDXt0(i) == 3
%                     expResp(i) = 2;
%                 elseif IDXt0(i) == 4
%                     expResp(i) = 3;
%                 elseif IDXt0(i) == 5
%                     expResp(i) = 4;
%                 elseif IDXt0(i) == 6
%                     expResp(i) = 5;
%                 elseif IDXt0(i) == 7
%                     expResp(i) = 6;
%                 elseif IDXt0(i) == 8
%                     expResp(i) = 8;
%                 elseif IDXt0(i) == 9
%                     expResp(i) = 9;
%                 end
%             end
%
%             TRTstruct.t0.expResp(trial,:) = expResp;
%
%             thisFont = char('Ariel');
%
%             test3_TRT_showStim_V4(cfg,IDXt0,thisFont,ptMasking);
%
%             resp = responseKeyboard(cfg);
%
%
%             TRTstruct.t0.responseGiven{trial}=[num2str(resp(1)) num2str(resp(2)) num2str(resp(3))];
%
%             if isequal(resp,expResp')
%                 TRTstruct.t0.trialScore(trial) = 1;
%                 t0_correct = 1;
%                 break;
%             else
%                 TRTstruct.t0.trialScore(trial)=0;
%                 ptMasking=ptMasking-6;
%             end
%     end
% end
%
% TRTstruct.Data.startingPtMasking = ptMasking;
%
% ptMasking=ptMasking+6;
%
% % stepSize = [12 12 9 9 6 6 3 3]; % in percent
% % these values are chosen to exactly match the SNR dB change of the TRT
% % (from the results of Zekveld et al., 2007)
%
% stepSize = [6 6 6 6 3 3 3 3]; % in percent
% % although should be like above for total comparability with SSNRT
%
% nMaxTrials=30;
%
% trialScore=NaN([1 nMaxTrials]);
%
% % newOrder = randOrder(2:end-5);      % max 3 trials * 30 SNR lvls (need to modify?)
% % randOrderRS=reshape(newOrder, [nMaxTrials nMaxPres4Trial]);
%
% breakInner = 0;
% TRTfinished = 0;
% nMaxPres4Trial = 3;
% reversal = 0;
% reversalID=1;
%
% ceilCount = 0;
%
% if cfg.EEGflag
%     outp64(cfg.trigger.PPaddress,cfg.trigger.testStart);
%     pause(cfg.trigger.time); %5 ms
%     outp64(cfg.trigger.PPaddress,cfg.trigger.triggerOffset);
% end
% testStartSecs=fix(GetSecs);
%
% while ~TRTfinished
%
%     trialCheck=NaN([nMaxTrials nMaxPres4Trial]);
%     SEED=NaN([nMaxTrials nMaxPres4Trial]);
%
%     for trial=1:nMaxTrials
%         thisTrialCheck=NaN([1 3]);
%
%         for pres = 1:nMaxPres4Trial
%
%             seed=(cfg.subject+cfg.session+cfg.EEGflag+trial+pres)*pres;
%             rng(seed,'twister');
%             SEED(trial,pres) = seed;
%             IDX=randperm(9,3);
%
%             clear dig resp expResp
%
%             TRTstruct.Data.ptMaskingTrial(trial)=ptMasking;
%
% %             dig=cell([3 1]);
%             expResp=NaN([3 1]);
% %
%
%             for i=1:length(IDX)
%                 if IDX(i) == 1
%                     expResp(i) = 0;
%                 elseif IDX(i) == 2
%                     expResp(i) = 1;
%                 elseif IDX(i) == 3
%                     expResp(i) = 2;
%                 elseif IDX(i) == 4
%                     expResp(i) = 3;
%                 elseif IDX(i) == 5
%                     expResp(i) = 4;
%                 elseif IDX(i) == 6
%                     expResp(i) = 5;
%                 elseif IDX(i) == 7
%                     expResp(i) = 6;
%                 elseif IDX(i) == 8
%                     expResp(i) = 8;
%                 elseif IDX(i) == 9
%                     expResp(i) = 9;
%                 end
%             end
%
%             thisFont = char('Ariel');
%
%             test3_TRT_showStim_V4(cfg,IDX,thisFont,ptMasking);
%
%             resp = responseKeyboard(cfg);
%
%
%             TRTstruct.Data.responseGiven{trial,pres}=[num2str(resp(1)) num2str(resp(2)) num2str(resp(3))];
%
%             if isequal(resp,expResp')
%                 trialCheck(trial,pres) = 1;
%                 thisTrialCheck(pres)=1;
%                 TRTstruct.Data.correctPres(trial,pres)=1;
%             else
%                 trialCheck(trial,pres) = 0;
%                 thisTrialCheck(pres)=0;
%                 TRTstruct.Data.correctPres(trial,pres)=0;
%             end
%
%             if pres == 2
%                 if sum(thisTrialCheck,'omitnan')==2
%                     % if sum(thisTrialCheck(~isnan(thisTrialCheck))) ==2
%                     trialScore(trial)=1;
%                     TRTstruct.Data.correctTrial(trial)=1;
%                     pres = 3;
%                     if (trial == 1 && trialScore(trial) == 0)   ||   (trial ~= 1 && isequal(trialScore(trial),trialScore(trial-1))==0)
%                         reversal = reversal + 1;
%                         reversalID = reversalID + 1;
%                         if reversal == 8 || trial == nMaxTrials
%                             %save stuff
%                             TRTfinished =1;
%                             breakInner = 1;
%                         end
%                     end
%                     if ~TRTfinished && ((ptMasking + stepSize(reversalID)) < 100)
%                         ptMasking = ptMasking + stepSize(reversalID);
%                     elseif ~TRTfinished && ((ptMasking + stepSize(reversalID)) >= 100)
%                         ptMasking = 97;
%                         ceilCount = ceilCount+1;
%                     end
%
%                                         break
%                 elseif sum(thisTrialCheck,'omitnan')==0
%                     trialScore(trial)=0;
%                     TRTstruct.Data.correctTrial(trial)=0;
%                     pres = 3;
%                     if (trial == 1 && trialScore(trial) == 0)   ||   (trial ~= 1 && isequal(trialScore(trial),trialScore(trial-1))==0)
%                         reversal = reversal + 1;
%                         reversalID = reversalID + 1;
%                         if reversal == 8 || trial == nMaxTrials
%                             %save stuff
%                             TRTfinished =1;
%                             breakInner = 1;
%                         end
%                     end
%                     if ~TRTfinished
%                         ptMasking = ptMasking - stepSize(reversalID);
%                     end
%                                         break
%                 end
%             elseif pres == 3
%                 % isnan probably not needed:
%                 if sum(thisTrialCheck,'omitnan')==2 || sum(thisTrialCheck,'omitnan')==3
%                     trialScore(trial)=1;
%                     TRTstruct.Data.correctTrial(trial)=1;
%                     if (trial == 1 && trialScore(trial) == 0)   ||   (trial ~= 1 && isequal(trialScore(trial),trialScore(trial-1))==0)
%                         reversal = reversal + 1;
%                         reversalID = reversalID + 1;
%                         if reversal == 8 || trial == nMaxTrials
%                             %save stuff
%                             TRTfinished =1;
%                             breakInner = 1;
%                         end
%                     end
%                     if ~TRTfinished && ((ptMasking + stepSize(reversalID)) < 100)
%                         ptMasking = ptMasking + stepSize(reversalID);
%                     elseif ~TRTfinished && ((ptMasking + stepSize(reversalID)) >= 100)
%                         ptMasking = 97;
%                         ceilCount = ceilCount+1;
%                     end
%                                         break
%                 elseif sum(thisTrialCheck,'omitnan')==0 || sum(thisTrialCheck,'omitnan')==1
%                     trialScore(trial)=0;
%                     TRTstruct.Data.correctTrial(trial)=0;
%                     if (trial == 1 && trialScore(trial) == 0)   ||   (trial ~= 1 && isequal(trialScore(trial),trialScore(trial-1))==0)
%                         reversal = reversal + 1;
%                         reversalID = reversalID + 1;
%                         if reversal == 8 || trial == nMaxTrials
%                             %save stuff
%                             TRTfinished =1;
%                             breakInner = 1;
%                         end
%                     end
%                     if ~TRTfinished
%                         ptMasking = ptMasking - stepSize(reversalID);
%                     end
%                                         break
%                     %                 status = 'decrease difficulty';
%                 end
%             end
%         end     % pres loop
%
%         if breakInner || ceilCount > 2
%             break
%         end
%
%         if reversalID < 9
%             TRTstruct.Data.nextStepSize{trial} = stepSize(reversalID);
%             TRTstruct.Data.nextReversalN{trial} = reversal;
%         end
%
%         if reversal == 8 || trial == nMaxTrials
%             %save stuff
%             TRTfinished =1;
%             %                             break
%         end
% %         disp(['reversal ' num2str(reversal)])
%     end     % trial loop
% end
%
% save([cfg.path.TRTdir 'SEED.mat'],'SEED')
%
% if cfg.EEGflag
%     outp64(cfg.trigger.PPaddress,cfg.trigger.testStart);
%     pause(cfg.trigger.time); %5 ms
%     outp64(cfg.trigger.PPaddress,cfg.trigger.triggerOffset);
% end
% testEndSecs=fix(GetSecs);
% testDurationSecs=testEndSecs-testStartSecs;
%
% TRTstruct.Info.startTimeSecs = testStartSecs;
% TRTstruct.Info.endTimeSecs = testEndSecs;
% TRTstruct.Info.durationSecs = testDurationSecs;
% TRTstruct.Info.Ntrials = sum(~isnan(TRTstruct.Data.ptMaskingTrial));
% TRTstruct.Info.Npresentations = sum(sum(~isnan(TRTstruct.Data.correctPres)));
%
% TRTstruct.Data.RTUnmaskedPt=100-ptMasking;
% TRTstruct.Data.RTMaskedPt=ptMasking;
%
% %% ****************************** save ********************************* %%
%
% save([cfg.path.TRTdir 'TRTMaskedPt.mat'], 'ptMasking')
%
% save([cfg.path.TRTdir 'TRTfullReport.mat'],'TRTstruct')
%
% showGreetings(cfg);
%
% %
% trialID=(1:TRTstruct.Info.Ntrials)';
% maskingRange=TRTstruct.Data.ptMaskingTrial(1:TRTstruct.Info.Ntrials);
% pres1correct=TRTstruct.Data.correctPres(1:TRTstruct.Info.Ntrials,1);
% pres2correct=TRTstruct.Data.correctPres(1:TRTstruct.Info.Ntrials,2);
% pres3correct=TRTstruct.Data.correctPres(1:TRTstruct.Info.Ntrials,3);
% trialCorrect=TRTstruct.Data.correctTrial(1:TRTstruct.Info.Ntrials);
% revID=vertcat(TRTstruct.Data.nextReversalN{1:TRTstruct.Info.Ntrials-1}, 8);
%
% maskingPT_ChangeFromPrev=NaN([length(maskingRange) 1]);
%
%
% for i =1:length(maskingRange)
%     if i==1
%         maskingPT_ChangeFromPrev(i) = 6;
%     else
%         maskingPT_ChangeFromPrev(i) = maskingRange(i) - maskingRange(i-1);
%     end
% end
%
%
% clear T uB
%
% T = table(trialID,maskingRange,pres1correct,pres2correct,pres3correct,...
%      trialCorrect,revID,maskingPT_ChangeFromPrev);
%
% writetable(T,[cfg.path.TRTdir 'TRT.csv'],'Delimiter',',')
%
% %************************************************************%
% %           plot:
% [~, uB, ~] = unique(revID);
%
% if (max(maskingRange)+5) > 100
%     high=100;
% else
%     high = max(maskingRange)+5;
% end
% if (min(maskingRange)-5) < 0
%     low = 0;
% else
%     low=min(maskingRange)-5;
% end
%
% figure;
% if TRTstruct.Data.correctTrial(1) == 1
%     plot(trialID,maskingRange,'o-b','MarkerFaceColor','red','MarkerEdgeColor','red','MarkerIndices',uB(2:end));
% elseif TRTstruct.Data.correctTrial(1) == 1
%     plot(trialID,maskingRange,'o-b','MarkerFaceColor','red','MarkerEdgeColor','red','MarkerIndices',uB);
% end
% ylim([low high])
% xlim([-1 trialID(end)+1])
% xticks(0:trialID(end))
% yticks(low:high)
% grid on
% xtickangle(340)
% ytickangle(25)
% title(['TRT subject ' num2str(cfg.subject) ' ' date])
% xlabel('Trial')
% ylabel('Masking (%)')
% hold on
% plot([0;1],[TRTstruct.Data.startingPtMasking; TRTstruct.Data.ptMaskingTrial(1)],'--b')
% plot(0,TRTstruct.Data.startingPtMasking,'ob','MarkerFaceColor','blue')
%
% saveas(gcf,[cfg.path.TRTdir 'TRT subject ' num2str(cfg.subject) ' ' date '.jpg'], 'jpg')


% catch ME
%     ME.getReport % spits out error information to command window. Useful for debugging or error hunting purposes
%     c = fix(clock);
%     baseName = ['TRT_' num2str(c(1)) '_' num2str(c(2)) '_' num2str(c(3)) '_' num2str(c(4)) '_' num2str(c(5))]; %makes unique filename
%     save(fullfile(options.outputDir,['Crashed_TRT_Workspace_', baseName, '.mat']))
end

