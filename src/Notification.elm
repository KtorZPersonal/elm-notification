module Notification
  ( Notification
  , success
  , info
  , warning
  , error
  , address
  , task
  , view
  ) where

{-|
Easily display toast notifications to users. The module defines four common alert levels (success,
info, warning and error) and takes care of managing toast lifecycles.

See the [demo](https://ktorz.github.io/elm-notification) to get a nice overview of the capability.

# Create a notification

To create a notification, just send a `Notification` to the provided signal address. This can be
done either by directly calling `Signal.send` or, by using events subscriber from the `Html.Events`
module.

@docs Notification, success, info, warning, error, address

# Display and run effects

To be able to run and to actually work, notifications need to be added to your view. A `Signal Html`
is available for that purpose as well as a `Signal (Task Effects.Never ())` ready to be plugged in a
port, or merged with on of your application effects signal.

@docs view, task
-}

import String
import Time exposing (Time)
import Effects exposing (Effects)
import Task exposing (Task)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Easing


-------------------------------------------------------
-- CONSTANTS
-------------------------------------------------------
{- Transition delay for the toast creation animation -}
createDuration : Time
createDuration =
  Time.millisecond * 500

{- Transiation delay for the toast discard animation -}
discardDuration : Time
discardDuration =
  Time.millisecond * 1000

{- Transition delay for the toast hover animation -}
hoverDuration : Time
hoverDuration =
  Time.millisecond * 250

{- Color binding with levels -}
asColor : Level -> String
asColor level =
  case level of
    Success -> "#8BC34A"
    Info    -> "#2196F3"
    Warning -> "#FFC107"
    Error   -> "#F44336"


-------------------------------------------------------
-- STATE
-------------------------------------------------------
{- Module internal state, a list of active toast -}
type alias State =
  List Toast

{- An actual displayed notification, so called Toast -}
type alias Toast =
  { id: Float
  , notification: Notification
  , status: Status
  , animation: Animation
  }

{- Animation encapsulate and abstract metadata needed to handle animations -}
type alias Animation =
  { at: Time
  , current: Time
  }

{- The toast status
  Idle: The toast is there, waiting for a user interaction
  IdleHovered: The toat is there and the user is hovering it
  Dicarded: Transition state starting after the toast has been discarded
  Hovered: Transition state for when the mouse is interacting with the toast
-}
type Status
  = Idle
  | IdleHovered
  | Discarded
  | Hovered HoverType

{- Type of Hover action, MouseEnter -> HoverIn; MouseOut -> Hover Out -}
type HoverType
  = HoverIn
  | HoverOut

{-| Representation of a notification -}
type alias Notification =
  { content: String
  , level: Level
  }

type Level
  = Success
  | Info
  | Warning
  | Error


-------------------------------------------------------
-- ACTIONS
-------------------------------------------------------
type Action
  = NoOp
  | Show (Time, Notification)
  | Discard (Time, Toast)
  | Hover (Time, HoverType, Toast)
  | Tick Time

type Event
  = None
  | OnDiscard Toast
  | OnHover (HoverType, Toast)


-------------------------------------------------------
-- REDUCER
-------------------------------------------------------
{- Update a given state by making one animation step. -}
step : Time -> Time -> Maybe Status -> Toast -> (State, Effects Action) -> (State, Effects Action)
step current max after toast (state, effects) =
  if current - toast.animation.at <= max
  then
    let
      t = { toast | animation = { at = toast.animation.at, current = current } }
    in
      (t::state, Effects.tick Tick)
  else
    case after of
      Nothing ->
        (state, effects)
      Just status ->
        ({toast | status = status, animation = { at = 0, current = current }}::state, effects)

{- Reduce the application state for a given action -}
update : Action -> State -> (State, Effects Action)
update action state =
  case action of
    NoOp ->
      (state, Effects.none)


    Show (clock, notif) ->
      let
        animation = { at = clock, current = clock }
        id = Time.inMilliseconds clock
        toast = { id = id, notification = notif, status = Idle, animation = animation }
      in
      (toast::state, Effects.tick Tick)


    Discard (clock, toast) ->
      let
        discard target src =
          if target.id == src.id
          then { src | status = Discarded, animation = {at = clock, current = clock} }
          else src
      in
        case toast.status of
          Discarded ->
            (state, Effects.none)
          _ ->
            (List.map (discard toast) state, Effects.tick Tick)


    Hover (clock, hoverType, toast) ->
      let
        hover target src =
          if target.id == src.id
          then { src | status = Hovered hoverType, animation = {at = clock, current = clock} }
          else src
      in
        case toast.status of
          Discarded ->
            (state, Effects.none)
          _ ->
            (List.map (hover toast) state, Effects.tick Tick)


    Tick clock ->
      let
        reduce refClock toast acc =
          case toast.status of
            Idle ->
              step refClock createDuration (Just Idle) toast acc
            IdleHovered ->
              (toast::(fst acc), snd acc)
            Discarded ->
              step refClock discardDuration Nothing toast acc
            Hovered HoverIn ->
              step refClock hoverDuration (Just IdleHovered) toast acc
            Hovered HoverOut ->
              step refClock hoverDuration (Just Idle) toast acc


      in
        List.foldr (reduce clock) ([], Effects.none) state

-------------------------------------------------------
-- VIEWS
-------------------------------------------------------
viewAll : (Signal.Address Event -> State -> Html)
viewAll addr state =
  let
    toastsStyle = style
      [ ("top", "0")
      , ("left", "0")
      , ("width", "100%")
      , ("zIndex", "99")
      , ("position", "fixed")
      ]
  in
    div
      [toastsStyle]
      (List.map (viewToast addr) (List.reverse state))

viewToast : (Signal.Address Event -> Toast -> Html)
viewToast addr toast =
  let
    elapsed = toast.animation.current - toast.animation.at
    (toastAnim, crossAnim) = case toast.status of
      Idle ->
        let x = Easing.ease Easing.easeOutQuad Easing.float 0 1 createDuration elapsed
        in
          ( [ ("top", String.append (toString (-3 + x * 3)) "rem")
            , ("opacity", toString x)
            ]
          , [ ("opacity", "0.3") ]
          )


      IdleHovered ->
        ( [ ("top", "0")
          , ("opacity", "1")
          ]
        , [ ("opacity", "1") ]
        )


      Discarded ->
        let x = Easing.ease (Easing.bezier 0.85 -0.2 0 1.1) Easing.float 1 0 discardDuration elapsed
        in
          ( [ ("left", String.append (toString (-100 + 100 * x)) "%")
            , ("opacity", toString x)
            ]
          , [ ("opacity", "0") ]
          )


      Hovered HoverIn ->
        let x = Easing.ease Easing.easeOutQuad Easing.float 0.3 1 hoverDuration elapsed
        in
          ( []
          , [ ("opacity", toString x) ]
          )


      Hovered HoverOut ->
        let x = Easing.ease Easing.easeOutQuad Easing.float 1 0.3 hoverDuration elapsed
        in
          ( []
          , [ ("opacity", toString x) ]
          )

    toastStyle = style
      <| List.append toastAnim
        [ ("background", asColor toast.notification.level)
        , ("border-bottom", "1px solid #FFFFFF")
        , ("color", "#FFFFFF")
        , ("cursor", "pointer")
        , ("fontFamily", "Arial")
        , ("padding", "1rem")
        , ("position", "relative")
        , ("width", "100%")
        ]

    crossStyle = style
      <| List.append crossAnim
        [ ("position", "absolute")
        , ("right", "3rem")
        , ("top", "50%")
        , ("margin-top", "-0.5rem")
        ]
  in
    div
      [ toastStyle
      , onClick addr (OnDiscard toast)
      , onMouseEnter addr (OnHover (HoverIn, toast))
      , onMouseLeave addr (OnHover (HoverOut, toast))
      ]
      [ div [style [("padding-right", "4rem")]] [text toast.notification.content]
      , div [crossStyle] [text "✖"]
      ]


-------------------------------------------------------
-- VIEWS
-------------------------------------------------------
notifications : Signal.Mailbox Notification
notifications =
  Signal.mailbox { content = "", level = Info }

app : { view: Signal Html, task: Signal (Task Effects.Never ()) }
app =
  let
    -- Mailbox Event
    events = Signal.mailbox None

    -- Mailbox (List Action)
    ticks = Signal.mailbox []

    -- (Time, Event) -> Action
    forwardToAction (t, event) =
      case event of
        OnDiscard toast ->
          Discard (t, toast)
        OnHover (hoverType, toast) ->
          Hover (t, hoverType, toast)
        None ->
          NoOp

    -- a -> List a
    singleton a = [a]

    -- Signal (List Action)
    signals = Signal.mergeMany
      [ Signal.map (Show >> singleton) (Time.timestamp notifications.signal)
      , Signal.map (forwardToAction >> singleton)  (Time.timestamp events.signal)
      , Signal.map (fst >> Tick >> singleton) (Time.timestamp ticks.signal)
      ]

    -- Action -> (State, Effects Action) -> (State, Effects Action)
    adaptUpdate action (state, effects) = update action state

    -- List Action -> (State, Effects Action) -> (State, Effects Action)
    reduce = List.foldr adaptUpdate |> flip

    -- Signal (State, Effects Action)
    states = Signal.foldp reduce ([], Effects.none) signals

    -- State -> Signal Html
    asView = viewAll events.address

    -- Effects Action -> Task never ()
    asTask = Effects.toTask ticks.address
  in
    { view = Signal.map (fst >> asView) states
    , task = Signal.map (snd >> asTask) states
    }


-------------------------------------------------------
-- CONSTRUCTORS
-------------------------------------------------------
{-| Create a `success` notification -}
success : String -> Notification
success =
  new Success

{-| Create an `info` notification -}
info : String -> Notification
info =
  new Info

{-| Create a `warning` notification -}
warning : String -> Notification
warning =
  new Warning

{-| Create an `error` notification -}
error : String -> Notification
error =
  new Error

{- Internal constructor to instantiate a notification given a type and a string -}
new : Level -> String -> Notification
new level content =
  { content = content
  , level = level
  }


-------------------------------------------------------
-- VIEWS
-------------------------------------------------------
{-| Communication address to require a notification on the screen -}
address : Signal.Address Notification
address =
  notifications.address

{-| Effects runner -}
task : Signal (Task Effects.Never ())
task =
  app.task

{-| Notification view updated for each user interaction -}
view : Signal Html
view =
  app.view
