from discogs import DiscogsApi
import ConfigParser

class UserCollection():

    def __init__(self, username):
        
        self.username = username
        self.user_token = self._get_token()
        self.dapi = DiscogsApi()


    def add_release(self, release_id, folder_id="1"):
        
        search_extension = "/users/{username}/collection/folders/{folder_id}/releases/{release_id}".replace("{username}", self.username).replace("{folder_id}", folder_id).replace("{release_id}", str(release_id))
        self.url = self.dapi.build_url(search_extension)
        self.dapi.add_param("token", self.user_token)
        response = self.dapi.open_url(self.url, request_type="POST")
        return response


    def _get_token(self):
        """Read config file and get user token."""

        config = ConfigParser.RawConfigParser()
        config.read('config.cfg')
        return config.get(self.username, "user_token")