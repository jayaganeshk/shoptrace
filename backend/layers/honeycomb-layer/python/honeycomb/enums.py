from enum import Enum


class HoneycombStatus(Enum):
    SUCCESS = "Success"
    FAILURE = "Failure"


class HoneycombErrorType(Enum):
    EXCEPTION = "exception"
    NO_DATA = "no_data"
    INVALID_DATA = "invalid_data"
    UNKNOWN = "unknown"
