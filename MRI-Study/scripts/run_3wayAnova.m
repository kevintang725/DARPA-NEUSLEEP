clc ; clear all; close all

%%

filepath = '/Users/kevintang/Downloads/BetaCoefficients.xlsx';

run_three_way_anova_per_roi(filepath);
%%
function run_three_way_anova_per_roi(xlsxPath)
% run_three_way_anova_per_roi
% Usage:
%   run_three_way_anova_per_roi('BetaCoefficients.xlsx')
%
% Does:
%   - Parse wide ROI x (Subject×Condition) Excel
%   - Build long table with factors: Task, Group, Treatment
%   - Separate 3-way ANOVA per ROI (Task×Group×Treatment)
%   - Export p-values, BH-FDR q-values, and detailed results

if nargin < 1
    xlsxPath = 'BetaCoefficients.xlsx';
end

%% ---------- Load ----------
T = readtable(xlsxPath, 'Sheet', 1, 'ReadVariableNames', true);

if width(T) < 2
    error('The table must have ROI names in col 1 and data columns after that.');
end

roiCol = T{:,1};
if ~iscellstr(roiCol) && ~isstring(roiCol) && ~iscategorical(roiCol)
    % Try to coerce into strings if someone pasted numeric codes
    roiCol = string(roiCol);
end
ROI = string(roiCol);

allVarNames = string(T.Properties.VariableNames);

% Drop columns that are clearly empty/unnamed or entirely NaN
keep = false(size(allVarNames));
keep(1) = true; % keep ROI name column
for c = 2:numel(allVarNames)
    vn = allVarNames(c);
    if startsWith(vn, "Unnamed", 'IgnoreCase', true)
        continue
    end
    col = T{:,c};
    if isnumeric(col)
        if all(isnan(col))
            continue
        end
    end
    keep(c) = true;
end

T = T(:, keep);
allVarNames = string(T.Properties.VariableNames);
condNames = allVarNames(2:end);

%% ---------- Helper: parse header -> Task, Hemisphere, Group, Treatment ----------
% Headers look like: "Anger (Left/Healthy/Sham)"
% We only need Task, Group, Treatment for the 3-way ANOVA; Hemisphere is parsed but unused.
nbspace = char(160); % non-breaking space that often appears in Excel headers
parseOne = @(s) parseHeader(cleanHeader(s, nbspace));

%% ---------- Build long table ----------
stacked = table();
nR = height(T);

rowBlocks = cell(numel(condNames),1);
for c = 1:numel(condNames)
    rawName = condNames(c);
    [Task, Hemisphere, Group, Treatment] = parseOne(rawName);

    betaCol = T{:, c+1}; % +1 because col1 is ROI names
    % Build block for this column (one row per ROI)
    blk = table();
    blk.ROI        = ROI;
    blk.Task       = repmat(Task, nR, 1);
    blk.Hemisphere = repmat(Hemisphere, nR, 1);
    blk.Group      = repmat(Group, nR, 1);
    blk.Treatment  = repmat(Treatment, nR, 1);
    blk.Beta       = betaCol;
    % Make a subject ID per column (unique)
    blk.Subject    = repmat(rawName, nR, 1);
    rowBlocks{c}   = blk;
end

stacked = vertcat(rowBlocks{:});

% Drop rows with missing Beta
stacked = stacked(~isnan(stacked.Beta), :);

% Cast to categorical
stacked.Task      = categorical(stacked.Task);
stacked.Group     = categorical(stacked.Group);
stacked.Treatment = categorical(stacked.Treatment);
stacked.ROI       = categorical(stacked.ROI);
stacked.Subject   = categorical(stacked.Subject);

%% ---------- Separate 3-way ANOVA per ROI ----------
effects = {'Task','Group','Treatment', ...
           'Task*Group','Task*Treatment','Group*Treatment', ...
           'Task*Group*Treatment'};

uROIs = categories(stacked.ROI);
nROI  = numel(uROIs);

P = nan(nROI, numel(effects));       % p-values
Results = struct();

for i = 1:nROI
    r = uROIs{i};
    roiTbl = stacked(stacked.ROI == r, :);

    % anovan will accept unbalanced cells as long as every term is estimable
    try
        [p, tbl, stats] = anovan(roiTbl.Beta, ...
            {roiTbl.Task, roiTbl.Group, roiTbl.Treatment}, ...
            'model', 'full', ...
            'varnames', {'Task','Group','Treatment'}, ...
            'display', 'off');

        % anovan returns p's in this order for 3 factors with model='full':
        % main effects (1:3), two-way (4:6), three-way (7)
        if numel(p) ~= 7
            warning('Unexpected number of terms for ROI %s. Skipping.', r);
            continue
        end

        P(i,:) = p(:)';

        Results.(r).p       = p;
        Results.(r).table   = tbl;
        Results.(r).stats   = stats;
        Results.(r).effects = effects;

    catch ME
        warning('ANOVA failed for ROI %s: %s', r, ME.message);
    end
end

%% ---------- Multiple-comparison correction (BH-FDR) per effect ----------
Q = nan(size(P));
for j = 1:numel(effects)
    Q(:,j) = bh_fdr(P(:,j));
end

%% ---------- Export summaries ----------
outDir = fileparts(which(xlsxPath));
if isempty(outDir); outDir = pwd; end

pTbl = array2table(P, 'VariableNames', matlab.lang.makeValidName(effects), ...
                      'RowNames', cellstr(uROIs));
