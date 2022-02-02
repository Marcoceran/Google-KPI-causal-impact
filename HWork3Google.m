clc, close all, clear all
% test period is from 1 to 520
% our track is #8
rawdata = readtable('Google @ Politecnico - Exercise data.xlsx');
rawdata = table2array(rawdata(:, 3:5));
structdata = zeros(659, 8, 3);
for i1 = 0:658
    for i2 = 1:8
        for i3 = 1:3
            structdata(i1+1, i2, i3) = rawdata(i1*8+i2, i3);
        end
    end
end
clearvars i1 i2 i3 rawdata;
structdata = flip(structdata, 3);   % CONVERSIONS - CLICKS - COST
endtest = 520;  

offset = 43464; % offset day between 1.1.1900 and 1.1.2019, needed for the datetime function
dates = (1+offset:length(structdata)+offset);

testtrack = squeeze(structdata(:, 8, :));
esttrack = zeros(size(testtrack));

h = [1/2 1/2];
binomialCoeff = conv(h,h);
for n = 1:25
    binomialCoeff = conv(binomialCoeff,h);
end

smoothstructdata = zeros(length(structdata)+length(binomialCoeff)-1, 8, 3);
for i = 1:3
    for j = 1:8
        smoothstructdata(: , j, i) = conv(squeeze(structdata(:, j, i)), binomialCoeff);
    end
end
smoothstructdata = smoothstructdata(length(binomialCoeff)/2:end-length(binomialCoeff)/2, :, :);

% Simulated annealing method
a = ones(7, 3)/7;
kmax = 8000;
RMSEpre = [0 0 0];
for i = 1:3
    for k = 0:kmax-1
        ak = 0.1*(kmax-k)/kmax*randn(length(a), 1);
        RMSE = mean(((a(:, i)+ak)'*squeeze(smoothstructdata(1:endtest, 1:7, i)')-smoothstructdata(1:endtest, 8, i)').^2)^0.5;
        RMSEa = mean((a(:, i)'*squeeze(smoothstructdata(1:endtest, 1:7, i)')-smoothstructdata(1:endtest, 8, i)').^2)^0.5;
        if RMSE < RMSEa
            a(:, i)=a(:, i)+ak;
        end
    end
    RMSEpre(i) = min(RMSE, RMSEa);
end


for i = 1:3
    esttrack(:, i) = a(:, i)'*squeeze(smoothstructdata(:, 1:7, i))';
end
esttrack(esttrack<0) = 0;
a

smoothtest = zeros(length(testtrack)+length(binomialCoeff)-1, 3);
for i = 1:3
    smoothtest(:, i) = conv(testtrack(:, i), binomialCoeff);
end
smoothtest = smoothtest(length(binomialCoeff)/2:end-length(binomialCoeff)/2, :);

cumulative = zeros(size(esttrack));
for i = 521:length(cumulative)
    cumulative(i, :) = cumulative(i-1, :) + smoothtest(i, :) - esttrack(i, :);
end

for i = 1:3
    figure(i)
    hold on;
    plot(esttrack(:, i)); plot(testtrack(:, i))
    legend('Estimated track', 'True track')
end

figure(4); hold on;
plot(datetime(dates,'ConvertFrom','excel'), cumulative)
legend('Cumul. Conversions', 'Cumul. Clicks', 'Cumul. Cost')
ylabel('KPI value')