"""Discogs interactions."""
import urllib
import requests
import json
import os
import sys
import time
import configparser
from urllib.parse import urljoin
import networkx as nx
import codecs
from itertools import combinations
from formatobject.formatobject import FormatObject
from networkx.readwrite import json_graph
from collections import Counter


class DiscogsApi():
    """Class for interacting with Discogs API."""

    def __init__(self, username=None):
        """Establish base API url and provide arbitrary user agent name."""
        self.base_url = "https://api.discogs.com"
        self.user_agent = "DevinHigginsMSULibraries/0.1"
        self.headers = {'User-Agent': self.user_agent}
        self.params = {}

        if username:
            self.username = username
            self._get_token()
            self.add_param("token", self.user_token)

    def open_url(self, url, request_type=None):
        """Function to make all calls to the API."""
        print(url, self.params)
        response = requests.get(url, params=self.params, headers=self.headers)
        json_response = response.json()
        time.sleep(2)
        return json_response

    def add_param(self, key, value):
        """Add parameter to the header of the request sent to the API.

        args:
            key (str) -- key to use in header, e.g. 'User-Agent'
            value (str) -- value to associated with the given key.
        """
        self.params[key] = value

    def clear_params(self):
        """Clear all current header parameters."""
        self.params = {}

    def get_collection(self, username, folder_id="0", per_page=100):
        """Use discogs username to return release data from given folder.

        Most folders require authentication for access. Folder "0" is the "all" folder.

        Positional arguments:
        username (str) -- Any valid discogs user name; no authentication required.

        Keyword arguments:
        folder_id (str) -- The folder containing all releases (0) is the only one supported.
        per_page (int) -- The number of results to return per request. Max value is 100.
        """
        self.clear_params()
        self.add_param("per_page", per_page)
        self.add_param("token", self.user_token)
        self.collection_extension = "/users/{username}/collection/folders/{folder_id}/releases".format(username=username, folder_id=folder_id)
        self.url = self.build_url(self.collection_extension)
        self.collection = self.open_url(self.url)
        self.releases = self.collection["releases"]
        self.release_ids = []
        print("{:=^30}".format("Getting Collection"), "for {0}".format(username))
        if self.collection["pagination"]["pages"] > 1:
            for i in range(2, self.collection["pagination"]["pages"] + 1, 1):
                self.add_param("page", i)
                collection = self.open_url(self.url)
                for release in collection["releases"]:
                    self.releases.append(release)

        for release in self.releases:
            self.release_ids.append(release["id"])

        print("{:=^30} Releases".format(len(self.releases)))

        return self.releases

    def GetRelease(self, release_id):
        """
        Use release ID to return release data.

        Positional arguments:
        release_id (str) -- The numerical id for a given discogs release.
        """
        self.clear_params()
        self.release_extension = "/releases/{release_id}".format(release_id=release_id)
        self.url = self.build_url(self.release_extension)
        self.release = self.open_url(self.url)

        return self.release

    def build_url(self, url_extension):
        """
        Combine base url and search extension.

        Positional arguments:
        url_extension (str) -- query string to append to the base url.
        """
        return urljoin(self.base_url, url_extension)

    def _get_token(self):
        """Read config file and get user token."""
        config = configparser.RawConfigParser()
        config.read('config.cfg')
        self.user_token = config.get(self.username, "user_token")


