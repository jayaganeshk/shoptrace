import json


class NoDataException(Exception):
    def __init__(self, msg) -> None:
        self.msg = msg

    def __str__(self) -> str:
        return json.dumps({"Error": self.msg})


class InvalidRequestException(Exception):
    def __init__(self, msg) -> None:
        self.msg = msg

    def __str__(self):
        return json.dumps({"Error": self.msg})
