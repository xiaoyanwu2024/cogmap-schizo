function results = optimizeParallelVersion(likfun,param,data,NumMoltiiStart,NumMaxTry)

K = length(param);
results.K = K;
results.param = param;
results.likfun = likfun;
results.subid(:,1) = {data.subid};

parfor s = 1:length(data) % loop in parallel 
    [loglik(s,1),logp(s,1),p(s,1),x(s,:),aic(s,1),aicc(s,1)] = IndividualFittingMultipleTimes(likfun,param,data(s).data,NumMoltiiStart,NumMaxTry,K);
    disp(['Subject ',num2str(s)]);
end

results.loglik = loglik;
results.logp = logp;
results.p = p;
results.x = x;
results.aic = aic;
results.aicc = aicc;
