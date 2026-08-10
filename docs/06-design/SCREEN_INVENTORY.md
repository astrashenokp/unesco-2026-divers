# Screen inventory and states

| P0 screen | Core states |
|---|---|
| language/guest onboarding | default, consent notice, error/offline |
| learning path/home | available/completed/locked, booster due, offline pack |
| mission brief | media loaded/alternative, warning, unavailable |
| prediction | reaction unselected/selected, confidence, validation |
| investigation workspace | empty, evidence loading/found/not found/conflict/unavailable, hint levels |
| three-axis conclusion | incomplete, unknown/insufficient, submit/retry/conflict |
| reflection/receipt | score, confidence delta, sources, limitations, correction banner |
| profile/progress | guest/signed-in, skills, streak paused |
| report dialog | reason, privacy warning, submitted/error |

## Responsive behavior

Mobile is primary: bottom action region and one-pane flow. Tablet/web may use split mission/evidence panes but preserve reading/focus order. At 200% text, no clipped controls or horizontal reading scroll. Landscape and narrow web get explicit tests.

## Demo route

Hidden non-production/demo entry selects local signed pack, seeds learner state and blocks outgoing providers unless presenter enables one bounded call. The UI labels demo data only outside the recorded learner experience.
