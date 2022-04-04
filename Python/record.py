import datetime

class Record:
    key: str
    value: str
    timestamp: datetime.datetime
    valid: bool

    def __init__(self, key: str = "", value: str = ""):
        self.key = key
        self.value = value
        self.timestamp = datetime.datetime.now()
        self.valid = True

    def invalidate(self):
        self.valid = False

    def __str__(self):
        return "{} {} {}".format(self.key, self.value, self.timestamp)