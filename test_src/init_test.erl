%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description :  1
%%% 
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(init_test).    
   
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------

-include("controller.hrl").
%% --------------------------------------------------------------------

%% External exports
-export([start/0]). 


%% ====================================================================
%% External functions
%% ====================================================================


%% --------------------------------------------------------------------
%% Function:tes cases
%% Description: List of test cases 
%% Returns: non
%% --------------------------------------------------------------------
start()->
  %  io:format("~p~n",[{"Start setup",?MODULE,?FUNCTION_NAME,?LINE}]),
    ok=setup(),
  %  io:format("~p~n",[{"Stop setup",?MODULE,?FUNCTION_NAME,?LINE}]),

%    io:format("~p~n",[{"Start load_first()",?MODULE,?FUNCTION_NAME,?LINE}]),
    ok=load_first(),
    io:format("~p~n",[{"Stop load_first()",?MODULE,?FUNCTION_NAME,?LINE}]),

%    io:format("~p~n",[{"Start load_all()",?MODULE,?FUNCTION_NAME,?LINE}]),
    ok=load_all(),
    io:format("~p~n",[{"Stop load_all()",?MODULE,?FUNCTION_NAME,?LINE}]),

 %   io:format("~p~n",[{"Start add_node()",?MODULE,?FUNCTION_NAME,?LINE}]),
 %   ok=add_node(),
 %   io:format("~p~n",[{"Stop add_node()",?MODULE,?FUNCTION_NAME,?LINE}]),

 %   io:format("~p~n",[{"Start node_status()",?MODULE,?FUNCTION_NAME,?LINE}]),
 %   ok=node_status(),
 %   io:format("~p~n",[{"Stop node_status()",?MODULE,?FUNCTION_NAME,?LINE}]),

%   io:format("~p~n",[{"Start start_args()",?MODULE,?FUNCTION_NAME,?LINE}]),
 %   ok=start_args(),
 %   io:format("~p~n",[{"Stop start_args()",?MODULE,?FUNCTION_NAME,?LINE}]),

%   io:format("~p~n",[{"Start detailed()",?MODULE,?FUNCTION_NAME,?LINE}]),
%    ok=detailed(),
%    io:format("~p~n",[{"Stop detailed()",?MODULE,?FUNCTION_NAME,?LINE}]),

%   io:format("~p~n",[{"Start start_stop()",?MODULE,?FUNCTION_NAME,?LINE}]),
 %   ok=start_stop(),
 %   io:format("~p~n",[{"Stop start_stop()",?MODULE,?FUNCTION_NAME,?LINE}]),



 %   
      %% End application tests
  %  io:format("~p~n",[{"Start cleanup",?MODULE,?FUNCTION_NAME,?LINE}]),
    ok=cleanup(),
  %  io:format("~p~n",[{"Stop cleaup",?MODULE,?FUNCTION_NAME,?LINE}]),
   
    io:format("------>"++atom_to_list(?MODULE)++" ENDED SUCCESSFUL ---------"),
    ok.

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% -------------------------------------------------------------------
load_first()->
    {ok,AppInfo}=case pod:restart_hosts_nodes() of
		     {error,StartRes}->
			 {error,StartRes};
		     {ok,_HostIdNodesList}-> %[{HostId,HostNode}]
			 FirstHostId={"c100","host1"},
			 FirstHostNode=db_host:node(FirstHostId),
			 pod:load_start_boot_loader([{FirstHostId,FirstHostNode}])
		 end,
    io:format("AppInfo ~p~n",[{AppInfo,?MODULE,?FUNCTION_NAME,?LINE}]),
    ok.
		    
%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% -------------------------------------------------------------------
load_all()->
   
   %FirstHostId={"c100","host2"},
  %  io:format("service_catalog ~p~n",[{db_service_catalog:read_all(),?MODULE,?FUNCTION_NAME,?LINE}]),
     Result=case pod:restart_hosts_nodes() of
	       {error,StartRes}->
		   {error,StartRes};
	       {ok,HostIdNodesList}-> %[{HostId,HostNode}]
		    {ok,AppInfo}=load_start_boot_loader(HostIdNodesList),
		    io:format("AppInfo ~p~n",[{AppInfo,?MODULE,?FUNCTION_NAME,?LINE}]),
		    [CtrlNode|_]=[N||[{{"controller","1.0.0"},N,_Dir,_App,_Vsn}|_]<-AppInfo],
		    CtrlNodes=[N||[{{"controller","1.0.0"},N,_Dir,_App,_Vsn}|_]<-AppInfo],
		    
		    io:format("CtrlNodes ~p~n",[{CtrlNodes,?MODULE,?FUNCTION_NAME,?LINE}]),
		    io:format("CtrlNode, sd:all()~p~n",[{rpc:call(CtrlNode,sd,all,[],2*5*1000),?MODULE,?FUNCTION_NAME,?LINE}]),
		    
		    WhoIsLeader=[{N,rpc:call(N,bully,who_is_leader,[],5*1000)}||N<-CtrlNodes],
		    io:format("WhoIsLeader ~p~n",[{WhoIsLeader,?MODULE,?FUNCTION_NAME,?LINE}]),
		    
		    io:format("CtrlNode,db_logger,read_all ~p~n",[{rpc:call(CtrlNode,db_logger,read_all,[],2*5*1000),?MODULE,?FUNCTION_NAME,?LINE}]),
		    Catalog=[{N,rpc:call(N,db_service_catalog,read_all,[],5*1000)}||N<-CtrlNodes],
		    io:format("Catalog ~p~n",[{Catalog,?MODULE,?FUNCTION_NAME,?LINE}]),

		    DeployState=[{N,rpc:call(N,db_deploy_state,read_all,[],5*1000)}||N<-CtrlNodes],
		    io:format("DeployState ~p~n",[{DeployState,?MODULE,?FUNCTION_NAME,?LINE}]),
		 %   io:format("CtrlNode,db_deploy_state,read_all ~p~n",[{rpc:call(CtrlNode,db_deploy_state,read_all,[],2*5*1000),?MODULE,?FUNCTION_NAME,?LINE}]),
		   ok

	    end,
    Result.

