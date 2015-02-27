Discogs API
===========

Scripts for accessing discogs API and processing data.
--------------------------------------------

[Discogs API documentation](http://www.discogs.com/developers/)
[Networkx Library](http://networkx.github.io/documentation/latest/install.html)

Scripts currently in place to return a user's collection; compiles styles for all releases; build network graph and output results in gephi or D3 format.

Clone repository and change into its directory:

	cd discogs

Open Python (iPython) shell:

    from discogs import DiscogsData
    dd = DiscogsData()

Run `CollectionStyleGraph` to gather data about styles for every release in a given collection. Supply a discogs username and the ID for a folder. Folder `0` contains all releases in a user's collection. All other folders require additional authentication to access and aren't currently functional.

    data = dd.CollectionStyleGraph(username="[discogs_user]", folder_id="0")

To instead load locally-stored data, supply a path to a JSON file in the appropriate format (a list of lists), when initiating the class.

    dd = DiscogsData("/Users/devinhiggins/Projects/discogs/data/joshua-styles_by_release.json")
    data = dd.CollectionStyleGraph()

To output the data in a format suitable for use in Gephi or a D3 network graph:

    a.GraphOutput("gephi", output_path="/path/to/new/file")
    a.GraphOutput("d3", output_path="path/to/new/file")

Or, to save other computed data as JSON for later use:

    json_object = JsonObject()
    json_object.SaveAsJson(dd.styles, "/path/to/new/file")
    json_object.SaveAsJson(dd.styles_by_release, "/path/to/new/file")

`dd.styles` is a dictionary object containing all styles along with counts for each. `dd.styles_by_release` is a list of lists, where each sub-list contains an individual release's set of styles. 



