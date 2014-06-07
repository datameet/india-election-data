.mode csv
.headers on
.output booth-wise-electors.csv
select electors.state 'state', actopc.state_name 'state_name',
actopc.pc 'pc', actopc.pc_name 'pc_name', actopc.ac 'ac',
actopc.ac_name 'ac_name', electors.booth 'booth', sum(electors.male)
'male',sum(electors.female) 'female',sum(electors.other)
'other',sum(electors.total) 'total' from electors join actopc on
electors.state = actopc.state and electors.ac = actopc.ac group by
electors.state,electors.ac,electors.booth order by
actopc.state_name,actopc.pc,actopc.ac;
