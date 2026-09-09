function score = focus_score(I)

if size(I, 3) == 3
    I = rgb2gray(I);
end

I = im2double(I);

L = imfilter(I, fspecial("laplacian", 0.2), "replicate");

score = var(L(:));

end