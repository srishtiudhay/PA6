clear
clc
close all
warning('on', 'all');
%% declarations
dataFile = 'aluminum.xlsx';
gageLength = 38e-3; % m
sampleRadius = 1.5e-3; % m
queryStrain = 0.1000;
filterPoints = 25; % Points in the force averaging filter
offsetStrain = 0.002; % 0.2 percent offset

% Adjustable estimates for a ductile metal's initial linear region.
elasticLowFrac = 0.05; % Fraction of ultimate stress to start the fit
elasticHighFrac = 0.20; % Fraction of ultimate stress to end the fit
proportionalTolerance = 0.05; % Sustained 5 percent departure from the fit
deviationPoints = 5; % Consecutive points needed to confirm departure
fractureDropFrac = 0.50; % A post-peak force drop of at least 50 percent

pointNames = {'Proportional'; 'Yield'; 'Ultimate'; 'Fracture'};
prefixNames = {'q', 'r', 'y', 'z', 'a', 'f', 'p', 'n', char(181), ...
               'm', '', 'k', 'M', 'G', 'T', 'P', 'E', 'Z', 'Y', 'R', 'Q'};
%% calculations
if gageLength <= 0 || sampleRadius <= 0
    error('Gage length and sample radius must be positive.')
end
if ~isscalar(queryStrain) || isnan(queryStrain) || isinf(queryStrain)
    error('Declare queryStrain as one finite number.')
end

data = readmatrix(dataFile);
if size(data, 2) < 2
    error('The data file must contain displacement and force columns.')
end
data = data(:, 1:2);
validMask = all(~isnan(data) & ~isinf(data), 2) & data(:, 1) >= 0;
if any(~validMask)
    warning('Ignoring header, missing, or negative-displacement rows.')
end
data = data(validMask, :);
if size(data, 1) < filterPoints
    error('At least 25 valid data points are needed for the averaging filter.')
end

% Keep the last loaded point before a sudden post-peak rupture drop.
% If the file ends at fracture already, use its final sample.
[rawPeakForce, rawPeakIdx] = max(data(:, 2));
if rawPeakForce <= 0
    error('The data must contain a positive tensile force.')
end
fractureRow = size(data, 1);
fractureDetected = false;
for k = rawPeakIdx:size(data, 1)-1
    if data(k, 2) > 0.05*rawPeakForce && ...
            data(k+1, 2) <= (1-fractureDropFrac)*data(k, 2)
        fractureRow = k;
        fractureDetected = true;
        break
    end
end
if fractureRow < filterPoints
    error('Too few pre-fracture samples remain for the averaging filter.')
end
displacement = data(1:fractureRow, 1); % m
force = data(1:fractureRow, 2); % N

% Smooth before converting force to stress. Shrink the window at the ends.
smoothForce = movmean(force, filterPoints, 'Endpoints', 'shrink');
sampleArea = pi * sampleRadius^2; % m^2
strain = displacement / gageLength;
stress = smoothForce / sampleArea; % Pa

% Small displacement reversals are sensor jitter in this monotonic test.
% Order the curve and average exact repeats for interp1 and trapz.
[strain, sortIdx] = sort(strain);
stress = stress(sortIdx);
[strain, ~, strainGroups] = unique(strain);
stress = accumarray(strainGroups, stress, [], @mean);
if numel(strain) < filterPoints || strain(end) <= strain(1)
    error('The curve needs at least 25 distinct, increasing strain values.')
end

[ultimateStress, ultimateIdx] = max(stress);
ultimateStrain = strain(ultimateIdx);
fractureStrain = strain(end);
fractureStress = stress(end);

% Fit E from a low-load section of the rising curve, not from two points.
elasticStart = find(stress >= elasticLowFrac*ultimateStress, 1, 'first');
elasticEnd = find(stress >= elasticHighFrac*ultimateStress, 1, 'first');
if isempty(elasticStart) || isempty(elasticEnd) || ...
        elasticEnd-elasticStart < 2 || elasticEnd >= ultimateIdx
    error('Cannot fit an elastic region. Review the elastic fit fractions.')
