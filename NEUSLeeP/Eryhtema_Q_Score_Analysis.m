%% 
clc; clear all; close all

%% Main
result = erythema_qscore_analysis('/Users/kevintang/Desktop/Desktop-Kevin/UTAustin/Project/DARPA-REM-Sleep/Experiments/Bioadhesive Substrate/Images/Day 2.jpg');
disp(result)
%%
function results = erythema_qscore_analysis(imageFile, doInvert)

if nargin < 2
    doInvert = false;
end

I = imread(imageFile);
I = im2double(I);

R = I(:,:,1);
G = I(:,:,2);
ratio_red = R ./ max(G,1e-6);

[H,W,~] = size(I);

figure('Name','EQ Score Analysis','Color','w')
imshow(I)
hold on

results = struct([]);
lesionIdx = 0;
continueFlag = true;

while continueFlag

    lesionIdx = lesionIdx + 1;

    fprintf('\nLesion %d\n', lesionIdx);

    %% -----------------------------
    % FREEHAND LESION FIELD
    %% -----------------------------
    title({'Draw LESION FIELD (freehand)','Double-click to finish'})

    hField = drawfreehand('Color','y','LineWidth',1.5);
    wait(hField)

    fieldMask = createMask(hField);
    fieldPos = hField.Position;

    input('Press Enter to define gradient ROI...','s')

    delete(hField)

    %% -----------------------------
    % GRADIENT ROI (TEMPORARY)
    %% -----------------------------
    title({'Draw GRADIENT ROI','Must include lesion + normal skin'})

    hGrad = drawrectangle('Color','c','LineWidth',1.5);
    wait(hGrad)

    gradRect = round(hGrad.Position);
    gradMask = rectMask(gradRect,H,W);

    input('Press Enter to define normal ROI...','s')

    delete(hGrad)

    %% -----------------------------
    % NORMAL ROI (TEMPORARY)
    %% -----------------------------
    title({'Draw NORMAL SKIN ROI','Only unaffected skin'})

    hNorm = drawrectangle('Color','g','LineWidth',1.5);
    wait(hNorm)

    normRect = round(hNorm.Position);
    normMask = rectMask(normRect,H,W);

    input('Press Enter to calculate EQ score...','s')

    delete(hNorm)

    %% -----------------------------
    % PAPER METHOD CALCULATION
    %% -----------------------------
    threshold = median(ratio_red(gradMask),'omitnan');

    if ~doInvert
        lesionMask = fieldMask & (ratio_red > threshold);
    else
        lesionMask = fieldMask & (ratio_red < threshold);
    end

    lesionVals = ratio_red(lesionMask);
    norm_red = mean(ratio_red(normMask),'omitnan');

    if isempty(lesionVals)
        lesion_red = NaN;
        EQCI = NaN;
        EQCIs = NaN;
        EQscore = NaN;
    else
        lesion_red = mean(lesionVals,'omitnan');

        EQCI  = 10*(lesion_red/norm_red - 1);
        EQCIs = 0.34 + 0.54*EQCI;
        EQscore = -0.35 + 1.9*EQCIs - 0.2*(EQCIs.^2);
    end

    %% -----------------------------
    % CLEAN DISPLAY
    %% -----------------------------
    plot(fieldPos(:,1),fieldPos(:,2),'y','LineWidth',1.5)

    if ~isnan(EQscore) && EQscore >= 0

        B = bwboundaries(lesionMask);

        for k = 1:length(B)
            plot(B{k}(:,2),B{k}(:,1),'r','LineWidth',1.5)
        end

    end

    stats = regionprops(fieldMask,'Centroid');

    if ~isempty(stats)
        c = stats(1).Centroid;
    else
        c = [20 20];
    end

    text(c(1),c(2),sprintf('EQ=%.2f',EQscore),...
        'Color','w',...
        'FontSize',10,...
        'FontWeight','bold',...
        'BackgroundColor','k',...
        'Margin',3,...
        'HorizontalAlignment','center')

    %% -----------------------------
    % SAVE RESULT
    %% -----------------------------
    results(lesionIdx).EQscore = EQscore;
    results(lesionIdx).EQCI = EQCI;
    results(lesionIdx).lesion_red = lesion_red;
    results(lesionIdx).norm_red = norm_red;
    results(lesionIdx).threshold = threshold;

    fprintf('\nEQ Score = %.3f\n',EQscore);

    %% -----------------------------
    % CONTINUE?
    %% -----------------------------
    resp = input('Add another lesion? (y/n): ','s');

    if isempty(resp)
        resp = 'n';
    end

    continueFlag = lower(resp(1)) == 'y';

end

hold off

end


function mask = rectMask(rect,H,W)

mask = false(H,W);

x1 = rect(1);
y1 = rect(2);
x2 = min(W,rect(1)+rect(3)-1);
y2 = min(H,rect(2)+rect(4)-1);

mask(y1:y2,x1:x2) = true;

end