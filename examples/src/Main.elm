import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Notification
import Effects exposing (Effects)
import Task exposing (Task)

main =
  let
    controls =
      div
        [ class "controls" ]
        [ button
          [ class "btn btn-success"
            , onClick Notification.address (Notification.success "Notification Success")
          ]
          [ text "Success" ]
        , button
          [ class "btn btn-info"
          , onClick Notification.address (Notification.info "Notification Info")
          ]
          [ text "Info" ]
        , button
          [ class "btn btn-warning"
          , onClick Notification.address (Notification.warning "Notification Warning")
          ]
          [ text "Warning" ]
        , button
          [ class "btn btn-error"
          , onClick Notification.address (Notification.error "Notification Error")
          ]
          [ text "Error" ]
        ]
    view notifications =
      div [ class "wrapper" ]
        [ notifications
        , controls
        ]
  in
    Signal.map view Notification.view

port notifications : Signal (Task Effects.Never ())
port notifications =
  Notification.task
