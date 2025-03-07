"""
Taran's Notify Script.

I made this since I use the same featureset when using my Linux OS, and it's handy for sure.

How this works:
notify.py -t "Title of the notification" -b "Body of the notification" -a "App ID" -i "path/to/icon"

It'll send a notification to your Windows :)
"""

import os
import argparse

# pip install win11toast :)
from win11toast import notify

def main(*args, **kwargs) -> None:
    if kwargs["icon"] is not None:
        icon_path = os.path.abspath(kwargs["icon"])
        icon_path = f"file:///{icon_path}"

        # square icon placement as per their docs
        icon = {
            "src": icon_path,
            "placement": "appLogoOverride"
        }

    else:
        icon = None

    notify(
        title=kwargs["title"],
        body=kwargs["body"],
        app_id=kwargs["app_id"],
        icon=icon,
    )

def send_test() -> None:
    notify(
        title="Testing title",
        body="Tesing body",
        app_id="Custom APP ID"
    )

def list_all(icon: str) -> list[str]:
    if os.path.isfile(icon):
        dir_path = os.path.abspath(icon)
        print(f"{dir_path}")

if __name__ == '__main__':
    argparse = argparse.ArgumentParser(
        description="Send Windows 11 notifications with customisability. Powered by win11toast :)",
    )
    argparse.add_argument("-t", "--title", type=str, help="The title of the toast notification.", default="Default Title")
    argparse.add_argument("-b", "--body", type=str, help="The body of the toast notification (wraps text).", default="Default Body")
    argparse.add_argument("-a", "--app-id", type=str, default="Notification", required=False, help="The app id that appears above the notification. Defaults to 'Notification'")
    argparse.add_argument("-i", "--icon", type=str, required=False, default=None, help="Path to a custom icon to view. E.g., -i 'path/to/icon.png/jpg/ico (etc)'.")
    parser = argparse.parse_args()

    main(
        title=parser.title,
        body=parser.body,
        app_id=parser.app_id,
        icon=parser.icon,
    )