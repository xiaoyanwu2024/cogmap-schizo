function [rt, timeClickCount, ageClickCount] = presentNavigationTrial(win, instrDir, correctAge, correctTime, foodName, xCenter, yCenter)
ShowCursor;

% Lists
ageList  = {'toddler', 'child', 'teenager', 'adult', 'midAge', 'elderly', 'old'};
timeList = {'dawn', 'morning', 'noon', 'afternoon', 'sunset', 'evening', 'night'};
nAge  = length(ageList);
nTime = length(timeList);

% Layout parameters
imgSize = 80;
spacing = 30;
totalWidthAge = nAge * imgSize + (nAge - 1) * spacing;
startXAge = xCenter - totalWidthAge / 2 + imgSize / 2;
yAge = yCenter + 250;
totalWidthTime = nTime * imgSize + (nTime - 1) * spacing;
startXTime = xCenter - totalWidthTime / 2 + imgSize / 2;
yTime = yCenter + 150;

% Preload images
foodImg = imread(fullfile(instrDir, 'food', [foodName '.tiff']));
texFood = Screen('MakeTexture', win, foodImg);
preloadTimeTex = cellfun(@(x) Screen('MakeTexture', win, imread(fullfile(instrDir, 'time', [x '.tiff']))), timeList, 'UniformOutput', false);
preloadAgeTex  = cellfun(@(x) Screen('MakeTexture', win, imread(fullfile(instrDir, 'age',  [x '.tiff']))), ageList, 'UniformOutput', false);

% Initialization
chosenAgeIdx = [];
chosenTimeIdx = [];
mWasDown = false;
TimeisCorrect = false;
AgeisCorrect = false;

timeClickCount = 0;
ageClickCount = 0;

rtStart = GetSecs;
while true
    checkForEscape();
    % --- Update image positions on every screen refresh ---
    Screen('FillRect', win, 255);
    Screen('DrawTexture', win, texFood, [], CenterRectOnPoint([0 0 120 120], xCenter, yCenter - 150));

    % === Present Time options first ===
    timeRects = cell(1, nTime);
    for t = 1:nTime
        rect = CenterRectOnPoint([0 0 imgSize imgSize], startXTime + (t-1) * (imgSize + spacing), yTime);
        timeRects{t} = rect;
        Screen('DrawTexture', win, preloadTimeTex{t}, [], rect);
        if ~isempty(chosenTimeIdx) && chosenTimeIdx == t
            TimeisCorrect = strcmp(timeList{t}, correctTime);
            color = [0 255 0] * TimeisCorrect + [255 0 0] * (1 - TimeisCorrect);
            Screen('FrameRect', win, color, rect, 4);
        end
    end

    % === Mouse detection ===
    [x, y, buttons] = GetMouse(win);
    if any(buttons) && ~mWasDown
        % Time check
        for t = 1:nTime
            if IsInRect(x, y, timeRects{t})
                chosenTimeIdx = t;
                chosenAgeIdx = [];  % After selecting Time, reset Age choice
                timeClickCount = timeClickCount + 1;  % ★ Time click counter +1
                break;
            end
        end
        % Age check (must choose Time first)
        if ~isempty(chosenTimeIdx) && ~isempty(ageRects)
            for a = 1:nAge
                if ~isempty(ageRects{a}) && IsInRect(x, y, ageRects{a})
                    chosenAgeIdx = a;
                    ageClickCount = ageClickCount + 1;  % ★ Age click counter +1
                    break;
                end
            end
        end
        mWasDown = true;
    elseif ~any(buttons)
        mWasDown = false;
    end

    % === After Time is chosen correctly → Age options appear ===
    if TimeisCorrect
        % if ~isempty(chosenTimeIdx)
        ageRects = cell(1, nAge);
        for a = 1:nAge
            rect = CenterRectOnPoint([0 0 imgSize imgSize], startXAge + (a-1) * (imgSize + spacing), yAge);
            ageRects{a} = rect;
            Screen('DrawTexture', win, preloadAgeTex{a}, [], rect);
            if ~isempty(chosenAgeIdx) && chosenAgeIdx == a
                AgeisCorrect = strcmp(ageList{a}, correctAge);
                color = [0 255 0] * AgeisCorrect + [255 0 0] * (1 - AgeisCorrect);
                Screen('FrameRect', win, color, rect, 4);
            end
        end
    else
        ageRects = cell(1, nAge); % Keep structure to prevent errors
    end

    % === If both choices are correct, display "Correct!" ===
    if TimeisCorrect && AgeisCorrect
        DrawFormattedText(win, 'Correct!', 'center', 'center', [0 128 0]);
        Screen('Flip', win);           % Actually display "Correct!" first
        WaitSecs(1);                   % Hold for 1 second
        break;                         % Then exit the while loop
    end

    Screen('Flip', win);
    WaitSecs(0.01);  % Prevent excessive CPU usage
end

% === Trial end: compute RT ===
rt = GetSecs - rtStart;
end
