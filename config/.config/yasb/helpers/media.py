""" 
Taran's Media Custom Widget

This is intended for usage with YASB.
"""

import json
import asyncio
from typing import Union

from winsdk.windows.media.control import GlobalSystemMediaTransportControlsSessionManager as MediaManager

async def get_media_info() -> Union[None, str]:
    sessions = await MediaManager.request_async()
    current_session = sessions.get_current_session()
    if current_session:
        info = await current_session.try_get_media_properties_async()
        return info.artist, info.title
    return None

async def main() -> None:
    out = await get_media_info()
    formatt = {
        "artist": "",
        "title": "",
        "status": "🔇",
        "full": ""
    }
    if out is None:
        print(json.dumps(formatt))
        return
    artist = out[0]
    title = out[1]
    formatt["artist"] = artist
    formatt["title"] = title
    formatt["full"] = f"{artist} - {title}"
    formatt["status"] = "🎧"
    print(json.dumps(formatt))

asyncio.run(main())