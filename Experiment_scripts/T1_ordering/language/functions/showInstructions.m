function lastPage = showInstructions(win, instrPattern, instrDir)

    % 默认参数
    if nargin < 2
        instrPattern = 'ins*.tiff';
    end
    if nargin < 3
        instrDir = fullfile(pwd, 'stimuli');
    end

    % 加载指令图片文件名
    instrFiles = dir(fullfile(instrDir, instrPattern));
    instrPages = sort({instrFiles.name});

    page = 1;
    while page <= length(instrPages)
        % 读取并显示图像
        instrImg = imread(fullfile(instrDir, instrPages{page}));
        tex = Screen('MakeTexture', win, instrImg);

        % 获取屏幕尺寸
        [imgH, imgW, ~] = size(instrImg);
        [screenX, screenY] = Screen('WindowSize', win);
        scale = min(screenX / imgW, screenY / imgH);
        dstRect = CenterRectOnPointd([0 0 imgW*scale imgH*scale], screenX/2, screenY/2);

        % 呈现图片
        Screen('DrawTexture', win, tex, [], dstRect);
        Screen('Flip', win);
        WaitSecs(0.2);  % 防误触

        % 等待按键翻页
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

        WaitSecs(0.2);  % 防连按
        Screen('Close', tex);
    end

    if nargout > 0
        lastPage = page;
    end
end