end
elasticFit = polyfit(strain(elasticStart:elasticEnd), ...
                     stress(elasticStart:elasticEnd), 1);
elasticModulus = elasticFit(1); % Pa
if isnan(elasticModulus) || isinf(elasticModulus) || elasticModulus <= 0
    error('The fitted elastic modulus must be positive and finite.')
end
elasticLine = polyval(elasticFit, strain);

% The proportional point is the last point before sustained nonlinearity.
proportionalIdx = [];
deviationCount = 0;
for k = elasticEnd+1:ultimateIdx
    relativeDeviation = abs(stress(k)-elasticLine(k)) / ...
                        max(abs(elasticLine(k)), elasticLowFrac*ultimateStress);
    if relativeDeviation > proportionalTolerance
        deviationCount = deviationCount + 1;
    else
        deviationCount = 0;
    end
    if deviationCount == deviationPoints
        proportionalIdx = k-deviationPoints;
        break
    end
end
if isempty(proportionalIdx)
    error(['No sustained proportional limit found. Review the elastic fit ' ...
           'fractions or proportionalTolerance for this dataset.'])
end
proportionalStrain = strain(proportionalIdx);
proportionalStress = stress(proportionalIdx);

% The offset line passes through (0.002, 0) with slope E.
offsetLine = elasticModulus * (strain-offsetStrain);
offsetDifference = stress-offsetLine;
yieldLowerIdx = find(offsetDifference(1:end-1) > 0 & ...
                     offsetDifference(2:end) <= 0 & ...
                     strain(2:end) >= offsetStrain, 1, 'first');
if isempty(yieldLowerIdx)
    error('The measured curve does not cross the 0.2 percent offset line.')
end
% Interpolate the intersection rather than selecting the nearest sample.
yieldWeight = offsetDifference(yieldLowerIdx) / ...
              (offsetDifference(yieldLowerIdx)-offsetDifference(yieldLowerIdx+1));
yieldStrain = strain(yieldLowerIdx) + yieldWeight * ...
              (strain(yieldLowerIdx+1)-strain(yieldLowerIdx));
yieldStress = stress(yieldLowerIdx) + yieldWeight * ...
              (stress(yieldLowerIdx+1)-stress(yieldLowerIdx));
if proportionalStrain >= yieldStrain || yieldStrain > ultimateStrain
    error('Point order is inconsistent. Review the initial elastic fit.')
end

% Query the exact declared strain without extrapolating beyond the data.
queryStress = NaN;
if queryStrain >= strain(1) && queryStrain <= fractureStrain
    queryStress = interp1(strain, stress, queryStrain, 'linear');
else
    warning('queryStrain lies outside the measured strain range.')
end

% Add the origin and interpolated yield point to split the energy areas.
elasticStrain = [0; strain(1:yieldLowerIdx); yieldStrain];
elasticStress = [0; stress(1:yieldLowerIdx); yieldStress];
plasticStrain = [yieldStrain; strain(yieldLowerIdx+1:end)];
plasticStress = [yieldStress; stress(yieldLowerIdx+1:end)];
resilience = trapz(elasticStrain, elasticStress) / 1e6; % MJ/m^3
plasticEnergy = trapz(plasticStrain, plasticStress) / 1e6; % MJ/m^3
toughness = resilience + plasticEnergy; % MJ/m^3

pointStrain = [proportionalStrain; yieldStrain; ultimateStrain; fractureStrain];
pointStress = [proportionalStress; yieldStress; ultimateStress; fractureStress];
outputValues = [pointStress; elasticModulus; queryStress];
displayScales = ones(size(outputValues));
displayPrefixes = cell(size(outputValues));
for k = 1:numel(outputValues)
    prefixPower = 0;
    if ~isnan(outputValues(k)) && ~isinf(outputValues(k)) && outputValues(k) ~= 0
        prefixPower = 3 * floor(log10(abs(outputValues(k)))/3);
        prefixPower = max(-30, min(30, prefixPower));
    end
    displayScales(k) = 10^prefixPower;
    displayPrefixes{k} = prefixNames{prefixPower/3+11};
