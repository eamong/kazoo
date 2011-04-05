%%%============================================================================
%%% @author Vladimir Darmin <vova@2600hz.org>
%%% @copyright (C) 2011, Vladimir Darmin
%%% @doc
%%% Handles dialplan actions
%%%
%%% @end
%%% Created:       21 Feb 2011 by Vladimir Darmin <vova@2600hz.org>
%%% Last Modified: 23 Feb 2011 by Vladimir Darmin <vova@2600hz.org>
%%%============================================================================
-module(cf_dialplan).

%% API
-export([handle/2]).

-import(logger, [format_log/3]).

-include("../callflow.hrl").

handle (_Data, _Call) ->
    {continue}.

%%%
%%%============================================================================
%%%== END =====
%%%============================================================================
