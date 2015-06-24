## Discogs API

This repository contains scripts for accessing the discogs API and doing some processing on the data that's returned.

For more information about the Discogs API: [Discogs API documentation](http://www.discogs.com/developers/)

Non built-in libraries used by this module:

+ [Networkx Library](http://networkx.github.io/documentation/latest/install.html)
+ [FormatObject](https://git.lib.msu.edu/higgi135/formatobject/tree/master)


### Getting Started

Scripts are currently in place to provide such functions as: 

+ return a given user's collection in several formats 
+ compile "styles" for all releases 
+ build network graph, and output results in gephi or D3 format.
+ transfer releases between collections (developer key required)
+ add new releases to a given collection (developer key required)

### Running Code

To work with this library, first clone the repository and change into its directory:

	cd discogs

Open Python (or iPython) shell:

    python
    ipython

Now you are ready to begin using python commands, including calling the functions included in this repository. (In addition, some code can be explored in an ipython notebook: Open `discogs.ipynb` in an [ipython notebook server](http://ipython.org/notebook.html) and explore from there.)

#### Getting All Releases in XML Format

To access all releases for a given user, run the following code:

    from discogs import DiscogsData
    dd = DiscogsData()
    dd.ReturnXmlReleases(username="[discogs_user]", folder_id="0", output_path="[path/to/store/data]")

To further transform these generic XML files into MARC format, use `xslt/discogs2marc.xsl`.

#### Accessing Discogs 'Style' Content

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