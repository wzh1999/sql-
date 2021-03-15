create table log_sto
(logid int not null identity(1,1),  -- 日志序号(日志主键)
 operate varchar(10),               -- 操作类型 如Insert,Update,Delete.
 id int,                            -- 原表ID(主键) 
 old_de varchar(200),                   -- de字段旧值
 new_de varchar(200),                   -- de字段新值
 spid int not null,                 -- spid
 login_name varchar(100),           -- 登录名
 prog_name varchar(100),            -- 程序名
 hostname varchar(100),             -- 主机名
 ipaddress varchar(100),            -- IP地址
 runsql varchar(4000),              -- 执行的TSQL代码
 UDate datetime                     -- 操作日期时间
 constraint pk_logsto primary key(logid)
)
select * from log_sto

go

create trigger tr_sto
on [User] after update,insert,delete
as
begin
   declare @di table(et varchar(200),pt varchar(200),ei varchar(max))
   insert into @di exec('dbcc inputbuffer(@@spid)')
   
   declare @op varchar(10)
   select @op=case when exists(select 1 from inserted) and exists(select 1 from deleted)
                   then 'Update'
                   when exists(select 1 from inserted) and not exists(select 1 from deleted)
                   then 'Insert'
                   when not exists(select 1 from inserted) and exists(select 1 from deleted)
                   then 'Delete' end
                   
   if @op in('Update','Insert')
   begin
   insert into log_sto
     (operate,id,old_de,new_de,spid,login_name,prog_name,hostname,ipaddress,runsql,UDate)
     select @op,n.id,o.name,n.name,@@spid,
       (select login_name from sys.dm_exec_sessions where session_id=@@spid),
       (select program_name from sys.dm_exec_sessions where session_id=@@spid),
       (select hostname from sys.sysprocesses where spid=@@spid),
       (select client_net_address from sys.dm_exec_connections where session_id=@@spid),
       (select top 1 isnull(ei,'') from @di),
       getdate()
     from inserted n
     left join deleted o on o.id=n.id
   end
   else
   begin
     insert into log_sto
       (operate,id,old_de,new_de,spid,login_name,prog_name,hostname,ipaddress,runsql,UDate)
       select @op,o.id,o.name,null,@@spid,
         (select login_name from sys.dm_exec_sessions where session_id=@@spid),
         (select program_name from sys.dm_exec_sessions where session_id=@@spid),
         (select hostname from sys.sysprocesses where spid=@@spid),
         (select client_net_address from sys.dm_exec_connections where session_id=@@spid),
         (select top 1 isnull(ei,'') from @di),
         getdate()
       from deleted o
   end
end
go



