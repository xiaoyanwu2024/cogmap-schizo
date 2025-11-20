function [loglik,logp,p,x,aic,aicc] = IndividualFittingMultipleTimes(likfun,param,subdata,NumMoltiiStart,NumMaxTry,K)

%--------------------------------------------------------------------------
options = optimset('Display','off');
lb = [param.lb];
ub = [param.ub];
f = @(x) -likfun(x,subdata);
numTry = 1;

while numTry < NumMaxTry

    x0 = zeros(size(ub));
    for i = 1:numel(ub)
        if isfinite(lb(i)) && isfinite(ub(i))
            x0(i) = lb(i) + (ub(i)-lb(i))*rand();
        elseif isfinite(lb(i)) && ~isfinite(ub(i))
            x0(i) = lb(i) + 2*rand();     
        elseif ~isfinite(lb(i)) && isfinite(ub(i))
            x0(i) = ub(i) - 2*rand();
        else
            x0(i) = lb(i) + rand()*ub(i);  
        end
    end

    try
        numRuns = 2;
        best_nlogp = inf;
        best_x = [];
        for r = 1:numRuns
            problem = createOptimProblem('fmincon',...
                'objective', f,...
                'x0',x0,...
                'lb',lb,...
                'ub',ub,...%'Aineq', A, ...'bineq', b, ...
                'options',options);
            gs = GlobalSearch('StartPointsToRun','bounds','Display','off','NumTrialPoints',NumMoltiiStart);

            [x_temp,nlogp_temp] = run(gs,problem);
            if nlogp_temp < best_nlogp
                best_nlogp = nlogp_temp;
                best_x = x_temp;
            end
        end
        x = best_x;
        nlogp = best_nlogp;
        break;
    catch
        numTry = numTry+1;
    end
end

n = length(subdata);
loglik = likfun(x,subdata);
logp = -nlogp;
p = exp(logp);
aic = -2*logp+ 2*K;
aicc = aic + (2*K*(K+1))/(n-K-1);
