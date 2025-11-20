function lik = loglik_m1(x,data)

% setup parameter values
alpha = x(1); % learning rate
beta = x(2); % inverse tempreture

% setup initial values
lik = 0;
Q = nan(2, 6); % 2 maps × 6 items (index 1–6); 6th may be unobserved

% likelihood function
for t = 1:length(data)
    map = data(t).map;
    o1 = data(t).option1;
    o2 = data(t).option2;
    ch = data(t).chosen;
    reward = data(t).chosen_value;
    
    % Get Q-values
    q1 = Q(map, o1);
    q2 = Q(map, o2);
    if isnan(q1), q1 = 0; end
    if isnan(q2), q2 = 0; end
    
    %choice probability
    if ch == o1
        prob = 1 / (1 + exp(beta * (q2 - q1)));
    else
        prob = 1 / (1 + exp(beta * (q1 - q2)));
    end
    
    % log-likelihood
    prob = max(min(prob, 1-1e-5), 1e-5); 
    lik = lik + log(prob);
    
    % Q-value update
    if ch == o1
        Q(map, o1) = q1 + alpha * (reward - q1);
    else
        Q(map, o2) = q2 + alpha * (reward - q2);
    end
    
end