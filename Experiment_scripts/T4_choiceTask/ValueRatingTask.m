function ValueRatingTask(subid, group)
try
    %% Initialization
    addpath(fullfile(pwd, 'functions'));
    Screen('Preference', 'SkipSyncTests', 1);
    KbName('UnifyKeyNames');
    ListenChar(2);

    % Set up result saving path
    resultFolder = fullfile(pwd, 'results', group, ['sub_' subid]);
    dateStr = datestr(now, 'yyyy_mm_dd');
    dataFile = fullfile(resultFolder, sprintf('sub_%s_%s_rating_task.mat', subid, dateStr));

    % Load participant-specific basetrial file
    basePath = fullfile('..', 'T3_associationLearn', group, 'baseTrials');
    files = dir(fullfile(basePath, ['sub' subid '*.mat']));
    assert(~isempty(files), 'No matching baseTrials file found.');
    load(fullfile(basePath, files(1).name), 'baseTrials');

    % Load participants' data to get the restaurant name
    fileInfo = dir(fullfile(resultFolder, '*_data.mat'));  % Find files ending with .data.mat

    % Check whether the file is found
    if ~isempty(fileInfo)
        dataFilePath = fullfile(resultFolder, fileInfo(1).name);  % Use the first matched file
        loadedData = load(dataFilePath);
    else
        error('No .data.mat file found in the folder: %s', resultFolder);
    end

    % Create a matrix of mappings and restaurant names based on the data file
    % Get mapping info from the first record
    mapValue = loadedData.result(1).map;
    restaurantName = loadedData.result(1).restaurantName;

    % Derive the overall mapping from this record
    if mapValue == 1
        map1_restaurant = restaurantName;
        map2_restaurant = setdiff({'Tree', 'River'}, restaurantName);
        map2_restaurant = map2_restaurant{1};
    else
        map2_restaurant = restaurantName;
        map1_restaurant = setdiff({'Tree', 'River'}, restaurantName);
        map1_restaurant = map1_restaurant{1};
    end

    % Assign monetary values to food options
    map1 = [0.25, 0.67, 0.08, 0.5, 0.92, 0.42]*95 + 5;   % map1 was missing 5
    map2 = [0.67, 0.22, 0.94, 0.56, 0.11, 0.72]*95 + 5;  % map2 was missing 2

    %% Screen setup
    screenNumber = max(Screen('Screens'));
    [win, winRect] = Screen('OpenWindow', screenNumber, 255);  % 白色背景
    [xCenter, yCenter] = RectCenter(winRect);
    Screen('TextSize', win, 28);
    HideCursor;

    %% Construct randomized trial list
    createTrialList = @(mapVals, restID) [baseTrials(randperm(6),3), repmat({num2str(restID)},6,1), num2cell(mapVals(randperm(6))')];

    idx1 = randperm(6);
    trialList1 = cell(6, 3);
    trialList1(:,1) = baseTrials(idx1, 3);
    trialList1(:,2) = repmat({num2str(1)}, 6, 1);
    trialList1(:,3) = num2cell(map1(idx1));
    trialList1(:,4) = {map1_restaurant};

    idx2 = randperm(6);
    trialList2 = cell(6, 3);
    trialList2(:,1) = baseTrials(idx2, 3);
    trialList2(:,2) = repmat({num2str(2)}, 6, 1);
    trialList2(:,3) = num2cell(map2(idx2));
    trialList2(:,4) = {map2_restaurant};

    randStart = randi(2);
    if randStart == 1
        trialList = [trialList1; trialList2];
    else
        trialList = [trialList2; trialList1];
    end

    %% Show instruction slides
    imgPath = fullfile(pwd, 'stimuli');
    instrFiles = dir(fullfile(imgPath, 'ratingIns1*.tiff'));
    instrPages = sort({instrFiles.name});

    page = 1;
    while page <= length(instrPages)
        instrImg = imread(fullfile(imgPath, instrPages{page}));
        tex = DrawImageNoStretch(win, instrImg);
        Screen('Flip', win);
        WaitSecs(0.5); % Debounce delay

        % wait for response
        while true
            checkForEscape();
            [keyIsDown, ~, keyCode] = KbCheck;
            if keyIsDown
                if keyCode(KbName('RightArrow'))
                    page = page + 1;
                    break;
                elseif keyCode(KbName('LeftArrow'))
                    page = max(1, page - 1);
                    break;
                end
            end
        end
        WaitSecs(0.2); % Debounce delay
        Screen('Close', tex);
    end

    %% Rating Task
    ratingResults = struct();
    for t = 1:length(trialList)
        food = trialList{t, 1};
        map = trialList{t, 2};
        tValue = trialList{t, 3};
        restaurant = trialList{t, 4};
        % Show restaurant cue at the start of each block
        if ismember(t, [1,7]) % each restaurant has 6 trials
            remainText = sprintf('The following food items are from Restaurant %s.\n\nPress any key to start.', restaurant);
            Screen('FillRect', win, [217 217 217]);
            DrawFormattedText(win, remainText, 'center', 'center', [0 0 0]);
            Screen('Flip', win);
            KbStrokeWait;
        end

        % Load and display image
        img = imread(fullfile(imgPath, [food '.tiff']));
        tex = Screen('MakeTexture', win, img);
        imgRect = [0 0 300 300];
        dstRect = CenterRectOnPoint(imgRect, xCenter, yCenter - 100);

        % Slider setup
        sliderMin = xCenter - 300;
        sliderMax = xCenter + 300;
        sliderX = round((2*xCenter - 600) + rand() * 1200); % Random initial position
        SetMouse(sliderX, 2*yCenter + 400, win);

        clicked = false;
        tStart = GetSecs;

        % Rating loop
        while ~clicked
            checkForEscape();
            [x,~,buttons] = GetMouse(win);
            x = min(max(x, sliderMin), sliderMax);
            rating = round(100 * (x - sliderMin) / (sliderMax - sliderMin));

            % Draw screen elements
            Screen('FillRect', win, 255);
            Screen('DrawTexture', win, tex, [], dstRect);
            DrawFormattedText(win, sprintf('Restaurant: %s', restaurant), 'center', yCenter + 100, [0 0 0]);

            % Slider rendering
            baseRect = [sliderMin-5, yCenter+195, sliderMax+5, yCenter+205];
            handleRect = [x-10, yCenter+190, x+10, yCenter+210];
            Screen('FillRect', win, [160 160 160], baseRect);
            Screen('FillRect', win, [176 36 24], handleRect);

            % Display rating value
            % ratingStr = sprintf('%d', rating);
            ratingStr = sprintf('$%d', rating);
            bounds = Screen('TextBounds', win, ratingStr);
            textX = x - (bounds(3)-bounds(1))/2;
            textY = yCenter + 150;
            DrawFormattedText(win, ratingStr, textX, textY, [0 0 0]);
            DrawFormattedText(win, 'Move the slider with your mouse. Click the left mouse button to confirm.', 'center', yCenter + 250, [0 0 0]);
            Screen('Flip', win);

            % Confirm response on click
            if any(buttons)
                while any(buttons)
                    [~,~,buttons] = GetMouse(win);
                end
                clicked = true;

                % Display confirmation screen
                Screen('FillRect', win, 255);
                Screen('DrawTexture', win, tex, [], dstRect);
                DrawFormattedText(win, sprintf('Restaurant: %s', restaurant), 'center', yCenter + 100, [0 0 0]);
                Screen('FillRect', win, [160 160 160], baseRect);
                Screen('FillRect', win, [176 36 24], handleRect);
                DrawFormattedText(win, ratingStr, textX, textY, [255 0 0]);
                DrawFormattedText(win, 'Move the slider with your mouse. Click the left mouse button to confirm.', 'center', yCenter + 250, [0 0 0]);
                Screen('Flip', win);
                WaitSecs(0.5);
            end
        end

        % Record trial data
        rt = GetSecs - tStart;
        ratingResults(t).trial = t;
        ratingResults(t).food = food;
        ratingResults(t).map = map;
        ratingResults(t).restaurantName = restaurant;
        ratingResults(t).trueValue = tValue;
        ratingResults(t).ratingValue = rating;
        ratingResults(t).RT = rt;
        save(dataFile, 'ratingResults');

        % Inter-trial pause
        Screen('FillRect', win, [217 217 217]);
        DrawFormattedText(win, 'next round...', 'center', 'center', [0 0 0]);
        Screen('Flip', win);
        WaitSecs(0.5);
    end

    %% Task complete
    DrawFormattedText(win, 'Rating task complete! Press any key to exit.', 'center', 'center', [0 0 0]);
    Screen('Flip', win);
    ListenChar(0);
    ShowCursor;
    KbWait;
    sca;

catch ME
    sca; ListenChar(0); ShowCursor;
    rethrow(ME);
end
