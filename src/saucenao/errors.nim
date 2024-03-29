type
  SauceNaoApiError* = object of CatchableError
  UrlAndFileError* = object of SauceNaoApiError
  UnknownApiError* = object of SauceNaoApiError
  UnknownServerError* = object of UnknownApiError
  UnknownClientError* = object of UnknownApiError
  BadKeyError* = object of SauceNaoApiError
  BadFileSizeError* = object of SauceNaoApiError
  LimitReachedError* = object of SauceNaoApiError
  ShortLimitReachedError* = object of LimitReachedError
  LongLimitReachedError* = object of LimitReachedError
  AnonymousAccessError* = object of SauceNaoApiError
