function [lik] = loglik_m3_hybrid_m1m2(x, data)
% Hybrid model: Q-learning + spatial GP (trial-history)
% Parameters:
%   x(1): alpha - learning rate for Q
%   x(2): beta - inverse temperature
%   x(3): log lengthscale for GP
%   x(4): w - Q/GP mixing weight

alpha = x(1);
beta = x(2);
lamda = exp(x(3));
% log_lamda = x(3);
% lamda = exp(log_lamda);
w = x(4);  % weight on Q-value

lik = 0;
Q = nan(2, 6);  % Q-values: 2 maps × 6 items

% Initialize memory for spatial GP
chosen_hist = cell(1, 2);
reward_hist = cell(1, 2);
for m = 1:2
    chosen_hist{m} = [];
    reward_hist{m} = [];
end

for t = 1:length(data)
    map = data(t).map;

    % Item info
    op1 = data(t).option1;
    op2 = data(t).option2;
    ch = data(t).chosen;
    reward = data(t).chosen_value;

    % Q values
    q1 = Q(map, op1); if isnan(q1), q1 = 0; end
    q2 = Q(map, op2); if isnan(q2), q2 = 0; end

    % Spatial GP predictions
    op1_xy = [data(t).op1_x, data(t).op1_y];
    op2_xy = [data(t).op2_x, data(t).op2_y];

    X = chosen_hist{map};
    Y = reward_hist{map};
    if size(X,1) < 1
        mu1 = 0; mu2 = 0;
    else
        Y = Y(:);
        if size(X,1) == 1
            K = 1;
        else
            D2 = squareform(pdist(X).^2);
            K = exp(-D2 / (2 * lamda^2)) + 1e-5 * eye(size(D2));
        end
        k1 = exp(-sum((X - op1_xy).^2, 2) / (2 * lamda^2));
        k2 = exp(-sum((X - op2_xy).^2, 2) / (2 * lamda^2));
        mu1 = k1' * (K \ Y);
        mu2 = k2' * (K \ Y);
    end

    % Hybrid value
    V1 = w * q1 + (1 - w) * mu1;
    V2 = w * q2 + (1 - w) * mu2;

    if ch == op1
        prob = 1 / (1 + exp(beta * (V2 - V1)));
    else
        prob = 1 / (1 + exp(beta * (V1 - V2)));
    end
    prob = max(min(prob, 1 - 1e-5), 1e-5);
    lik = lik + log(prob);

    % Update Q
    if ch == op1
        Q(map, op1) = q1 + alpha * (reward - q1);
    else
        Q(map, op2) = q2 + alpha * (reward - q2);
    end

    % Update GP memory
    if ch == op1
        chosen_hist{map} = [chosen_hist{map}; op1_xy];
    else
        chosen_hist{map} = [chosen_hist{map}; op2_xy];
    end
    reward_hist{map} = [reward_hist{map}; reward];
end
end
