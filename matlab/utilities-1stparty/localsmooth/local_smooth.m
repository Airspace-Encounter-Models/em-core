function y = local_smooth(t, x, sigma)
% Copyright 2008 - 2021, MIT Lincoln Laboratory
% SPDX-License-Identifier: BSD-2-Clause
%
% Locally weighted temporal smoother with a Guassian kernel
%
% The first parameter should be a column vector and the second parameter
% should have a corresponding number of rows and arbitrarily many columns.
%
% The third parameter specifies the width (standard deviation) of the
% Guassian kernel to be used.
%
% EXAMPLE:
% (In this example, 5 is the kernel width.)
%
% t = 1:100;
% x = [(t + rand(1,100)).*2; (t + rand(1,100)).*3];
% plot(x(1,:), x(2,:))
% hold on
% smooth_x = local_smooth(t', x', 5);
% plot(smooth_x(:,1),smooth_x(:,2),'r')

assert(size(t,2) == 1 && size(t,1) == size(x,1));

y = x;
if sigma == 0
    return
end

for i=1:length(t)
    w = normpdf(t, t(i), sigma);
    s = sum(w);       % denominator when normalizing
    s = s + (s == 0); % ensures denominator is not 0
    w = w / s;        % normalizes
    y(i,:) = (x'*w)';
end
