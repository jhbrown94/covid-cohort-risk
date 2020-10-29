{-
   Copyright 2020 Jeremy Brown and Daniele Lantagne.

   Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

   1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

   2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

   3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
-}


module Main exposing (..)

import Browser exposing (UrlRequest)
import Browser.Navigation as Navigation
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import FormatNumber exposing (format)
import FormatNumber.Locales exposing (Decimals(..), spanishLocale, usLocale)
import Html exposing (Html)
import Url exposing (Url)


grey =
    rgb 0.5 0.5 0.5


lightGrey =
    rgb 0.95 0.95 0.95


darkGrey =
    rgb 0.2 0.2 0.2


red =
    rgb 1.0 0.0 0.0


slider attrs message description minVal maxVal step value =
    Input.slider
        ([ height (px 30)

         -- Here is where we're creating/styling the "track"
         , behindContent
            (el
                [ width fill
                , height (px 2)
                , centerY
                , Background.color grey
                , Border.rounded 2
                ]
                none
            )
         ]
            ++ attrs
        )
        { onChange = message
        , label = Input.labelHidden description
        , min = minVal
        , max = maxVal
        , step = step
        , value = value
        , thumb =
            Input.defaultThumb
        }


textInput attrs message description value =
    Input.text attrs
        { onChange = message
        , text = value
        , placeholder = Nothing
        , label = Input.labelHidden description
        }


type TextOrSliderMsg
    = SliderUpdate Float
    | TextUpdate String


type alias TextOrSliderState =
    { value : Float
    , string : String
    }


textOrSliderUpdate msg decimals state =
    case msg of
        SliderUpdate value ->
            { state | value = value, string = format { usLocale | decimals = Exact decimals, thousandSeparator = "" } value }

        TextUpdate value ->
            { state | string = value, value = String.toFloat value |> Maybe.withDefault state.value }


textOrSliderValidText state =
    case String.toFloat state.string of
        Just value ->
            True

        Nothing ->
            False


textOrSliderValue state =
    state.value


type Msg
    = DailyNewCasesPer100K TextOrSliderMsg
    | DaysOfInfection TextOrSliderMsg
    | CohortSizeIncludingTeacher TextOrSliderMsg
    | NumberOfStudents String


type alias Flags =
    ()


type alias Model =
    { daily_new_cases_per_100k : TextOrSliderState
    , days_of_infection : TextOrSliderState
    , cohort_size_including_teacher : TextOrSliderState
    , number_of_students : Int
    , number_of_students_field : String
    }


newTextOrSliderState decimals value =
    TextOrSliderState value "banana" |> textOrSliderUpdate (SliderUpdate value) decimals


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( Model (newTextOrSliderState 2 5.0)
        (newTextOrSliderState 0 10.0)
        (newTextOrSliderState 0 13.0)
        2000
        "2000"
    , Cmd.none
    )


blurb =
    """
As part of COVID-19 response, some schools are dividing students into "cohorts" for in-person learning. Students and teachers in a cohort meet only with one another. This strategy is intended to limit the number of people exposed to a person who is positive COVID-19 in a school -- if someone in a cohort acquires COVID-19 in the community, only the people in that cohort need to subsequently quarantine and test.

In a "cohort" strategy, the probability of having one person of a cohort positive for COVID-19 is dependent on: community transmission rates, size of cohort.  The probability of having a cohort in a district test positive depends on these factors, as well as the number of cohorts. 

This is a simple tool to help schools evaluate how often an individual cohort is likely to have a COVID-positive person or people in it, and how often one or more cohorts, out of many in a district, are likely to have COVID-positive people in them.

This tool examines both the likelihood that a cohort has someone infected on day one -- which is to say, the first day that students walk into the classroom -- and the likelihood of later infections impacting cohorts.

This tool makes the simplifying assumption that everyone in a community has the same risk of being infected, based on the community new-case-rate, regardless of age and other distinguishing characteristics.

This model *only* describes the probability that a person arrives at the school COIVD-19 positive due to community transmission.  This model does NOT say anything about transmission within a cohort or within a school.   Transmission within a cohort or school will be dependent on a variety of factors, including but not limited to: cohort strategy, masking, social distancing, disinfection, and ventilation strategy.  None of these are modeled here.  

For questions or comments, contact Professor Daniele Lantagne at danielelantagne@earthlink.net and Dr. Jeremy Brown at jhbrown@gmail.com

Veradept, Inc. is hosting this tool as a courtesy. This tool is not an official product of Veradept, Inc. or Tufts University and Veradept and Tufts University make no representations as to the correctness of this tool, or its suitability for any purpose whatsoever.
"""


