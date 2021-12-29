%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : 
%%% 
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(boot_loader).  
   
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
%-include("controller.hrl").
%%---------------------------------------------------------------------
%% Records for test
%%

%% --------------------------------------------------------------------
%-compile(export_all).
-export([
	 start/2
	]).
	 

%% ====================================================================
%% External functions
%% ====================================================================
start(DepId,HostId)->
    %% 
    ok=application:start(sd),
    ok=application:start(dbase_infra),
    db_deployment:read_all().

    %pod:start_deployment(DepId,HostId).
  
   % ok.
start_deployment(DepId,HostId)->      
    {ok,DeployInstanceId}=db_deploy_state:create(DepId,[]),
    [PodId]=db_deployment:pod_specs(DepId),
    Result=case pod:start_pod(PodId,HostId,DepId,DeployInstanceId) of
	       {error,Reason}->
		   {error,Reason};
	       {ok,PodNode,PodDir}->
		   AppIds=db_pods:application(PodId),
		   io:format(" AppIds ~p~n",[{AppIds,?MODULE,?FUNCTION_NAME,?LINE}]),
		   case pod:load_start_apps(AppIds,PodId,PodNode,PodDir) of
		       {error,Reason}->
			   {error,Reason};
		       {ok,PodAppInfo} -> %{PodId,PodNode,PodDir,App,Vsn}
			   case rpc:call(PodNode,sd,get,[bully],5*1000) of
			       []->
				   io:format(" bully not installed ~p~n",[{?MODULE,?FUNCTION_NAME,?LINE}]);
			       [BullyNode|_]->
				   io:format("who_is_leader ~p~n",[{rpc:call(BullyNode,bully,who_is_leader,[],5*1000),?MODULE,?FUNCTION_NAME,?LINE}])
			   end,
			   {ok,PodAppInfo}
		   end
		
	   end,
    Result.
