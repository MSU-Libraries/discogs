from discogs import DiscogsApi
from user_collection import UserCollection

class DiscogsCalls():

    def __init__(self):
        pass

    def move_collection(self, source_user, end_user):

        dapi = DiscogsApi()
        collection = dapi.get_collection(source_user)

        uc = UserCollection(end_user)

        for record in collection:
            record_id = record["id"]
            response = uc.add_release(record_id)
        
        print "Transferred {0} releases".format(len(collection))

        