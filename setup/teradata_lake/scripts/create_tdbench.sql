-- NOTE: When you execute this setup, you'll be prompted for the parent DB and password
create user ${TdBenchDb} from :parent as password = :dbpassword, perm = 2 * 1024**3;

grant all on ${TdBenchDb} to ${TdBenchDb} with grant option;
grant select, execute on dbc to ${TdBenchDb} with grant option;
grant select on TD_METRIC_SVC to ${TdBenchDb} with grant option;
grant exec function on syslib to ${TdBenchDb} with grant option;
grant exec function, select on tdwm to ${TdBenchDb} with grant option;

replace query logging with all on ${TdBenchDb};
