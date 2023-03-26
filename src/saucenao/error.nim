type
  SauceNaoApiError = object of Exception
  UnknownApiError = object of SauceNaoApiError
  UnknownServerError = object of UnknownApiError
  UnknownClientError = object of UnknownApiError
  BadKeyError = object of SauceNaoApiError
  BadFileSizeError = object of SauceNaoApiError
  LimitReachedError = object of SauceNaoApiError
  ShortLimitReachedError = object of LimitReachedError
  LongLimitReachedError = object of LimitReachedError
