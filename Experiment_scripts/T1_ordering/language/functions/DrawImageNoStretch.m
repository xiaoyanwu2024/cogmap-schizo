function DrawImageNoStretch(win, img)
% DrawImageNoStretch  绘制一张图片，不变形、保持比例、自动居中
%
% 用法:
%    DrawImageNoStretch(win, img)
%
% 参数:
%    win : Psychtoolbox 窗口句柄
%    img : 已经 imread 读取好的图片 (matrix)

    % 创建纹理
    tex = Screen('MakeTexture', win, img);

    % 获取屏幕大小
    [screenXpixels, screenYpixels] = Screen('WindowSize', win);

    % 获取图片的尺寸
    [imgHeight, imgWidth, ~] = size(img);

    % 计算缩放比例，保持比例适配屏幕
    scaleX = screenXpixels / imgWidth;
    scaleY = screenYpixels / imgHeight;
    scaleFactor = min(scaleX, scaleY);  % 选最小的比例

    % 缩放后的图片尺寸
    newWidth  = imgWidth * scaleFactor;
    newHeight = imgHeight * scaleFactor;

    % 计算居中位置
    xCenter = screenXpixels / 2;
    yCenter = screenYpixels / 2;
    destinationRect = CenterRectOnPointd([0 0 newWidth newHeight], xCenter, yCenter);

    % 绘制图片
    Screen('DrawTexture', win, tex, [], destinationRect);

end
