Discogs API
===========

Scripts for accessing discogs API and processing data that's returned.

For more information about the Discogs API:

[Discogs API documentation](http://www.discogs.com/developers/)

Non built-in libraries used by this module:

[Networkx Library](http://networkx.github.io/documentation/latest/install.html)

[FormatObject](https://git.lib.msu.edu/higgi135/formatobject/tree/master)


Getting Started
--------------------

Scripts currently in place to return a user's collection; compiles "styles" for all releases; build network graph and output results in gephi or D3 format.

To work with this library, first clone the repository and change into its `py` directory:

	cd discogs/py

Open Python (or iPython) shell:

    from discogs import DiscogsData
    dd = DiscogsData()

Run `CollectionStyleGraph` to gather data about styles for every release in a given collection. Run `GetFullCollection` to get data for all releases. Supply a discogs username and the ID for a folder. Folder `0` contains all releases in a user's collection. All other folders require additional authentication to access and aren't currently functional.

    data = dd.CollectionStyleGraph(username="[discogs_user]", folder_id="0")

or

    data = dd.GetFullCollection(username="[discogs_user]", folder_id="0")

To instead load locally-stored data, supply a path to a JSON file in the appropriate format (a list of lists), when initiating the class.

    dd = DiscogsData(path_to_data="/Users/devinhiggins/Projects/discogs/data/joshua-styles_by_release.json")
    data = dd.CollectionStyleGraph()

To output the data in a format suitable for use in Gephi or a D3 network graph:

    dd.GraphOutput("gephi", output_path="/path/to/new/file")
    dd.GraphOutput("d3", output_path="path/to/new/file")

Or, to save other computed data as JSON for later use:

    json_object = JsonObject()
    json_object.SaveAsJson(dd.styles, "/path/to/new/file")
    json_object.SaveAsJson(dd.styles_by_release, "/path/to/new/file")

`dd.styles` is a dictionary object containing all styles along with counts for each. `dd.styles_by_release` is a list of lists, where each sub-list contains an individual release's set of styles. 



