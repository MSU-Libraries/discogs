import json

class JsonObject():

    def __init__(self):
        pass

    def SaveAsJson(self, data, filepath):
        with open(filepath, "w") as f:
            json.dump(data, f)

    def LoadJson(self, filepath):
        with open(filepath) as f:
            data = json.load(f)
        return data
        