qTbl = array2table(Q, 'VariableNames', matlab.lang.makeValidName(strcat(effects,'_q')), ...
                      'RowNames', cellstr(uROIs));

writetable(resetRowNames(pTbl), fullfile(outDir, 'ROI_ThreeWayANOVA_pvals.csv'));
writetable(resetRowNames(qTbl), fullfile(outDir, 'ROI_ThreeWayANOVA_qvals.csv'));

% Also export a long tidy table
[roiIdx, effIdx] = find(~isnan(P));
long = table();
long.ROI    = uROIs(roiIdx);
long.Effect = effects(effIdx)';
long.p      = arrayfun(@(i,j) P(i,j), roiIdx, effIdx);
long.q      = arrayfun(@(i,j) Q(i,j), roiIdx, effIdx);
writetable(long, fullfile(outDir, 'ROI_ThreeWayANOVA_long.csv'));

% Save detailed struct
save(fullfile(outDir, 'ROI_ThreeWayANOVA_results.mat'), 'Results', 'effects', 'P', 'Q', 'uROIs');

fprintf('\nDone.\nWrote:\n  %s\n  %s\n  %s\n', ...
    fullfile(outDir, 'ROI_ThreeWayANOVA_pvals.csv'), ...
    fullfile(outDir, 'ROI_ThreeWayANOVA_qvals.csv'), ...
    fullfile(outDir, 'ROI_ThreeWayANOVA_long.csv'));

%% ---------- Optional: examples for post hocs ----------
%{
% Example: post-hoc on a specific ROI if main effect of Task is significant
roiName = 'Amyg';
roiTbl = stacked(stacked.ROI == roiName, :);
[~, ~, stats] = anovan(roiTbl.Beta, {roiTbl.Task, roiTbl.Group, roiTbl.Treatment}, ...
    'model','full','varnames',{'Task','Group','Treatment'},'display','off');

% Pairwise Task comparisons collapsed over Group/Treatment
mcTask = multcompare(stats, 'Dimension', 1);  % 1=Task, 2=Group, 3=Treatment
%}

end % main function


%% ---------- Helpers ----------
function s = cleanHeader(s, nbspace)
% Normalize header strings:
% - convert to string
% - replace non-breaking spaces with regular spaces
% - trim
% - collapse multiple spaces
% - replace commas with slashes (just in case)
s = string(s);
s = replace(s, nbspace, ' ');
s = strtrim(s);
s = regexprep(s, '\s+', ' ');
s = replace(s, ',', '/');
end

function [Task, Hemisphere, Group, Treatment] = parseHeader(hdr)
% Parse "Task (Hemisphere/Group/Treatment)" robustly.
% Fallback: split on underscores.
Task = "UNKNOWN_Task";
Hemisphere = "UNKNOWN_Hemi";
Group = "UNKNOWN_Group";
Treatment = "UNKNOWN_Trt";

% Strip variable-name artifacts like underscores from MATLAB auto-fix
raw = hdr;
raw = replace(raw, '_', ' ');

% Grab Task (prefix) and the (...) payload
m = regexp(raw, '^(?<task>[^()]+)\((?<inside>[^)]*)\)\s*$', 'names');
if isempty(m)
    % Try tolerant: maybe there's a space before '(' or missing ')'
    m = regexp(raw, '^(?<task>[^()]+)\s*\((?<inside>[^)]*)\)\s*$', 'names');
end

if ~isempty(m)
    Task = strtrim(m.task);
    inside = strtrim(m.inside);
    parts = regexp(inside, '\/|\s*\/\s*|\s+', 'split'); % split on '/', tolerant spaces
    parts = parts(~cellfun('isempty', parts));
    parts = string(parts);
    % Expect 3 parts: Hemisphere, Group, Treatment
    if numel(parts) >= 1, Hemisphere = parts(1); end
    if numel(parts) >= 2, Group      = parts(2); end
    if numel(parts) >= 3, Treatment  = parts(3); end
else
    % Fallback: Task_Hemisphere_Group_Treatment with underscores
    parts = split(hdr, {'_',' '});
    parts = parts(parts~="");
    if numel(parts) >= 1, Task = parts(1); end
    if numel(parts) >= 2, Hemisphere = parts(2); end
    if numel(parts) >= 3, Group = parts(3); end
    if numel(parts) >= 4, Treatment = parts(4); end
end

% Final trim
Task = strtrim(Task);
Hemisphere = strtrim(Hemisphere);
Group = strtrim(Group);
Treatment = strtrim(Treatment);
end

function q = bh_fdr(p)
% Benjamini-Hochberg FDR across a vector p
q = nan(size(p));
valid = ~isnan(p);
pv = p(valid);
[ps, idx] = sort(pv(:));
m = numel(ps);
r = (1:m)';
qs = (ps .* m) ./ r;
% ensure monotonicity
for i = m-1:-1:1
    qs(i) = min(qs(i), qs(i+1));
end
qv = nan(size(pv));
qv(idx) = qs;
q(valid) = qv;
end

function T2 = resetRowNames(T1)
% Convert RowNames to a column for writetable
if ~isempty(T1.Properties.RowNames)
    T2 = T1;
    rn = T2.Properties.RowNames;
    T2 = addvars(T2, rn, 'Before', 1, 'NewVariableNames','ROI');
    T2.Properties.RowNames = {};
else
    T2 = T1;
end
end
