%% Author: dave
%% Created: Mar 1, 2010
%% Description: Parses source files and extracts translation directives on templates
-module(sources_parser).

%%
%% Include files
%%

-define(bail(Fmt, Args),
        throw(lists:flatten(io_lib:format(Fmt, Args)))).

%%
%% Exported Functions
%%
-export([parse/0,parse/1, process_content/2]).

%%
%% API Functions
%%
parse() ->
    Parsed_Files = parse(["./views/*/*.html"]),
    io:format("Parsed files are ~p~n",[Parsed_Files]).
parse(Pattern) ->
    %%We assume a basedir
    GetFiles = fun(Path,Acc) -> Acc ++ filelib:wildcard(Path) end,
    Files = lists:foldl(GetFiles,[],Pattern),
    io:format("Parsing files ~p~n",[Files]),
    ParsedFiles = lists:map(fun(File)-> parse_file(File) end, Files),
    lists:flatten(ParsedFiles).

%%
%% Local Functions
%%
parse_file(Path) ->
    case file:read_file((Path)) of
        {ok, Content} ->
            process_content(Path, Content);
        Error ->
            ?bail("Cannot read file ~s problem ~p~n", [Path, Error])
    end.

process_content(Path,Content)->
    case erlydtl_compiler:parse(Content) of
        {ok, Data, _} ->
            {ok, Result} = process_ast(Path, Data),
            Result;
        Error ->
            ?bail("Template parsing failed for template ~s, cause ~p~n", [Path, Error])
    end.


process_ast(Fname, Tokens) -> {ok, process_ast(Fname, Tokens ,[]) }.
process_ast(_Fname, [],Acc) -> Acc;
process_ast(Fname,[Head|Tail], Acc) ->
    NewAcc = process_token(Fname,Head,Acc),
    process_ast(Fname, Tail, NewAcc).

%%Block are recursivelly processed, trans are accumulated and other tags are ignored
process_token(Fname, {block,{identifier,{_Line,_Col},_Identifier},Children}, Acc ) -> process_ast(Fname, Children, Acc);
process_token(Fname, {trans,{string_literal,{Line,Col},String}}, Acc ) -> [{unescape(String), {Fname, Line, Col}} | Acc];
process_token(_Fname, {apply_filter, _Value, _Filter}, Acc) -> Acc;
process_token(_Fname, {date, now, _Filter}, Acc) -> Acc;
process_token(Fname, {blocktrans, Args, Contents}, Acc) -> [{lists:flatten(erlydtl_unparser:unparse(Contents)),
                                                             guess_blocktrans_lc(Fname, Args, Contents)} | Acc];
process_token(Fname, {_Instr, _Cond, Children}, Acc) -> process_ast(Fname, Children, Acc);
process_token(Fname, {_Instr, _Cond, Children, Children2}, Acc) ->
    AccModified = process_ast(Fname, Children, Acc),
    process_ast(Fname, Children2, AccModified);
process_token(_,_AST,Acc) -> Acc.

unescape(String) ->string:sub_string(String, 2, string:len(String) -1).

%% hack to guess ~position of blocktrans
guess_blocktrans_lc(Fname, [{{identifier, {L, C}, _}, _} | _], _) ->
    %% guess by 1'st with
    {Fname, L, C - length("blocktrans with ")};
guess_blocktrans_lc(Fname, _, [{string, {L, C}, _} | _]) ->
    %% guess by 1'st string
    {Fname, L, C - length("blocktrans %}")};
guess_blocktrans_lc(Fname, _, [{variable, {identifier, {L, C}, _}} | _]) ->
    %% guess by 1'st {{...}}
    {Fname, L, C - length("blocktrans %}")};
guess_blocktrans_lc(Fname, _, _) ->
    {Fname, -1, -1}.
