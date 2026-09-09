function result = illumination_score(I)

if size(I, 3) == 3
    gray = rgb2gray(I);
else
    gray = I;
end

gray = im2double(gray);

result.meanIntensity = mean(gray(:));
result.darkPixelRatio = mean(gray(:) < 0.05);
result.brightPixelRatio = mean(gray(:) > 0.95);

end