load_start_boot_loader(HostIdNodesList)->
    load_start_boot_loader(HostIdNodesList,[]).

load_start_boot_loader([],StartRes)->
    Res=[{error,Reason}||{error,Reason}<-StartRes],
    case Res of
	[]->
	    {ok,[AppInfo||{ok,AppInfo}<-StartRes]};
	Reason->
	    {error,Reason}
    end;

load_start_boot_loader([{HostId,HostNode}|T],Acc)->
		    %% Start Controller OaM load boot_loader
    ControllerDepIdList=[Id||{Id,_Name,_Vsn,PodSpecs,Affinity,_Status}<-db_deployment:read_all(),
			     [{"controller","1.0.0"}]=:=PodSpecs,
			     [HostId]=:=Affinity],
    LoadStartRes=case ControllerDepIdList of
		     []->
			 WorkerDepIdList=[Id||{Id,_Name,_Vsn,PodSpecs,Affinity,_Status}<-db_deployment:read_all(),
					      [{"worker","1.0.0"}]=:=PodSpecs,
					      [HostId]=:=Affinity],
			 case WorkerDepIdList of
			     []->
				 {error,[no_deployment,HostId,HostNode]};
			     [DepId|_]->
				 start_boot_loader(HostId,HostNode,DepId)
			 end;
		     [DepId|_]->
			 start_boot_loader(HostId,HostNode,DepId)
		 end,
    NewAcc=[LoadStartRes|Acc],
    load_start_boot_loader(T,NewAcc).	

   
start_boot_loader(HostId,HostNode,DepId)->    
    io:format("HostId,HostNode,DepId ~p~n",[{HostId,HostNode,DepId,?MODULE,?FUNCTION_NAME,?LINE}]),
    %AppDir=db_host:application_dir(FirstHostId),
    PodDir="boot_loader",
    NodeName="boot",
    Cookie=atom_to_list(erlang:get_cookie()),
    HostName=db_host:hostname(HostId),
    Args="-hidden -setcookie "++Cookie,
    {ok,Pod,PodDir}=pod:start_slave(HostNode,HostName,NodeName,Args,PodDir),
    {App,Vsn,GitPath}=db_service_catalog:read({boot,"1.0.0"}),
    ok=pod:load_app(Pod,PodDir,{App,Vsn,GitPath}),
    {ok,AppInfo}=rpc:call(Pod,boot_loader,start,[DepId,HostId],4*5*1000),
    rpc:call(Pod,init,stop,[],5*1000),
    rpc:call(HostNode,os,cmd,["rm -rf "++PodDir],5*1000),
    timer:sleep(500),
    {ok,AppInfo}.
  
    
    
%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% -------------------------------------------------------------------
    %% 
 %   [CtrlNode|_]=[N||{{"controller","1.0.0"},N,_Dir,_App,Vsn}<-AppInfo],
    
  %  io:format("CtrlNode, sd:all() ~p~n",[{rpc:call(CtrlNode,sd,all,[],5*1000),?MODULE,?FUNCTION_NAME,?LINE}]),
  %  timer:sleep(1000),
  % io:format(" who_is_leader ~p~n",[{rpc:call(CtrlNode,bully,who_is_leader,[],5*1000),?MODULE,?FUNCTION_NAME,?LINE}]),

    
    %%
 %   DbaseNodes=rpc:call(CtrlNode,sd,get,[dbase_infra],5*1000),
 %   io:format("DbaseNodes ~p~n",[{DbaseNodes,?MODULE,?FUNCTION_NAME,?LINE}]),
 %   X1=[{N,rpc:call(N,db_service_catalog,read_all,[],5*1000)}||N<-DbaseNodes],
  %  io:format("db_service_catalog ~p~n",[{X1,?MODULE,?FUNCTION_NAME,?LINE}]),
  %  X2=[{N,rpc:call(N,mnesia,system_info,[],5*1000)}||N<-DbaseNodes],
  %  io:format("mnesia:system_info ~p~n",[{X2,?MODULE,?FUNCTION_NAME,?LINE}]),
    
    %%
 %   io:format("db_deploy_state ~p~n",[{db_deploy_state:read_all(),?MODULE,?FUNCTION_NAME,?LINE}]),
    
%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% -------------------------------------------------------------------
    
setup()->
    ok=application:start(sd),
    ok=application:start(dbase_infra),
 
    ok.

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% -------------------------------------------------------------------    

cleanup()->
  
    ok.
