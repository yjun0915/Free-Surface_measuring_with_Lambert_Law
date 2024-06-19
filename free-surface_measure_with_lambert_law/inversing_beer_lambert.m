function depth = inversing_beer_lambert(intensity, initialIntensity, absorbanceConstant)
    depth = (-1/absorbanceConstant)*(log(intensity) - log(initialIntensity));
end

