function output = preprocess_clahe(I)

if size(I, 3) == 3
    I = im2double(I);

    lab = rgb2lab(I);

    L = lab(:, :, 1) / 100;

    L = adapthisteq(L, ...
        "NumTiles", [8 8], ...
        "ClipLimit", 0.01);

    lab(:, :, 1) = L * 100;

    output = lab2rgb(lab);
    output = min(max(output, 0), 1);
else
    I = im2double(I);

    output = adapthisteq(I, ...
        "NumTiles", [8 8], ...
        "ClipLimit", 0.01);

    output = min(max(output, 0), 1);
end

end