function test2(fName,nQ)

if exist(fName,'file')
    delete(fName);
end

if nargin<2
    nQ = 1e5;
end

partest2('nQ',nQ,'nWorker',[8 16 24 32],'nThread',4,'nRun',5,'fName','test01.mat','nSlice',1,'hermit',true)

end