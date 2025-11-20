function lik = loglik_m0(x,data)

%--------------------------------------------------------------------------
% Function Name: m1
% Author: Xiaoyan Wu
% Date: February 12, 2024
%
% Usage:
%   Computes the log likelihood of the baseline model (model 1)
%
% Inputs:
%   - x: The value of the free parameter of one subject.
%   - data: The dataset of one subject, containing 300 trials in total.
%
% Output:
%   - lik: Log likelihood of observing the actions.
%--------------------------------------------------------------------------

%setup initial values
lik = 0;
p = x(1);
% acc = 0;
%likelihood function
for t = 1:length(data)
    option1 = data(t).option1;
    chosen = data(t).chosen;

    if chosen == option1
        action = 1;
    else
        action =0;
    end

    if action == 1
        lik = lik + log(p);
    elseif action == 0
        lik = lik +log(1-p);
    end

end
