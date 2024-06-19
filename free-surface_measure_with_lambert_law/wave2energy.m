function energy = wave2energy(output, fps, initialIntensity, absorbance)
    value = output.("intensity");
    for i = 1:size(value, 1)
        value(i) = inversing_beer_lambert(value(i), initialIntensity, absorbance);
    end
    value = value - mean(value);
    N = size(value, 1);
    x =lowpass(value, 12, fps);
    t = 0:1/fps:1-1/fps;     % 시간 벡터
    
    % 푸리에 변환 수행
    n = length(x);    % 신호 길이
    Y = fft(x);       % 푸리에 변환
    P2 = abs(Y/n);         % 푸리에 변환의 절대값
    P1 = P2(1:int32(n/2+1));      % 양쪽 스펙트럼
    P1(2:end-1) = 2*P1(2:end-1); % 양쪽 스펙트럼 수정
    
    % 주파수 벡터 생성
    f = fps*(0:(n/2))/n;
    
    % 가장 강한 주파수 찾기
    [~, idx] = max(P1);    % 최대값의 인덱스 찾기
    strongest_freq = f(idx); % 가장 강한 주파수

    sortedX = sort(x);
    meanMax_x = mean(sortedX(end-10:end));
    meanMin_x = mean(sortedX(1:10));

    amplitude = meanMax_x - meanMin_x;

    energy = (strongest_freq^2)*(amplitude^2);
end