display : Model -> Html Msg
display model =
    let
        daily_new_cases_per_100k =
            model.daily_new_cases_per_100k.value

        days_of_infection =
            model.days_of_infection.value

        number_of_students =
            toFloat model.number_of_students

        cohort_size_including_teacher =
            model.cohort_size_including_teacher.value

        number_of_cohorts =
            number_of_students
                / (cohort_size_including_teacher - 1)

        p_a_random_person_is_newly_infected_today =
            daily_new_cases_per_100k / 100000.0

        p_a_random_person_is_not_newly_infected_today =
            1.0 - p_a_random_person_is_newly_infected_today

        p_a_random_person_is_currently_infected =
            p_a_random_person_is_newly_infected_today * days_of_infection

        p_a_random_person_is_not_infected_today =
            1.0 - p_a_random_person_is_currently_infected

        p_a_random_cohort_has_no_infections =
            p_a_random_person_is_not_infected_today
                ^ cohort_size_including_teacher

        p_a_random_cohort_has_at_least_one_infection =
            1.0 - p_a_random_cohort_has_no_infections

        p_no_cohort_has_infections =
            p_a_random_cohort_has_no_infections ^ number_of_cohorts

        p_some_cohorts_have_infections =
            1.0 - p_no_cohort_has_infections

        p_a_random_cohort_gets_no_new_infections_today =
            p_a_random_person_is_not_newly_infected_today
                ^ cohort_size_including_teacher

        p_a_random_cohort_gets_some_new_infections_today =
            1.0 - p_a_random_cohort_gets_no_new_infections_today

        expected_number_of_days_between_infections_in_a_cohort =
            1.0 / p_a_random_cohort_gets_some_new_infections_today

        p_no_cohorts_get_new_infections_today =
            p_a_random_cohort_gets_no_new_infections_today ^ number_of_cohorts

        p_some_cohorts_get_new_infections_today =
            1.0 - p_no_cohorts_get_new_infections_today

        expected_number_of_days_between_new_cohort_infection_events =
            1.0 / p_some_cohorts_get_new_infections_today
    in
    layout [ width fill, Background.color darkGrey ] <|
        column
            [ centerX
            , width (fill |> maximum 800)
            , Border.rounded 4
            , Background.color lightGrey
            , padding 16
            , spacing 16
            ]
            [ textColumn [ width fill, Border.width 1, Border.color grey, padding 16, spacing 16 ] <|
                List.map (text >> List.singleton >> paragraph [ width fill ]) (String.split "\n" blurb)
            , column [ width fill, Border.width 1, Border.color grey, padding 16, spacing 16 ]
                [ text "COVID-19 parameters"
                , textSlider { onChange = DailyNewCasesPer100K, description = "Daily new cases per 100,000 people", min = 0.1, max = 25.0, step = Nothing } model.daily_new_cases_per_100k
                , textSlider { onChange = DaysOfInfection, description = "Days someone is infectious (10 is current best estimate)", min = 1, max = 25, step = Just 1.0 } model.days_of_infection
                ]
            , column [ width fill, Border.width 1, Border.color grey, padding 16, spacing 16 ]
                [ text "District parameters:"
                , column [ centerX, spacing 8, width fill ]
                    [ el
                        [ width fill
                        , Border.width 1
                        , Border.color grey
                        , padding 8
                        ]
                      <|
                        Input.text
                            [ width (px 120)
                            , if String.toInt model.number_of_students_field == Nothing then
                                Border.color red

                              else
                                Border.color grey
                            ]
                            { onChange = NumberOfStudents
                            , text = model.number_of_students_field
                            , placeholder = Nothing
                            , label = Input.labelLeft [] <| text "Total number of students"
                            }
                    ]
                , textSlider { onChange = CohortSizeIncludingTeacher, description = "Cohort size (including teacher)", min = 5, max = 31, step = Just 1.0 } model.cohort_size_including_teacher
                , roundup "Number of cohorts" number_of_cohorts
                ]
            , column [ width fill, spacing 8 ]
                [ wrappedRow [ width fill, spacing 8 ]
                    [ percent "Chance that a randomly selected cohort has one or more infected people on day one" p_a_random_cohort_has_at_least_one_infection
                    , percent "Chance that one or more of the cohorts has one or more infected people on day one" p_some_cohorts_have_infections
                    ]
                , wrappedRow [ width fill ]
                    [ el [ width (fillPortion 1 |> minimum 150) ] none
                    , el [ width (fillPortion 2) ] <| percent "Chance that one or more of the cohorts get one or more new infections on any given calendar day" p_some_cohorts_get_new_infections_today
                    , el [ width (fillPortion 1 |> minimum 150) ] none
                    ]
                , wrappedRow [ width fill, spacing 8 ]
                    [ expected "Expected number of calendar days between infections in one cohort" expected_number_of_days_between_infections_in_a_cohort
                    , expected "Expected number of calendar days between new infections in one or more cohorts" expected_number_of_days_between_new_cohort_infection_events
                    ]
                ]
            ]


