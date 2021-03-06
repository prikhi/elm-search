module Search.Update exposing (..)

import Docs.Package as Package exposing (Package)
import Search.Model as Model exposing (..)
import String


init : Filter -> List Package -> Model
init filter packages =
    let
        model =
            update (BuildIndex packages) { initialModel | filter = filter }

        _ =
            List.length model.index.chunks
    in
        case filter.query of
            [ query ] ->
                update RunFilter model

            _ ->
                model


update : Msg -> Model -> Model
update msg model =
    case msg of
        BuildIndex packages ->
            { model | index = buildIndex packages }

        SetFilter filter ->
            { model | filter = filter }

        SetFilterQueryString queryString ->
            let
                filterFacts =
                    model.filter

                filter =
                    { filterFacts
                        | queryString = queryString
                        , query = queryListFromString queryString
                    }

                resultChunks =
                    if String.isEmpty queryString then
                        []
                    else
                        model.result.chunks
            in
                { model
                    | filter = filter
                    , result = { chunks = resultChunks }
                }

        SetFilterQueryStringAndRunFilter queryString ->
            update (SetFilterQueryString queryString) model
                |> update RunFilter

        RunFilter ->
            { model | result = runFilter model.filter model.index }
