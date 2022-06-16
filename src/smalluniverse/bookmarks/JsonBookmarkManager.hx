package smalluniverse.bookmarks;

import smalluniverse.SmallUniverse;
import smalluniverse.util.JsonFiles;

using tink.CoreApi;

typedef Bookmarks = Map<String, EventId>;

class JsonBookmarkManager implements BookmarkManager {
	var jsonFile:String;
	var encoder:IJsonEncoder<Bookmarks>;

	public function new(bookmarkJsonFile:String) {
		this.jsonFile = bookmarkJsonFile;
		this.encoder = new JsonEncoder<Bookmarks>();
	}

	public function getBookmark(bookmarkId:String):Promise<Option<EventId>> {
		return readJson(jsonFile, encoder).next(bookmarks -> {
			final bookmark = bookmarks.get(bookmarkId);
			return bookmark != null ? Some(bookmark) : None;
		});
	}

	public function updateBookmark(
		bookmarkId:String,
		bookmark:EventId
	):Promise<Noise> {
		return readJson(jsonFile, encoder).next(bookmarks -> {
			bookmarks.set(bookmarkId, bookmark);
			return writeJson(jsonFile, bookmarks, encoder);
		});
	}
}
