import asyncio
import os
import sys
from telethon import TelegramClient
from telethon.tl.functions.help import GetConfigRequest

API_ID = os.environ.get("API_ID")
API_HASH = os.environ.get("API_HASH")

BOT_TOKEN = os.environ.get("BOT_TOKEN")
CHAT_ID = int(os.environ.get("CHAT_ID"))
MESSAGE_THREAD_ID = int(os.environ.get("MESSAGE_THREAD_ID"))
VERSION = os.environ.get("VERSION")
COMMIT = os.environ.get("COMMIT")
MSG_TEMPLATE = """
{version}

{commit}

[Github](https://github.com/taamarin/box_for_magisk)
[Releases](https://github.com/taamarin/box_for_magisk/releases)

#module #ksu #apatch #magisk #bfr #debug
""".strip()

def get_caption():
    msg = MSG_TEMPLATE.format(
        version=VERSION,
        commit=COMMIT
    )
    if len(msg) > 1024:
        return COMMIT
    return msg

def check_environ():
    if BOT_TOKEN is None:
        print("[-] Invalid BOT_TOKEN")
        exit(1)
    if CHAT_ID is None:
        print("[-] Invalid CHAT_ID")
        exit(1)
    if VERSION is None:
        print("[-] Invalid VERSION")
        exit(1)
    if COMMIT is None:
        print("[-] Invalid COMMIT")
        exit(1)

async def main():
    print("[+] Uploading to telegram")
    check_environ()
    files = sys.argv[1:]
    print("[+] Files:", files)
    if len(files) <= 0:
        print("[-] No files to upload")
        exit(1)
    print("[+] Logging in Telegram with bot")
    script_dir = os.path.dirname(os.path.abspath(sys.argv[0]))
    session_dir = os.path.join(script_dir, "bot.session")
    async with await TelegramClient(session=session_dir, api_id=API_ID, api_hash=API_HASH).start(bot_token=BOT_TOKEN) as bot:
        caption = [""] * len(files)
        caption[-1] = get_caption()
        print("[+] Caption: ")
        print("---")
        print(caption)
        print("---")
        print("[+] Sending")
        await bot.send_file(entity=CHAT_ID, file=files, caption=caption, reply_to=MESSAGE_THREAD_ID, parse_mode="markdown")
        print("[+] Done!")

if __name__ == "__main__":
    try:
        asyncio.run(main())
    except Exception as e:
        print(f"[-] An error occurred: {e}")
        