class DiscogsData():
    """Class to process data accessed via the Discogs API."""

    def __init__(self, path_to_data=None):
        """Analyze collection data.

        If no data is provided as an argument here (JSON), data will be collected via API.

        Keyword arguments:
        path_to_data (str) -- Must be a valid path to a JSON file matching expected formatting.
        """
        self.data = None
        self.graph = None
        self.path_to_data = path_to_data
        if self.path_to_data is not None:
            json_object = FormatObject()
            self.data = json_object.LoadJson(self.path_to_data)

    def compare_users(self, users):
        """
        Check for shared releases and wantlist overlaps.

        Positional arguments:
        users (list) -- list of users to compare_users
        """
        self.releases_by_user = {}
        self.master_ids = {}
        for user in users:
            self._load_collection(user)
            self.master_ids[user] = {"master_ids": [], "release_ids": []}
            for release in self.releases_by_user[user]:
                if "master_id" in release:
                    self.master_ids[user]["master_ids"].append(release["master_id"])
                else:
                    self.master_ids[user]["release_ids"].append(release["id"])

        self._compare_id_lists()
        for record in self.releases_by_user[users[0]]:
            if record["id"] in self.union_ids:
                print("{0} -- {1}".format(record["artists"][0]["name"], record["title"]))
            if "master_id" in record:
                if record["master_id"] in self.union_masters:
                    print("{0} -- {1}".format(record["artists"][0]["name"], record["title"]))

    def _load_collection(self, user):
        """
        Load user collection from JSON file or by querying discogs.

        Positional arguments:
        user (str) -- user name to load collection for.
        """
        user_collection_path = "output/full_collections/{0}_collection.json".format(user)
        if os.path.exists(user_collection_path):
            self.releases_by_user[user] = json.load(open(user_collection_path, "r"))

        else:
            self.releases_by_user[user] = self.get_full_collection(user)

    def _compare_id_lists(self):
        """Check ID lists for all users to find common IDs."""
        setlist_master = [set(self.master_ids[id_list]["master_ids"])
                          for id_list in self.master_ids]

        setlist_release = [set(self.master_ids[id_list]["release_ids"])
                           for id_list in self.master_ids]

        self.union_ids = set.intersection(*setlist_release)
        self.union_masters = set.intersection(*setlist_master)

    def return_xml_releases(self, username="username", folder_id="folder_id",
                            output_path="/", json_output=False):
        """Special function to access release data and transform it into XML.

        Keyword arguments:
        username (str) -- Any valid discogs user name; no authentication required.
        folder_id (str) -- The folder containing all releases (0) is the only one supported.
        output_path (str) -- Location to save file(s) to; defaults to current directory.
        """
        self.username = username
        self.folder_id = folder_id
        dapi = DiscogsApi(username=username)
        self.releases = dapi.get_collection(self.username, folder_id=self.folder_id)
        release_counter = Counter(dapi.release_ids)
        for i, release in enumerate(self.releases):
            r_id = release["id"]
            json_path = os.path.join(output_path, str(r_id) + ".json")
            xml_path = os.path.join(output_path,
                                    str(r_id) + "-{0}.xml".format(release_counter[r_id]))
            if not os.path.exists(json_path) and not os.path.exists(xml_path):
                release_data = dapi.GetRelease(r_id)
                if json_output:
                    with codecs.open(json_path, "w", "utf-8") as json_file:
                        json.dump(release_data, json_file, ensure_ascii=False)

                sys.stdout.write("{:=^30}\r".format(i + 1))
                sys.stdout.flush()

                a = FormatObject()
                xml = a.DictToXml(release_data)
                a.WriteFile(xml, xml_path, opener="wb")

                print("Wrote file at {0}".format(xml_path))

            else:
                print("Found {0}".format(xml_path))

    def collection_style_graph(self, username="username", folder_id="0"):
        """Return networkx graph object linking styles that co-occur by release.

        Keyword arguments:
        username (str) -- Any valid discogs user name; no authentication required.
        folder_id (str) -- The folder containing all releases (0) is the only one supported.
        """
        self.username = username
        self.folder_id = folder_id
        if self.data is None:
            self.data = self.GetCollectionStyles()
        self.graph = self.graph_cooccurrence_data(self.data)
        return self.graph

    def graph_output(self, data_type, output_path="co_graph"):
        """
        Write graph data to formats suitable for Gephi and D3 force layout.

        Positional arguments:
        data_type (str) -- accepted values are 'gephi' and 'd3'.

        Keyword arguments:
        output_path (str) -- path to write output file (don't include extension).
        """

        valid_types = ["gephi", "d3"]

        if self.graph is None:
            print("===No Graph Data Available===")
            print("===Run graph_cooccurrence_data===")

        if data_type not in valid_types:
            print("===Invalid data_type===")
            print("===Try===")
            for t in valid_types:
                print("==={0}===".format(t))

        if data_type == "gephi":
            if not output_path.endswith(".gexf"):
                output_path += ".gexf"
            nx.write_gexf(self.graph, output_path)
            print("GEXF Written to {0}".format(output_path))

        elif data_type == "d3":
            data = json_graph.node_link_data(self.graph)
            json_data = FormatObject()
            if not output_path.endswith(".json"):
                output_path += ".json"
            json_data.SaveAsJson(data, output_path)
            print("JSON Written to {0}".format(output_path))

    def graph_cooccurrence_data(self, data=None):
        """
        Format data representing coocurrences into preliminary nodes and edges.

        kwargs:
            data (list) -- list of dict objects, each containing data for one release.
        """
        if data is None:
            data = self.data
        self.graph = nx.Graph()
        for release in data:
            self._release = release
            if "styles" not in release:
                self._release["styles"] = ["No style information"]
            if isinstance(self._release["styles"], str):
                self._release["styles"] = [self._release["styles"]]
            self._update_nodes()
            self._update_edges()
        print(self.graph.nodes(data=True))
        print(self.graph.edges(data=True))

    def _update_nodes(self):
        """Update node data based on current release."""
        for style in self._release["styles"]:
            if style not in self.graph.nodes():
                self.graph.add_node(style, count=1, ids=[self._release["id"]],
                                    release_data=[self._get_release_data()])
            else:
                self.graph.node[style]["ids"].append(self._release["id"])
                self.graph.node[style]["release_data"].append(self._get_release_data())
                self.graph.node[style]["count"] += 1

    def _update_edges(self):
        """Update edge data based on current release."""
        for ab in combinations(self._release["styles"], 2):
            if not self.graph.has_edge(*ab):
                self.graph.add_edge(ab[0], ab[1])
                self.graph.add_edge(ab[0], ab[1], weight=1, ids=[self._release["id"]],
                                    release_data=[self._get_release_data()])
            else:
                self.graph.edge[ab[0]][ab[1]]["ids"].append(self._release["id"])
                self.graph.edge[ab[0]][ab[1]]["release_data"].append(self._get_release_data())
                self.graph.edge[ab[0]][ab[1]]["weight"] += 1

    def _get_release_data(self):
        """Get key release data info.

        returns:
            release_data(dict): contains basic info about release.
        """
        release_data = {}
        release_data["id"] = self._release["id"]
        release_data["artists"] = ", ".join(a["name"] for a in self._release["artists"])
        release_data["title"] = self._release["title"]
        release_data["videos"] = self._release.get("videos", 0)
        release_data["year"] = self._release.get("year", 0)
        return release_data



    def BuildGraphData(self, nodes, edges):
        """
        Use preliminary graph data to build networkx graph object.
        
        Positional arguments:
        nodes (dict) -- Count values for nodes
        edges (dict) -- Count values for edges
        """

        graph = nx.Graph()
        for key in nodes:
            graph.add_node(key, weight=nodes[key])

        for key in edges:
            edge_values = tuple(key.split("----"))
            graph.add_edge(edge_values[0], edge_values[1], weight=edges[key])

        return graph

    def StylesDictCounter(self, styles):
        """
        Count frequency of individual styles.

        Positional arguments:
        styles (list) -- list of styles in a given release.
        """

        for s in styles:
            if s in self.styles:
                self.styles[s] += 1
            else:
                self.styles[s] = 1

    def get_full_collection(self, username, folder_id="0"):
        """
        Use discogs username to return full release data for storage, from a given folder.
        Most folders require authentication for access. Folder "0" is the "all" folder.

        Positional arguments:
        username (str) -- Any valid discogs user name; no authentication required.

        Keyword arguments:
        folder_id (str) -- The folder containing all releases (0) is the only one supported.
        """

        self.folder_id = folder_id
        self.username = username
        self.all_releases = []
        
        dapi = DiscogsApi()
        self.releases = dapi.get_collection(self.username, folder_id=self.folder_id)
        i = 1
        for release in self.releases:
            #print release["basic_information"]["artists"][0]["name"]
            r_id = release["id"]
            try:
                release_data = dapi.GetRelease(r_id)
                self.all_releases.append(release_data)

            except Exception as e:
                print(e)
                release_data = dapi.GetRelease(r_id)
                self.all_releases.append(release_data)

            #sys.stdout.write("{:=^30}\r".format(i))
            #sys.stdout.flush()
            print(i)
            i += 1

        with open("output/full_collections/{0}_collection.json".format(username), "w") as f:
            json.dump(self.all_releases, f)

        return self.all_releases

    def get_collection_styles(self, source_file=None):
        """Get styles associated with each release in a given collection."""

        self.styles_by_release = []
        self.styles = {}

        dapi = DiscogsApi()
        self.releases = dapi.get_collection(self.username, folder_id=self.folder_id)
        i = 0
        for release in self.releases:
            #print release["basic_information"]["artists"][0]["name"]
            r_id = release["id"]
            release_data = dapi.GetRelease(r_id)
            if "styles" in release_data:
                self.styles_by_release.append(release_data["styles"])
                self.StylesDictCounter(release_data["styles"])
            i += 1
            sys.stdout.write("{:=^30}\r".format(i))
            sys.stdout.flush()

        #print "{:=^30}".format("\nStyles by Count")    
        #pprint(self.styles)
        
        return self.styles_by_release


