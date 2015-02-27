import urllib
import urllib2
import json
import os
import sys
import time
from urlparse import urljoin
import networkx as nx
from pprint import pprint
from itertools import combinations
from pyjson import JsonObject
import networkx as nx
from networkx.readwrite import json_graph


class DiscogsApi():

    def __init__(self):
        
        self.base_url = "https://api.discogs.com"

    def _OpenUrl(self):

        data = ""
        if self.params:
            data = urllib.urlencode(self.params)
            search_url = "?".join([self.url, data])
        else:
            search_url = self.url
        request = urllib2.Request(search_url)
        response = urllib2.urlopen(request)
        json_response = json.load(response)
        time.sleep(1.1)
        return json_response

    def _AddParam(self, key, value):

        self.params[key] = value

    def _ClearParams(self):

        self.params = {}

    def GetCollection(self, username, folder_id="0", per_page=100):
        """
        Use discogs username and folder to return release data from given folder; 
        Most folders require authentication for access. Folder "0" is the "all" folder.
        """
        self._ClearParams()
        self._AddParam("per_page", per_page)

        self.collection_extension = "/users/{username}/collection/folders/{folder_id}/releases".format(username=username, folder_id=folder_id)
        self.url = self._BuildUrl(self.collection_extension)
        self.collection = self._OpenUrl()
        self.releases = self.collection["releases"]
        print "{:=^30}".format("Getting Collection")
        if self.collection["pagination"]["pages"] > 1:
            for i in range(2, self.collection["pagination"]["pages"]+1, 1):
                self._AddParam("page", i)
                collection = self._OpenUrl()
                for release in collection["releases"]:
                    self.releases.append(release)

        print "Processing {:=^30} Releases".format(len(self.releases))

        return self.releases

    def GetRelease(self, release_id):
        """
        Use release ID to return release data
        """
        self._ClearParams()
        self.release_extension = "/releases/{release_id}".format(release_id=release_id)
        self.url = self._BuildUrl(self.release_extension)
        self.release = self._OpenUrl()

        return self.release

    def _BuildUrl(self, url_extension):
        """
        Combine base url and search extension
        """
        return urljoin(self.base_url, url_extension)


class DiscogsData():
    
    def __init__(self, path_to_data=None):
        """
        If no data is provided as an argument here (JSON), data will be collected via API.
        """
        
        self.data = None
        self.co_graph = None
        self.path_to_data = path_to_data
        if self.path_to_data is not None:
            json_object = JsonObject()
            self.data = json_object.LoadJson(self.path_to_data)

    def CollectionStyleGraph(self, username="username", folder_id="0"):
        self.username = username
        self.folder_id = folder_id
        if self.data is None:
            self.data = self.GetCollectionStyles()
        self.co_graph = self.GraphCooccurrenceData(self.data)
        return self.co_graph

    def GraphOutput(self, data_type, output_path="co_graph"):
        """
        Currently support for writing graph data to formats suitable for Gephi and D3 force layout.
        """

        valid_types = ["gephi", "d3"]

        if self.co_graph is None:
            print "===No Graph Data Available==="
            print "===Run GraphCooccurrenceData==="

        if data_type not in valid_types:
            print "===Invalid data_type==="
            print "===Try==="
            for t in valid_types:
                print "==={0}===".format(t)

        if data_type == "gephi":
            if not output_path.endswith(".gexf"):
                output_path += ".gexf"
            nx.write_gexf(self.co_graph, output_path)
            print "GEXF Written to {0}".format(output_path)

        elif data_type == "d3":
            data = json_graph(self.co_graph)
            json_data = JsonObject()
            if not output_path.endswith(".json"):
                output_path += ".json"
            json_data.SaveAsJson(data, output_path)
            print "JSON Written to {0}".format(output_path)

    def GraphCooccurrenceData(self, data):
        format_nodes = {}
        format_edges = {}
        for listing in data:
            for value in listing:
                format_nodes[value] = format_nodes.get(value, 0) + 1
            for c in combinations(listing, 2):
                c_string = "----".join(c)
                c_string_reverse = "----".join(c[::-1])
                if c_string in format_edges:
                    format_edges[c_string] += 1
                elif c_string_reverse in format_edges:
                    format_edges[c_string_reverse] += 1
                else:
                    format_edges[c_string] = 1
        co_graph = self.BuildGraphData(format_nodes, format_edges)
        return co_graph

    def BuildGraphData(self, nodes, edges):
        graph = nx.Graph()
        for key in nodes:
            graph.add_node(key, weight=nodes[key])

        for key in edges:
            edge_values = tuple(key.split("----"))
            graph.add_edge(edge_values[0], edge_values[1], weight=edges[key])

        return graph

    def StylesDictCounter(self, styles):
        for s in styles:
            if s in self.styles:
                self.styles[s] += 1
            else:
                self.styles[s] = 1

    def GetCollectionStyles(self):

        self.styles_by_release = []
        self.styles = {}

        dapi = DiscogsApi()
        self.collection = dapi.GetCollection(self.username, folder_id=self.folder_id)
        i = 0
        for release in self.collection:
            #print release["basic_information"]["artists"][0]["name"]
            r_id = release["id"]
            release_data = dapi.GetRelease(r_id)
            if "styles" in release_data:
                self.styles_by_release.append(release_data["styles"])
                self.StylesDictCounter(release_data["styles"])
            i += 1
            sys.stdout.write("{:=^30}\r".format(i))
            sys.stdout.flush()

        print "{:=^30}".format("\nStyles by Count")    
        pprint(self.styles)
        
        return self.styles_by_release


