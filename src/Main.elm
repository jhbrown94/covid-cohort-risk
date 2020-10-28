module Main exposing (..)

import Browser exposing (UrlRequest)
import Browser.Navigation as Navigation
import Element
import Element.Background as Background
import Element.Border as Border
import Element.Input as Input
import FormatNumber exposing (format)
import FormatNumber.Locales exposing (Decimals(..), spanishLocale, usLocale)
import Html exposing (Html)
import Url exposing (Url)


float value =
    Element.text (format usLocale value)


grey =
    Element.rgb 0.5 0.5 0.5


red =
    Element.rgb 1.0 0.0 0.0


slider attrs message description minVal maxVal step value =
    Input.slider
        ([ Element.height (Element.px 30)

         -- Here is where we're creating/styling the "track"
         , Element.behindContent
            (Element.el
                [ Element.width Element.fill
                , Element.height (Element.px 2)
                , Element.centerY
                , Background.color grey
                , Border.rounded 2
                ]
                Element.none
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


text attrs message description value =
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
    = OnUrlChange Url
    | OnUrlRequest UrlRequest
    | DailyNewCasesPer100K TextOrSliderMsg
    | DaysOfInfection TextOrSliderMsg
    | PodSizeIncludingTeacher TextOrSliderMsg
    | NumberOfStudents TextOrSliderMsg


type alias Flags =
    ()


type alias Model =
    { daily_new_cases_per_100k : TextOrSliderState
    , days_of_infection : TextOrSliderState
    , pod_size_including_teacher : TextOrSliderState
    , number_of_students : TextOrSliderState
    }


newTextOrSliderState decimals value =
    TextOrSliderState value "banana" |> textOrSliderUpdate (SliderUpdate value) decimals


init : Flags -> Url -> Navigation.Key -> ( Model, Cmd Msg )
init flags url key =
    ( Model (newTextOrSliderState 2 5.0)
        (newTextOrSliderState 0 14.0)
        (newTextOrSliderState 0 13.0)
        (newTextOrSliderState 0 2000.0)
    , Cmd.none
    )


display : Model -> Html Msg
display model =
    let
        daily_new_cases_per_100k =
            model.daily_new_cases_per_100k.value

        days_of_infection =
            model.days_of_infection.value

        number_of_students =
            model.number_of_students.value

        pod_size_including_teacher =
            model.pod_size_including_teacher.value

        number_of_pods =
            number_of_students
                / (pod_size_including_teacher - 1)

        p_a_random_person_is_newly_infected_today =
            daily_new_cases_per_100k / 100000.0

        p_a_random_person_is_not_newly_infected_today =
            1.0 - p_a_random_person_is_newly_infected_today

        p_a_random_person_is_currently_infected =
            p_a_random_person_is_newly_infected_today * days_of_infection

        p_a_random_person_is_not_infected_today =
            1.0 - p_a_random_person_is_currently_infected

        p_a_random_pod_has_no_infections =
            p_a_random_person_is_not_infected_today
                ^ pod_size_including_teacher

        p_a_random_pod_has_at_least_one_infection =
            1.0 - p_a_random_pod_has_no_infections

        p_no_pod_has_infections =
            p_a_random_pod_has_no_infections ^ number_of_pods

        p_some_pods_have_infections =
            1.0 - p_no_pod_has_infections

        p_a_random_pod_gets_no_new_infections_today =
            p_a_random_person_is_not_newly_infected_today
                ^ pod_size_including_teacher

        p_a_random_pod_gets_some_new_infections_today =
            1.0 - p_a_random_pod_gets_no_new_infections_today

        expected_number_of_days_between_infections_in_a_pod =
            1.0 / p_a_random_pod_gets_some_new_infections_today

        p_no_pods_get_new_infections_today =
            p_a_random_pod_gets_no_new_infections_today ^ number_of_pods

        p_some_pods_get_new_infections_today =
            1.0 - p_no_pods_get_new_infections_today

        expected_number_of_days_between_new_pod_infection_events =
            1.0 / p_some_pods_get_new_infections_today
    in
    Element.layout [] <|
        Element.column [ Element.padding 8, Element.spacing 8 ]
            [ textSlider { onChange = DailyNewCasesPer100K, description = "Daily new cases per 100,000 people", min = 0.1, max = 25.0, step = Nothing } model.daily_new_cases_per_100k
            , textSlider { onChange = DaysOfInfection, description = "Days of infection", min = 1, max = 25, step = Just 1.0 } model.days_of_infection
            , textSlider { onChange = NumberOfStudents, description = "Number of students", min = 10.0, max = 10000.0, step = Just 10 } model.number_of_students
            , textSlider { onChange = PodSizeIncludingTeacher, description = "Pod size (including teacher)", min = 5, max = 31, step = Just 1.0 } model.pod_size_including_teacher
            , percent "Chance that a randomly selected pod has one or more infected people on day one" p_a_random_pod_has_at_least_one_infection
            , percent "Chance that one or more of the pods has one or more infected people on day one" p_some_pods_have_infections
            , expected "Expected number of calendar days between infections in one pod" expected_number_of_days_between_infections_in_a_pod
            , percent "Chance that one or more of the pods get one or more new infections on any given calendar day" p_some_pods_get_new_infections_today
            , expected "Expected number of calendar days between new infections in one or more pods" expected_number_of_days_between_new_pod_infection_events
            ]


textSlider { onChange, description, min, max, step } state =
    Element.column
        [ Element.padding 8
        , Element.spacing 4
        , Border.width 1
        , Border.color grey
        ]
        [ Element.paragraph [] [ Element.text description ]
        , Element.row
            [ Element.padding 8
            , Element.spacing 4
            ]
            [ slider [ Element.width (Element.px 250) ] (SliderUpdate >> onChange) description min max step state.value
            , Element.el [ Element.width (Element.px 100) ] <|
                text
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


percent description value =
    Element.row []
        [ Element.paragraph [] [ Element.text description, Element.text ":  ", float (value * 100.0), Element.text "%" ]
        ]


expected description value =
    Element.row []
        [ Element.paragraph [] [ Element.text description, Element.text ":  ", float value ]
        ]


view : Model -> Browser.Document Msg
view model =
    { title = "Pod Stats"
    , body = [ display model ]
    }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        OnUrlChange _ ->
            ( model, Cmd.none )

        OnUrlRequest _ ->
            ( model, Cmd.none )

        DailyNewCasesPer100K m ->
            ( { model | daily_new_cases_per_100k = textOrSliderUpdate m 2 model.daily_new_cases_per_100k }, Cmd.none )

        DaysOfInfection m ->
            ( { model | days_of_infection = textOrSliderUpdate m 0 model.days_of_infection }, Cmd.none )

        PodSizeIncludingTeacher m ->
            ( { model | pod_size_including_teacher = textOrSliderUpdate m 0 model.pod_size_including_teacher }, Cmd.none )

        NumberOfStudents m ->
            ( { model | number_of_students = textOrSliderUpdate m 0 model.number_of_students }, Cmd.none )


subscriptions model =
    Sub.none


main =
    Browser.application
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        , onUrlChange = OnUrlChange
        , onUrlRequest = OnUrlRequest
        }
