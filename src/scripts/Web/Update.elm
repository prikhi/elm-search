module Web.Update exposing (..)

import Http
import Json.Decode as Decode
import Task
import Package.Package as Package
import Ports
import Search.Model as Search
import Search.Update as Search
import Web.Model as Model exposing (..)


init : Flags -> ( Model, Cmd Msg )
init { search } =
    ( Loading search
    , getPackages
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Fail httpError ->
            ( Failed httpError
            , Cmd.none
            )

        Load packages ->
            let
                queryString =
                    case model of
                        Loading string ->
                            string

                        _ ->
                            ""

                ( search, searchCmd ) =
                    Search.init (parseSearchString queryString) packages
            in
                ( Ready search
                , Cmd.none
                )

        Search searchMsg ->
            case model of
                Ready search ->
                    let
                        ( newSearch, searchCmd ) =
                            Search.update searchMsg search

                        cmd =
                            case searchMsg of
                                Search.RunFilter ->
                                    Ports.pushQuery
                                        (toQueryString search.filter.elmVersion
                                            search.filter.queryString
                                        )

                                _ ->
                                    Cmd.none
                    in
                        ( Ready newSearch
                        , cmd
                        )

                _ ->
                    ( model, Cmd.none )

        LocationSearchChange queryString ->
            --let
            --    ( query, maybeVersion ) =
            --        parseQueryString queryString
            --    newModel =
            --        case model of
            --            Success info ->
            --                Success
            --                    (handleSearch
            --                        { info
            --                            | query = query
            --                            , elmVersionsFilter = maybeVersion
            --                        }
            --                    )
            --            _ ->
            --                model
            --in
            --    ( newModel, Cmd.none )
            ( model, Cmd.none )


getPackages : Cmd Msg
getPackages =
    let
        decodeSafe =
            [ Decode.map Just Package.decoder, Decode.succeed Nothing ]
                |> Decode.oneOf
                |> Decode.list
    in
        "/all-package-docs.json"
            |> Http.get decodeSafe
            |> Task.perform Fail
                (\maybePackages ->
                    Load (List.filterMap identity maybePackages)
                )