textSlider { onChange, description, min, max, step } state =
    column
        [ padding 8
        , spacing 4
        , Border.width 1
        , Border.color grey
        , width fill
        ]
        [ paragraph [] [ text description ]
        , row
            [ padding 8
            , spacing 4
            , width fill
            ]
            [ slider [ width fill ] (SliderUpdate >> onChange) description min max step state.value
            , el [ width (px 100) ] <|
                textInput
                    (if textOrSliderValidText state then
                        []

                     else
                        [ Border.color red ]
                    )
                    (TextUpdate >> onChange)
                    description
                    state.string
            ]
        ]


float value =
    text (format usLocale value)


percent description value =
    el [ Border.width 1, padding 8, width fill, height fill ] <|
        row [ width (fill |> minimum 300), spacing 16, centerY ]
            [ paragraph [ Font.alignRight ] [ text description, text ":" ]
            , paragraph [ Font.alignRight, Font.bold, width (px 80) ] [ text (format usLocale (value * 100.0)), text "%" ]
            ]


expected description value =
    el [ Border.width 1, padding 8, width fill, height fill ] <|
        row [ width (fill |> minimum 300), spacing 16 ]
            [ paragraph [ Font.alignRight ] [ text description, text ":" ]
            , paragraph [ Font.alignRight, Font.bold, width (px 80) ] [ text (format { usLocale | decimals = Exact 1 } value) ]
            ]


roundup description value =
    el [ Border.width 1, padding 8, centerX ] <|
        row [ width (fill |> minimum 300), spacing 16 ]
            [ paragraph [ Font.alignRight ] [ text description, text ":" ]
            , paragraph [ Font.alignRight, Font.bold, width (px 80) ] [ text (ceiling value |> String.fromInt) ]
            ]


view : Model -> Browser.Document Msg
view model =
    { title = "Cohort Stats"
    , body = [ display model ]
    }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        DailyNewCasesPer100K m ->
            ( { model | daily_new_cases_per_100k = textOrSliderUpdate m 2 model.daily_new_cases_per_100k }, Cmd.none )

        DaysOfInfection m ->
            ( { model | days_of_infection = textOrSliderUpdate m 0 model.days_of_infection }, Cmd.none )

        CohortSizeIncludingTeacher m ->
            ( { model | cohort_size_including_teacher = textOrSliderUpdate m 0 model.cohort_size_including_teacher }, Cmd.none )

        NumberOfStudents string ->
            ( { model
                | number_of_students = String.toInt string |> Maybe.withDefault model.number_of_students
                , number_of_students_field = string
              }
            , Cmd.none
            )


subscriptions model =
    Sub.none


main =
    Browser.document
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }
