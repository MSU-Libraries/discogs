import json
from dicttoxml import dicttoxml

class FormatObject():

    def __init__(self):
        pass

    def SaveAsJson(self, data, filepath):
        with open(filepath, "w") as f:
            json.dump(data, f)

    def LoadJson(self, filepath):
        with open(filepath) as f:
            data = json.load(f)
        return data

    def DictToXml(self, dictionary):
        xml = dicttoxml(dictionary)
        return xml

    def WriteFile(self, data, path, opener="w"):
        with open(path, opener) as f:
            f.write(data)



        