class_name DLoggerDeferredToken
extends RefCounted

## Supersedes pending deferred work (debounced search rebuilds, button
## label restores). Each trigger claims a token; when the awaited timer
## fires, only the latest claim still counts as current, so rapid repeats
## can never apply a stale update. Extracted from DLoggerPanel, which
## repeated the claim/compare pattern three times (search/copy/save).

# ------------- [State] -------------
var _current := 0


# ------------- [Public Method] -------------
## Claims the next token, superseding any pending one.
func claim() -> int:
	_current += 1
	return _current


## Returns true when the given token is still the latest claim.
func is_current(token: int) -> bool:
	return token == _current
