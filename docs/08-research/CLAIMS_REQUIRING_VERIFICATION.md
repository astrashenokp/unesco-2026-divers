# Claims requiring verification or careful wording

Do not copy the following raw-corpus claims into proposal/product as established facts.

| Claim pattern | Problem | Safe wording/action |
|---|---|---|
| exact Bad News/Go Viral percentages without direct paper citation | metric/population mixed | cite primary study and exact outcome or omit number |
| tiny Deepfaked N=7 result proves effectiveness | no control/statistical power | usability anecdote only |
| Crossref/OpenAlex miss means fabricated | incomplete index/outage/other registry | “not found in queried registries” |
| metadata record/abstract proves paper supports claim | entailment needs relevant full text/review | separate existence, metadata match, support unknown |
| C2PA proves truth | provenance only | teach independent axes |
| no C2PA means fake | metadata may be absent/stripped | “credentials unavailable” |
| platforms always strip credentials | version/mode dependent | test named version/flow or say may |
| AI Act mandates C2PA/(cr) specifically | technology-neutral rules | cite official guidance; call C2PA one implementation option |
| “first in world”, “guarantees win”, “prevents all attacks/fakes” | unverifiable/absolute | describe differentiator/controls and evidence limits |
| named product cannot detect citations | no comparative current eval | do not claim; benchmark your flow |

## Known raw technical errors

The prior-art notes contain mojibake, duplicated AI-generated sections, a Python C2PA snippet with list/dict runtime bug, non-zero exit oversimplification, mocked credentials not clearly labeled, and bcrypt described as encryption rather than password hashing. Treat all snippets as non-production until independently reviewed/tested.

## Claim register fields

`claim`, `status(observed/inferred/hypothesis/target)`, `source URL`, `retrieval date`, `exact supported scope`, `owner`, `review date`, `approved wording`.
