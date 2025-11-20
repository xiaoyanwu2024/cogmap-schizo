function [lik] = loglik_m2(x, data)

lamda = x(1);
beta = x(2);
lik = 0;

% Initialize memory for map 1 and 2 independently
chosen_hist = cell(1, 2);
reward_hist = cell(1, 2);

for m = 1:2
    chosen_hist{m} = [];
    reward_hist{m} = [];
end

for t = 1:length(data)
    map = data(t).map;

    % Get item positions and outcome
    op1_xy = [data(t).op1_x, data(t).op1_y];
    op2_xy = [data(t).op2_x, data(t).op2_y];
    ch = data(t).chosen;
    reward = data(t).chosen_value;

    if ch == data(t).option1
        mu_chosen_xy = op1_xy;
    else
        mu_chosen_xy = op2_xy;
    end

    X = chosen_hist{map};
    Y = reward_hist{map};

    if size(X,1) < 1 || size(Y,1) < 1
        mu1 = 0;
        mu2 = 0;
    else
        Y = Y(:);
        if size(X,1) == 1
            K = 1;
        else
            D2 = squareform(pdist(X).^2);
            K = exp(-D2 / (2 * lamda^2)) + 1e-3 * eye(size(D2));
        end

        k1 = exp(-sum((X - op1_xy).^2, 2) / (2 * lamda^2)); %k1 = k1(:);
        k2 = exp(-sum((X - op2_xy).^2, 2) / (2 * lamda^2)); %k2 = k2(:);

        mu1 = k1' * (K \ Y);
        mu2 = k2' * (K \ Y);
    end

    if ch == data(t).option1
        prob = 1 / (1 + exp(beta * (mu2 - mu1)));
    else
        prob = 1 / (1 + exp(beta * (mu1 - mu2)));
    end

    % log-likelihood
    prob = max(min(prob, 1-1e-5), 1e-5);
    lik = lik + log(prob);

    chosen_hist{map} = [chosen_hist{map}; mu_chosen_xy];
    reward_hist{map} = [reward_hist{map}; reward];
end

