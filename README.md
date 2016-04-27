<p align="center">
    <img src="https://img.shields.io/badge/license-mit-blue.svg?style=flat-square" />
    <img src="https://img.shields.io/badge/gluten-free-green.svg?style=flat-square" />
</p>

# elm-notification

Easily display toast notifications to users. The module defines four common alert levels (success,
info, warning and error) and takes care of managing toast lifecycles.

See the [demo](https://ktorz.github.io/elm-notification) to get a nice overview of the capabilities.

# How to use it

Within your app, first connect the effects runner to a port (or alternatively, merged it into
one of your effects signal that is already bound to a port).

```elm
import Notification

-- 
-- Some stuff...
--

port notifications : Signal (Task Effects.Never ())
port notifications =
  Notification.task
```

Then, fold on the view signal and display a view accordingly:

```elm
view : Html -> Html
view notifications =
  div [] [notifications] 

main =
  Signal.map view Notification.view
```

To actually send a notification, use the `address` provided by the module:

```elm
view : Html -> Html
view notifications =
  let
    controls = button [onClick Notification.address (Notification.info "Elm rocks!")]
  in
    div [] [notifications, controls]
```

# TODOs

- Allow colors and easing animations to be configured

# Change log

### 1.0.0 (2016-04-27)

- First version, display notifications of four different types


