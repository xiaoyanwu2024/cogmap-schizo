function lastPage = showInstructions(win, instrPattern, instrDir)

% Default arguments
if nargin < 2
    instrPattern = 'ins*.tiff';
end
if nargin < 3
    instrDir = fullfile(pwd, 'stimuli');
end

% Load instruction image filenames
instrFiles = dir(fullfile(instrDir, instrPattern));
instrPages = sort({instrFiles.name});

page = 1;
while page <= length(instrPages)
    % Read and display the image
    instrImg = imread(fullfile(instrDir, instrPages{page}));
    tex = Screen('MakeTexture', win, instrImg);

    % Get screen and image size, compute scaling
    [imgH, imgW, ~] = size(instrImg);
    [screenX, screenY] = Screen('WindowSize', win);
    scale = min(screenX / imgW, screenY / imgH);
    dstRect = CenterRectOnPointd([0 0 imgW*scale imgH*scale], screenX/2, screenY/2);

    % Present image
    Screen('DrawTexture', win, tex, [], dstRect);
    Screen('Flip', win);
    WaitSecs(0.2);  % Debounce: prevent accidental key presses

    % Wait for key press to turn pages
    while true
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

    WaitSecs(0.2);  % Debounce: prevent rapid repeated presses
    Screen('Close', tex);
end

if nargout > 0
    lastPage = page;
end
end