end
%% Outputs
fprintf('\n%-22s %16s %12s\n', 'Property', 'Stress', 'Strain')
fprintf('%-22s %16s %12s\n', '----------------------', '----------------', '------------')
for k = 1:4
    fprintf('%-22s %10.2f %-5s %10.4f\n', pointNames{k}, ...
            pointStress(k)/displayScales(k), [displayPrefixes{k}, 'Pa'], pointStrain(k))
end
fprintf('\nElastic modulus: %.2f %sPa\n', ...
        elasticModulus/displayScales(5), displayPrefixes{5})
if ~isnan(queryStress) && ~isinf(queryStress)
    fprintf('Stress at strain %.4f: %.2f %sPa\n', queryStrain, ...
            queryStress/displayScales(6), displayPrefixes{6})
else
    fprintf('Stress at strain %.4f: outside measured range [%.4f, %.4f].\n', ...
            queryStrain, strain(1), fractureStrain)
end
fprintf('Resilience: %.4f MJ/m^3\n', resilience)
fprintf('Toughness : %.4f MJ/m^3\n', toughness)
fprintf('Proportional limit uses %.1f%% deviation for %d consecutive points.\n', ...
        100*proportionalTolerance, deviationPoints)
if fractureDetected
    fprintf('Fracture uses the last point before a sudden post-peak force drop.\n')
else
    fprintf('Fracture assumes the last supplied sample is the failure point.\n')
end

% Use the ultimate-stress prefix for the complete plot.
plotScale = displayScales(3);
figure('Color', 'w', 'Position', [100, 100, 1000, 600])
hold on
elasticArea = area(elasticStrain, elasticStress/plotScale, ...
                   'FaceColor', 'r', 'FaceAlpha', 0.25, 'EdgeColor', 'none');
plasticArea = area(plasticStrain, plasticStress/plotScale, ...
                   'FaceColor', 'c', 'FaceAlpha', 0.25, 'EdgeColor', 'none');
curvePlot = plot(strain, stress/plotScale, 'k', 'LineWidth', 1.5);

% Put labels in a separate space to the right of all measured points.
pointColors = [0.65, 0, 0; 0, 0.35, 0.65; 0.35, 0.15, 0.55; 0, 0.45, 0.15];
[~, labelOrder] = sort(pointStress, 'descend');
labelX = 1.08 * fractureStrain;
labelHeights = linspace(0.90, 0.20, 4) * ultimateStress/plotScale;
for k = 1:4
    pointIdx = labelOrder(k);
    plot(pointStrain(pointIdx), pointStress(pointIdx)/plotScale, 'ko', ...
         'MarkerFaceColor', pointColors(pointIdx, :), 'MarkerSize', 7, ...
         'HandleVisibility', 'off')
    plot([pointStrain(pointIdx), 0.98*labelX], ...
         [pointStress(pointIdx)/plotScale, labelHeights(k)], ':', ...
         'Color', pointColors(pointIdx, :), 'HandleVisibility', 'off')
    text(labelX, labelHeights(k), pointNames{pointIdx}, ...
         'Color', pointColors(pointIdx, :), 'VerticalAlignment', 'middle')
end
xlabel('Strain')
ylabel(sprintf('Stress (%sPa)', displayPrefixes{3}), 'Interpreter', 'none')
title('Engineering Stress-Strain Curve')
legend([curvePlot, elasticArea, plasticArea], ...
       {'Stress-strain curve', 'Elastic region (to yield)', 'Plastic region'}, ...
       'Location', 'southoutside')
xlim([0, 1.45*fractureStrain])
ylim([min(0, 1.10*min(stress)/plotScale), 1.10*ultimateStress/plotScale])
grid on
box on
hold off
